-- =============================================================================
-- Oylik to'lovlari dublikatlari: tekshirish → tozalash → noyob indeks → natija
-- Supabase → SQL Editor: barcha blokni bir marta Run qiling.
-- Eslatma: CREATE/DELETE ko'pincha "Success. No rows returned" — bu normal.
-- NATIJA: (1) va (4) so'rovlari jadval qaytarishi kerak.
-- =============================================================================

-- (1) HOZIRGI DUBLIKATLAR (agar bo'sh jadval = dublikat yo'q)
SELECT employee_id, payment_date, amount, COUNT(*) AS cnt
FROM public.employee_salary_payments
GROUP BY employee_id, payment_date, amount
HAVING COUNT(*) > 1
ORDER BY cnt DESC, payment_date DESC;

-- (2) Ortiqcha qatorlarni o'chirish (har guruhda eng eski qator qoladi)
DELETE FROM public.employee_salary_payments
WHERE id IN (
    SELECT id
    FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (
                PARTITION BY employee_id, payment_date, amount
                ORDER BY created_at ASC NULLS LAST, id ASC
            ) AS rn
        FROM public.employee_salary_payments
    ) x
    WHERE x.rn > 1
);

-- (3) Kelajakdagi bir xil yozuvlarni bloklash
CREATE UNIQUE INDEX IF NOT EXISTS uniq_employee_salary_payment_employee_date_amount
    ON public.employee_salary_payments (employee_id, payment_date, amount);

-- (4) Yana dublikat bormi? (bo'sh bo'lishi kerak)
SELECT employee_id, payment_date, amount, COUNT(*) AS cnt
FROM public.employee_salary_payments
GROUP BY employee_id, payment_date, amount
HAVING COUNT(*) > 1;

-- (5) Indeks bor-yo'qligi
SELECT indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'employee_salary_payments'
ORDER BY indexname;
