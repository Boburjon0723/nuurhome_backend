-- Tavsiya: bitta fayl — fix_employee_salary_duplicates_verify.sql (tekshiruv + tozalash + indeks + natija).
-- Yoki faqat indeks kerak bo‘lsa:

CREATE UNIQUE INDEX IF NOT EXISTS uniq_employee_salary_payment_employee_date_amount
    ON public.employee_salary_payments (employee_id, payment_date, amount);
