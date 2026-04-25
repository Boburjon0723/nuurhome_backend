-- Migration to support multilingual category names
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_en TEXT;

-- Move existing names to name_uz/name_ru/name_en as a starting point
UPDATE categories SET name_uz = name WHERE name_uz IS NULL;
UPDATE categories SET name_ru = name WHERE name_ru IS NULL;
UPDATE categories SET name_en = name WHERE name_en IS NULL;
