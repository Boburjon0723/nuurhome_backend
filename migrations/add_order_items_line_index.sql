-- Buyurtma qatorlari forma/chop etish tartibi (0, 1, 2, ...)
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS line_index INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_order_items_order_line ON order_items(order_id, line_index);

COMMENT ON COLUMN order_items.line_index IS 'Formada kiritilgan tartib (0-dan boshlanadi); chop etish va SKU guruhlash';
