/* eslint-disable no-console */
require('dotenv').config()
const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

const SOURCE_URL = String(process.env.NUUR_SOURCE_SUPABASE_URL || '').trim()
const SOURCE_ANON_KEY = String(process.env.NUUR_SOURCE_SUPABASE_ANON_KEY || '').trim()
const SOURCE_SCHEMA = String(process.env.NUUR_SOURCE_SUPABASE_SCHEMA || 'public').trim()
const DEFAULT_TARGET_CATEGORY_SLUG = String(process.env.NUUR_DEFAULT_TARGET_CATEGORY_SLUG || '').trim()
const DRY_RUN = process.argv.includes('--dry-run')

function normalizeText(v) {
  return String(v || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ')
}

function normalizeSku(v) {
  return String(v || '').trim().toLowerCase().replace(/\s+/g, '')
}

function toNumber(v, fallback = 0) {
  const n = Number(v)
  return Number.isFinite(n) ? n : fallback
}

function toTextArray(v) {
  if (Array.isArray(v)) return v.map((x) => String(x || '').trim()).filter(Boolean)
  if (v == null) return []
  const s = String(v).trim()
  if (!s) return []
  if (s.startsWith('[') || s.startsWith('{')) {
    try {
      const j = JSON.parse(s)
      if (Array.isArray(j)) return j.map((x) => String(x || '').trim()).filter(Boolean)
    } catch {
      /* ignore */
    }
  }
  return [s]
}

async function fetchSupabaseRows(table, selectColumns) {
  const out = []
  const pageSize = 1000
  let from = 0
  while (true) {
    const to = from + pageSize - 1
    const url = `${SOURCE_URL}/rest/v1/${table}?select=${encodeURIComponent(selectColumns)}`
    const res = await fetch(url, {
      headers: {
        apikey: SOURCE_ANON_KEY,
        Authorization: `Bearer ${SOURCE_ANON_KEY}`,
        Accept: 'application/json',
        Prefer: 'count=exact',
        Range: `${from}-${to}`,
        'Content-Profile': SOURCE_SCHEMA,
      },
    })
    if (!res.ok) {
      const body = await res.text()
      throw new Error(`Supabase fetch failed [${table}] ${res.status}: ${body}`)
    }
    const rows = await res.json()
    out.push(...rows)
    if (!Array.isArray(rows) || rows.length < pageSize) break
    from += pageSize
  }
  return out
}

function isMissingColumnErrorMessage(msg) {
  return /"code":"42703"|column .* does not exist/i.test(String(msg || ''))
}

async function fetchSupabaseRowsWithFallback(table, selectCandidates) {
  let lastErr = null
  for (const cols of selectCandidates) {
    try {
      const rows = await fetchSupabaseRows(table, cols)
      return rows
    } catch (e) {
      const m = String(e?.message || e)
      lastErr = e
      if (isMissingColumnErrorMessage(m)) {
        console.warn(`   [${table}] select fallback: ${cols}`)
        continue
      }
      throw e
    }
  }
  throw lastErr || new Error(`Supabase fetch failed [${table}]`)
}

function sourceCategoryKeys(c) {
  return [
    c.slug,
    c.name,
    c.name_uz,
    c.name_ru,
    c.name_en,
  ]
    .map(normalizeText)
    .filter(Boolean)
}

function targetCategoryKeys(c) {
  return [
    c.slug,
    c.name,
    c.name_uz,
    c.name_ru,
    c.name_en,
  ]
    .map(normalizeText)
    .filter(Boolean)
}

async function main() {
  if (!SOURCE_URL || !SOURCE_ANON_KEY) {
    throw new Error(
      'NUUR_SOURCE_SUPABASE_URL va NUUR_SOURCE_SUPABASE_ANON_KEY .env faylida bo‘lishi kerak.'
    )
  }

  console.log(`Mode: ${DRY_RUN ? 'DRY RUN' : 'WRITE'}`)
  console.log('1) Manba kategoriya va mahsulotlarni o‘qish...')

  const [sourceCategories, sourceProducts] = await Promise.all([
    fetchSupabaseRowsWithFallback('categories', [
      'id,name,name_uz,name_ru,name_en,slug',
      'id,name,name_uz,name_ru,name_en',
      'id,name',
    ]),
    fetchSupabaseRowsWithFallback('products', [
      'id,category_id,name,name_uz,name_ru,name_en,description,description_uz,description_ru,description_en,size,sku,sale_price,stock,is_kg,image_url,images,color,colors,is_active,show_in_new,sort_order,model_3d_url,rating,reviews,rope_weight_kg',
      'id,category_id,name,name_uz,name_ru,name_en,description,description_uz,description_ru,description_en,size,sale_price,stock,is_kg,image_url,color,colors,is_active,show_in_new,sort_order,rating,reviews,rope_weight_kg',
      'id,category_id,name,size,sale_price,stock,image_url,color,colors',
    ]),
  ])

  console.log(`   Source categories: ${sourceCategories.length}`)
  console.log(`   Source products: ${sourceProducts.length}`)

  console.log('2) Target kategoriyalarni o‘qish...')
  const targetCategories = await prisma.category.findMany({
    select: { id: true, slug: true, name: true, name_uz: true, name_ru: true, name_en: true },
  })
  if (!targetCategories.length) {
    throw new Error('Target bazada category yo‘q. Avval category larni yarating.')
  }

  const sourceCatById = new Map(sourceCategories.map((c) => [String(c.id), c]))
  const targetCatIdByKey = new Map()
  let defaultCategoryId = null
  for (const tc of targetCategories) {
    for (const k of targetCategoryKeys(tc)) {
      if (!targetCatIdByKey.has(k)) targetCatIdByKey.set(k, tc.id)
    }
    if (
      DEFAULT_TARGET_CATEGORY_SLUG &&
      normalizeText(tc.slug) === normalizeText(DEFAULT_TARGET_CATEGORY_SLUG)
    ) {
      defaultCategoryId = tc.id
    }
  }

  console.log('3) Target products (mavjud) o‘qish...')
  const existingProducts = await prisma.product.findMany({
    select: { id: true, sku: true, name_uz: true, name_ru: true, name_en: true },
  })
  const existingBySku = new Map()
  for (const p of existingProducts) {
    const k = normalizeSku(p.sku)
    if (!k) continue
    if (!existingBySku.has(k)) existingBySku.set(k, p)
  }

  let created = 0
  let updated = 0
  let skippedNoSku = 0
  let skippedNoCategory = 0

  console.log('4) Sync boshlanishi...')
  for (const sp of sourceProducts) {
    const skuRaw = sp.size ?? sp.sku
    const sku = String(skuRaw || '').trim()
    const skuKey = normalizeSku(sku)
    if (!skuKey) {
      skippedNoSku += 1
      continue
    }

    const sc = sourceCatById.get(String(sp.category_id || ''))
    let categoryId = null
    if (sc) {
      for (const key of sourceCategoryKeys(sc)) {
        const hit = targetCatIdByKey.get(key)
        if (hit) {
          categoryId = hit
          break
        }
      }
    }
    if (!categoryId) {
      if (defaultCategoryId) {
        categoryId = defaultCategoryId
      } else {
        skippedNoCategory += 1
        continue
      }
    }

    const price = toNumber(sp.sale_price, 0)
    const stock = toNumber(sp.stock, 0)
    const images = toTextArray(sp.images)
    if (!images.length && sp.image_url) images.push(String(sp.image_url).trim())
    const colors = toTextArray(sp.colors)
    if (!colors.length && sp.color) colors.push(String(sp.color).trim())

    const payload = {
      categoryId,
      name: String(sp.name || '').trim() || null,
      name_uz: String(sp.name_uz || '').trim() || null,
      name_ru: String(sp.name_ru || '').trim() || null,
      name_en: String(sp.name_en || '').trim() || null,
      description: String(sp.description || '').trim() || null,
      description_uz: String(sp.description_uz || '').trim() || null,
      description_ru: String(sp.description_ru || '').trim() || null,
      description_en: String(sp.description_en || '').trim() || null,
      sku,
      price,
      stock,
      isKg: Boolean(sp.is_kg),
      images: images.length ? images : null,
      colors: colors.length ? colors : null,
      isActive: sp.is_active == null ? true : Boolean(sp.is_active),
      showInNew: Boolean(sp.show_in_new),
      sortOrder: Number.isFinite(Number(sp.sort_order)) ? Number(sp.sort_order) : 0,
      model3dUrl: String(sp.model_3d_url || '').trim() || null,
      rating: toNumber(sp.rating, 0),
      reviews: Math.max(0, Math.trunc(toNumber(sp.reviews, 0))),
      rope_weight_kg: sp.rope_weight_kg == null ? null : toNumber(sp.rope_weight_kg, null),
    }

    const existing = existingBySku.get(skuKey)
    if (existing) {
      updated += 1
      if (!DRY_RUN) {
        await prisma.product.update({
          where: { id: existing.id },
          data: payload,
        })
      }
    } else {
      created += 1
      if (!DRY_RUN) {
        const createdRow = await prisma.product.create({ data: payload })
        existingBySku.set(skuKey, { id: createdRow.id, sku: createdRow.sku })
      }
    }
  }

  console.log('--- SYNC RESULT ---')
  console.log(`Created: ${created}`)
  console.log(`Updated: ${updated}`)
  console.log(`Skipped (no sku): ${skippedNoSku}`)
  console.log(`Skipped (no category match): ${skippedNoCategory}`)
  console.log(`Dry run: ${DRY_RUN ? 'yes' : 'no'}`)
}

main()
  .catch((e) => {
    console.error('sync-products-from-nuur failed:', e?.message || e)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
