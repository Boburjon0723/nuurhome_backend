-- Master Refinement Migration
-- 1. MULTILINGUAL PRODUCTS
ALTER TABLE products ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description_uz TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description_ru TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description_en TEXT;

-- Initial data sync for products
UPDATE products SET name_uz = name WHERE name_uz IS NULL;
UPDATE products SET name_ru = name WHERE name_ru IS NULL;
UPDATE products SET name_en = name WHERE name_en IS NULL;
UPDATE products SET description_uz = description WHERE description_uz IS NULL;

-- 2. MULTILINGUAL BANNERS
ALTER TABLE banners ADD COLUMN IF NOT EXISTS title_uz TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS title_ru TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS title_en TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS subtitle_uz TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS subtitle_ru TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS subtitle_en TEXT;

-- Initial data sync for banners
UPDATE banners SET title_uz = title WHERE title_uz IS NULL;
UPDATE banners SET title_ru = title WHERE title_ru IS NULL;
UPDATE banners SET title_en = title WHERE title_en IS NULL;
UPDATE banners SET subtitle_uz = subtitle WHERE subtitle_uz IS NULL;

-- 3. MULTILINGUAL SETTINGS
ALTER TABLE settings ADD COLUMN IF NOT EXISTS banner_text_uz TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS banner_text_ru TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS banner_text_en TEXT;

-- Initial data sync for settings
UPDATE settings SET banner_text_uz = banner_text WHERE banner_text_uz IS NULL;
UPDATE settings SET banner_text_ru = banner_text WHERE banner_text_ru IS NULL;
UPDATE settings SET banner_text_en = banner_text WHERE banner_text_en IS NULL;

-- 4. ENSURE CATEGORIES LOCALIZATION (Sanity)
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_en TEXT;

-- 5. ENSURE OTHER SYSTEM TABLES EXIST (Sanity Check)
CREATE TABLE IF NOT EXISTS moliya (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT now(),
    type TEXT, -- income, expense
    amount NUMERIC,
    description TEXT,
    date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS xodimlar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT now(),
    name TEXT NOT NULL,
    position TEXT,
    salary NUMERIC,
    phone TEXT
);
