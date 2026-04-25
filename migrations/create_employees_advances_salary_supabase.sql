-- =============================================================================
-- Xodimlar + avans + oylik to'lovlari (CRM / bot)
-- Supabase: SQL Editor → yangi query → hammasini joylashtiring → Run
-- Takroriy ishlatish xavfsiz: IF NOT EXISTS / DROP POLICY IF EXISTS
-- =============================================================================

-- 1) Xodimlar (asosiy jadval)
CREATE TABLE IF NOT EXISTS public.employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    position TEXT NOT NULL,
    monthly_salary DECIMAL(12, 2) NOT NULL CHECK (monthly_salary >= 0),
    bonus_percent DECIMAL(12, 2) DEFAULT 0 CHECK (bonus_percent >= 0),
    worked_days INTEGER DEFAULT 0 CHECK (worked_days >= 0),
    rest_days INTEGER DEFAULT 0 CHECK (rest_days >= 0),
    hire_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employees_created_at ON public.employees (created_at DESC);

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public employees all" ON public.employees;
DROP POLICY IF EXISTS "Allow authenticated full access to employees" ON public.employees;
CREATE POLICY "Public employees all"
    ON public.employees
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 2) Avanslar
CREATE TABLE IF NOT EXISTS public.employee_advances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    advance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    source TEXT NOT NULL DEFAULT 'crm',
    recorded_by_phone TEXT,
    recorded_by_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employee_advances_employee ON public.employee_advances (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_advances_date ON public.employee_advances (advance_date DESC);

ALTER TABLE public.employee_advances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employee_advances_crm_all" ON public.employee_advances;
CREATE POLICY "employee_advances_crm_all"
    ON public.employee_advances
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 3) Oylik to'lovlari
CREATE TABLE IF NOT EXISTS public.employee_salary_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    source TEXT NOT NULL DEFAULT 'crm',
    recorded_by_phone TEXT,
    recorded_by_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employee_salary_payments_employee ON public.employee_salary_payments (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_salary_payments_date ON public.employee_salary_payments (payment_date DESC);

ALTER TABLE public.employee_salary_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employee_salary_payments_crm_all" ON public.employee_salary_payments;
CREATE POLICY "employee_salary_payments_crm_all"
    ON public.employee_salary_payments
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 4) Oylik oyini yopish (CRM: tanlangan oy uchun avans/oylik yozuvlarini bloklash)
CREATE TABLE IF NOT EXISTS public.employee_payroll_month_closures (
    period_ym TEXT NOT NULL PRIMARY KEY
        CHECK (period_ym ~ '^\d{4}-\d{2}$'),
    closed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT,
    source TEXT NOT NULL DEFAULT 'crm'
);

CREATE INDEX IF NOT EXISTS idx_payroll_closures_closed_at
    ON public.employee_payroll_month_closures (closed_at DESC);

ALTER TABLE public.employee_payroll_month_closures ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employee_payroll_month_closures_crm_all" ON public.employee_payroll_month_closures;
CREATE POLICY "employee_payroll_month_closures_crm_all"
    ON public.employee_payroll_month_closures
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- Tayyor. Keyin CRM da xodimlar sahifasini yangilab tekshiring.
-- Eslatma: `employees` allaqachon bo'lsa va ustunlar farq qilsa, avval jadvalni
-- backup qiling; bu skript mavjud `employees` qatorini o'zgartirmaydi.
-- =============================================================================
