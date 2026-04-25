-- Buyurtma qatorlari uchun mahsulot bo'yicha izoh (CRM forma + chop etish)
-- Supabase SQL Editor: bir marta ishga tushiring.

ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS line_note TEXT;

COMMENT ON COLUMN public.order_items.line_note IS 'Per line item note from CRM (e.g. size detail, delivery note).';

-- RLS tekshiruvi (ixtiyoriy):
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'order_items';
-- Agar RLS yoqilgan bo'lsa, authenticated uchun SELECT/INSERT/UPDATE qoidalaringiz
-- orders bilan bog'langan shartlar (order_id) bo'yicha moslang — CRM `line_note` ni saqlashi uchun UPDATE ruxsat kerak.
