-- =============================================================================
-- CRM Moliya: eski obyektlarni olib tashlash + yangi sxema (bitta skript)
-- =============================================================================
-- Fayl: supabase_moliya_schema_yangi.sql
--
-- DIQQAT: DROP TABLE qismlari tegishli jadvallardagi MA'LUMOTLARNI O'CHIRADI.
-- Ishga tushirishdan oldin Supabase → Settings → Database → Backup yoki export.
-- Supabase SQL Editor da butun faylni bir marta ishga tushiring.
--
-- Bu skript quyidagilarni BEKITADI (oldingi alohida fayllar o'rniga):
--   add_departments_expense_types.sql (qisman: types jadvali o'chiriladi)
--   add_cost_accounting_mvp.sql (to'liq olib tashlanadi)
--   add_department_tree_and_expense_entries.sql (entries qayta yaratiladi)
--   alter_department_expense_entries_nullable_type.sql (endi kerak emas)
--
-- `transactions` jadvali loyihada bo'lmasa, 2-bobdagi ALTER qatorlarni izohga oling.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) ESKI JADVALLAR (xom ashyo, harakat, operatsion xarajatlar, xarajat yozuvlari)
--    Avval bog'liq jadval, keyin asosiy.
-- -----------------------------------------------------------------------------

DROP POLICY IF EXISTS "department_expense_entries_crm_all" ON department_expense_entries;
DROP POLICY IF EXISTS "material_movements_crm_all" ON material_movements;
DROP POLICY IF EXISTS "raw_materials_crm_all" ON raw_materials;
DROP POLICY IF EXISTS "department_operating_expenses_crm_all" ON department_operating_expenses;
DROP POLICY IF EXISTS "department_expense_types_crm_all" ON department_expense_types;

DROP TABLE IF EXISTS material_movements CASCADE;
DROP TABLE IF EXISTS raw_materials CASCADE;
DROP TABLE IF EXISTS department_operating_expenses CASCADE;
DROP TABLE IF EXISTS department_expense_entries CASCADE;
DROP TABLE IF EXISTS department_expense_types CASCADE;

-- -----------------------------------------------------------------------------
-- 2) transactions jadvalidagi eski ustunlar (jadval bo'lsa)
-- -----------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'transactions'
    ) THEN
        ALTER TABLE transactions DROP COLUMN IF EXISTS expense_type_id CASCADE;
        ALTER TABLE transactions DROP COLUMN IF EXISTS department_id CASCADE;
    END IF;
END $$;

DROP INDEX IF EXISTS idx_transactions_department;
DROP INDEX IF EXISTS idx_transactions_expense_type;

-- -----------------------------------------------------------------------------
-- 3) departments — ierarxiya ustuni
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_uz TEXT NOT NULL,
    name_ru TEXT,
    name_en TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE departments
    ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES departments (id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_departments_parent ON departments (parent_id);

-- -----------------------------------------------------------------------------
-- 4) Yangi xarajat yozuvlari (faqat bo'lim + summa; xarajat turi ustuni yo'q)
-- -----------------------------------------------------------------------------

CREATE TABLE department_expense_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments (id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount >= 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dept_exp_entries_dept ON department_expense_entries (department_id);
CREATE INDEX idx_dept_exp_entries_date ON department_expense_entries (expense_date);

-- -----------------------------------------------------------------------------
-- 5) Row Level Security (Supabase)
-- -----------------------------------------------------------------------------

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE department_expense_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "departments_crm_all" ON departments;
CREATE POLICY "departments_crm_all" ON departments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "department_expense_entries_crm_all" ON department_expense_entries;
CREATE POLICY "department_expense_entries_crm_all" ON department_expense_entries FOR ALL
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- TAYYOR. Keyin: Supabase → Settings → API → "Reload schema" (agar kesh eskirgan bo'lsa).
-- =============================================================================
