-- CRM: korxona bo'limlari va har bo'lim ichidagi xarajat turlari
-- Supabase SQL Editor yoki psql da bir marta ishga tushiring.

CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_uz TEXT NOT NULL,
    name_ru TEXT,
    name_en TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS department_expense_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name_uz TEXT NOT NULL,
    name_ru TEXT,
    name_en TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_department_expense_types_dept
    ON department_expense_types(department_id);

ALTER TABLE transactions
    ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL;

ALTER TABLE transactions
    ADD COLUMN IF NOT EXISTS expense_type_id UUID REFERENCES department_expense_types(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_department ON transactions(department_id);
CREATE INDEX IF NOT EXISTS idx_transactions_expense_type ON transactions(expense_type_id);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE department_expense_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "departments_crm_all" ON departments;
CREATE POLICY "departments_crm_all" ON departments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "department_expense_types_crm_all" ON department_expense_types;
CREATE POLICY "department_expense_types_crm_all" ON department_expense_types FOR ALL USING (true) WITH CHECK (true);
