-- Hamkorga xom ashyo sotish / chiqim: balansda to'lov (payment) kabi hisoblanadi.
-- `raw_materials` jadvali bo'lishi kerak (add_cost_accounting_mvp.sql).
-- Tayyor mahsulot (products.stock) uchun: keyin add_partner_finance_line_products.sql ni ishga tushiring.
-- Supabase SQL Editor da bir marta ishga tushiring.

ALTER TABLE partner_finance_entries
    DROP CONSTRAINT IF EXISTS partner_finance_entries_entry_type_check;

ALTER TABLE partner_finance_entries
    ADD CONSTRAINT partner_finance_entries_entry_type_check CHECK (
        entry_type IN ('supply', 'payment', 'sale_out', 'payment_in')
    );

ALTER TABLE partner_finance_entry_lines
    ADD COLUMN IF NOT EXISTS raw_material_id UUID REFERENCES raw_materials (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS quantity_numeric NUMERIC(14, 3) NULL;

ALTER TABLE partner_finance_entry_lines
    DROP CONSTRAINT IF EXISTS partner_finance_entry_lines_quantity_numeric_check;

ALTER TABLE partner_finance_entry_lines
    ADD CONSTRAINT partner_finance_entry_lines_quantity_numeric_check CHECK (
        quantity_numeric IS NULL OR quantity_numeric > 0
    );

CREATE INDEX IF NOT EXISTS idx_partner_finance_lines_raw_material
    ON partner_finance_entry_lines (raw_material_id)
    WHERE raw_material_id IS NOT NULL;
