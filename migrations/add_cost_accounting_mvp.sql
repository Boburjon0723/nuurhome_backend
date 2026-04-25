-- CRM: xom ashyo, ombordan bo'limga harakat, bo'lim operatsion xarajatlari
-- Oldin: add_departments_expense_types.sql (departments jadvali) ishlatilgan bo'lishi kerak.

CREATE TABLE IF NOT EXISTS raw_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_uz TEXT NOT NULL,
    name_ru TEXT,
    name_en TEXT,
    unit TEXT NOT NULL CHECK (unit IN ('kg', 'm', 'pcs')),
    unit_price NUMERIC(14, 2) NOT NULL CHECK (unit_price >= 0),
    track_stock BOOLEAN NOT NULL DEFAULT false,
    stock_quantity NUMERIC(14, 3),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS material_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    raw_material_id UUID NOT NULL REFERENCES raw_materials (id) ON DELETE RESTRICT,
    department_id UUID NOT NULL REFERENCES departments (id) ON DELETE RESTRICT,
    quantity NUMERIC(14, 3) NOT NULL CHECK (quantity > 0),
    unit_price_snapshot NUMERIC(14, 2) NOT NULL CHECK (unit_price_snapshot >= 0),
    total_cost NUMERIC(14, 2) NOT NULL CHECK (total_cost >= 0),
    movement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_material_movements_dept ON material_movements (department_id);
CREATE INDEX IF NOT EXISTS idx_material_movements_date ON material_movements (movement_date);
CREATE INDEX IF NOT EXISTS idx_material_movements_material ON material_movements (raw_material_id);

CREATE TABLE IF NOT EXISTS department_operating_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department_id UUID NOT NULL REFERENCES departments (id) ON DELETE RESTRICT,
    category TEXT NOT NULL CHECK (
        category IN ('salary', 'utilities', 'transport', 'marketing', 'other')
    ),
    amount NUMERIC(14, 2) NOT NULL CHECK (amount >= 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dept_op_exp_dept ON department_operating_expenses (department_id);
CREATE INDEX IF NOT EXISTS idx_dept_op_exp_date ON department_operating_expenses (expense_date);

ALTER TABLE raw_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE department_operating_expenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "raw_materials_crm_all" ON raw_materials;
CREATE POLICY "raw_materials_crm_all" ON raw_materials FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "material_movements_crm_all" ON material_movements;
CREATE POLICY "material_movements_crm_all" ON material_movements FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "department_operating_expenses_crm_all" ON department_operating_expenses;
CREATE POLICY "department_operating_expenses_crm_all" ON department_operating_expenses FOR ALL
    USING (true)
    WITH CHECK (true);
