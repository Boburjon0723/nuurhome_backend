/* eslint-disable no-console */
require('dotenv').config()
const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()
const DRY_RUN = process.argv.includes('--dry-run')

function normalizeSku(v) {
  return String(v || '').trim().toLowerCase().replace(/\s+/g, '')
}

async function main() {
  const url = String(process.env.NUUR_SOURCE_SUPABASE_URL || '').trim()
  const key = String(process.env.NUUR_SOURCE_SUPABASE_ANON_KEY || '').trim()
  const schema = String(process.env.NUUR_SOURCE_SUPABASE_SCHEMA || 'public').trim()
  if (!url || !key) throw new Error('NUUR source env missing')

  const fetchSource = async (cols) => {
    const res = await fetch(`${url}/rest/v1/products?select=${encodeURIComponent(cols)}`, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        Accept: 'application/json',
        'Content-Profile': schema,
      },
    })
    if (!res.ok) throw new Error(`Source fetch failed: ${await res.text()}`)
    return res.json()
  }
  let rows = []
  try {
    rows = await fetchSource('size,sku')
  } catch (e) {
    if (String(e?.message || e).includes('"code":"42703"')) {
      rows = await fetchSource('size')
    } else {
      throw e
    }
  }
  const sourceSkus = new Set(
    rows
      .map((r) => normalizeSku(r?.size ?? r?.sku))
      .filter(Boolean)
  )

  const all = await prisma.product.findMany({
    select: { id: true, sku: true, colors: true },
  })
  const targets = all.filter((p) => sourceSkus.has(normalizeSku(p.sku)))
  const toClear = targets.filter((p) => p.colors != null).map((p) => p.id)

  console.log(`Matched transferred products: ${targets.length}`)
  console.log(`Products with colors to clear: ${toClear.length}`)
  console.log(`Mode: ${DRY_RUN ? 'DRY RUN' : 'WRITE'}`)

  if (!DRY_RUN && toClear.length) {
    const result = await prisma.product.updateMany({
      where: { id: { in: toClear } },
      data: { colors: null },
    })
    console.log(`Updated rows: ${result.count}`)
  }
}

main()
  .catch((e) => {
    console.error('clear-migrated-product-colors failed:', e?.message || e)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })

