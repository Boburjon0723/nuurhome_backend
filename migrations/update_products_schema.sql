-- Add new columns for enhanced product management

-- 1. features: For storing key-value pairs like {"Material": "Cotton", "Color": "Red"}
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '{}';

-- 2. images: For storing multiple image URLs as an array
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}';

-- 3. original_price: To show "Was" price for discounts
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS original_price NUMERIC DEFAULT 0;

-- 4. stock / min_stock: CRM ombor, buyurtmalar va moliya integratsiyasi (supabase_fresh_install_complete.sql bilan mos)
ALTER TABLE products
ADD COLUMN IF NOT EXISTS stock INTEGER DEFAULT 0;

ALTER TABLE products
ADD COLUMN IF NOT EXISTS min_stock INTEGER DEFAULT 0;

-- 5. is_kg: CRM da kg narxi rejimi (og'irlik features JSONB ichida)
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS is_kg BOOLEAN NOT NULL DEFAULT false;

-- Optional: Add detailed description if needed (description is already there but maybe we want specific sections)
-- ALTER TABLE products ADD COLUMN IF NOT EXISTS specs JSONB DEFAULT '{}';
