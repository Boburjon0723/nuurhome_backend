-- Buyurtmalarni "karzinka" (soft delete): o‘chirish = deleted_at to‘ldiriladi.
-- Supabase SQL Editor yoki psql da bir marta ishga tushiring.

ALTER TABLE orders ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_orders_deleted_at ON orders (deleted_at) WHERE deleted_at IS NOT NULL;

COMMENT ON COLUMN orders.deleted_at IS 'NULL = faol buyurtma; to‘ldirilgan = karzinkada (soft delete)';
