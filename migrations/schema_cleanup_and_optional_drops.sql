-- =============================================================================
-- NuurHome / CRM + Telegram bot — sxema audit: moslashtirish va ixtiyoriy tozalash
-- DIQQAT: DROP qatorlari izohda. Avval backup, keyin kerak bo'lsa ochib ishlating.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A) CRM uchun kerakli ustunlar (sizning sxemangizda bo'lmasa — qo'shiladi)
--     To'liq variant: add_finance_dual_currency.sql ni ham ishga tushirish mumkin.
-- -----------------------------------------------------------------------------
ALTER TABLE public.material_movements
    ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'UZS';

ALTER TABLE public.material_movements
    DROP CONSTRAINT IF EXISTS material_movements_currency_check;

ALTER TABLE public.material_movements
    ADD CONSTRAINT material_movements_currency_check CHECK (currency IN ('UZS', 'USD'));

UPDATE public.material_movements SET currency = 'UZS' WHERE trim(currency) = '';

ALTER TABLE public.partner_finance_entries
    ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'UZS';

ALTER TABLE public.partner_finance_entries
    DROP CONSTRAINT IF EXISTS partner_finance_entries_currency_check;

ALTER TABLE public.partner_finance_entries
    ADD CONSTRAINT partner_finance_entries_currency_check CHECK (currency IN ('UZS', 'USD'));

UPDATE public.partner_finance_entries SET currency = 'UZS' WHERE trim(currency) = '';

-- -----------------------------------------------------------------------------
-- B) Xodimlar: avans / oylik (agar jadval yo'q bo'lsa)
-- -----------------------------------------------------------------------------
-- add_employee_advances.sql
-- add_employee_salary_payments.sql
-- (Sizda ikkalasi ham bor — qayta yaratish shart emas.)

-- -----------------------------------------------------------------------------
-- C) Eski salary_payments → employee_salary_payments (ixtiyoriy, DROP dan oldin)
--     Eski jadvalda ma'lumot bo'lsa bir marta ishga tushiring.
-- -----------------------------------------------------------------------------
/*
INSERT INTO public.employee_salary_payments (
    employee_id, amount, payment_date, note, source, created_at
)
SELECT
    sp.employee_id,
    COALESCE(sp.total, sp.base_salary, 0)::numeric,
    COALESCE((sp.paid_at::date), make_date(sp.year, sp.month, 1)),
    sp.notes,
    'migrated_from_salary_payments',
    COALESCE(sp.paid_at::timestamptz, now())
FROM public.salary_payments sp
WHERE sp.employee_id IS NOT NULL
  AND COALESCE(sp.total, sp.base_salary, 0) > 0;
*/

-- -----------------------------------------------------------------------------
-- D) Keraksiz deb hisoblangan jadvallar — FAQAT backupdan keyin!
--     CRM/telegram-finance-bot kodida .from('...') bilan ishlatilmaydi.
-- -----------------------------------------------------------------------------
-- | Jadval                        | Sabab                                              |
-- |-------------------------------|----------------------------------------------------|
-- | salary_payments               | Yangi oqim: employee_salary_payments             |
-- | expenses                      | CRM transactions / material_movements ishlatiladi  |
-- | attendance                    | Hozircha CRMda ishlatilmaydi                       |
-- | department_operating_expenses | CRMda ishlatilmaydi (bolimlar → material_movements)|
-- | inventory_movements           | CRMda ishlatilmaydi                                |
-- | stock_history                 | CRMda ishlatilmaydi                                |
--
-- Quyidagilarni ochib RUN qilmang, agar boshqa servis/skript ulardan foydalansa!

/*
DROP TABLE IF EXISTS public.stock_history CASCADE;
DROP TABLE IF EXISTS public.inventory_movements CASCADE;
DROP TABLE IF EXISTS public.department_operating_expenses CASCADE;
DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.salary_payments CASCADE;
*/

-- -----------------------------------------------------------------------------
-- E) Xodim o'chirilganda bog'langan yozuvlar (ixtiyoriy, FK qayta yaratish)
-- -----------------------------------------------------------------------------
/*
ALTER TABLE public.employee_advances DROP CONSTRAINT IF EXISTS employee_advances_employee_id_fkey;
ALTER TABLE public.employee_advances
    ADD CONSTRAINT employee_advances_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;

ALTER TABLE public.employee_salary_payments DROP CONSTRAINT IF EXISTS employee_salary_payments_employee_id_fkey;
ALTER TABLE public.employee_salary_payments
    ADD CONSTRAINT employee_salary_payments_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;
*/
