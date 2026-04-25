-- Hamkordan naqd / pul tushumi (sotilgan mahsulot uchun to‘lov va hokazo).
-- Balansda xomashyo kirimi (supply) bilan bir xil yo‘nalish: b += summa.
-- Supabase SQL Editor da bir marta ishga tushiring.

ALTER TABLE partner_finance_entries
    DROP CONSTRAINT IF EXISTS partner_finance_entries_entry_type_check;

ALTER TABLE partner_finance_entries
    ADD CONSTRAINT partner_finance_entries_entry_type_check CHECK (
        entry_type IN ('supply', 'payment', 'sale_out', 'payment_in')
    );
