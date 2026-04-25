-- Hamkor sotish (sale_out) qatorlarida tayyor mahsulot: products.stock dan chiqim
-- Avval add_partner_finance_sale_out.sql ishlagan bo'lishi kerak.
-- `products` jadvali (ombor) bo'lishi kerak.

ALTER TABLE partner_finance_entry_lines
    ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS product_quantity INTEGER NULL;

ALTER TABLE partner_finance_entry_lines
    DROP CONSTRAINT IF EXISTS partner_finance_lines_raw_or_product_check;

ALTER TABLE partner_finance_entry_lines
    ADD CONSTRAINT partner_finance_lines_raw_or_product_check CHECK (
        NOT (raw_material_id IS NOT NULL AND product_id IS NOT NULL)
    );

ALTER TABLE partner_finance_entry_lines
    DROP CONSTRAINT IF EXISTS partner_finance_lines_product_quantity_check;

ALTER TABLE partner_finance_entry_lines
    ADD CONSTRAINT partner_finance_lines_product_quantity_check CHECK (
        product_id IS NULL OR (product_quantity IS NOT NULL AND product_quantity > 0)
    );

CREATE INDEX IF NOT EXISTS idx_partner_finance_lines_product
    ON partner_finance_entry_lines (product_id)
    WHERE product_id IS NOT NULL;
