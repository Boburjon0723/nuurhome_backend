-- Tranzaksiya tafsilotlari: kod, ombor, mas'ul + xomashyo qatorlari
-- Avval add_finance_partners.sql ishlagan bo'lishi kerak.

ALTER TABLE partner_finance_entries
    ADD COLUMN IF NOT EXISTS reference_code TEXT,
    ADD COLUMN IF NOT EXISTS warehouse_note TEXT,
    ADD COLUMN IF NOT EXISTS responsible_name TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_partner_finance_entries_ref_code
    ON partner_finance_entries (reference_code)
    WHERE reference_code IS NOT NULL;

CREATE TABLE IF NOT EXISTS partner_finance_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID NOT NULL REFERENCES partner_finance_entries (id) ON DELETE CASCADE,
    line_index INTEGER NOT NULL DEFAULT 0,
    item_name TEXT NOT NULL,
    quantity_display TEXT NOT NULL,
    unit_price_uzs NUMERIC(14, 2) NOT NULL CHECK (unit_price_uzs >= 0),
    line_total_uzs NUMERIC(14, 2) NOT NULL CHECK (line_total_uzs > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_partner_finance_lines_entry ON partner_finance_entry_lines (entry_id);

ALTER TABLE partner_finance_entry_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "partner_finance_entry_lines_crm_all" ON partner_finance_entry_lines;
CREATE POLICY "partner_finance_entry_lines_crm_all" ON partner_finance_entry_lines FOR ALL USING (true) WITH CHECK (true);
