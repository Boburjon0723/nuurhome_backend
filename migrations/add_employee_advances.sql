-- Xodimlarga berilgan avanslar (Telegram bot va CRM)
-- Avval `employees` jadvali bo'lishi kerak.
-- Supabase SQL Editor da bir marta ishga tushiring.

CREATE TABLE IF NOT EXISTS employee_advances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees (id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    advance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    source TEXT NOT NULL DEFAULT 'telegram',
    recorded_by_phone TEXT,
    recorded_by_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employee_advances_employee ON employee_advances (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_advances_date ON employee_advances (advance_date DESC);

ALTER TABLE employee_advances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employee_advances_crm_all" ON employee_advances;
CREATE POLICY "employee_advances_crm_all" ON employee_advances FOR ALL USING (true) WITH CHECK (true);
