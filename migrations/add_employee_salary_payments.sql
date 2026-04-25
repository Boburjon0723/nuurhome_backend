-- Oylik to'lovlari (Telegram bot va CRM)
-- Avval `employees` jadvali bo'lishi kerak.
-- Supabase SQL Editor da bir marta ishga tushiring.

CREATE TABLE IF NOT EXISTS employee_salary_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees (id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    source TEXT NOT NULL DEFAULT 'telegram',
    recorded_by_phone TEXT,
    recorded_by_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employee_salary_payments_employee ON employee_salary_payments (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_salary_payments_date ON employee_salary_payments (payment_date DESC);

ALTER TABLE employee_salary_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employee_salary_payments_crm_all" ON employee_salary_payments;
CREATE POLICY "employee_salary_payments_crm_all" ON employee_salary_payments FOR ALL USING (true) WITH CHECK (true);
