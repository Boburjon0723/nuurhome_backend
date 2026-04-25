-- products jadvaliga 3D model manzili uchun ustun qo'shish
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS model_3d_url text;
