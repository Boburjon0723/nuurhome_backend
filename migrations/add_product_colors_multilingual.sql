-- Migratsiya: product_colors jadvaliga ko'p tilli nomlar qo'shish
-- Yangi rang qo'shganda O'zbekcha, Ruscha, Inglizcha nomlarni kiritish imkoniyati

-- 1. name_uz, name_ru, name_en ustunlarini qo'shish
ALTER TABLE product_colors ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE product_colors ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE product_colors ADD COLUMN IF NOT EXISTS name_en TEXT;

-- 2. Mavjud qatorlar uchun name ni name_uz/ru/en ga nusxalash (orqaga moslik)
UPDATE product_colors 
SET 
    name_uz = COALESCE(name_uz, name),
    name_ru = COALESCE(name_ru, name),
    name_en = COALESCE(name_en, name)
WHERE name_uz IS NULL OR name_ru IS NULL OR name_en IS NULL;
