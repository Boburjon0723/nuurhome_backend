-- Mahsulot ranglari bo'yicha alohida zaxira (ombor)
-- Supabase SQL Editor da bir marta ishga tushiring.

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS stock_by_color JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.products.stock_by_color IS 'Rang nomi -> dona soni, masalan {"Qora":5,"Kumush":2}. products.stock jami bilan sinxron (yig''indi).';
