-- Hamkorlar moliya boshqaruvi (xomashyo kirimi / to'lovlar)
-- Supabase SQL Editor da bir marta ishga tushiring.

CREATE TABLE IF NOT EXISTS finance_partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_uz TEXT NOT NULL,
    name_ru TEXT,
    name_en TEXT,
    legal_id TEXT,
    phone TEXT,
    note TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_finance_partners_active ON finance_partners (is_active);
CREATE INDEX IF NOT EXISTS idx_finance_partners_name ON finance_partners (name_uz);

CREATE TABLE IF NOT EXISTS partner_finance_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID NOT NULL REFERENCES finance_partners (id) ON DELETE CASCADE,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('supply', 'payment')),
    amount_uzs NUMERIC(14, 2) NOT NULL CHECK (amount_uzs > 0),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_partner_finance_entries_partner ON partner_finance_entries (partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_finance_entries_date ON partner_finance_entries (entry_date);

ALTER TABLE finance_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_finance_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "finance_partners_crm_all" ON finance_partners;
CREATE POLICY "finance_partners_crm_all" ON finance_partners FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "partner_finance_entries_crm_all" ON partner_finance_entries;
CREATE POLICY "partner_finance_entries_crm_all" ON partner_finance_entries FOR ALL USING (true) WITH CHECK (true);

-- Tranzaksiya tafsilotlari (kod, ombor, mas'ul, xomashyo qatorlari): add_partner_finance_entry_details.sql
