-- CRM / vitrina: mahsulot narxi 1 kg bo'yicha (arqon va h.k.)
-- Supabase SQL Editor da bir marta ishga tushiring.

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS is_kg BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.products.is_kg IS 'True: sale_price is per 1 kg. Pack weight stored in features JSONB (Ogirligi / Weight kg rows).';
