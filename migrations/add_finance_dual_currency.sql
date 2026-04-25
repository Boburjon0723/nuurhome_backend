-- Bo'lim xarajatlari va hamkor moliyasi: so'm va dollar alohida hisoblanadi.
-- Supabase SQL Editor da bir marta ishga tushiring.

ALTER TABLE material_movements
    ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'UZS';

ALTER TABLE material_movements
    DROP CONSTRAINT IF EXISTS material_movements_currency_check;

ALTER TABLE material_movements
    ADD CONSTRAINT material_movements_currency_check CHECK (currency IN ('UZS', 'USD'));

UPDATE material_movements SET currency = 'UZS' WHERE currency IS NULL OR trim(currency) = '';

ALTER TABLE partner_finance_entries
    ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'UZS';

ALTER TABLE partner_finance_entries
    DROP CONSTRAINT IF EXISTS partner_finance_entries_currency_check;

ALTER TABLE partner_finance_entries
    ADD CONSTRAINT partner_finance_entries_currency_check CHECK (currency IN ('UZS', 'USD'));

UPDATE partner_finance_entries SET currency = 'UZS' WHERE currency IS NULL OR trim(currency) = '';
