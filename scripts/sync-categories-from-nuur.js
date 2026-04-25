/* eslint-disable no-console */
require('dotenv').config()
const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

const SOURCE_URL = String(process.env.NUUR_SOURCE_SUPABASE_URL || '').trim()
const SOURCE_ANON_KEY = String(process.env.NUUR_SOURCE_SUPABASE_ANON_KEY || '').trim()
const SOURCE_SCHEMA = String(process.env.NUUR_SOURCE_SUPABASE_SCHEMA || 'public').trim()
const DRY_RUN = process.argv.includes('--dry-run')

function normalizeText(v) {
  return String(v || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ')
}

function slugify(v) {
  const s = String(v || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
  return s || 'category'
}

function isMissingColumnErrorMessage(msg) {
  return /"code":"42703"|column .* does not exist/i.test(String(msg || ''))
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

async function fetchCategoriesWithFallback() {
  const candidates = [
    'id,name,name_uz,name_ru,name_en,slug',
    'id,name,name_uz,name_ru,name_en',
    'id,name',
  ]
  let lastErr = null
  for (const cols of candidates) {
    try {
      return await fetchSupabaseRows('categories', cols)
    } catch (e) {
      const m = String(e?.message || e)
      lastErr = e
      if (isMissingColumnErrorMessage(m)) {
        console.warn(`   [categories] select fallback: ${cols}`)
        continue
      }
      throw e
    }
  }
  throw lastErr || new Error('Cannot fetch source categories')
}

function keysOfCategory(c) {
  return [c.slug, c.name, c.name_uz, c.name_ru, c.name_en].map(normalizeText).filter(Boolean)
}

async function main() {
  if (!SOURCE_URL || !SOURCE_ANON_KEY) {
    throw new Error('NUUR_SOURCE_SUPABASE_URL va NUUR_SOURCE_SUPABASE_ANON_KEY .env faylida bo‘lishi kerak.')
  }

  console.log(`Mode: ${DRY_RUN ? 'DRY RUN' : 'WRITE'}`)
  console.log('1) Manba kategoriyalarni o‘qish...')
  const sourceCategories = await fetchCategoriesWithFallback()
  console.log(`   Source categories: ${sourceCategories.length}`)

  console.log('2) Target kategoriyalarni o‘qish...')
  const targetCategories = await prisma.category.findMany({
    select: { id: true, slug: true, name: true, name_uz: true, name_ru: true, name_en: true },
  })
  const targetByKey = new Map()
  for (const tc of targetCategories) {
    for (const k of keysOfCategory(tc)) {
      if (!targetByKey.has(k)) targetByKey.set(k, tc)
    }
  }

  let created = 0
  let updated = 0
  let skipped = 0

  console.log('3) Sync boshlanishi...')
  for (const sc of sourceCategories) {
    const name_uz = String(sc.name_uz || sc.name || '').trim() || null
    const name_ru = String(sc.name_ru || '').trim() || null
    const name_en = String(sc.name_en || '').trim() || null
    const name = String(sc.name || sc.name_uz || '').trim() || null
    const keyCandidate = keysOfCategory(sc)[0]
    if (!keyCandidate) {
      skipped += 1
      continue
    }

    const slugRaw = String(sc.slug || '').trim()
    const slug = slugRaw || `${slugify(name || name_uz || 'category')}-${String(sc.id || '').slice(0, 8)}`
    const payload = { name, name_uz, name_ru, name_en, slug }

    let hit = null
    for (const k of keysOfCategory(sc)) {
      const found = targetByKey.get(k)
      if (found) {
        hit = found
        break
      }
    }

    if (hit) {
      updated += 1
      if (!DRY_RUN) {
        const row = await prisma.category.update({
          where: { id: hit.id },
          data: {
            name: payload.name ?? hit.name,
            name_uz: payload.name_uz ?? hit.name_uz,
            name_ru: payload.name_ru ?? hit.name_ru,
            name_en: payload.name_en ?? hit.name_en,
          },
        })
        for (const k of keysOfCategory(row)) {
          if (!targetByKey.has(k)) targetByKey.set(k, row)
        }
      }
      continue
    }

    created += 1
    if (!DRY_RUN) {
      const row = await prisma.category.create({ data: payload })
      for (const k of keysOfCategory(row)) {
        if (!targetByKey.has(k)) targetByKey.set(k, row)
      }
    }
  }

  console.log('--- CATEGORY SYNC RESULT ---')
  console.log(`Created: ${created}`)
  console.log(`Updated: ${updated}`)
  console.log(`Skipped: ${skipped}`)
  console.log(`Dry run: ${DRY_RUN ? 'yes' : 'no'}`)
}

main()
  .catch((e) => {
    console.error('sync-categories-from-nuur failed:', e?.message || e)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })

