-- Bo'limlar ierarxiyasi (ichki bo'limlar) va xarajat yozuvlari (bo'lim + xarajat turi)
-- Oldin: add_departments_expense_types.sql ishlatilgan bo'lishi kerak.

ALTER TABLE departments
    ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES departments (id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_departments_parent ON departments (parent_id);

CREATE TABLE IF NOT EXISTS department_expense_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments (id) ON DELETE CASCADE,
    expense_type_id UUID NOT NULL REFERENCES department_expense_types (id) ON DELETE RESTRICT,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount >= 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dept_exp_entries_dept ON department_expense_entries (department_id);
CREATE INDEX IF NOT EXISTS idx_dept_exp_entries_date ON department_expense_entries (expense_date);
CREATE INDEX IF NOT EXISTS idx_dept_exp_entries_type ON department_expense_entries (expense_type_id);

ALTER TABLE department_expense_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "department_expense_entries_crm_all" ON department_expense_entries;
CREATE POLICY "department_expense_entries_crm_all" ON department_expense_entries FOR ALL
    USING (true)
    WITH CHECK (true);
