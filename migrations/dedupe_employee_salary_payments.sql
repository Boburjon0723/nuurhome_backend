-- Bir xil (employee_id, payment_date, amount) guruhlarida faqat bitta qator qoldiradi (eng ilgari yaratilgan).
-- Ishga tushirishdan oldin zaxira oling. Keyin: employee_salary_payments_unique_day_amount.sql

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
