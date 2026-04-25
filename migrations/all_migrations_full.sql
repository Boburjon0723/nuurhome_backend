-- ============================================================
-- TechGear E-commerce - INCREMENTAL migratsiyalar (ESKI bazaga qo'shimchalar)
-- YANGI Supabase loyihasi uchun: avvalo supabase_fresh_install_complete.sql ni ishga tushiring.
-- Keyin kerak bo'lsa ushbu fayldagi qo'shimcha ALTER lar (ixtiyoriy).
-- ============================================================
-- Eslatma: Agar products, categories, banners jadvalari mavjud bo'lmasa,
-- 4, 5, 6-bo'limlardagi ALTER TABLE xatolik beradi - ularni o'chirib qoldiring.
-- storage.buckets ON CONFLICT bo'lishi mumkin - agar 'settings' bucket
-- allaqachon mavjud bo'lsa, 7-bo'limdagi INSERT ni o'tkazib yuboring.
-- ============================================================

-- order_items: chop etish tartibi (CRM buyurtmalar)
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS line_index INTEGER NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_order_items_order_line ON order_items(order_id, line_index);

-- products: vitrinada kategoriya ichidagi tartib (kichik raqam = yuqoriroq)
ALTER TABLE products ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

-- products: vitrinada kategoriya ichidagi tartib (kichik raqam = yuqorida)
ALTER TABLE products ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

-- products: narx 1 kg bo'yicha (CRM is_kg; og'irlik features JSONB da)
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_kg BOOLEAN NOT NULL DEFAULT false;

-- products: rang bo'yicha zaxira (ombor)
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS stock_by_color JSONB DEFAULT '{}'::jsonb;

-- order_items: miqdor kg yoki dona (kasr)
ALTER TABLE public.order_items
  ALTER COLUMN quantity TYPE NUMERIC(12, 3)
  USING (ROUND(quantity::numeric, 3));
ALTER TABLE public.order_items DROP CONSTRAINT IF EXISTS order_items_quantity_check;
ALTER TABLE public.order_items
  ADD CONSTRAINT order_items_quantity_check CHECK (quantity > 0);

-- ==================== 1. SETTINGS JADVALI ====================
-- (Agar settings mavjud bo'lsa, CREATE TABLE o'tkazilmaydi)
CREATE TABLE IF NOT EXISTS settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_name TEXT DEFAULT 'TechGear',
    logo_url TEXT,
    banner_text TEXT,
    phone TEXT,
    address TEXT,
    work_hours TEXT,
    telegram_url TEXT,
    instagram_url TEXT,
    facebook_url TEXT,
    humo_card TEXT,
    uzcard_card TEXT,
    visa_card TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public Read Settings" ON settings;
CREATE POLICY "Public Read Settings" ON settings FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin Update Settings" ON settings;
CREATE POLICY "Admin Update Settings" ON settings FOR ALL USING (auth.role() = 'authenticated');

-- Kamida bitta qator (agar settings bo'sh bo'lsa)
INSERT INTO settings (site_name)
SELECT 'TechGear'
WHERE NOT EXISTS (SELECT 1 FROM settings LIMIT 1);

-- ==================== 2. ABOUT SAHIFASI SOZLAMALARI ====================
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_hero_title TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_hero_subtitle TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_hero_image TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat1_value TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat1_label TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat2_value TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat2_label TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat3_value TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat3_label TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat4_value TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat4_label TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_title TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_text1 TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_text2 TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_image TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_images TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value1_title TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value1_desc TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value2_title TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value2_desc TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value3_title TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value3_desc TEXT;

-- Banner va banner textlar (ko'p tilli)
ALTER TABLE settings ADD COLUMN IF NOT EXISTS banner_text_uz TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS banner_text_ru TEXT;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS banner_text_en TEXT;

-- ==================== 3. PRODUCT_COLORS - RANGLAR (ko'p tilli) ====================
CREATE TABLE IF NOT EXISTS product_colors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    hex_code TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ranglar uchun ko'p tilli ustunlar
ALTER TABLE product_colors ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE product_colors ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE product_colors ADD COLUMN IF NOT EXISTS name_en TEXT;

-- RLS: product_colors uchun (anon key orqali CRM insert qilishi uchun)
ALTER TABLE product_colors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read product_colors" ON product_colors;
CREATE POLICY "Public read product_colors" ON product_colors FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert product_colors" ON product_colors;
CREATE POLICY "Allow insert product_colors" ON product_colors FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update product_colors" ON product_colors;
CREATE POLICY "Allow update product_colors" ON product_colors FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete product_colors" ON product_colors;
CREATE POLICY "Allow delete product_colors" ON product_colors FOR DELETE USING (true);

-- Mavjud ranglarni to'ldirish
UPDATE product_colors 
SET 
    name_uz = COALESCE(name_uz, name),
    name_ru = COALESCE(name_ru, name),
    name_en = COALESCE(name_en, name)
WHERE name_uz IS NULL OR name_ru IS NULL OR name_en IS NULL;

-- Ranglar katalogi (yangi DB uchun). Takror ishlatilsa, o‘chirilgan nomlar qayta paydo bo‘lishi mumkin.
INSERT INTO product_colors (name, name_uz, name_ru, name_en, hex_code) VALUES
('Oltin', 'Oltin', 'Золотой', 'Gold', '#FFD700'),
('Kumush', 'Kumush', 'Серебристый', 'Silver', '#C0C0C0'),
('Oq', 'Oq', 'Белый', 'White', '#FFFFFF'),
('Qora', 'Qora', 'Чёрный', 'Black', '#000000'),
('Sutli', 'Sutli', 'Молочный', 'Cream', '#FFFDD0'),
('Bej', 'Bej', 'Бежевый', 'Beige', '#F5F5DC'),
('Kulrang', 'Kulrang', 'Серый', 'Grey', '#808080'),
('Jigarrang', 'Jigarrang', 'Коричневый', 'Brown', '#A52A2A'),
('Yashil', 'Yashil', 'Зелёный', 'Green', '#008000'),
('Ko''k', 'Ko''k', 'Синий', 'Blue', '#0000FF'),
('Qizil', 'Qizil', 'Красный', 'Red', '#FF0000'),
('Sariq', 'Sariq', 'Жёлтый', 'Yellow', '#FFFF00'),
('Pushti', 'Pushti', 'Розовый', 'Pink', '#FFC0CB'),
('Binafsha', 'Binafsha', 'Фиолетовый', 'Purple', '#800080')
ON CONFLICT (name) DO UPDATE SET 
    name_uz = COALESCE(product_colors.name_uz, EXCLUDED.name),
    name_ru = COALESCE(product_colors.name_ru, EXCLUDED.name),
    name_en = COALESCE(product_colors.name_en, EXCLUDED.name);

-- ==================== 4. PRODUCTS JADVALI (colors, ko'p tilli) ====================
ALTER TABLE products ADD COLUMN IF NOT EXISTS colors TEXT[] DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description_uz TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description_ru TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description_en TEXT;

-- Mavjud color ustunini colors arrayga ko'chirish
UPDATE products 
SET colors = ARRAY[color] 
WHERE color IS NOT NULL AND color != '' 
  AND (colors IS NULL OR array_length(colors, 1) IS NULL);

-- ==================== 5. CATEGORIES (ko'p tilli) ====================
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_uz TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_ru TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_en TEXT;

-- ==================== 6. BANNERS (ko'p tilli) ====================
ALTER TABLE banners ADD COLUMN IF NOT EXISTS title_uz TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS title_ru TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS title_en TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS subtitle_uz TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS subtitle_ru TEXT;
ALTER TABLE banners ADD COLUMN IF NOT EXISTS subtitle_en TEXT;

-- ==================== 7. STORAGE - Settings bucket (About rasmi uchun) ====================
INSERT INTO storage.buckets (id, name, public)
VALUES ('settings', 'settings', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Auth can upload settings" ON storage.objects;
CREATE POLICY "Auth can upload settings"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'settings');

DROP POLICY IF EXISTS "Public can view settings" ON storage.objects;
CREATE POLICY "Public can view settings"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'settings');

-- ==================== 8. SITE_BENEFITS (Tez Yetkazib Berish, Sifat Kafolati, xavfsiz To'lov) ====================
CREATE TABLE IF NOT EXISTS site_benefits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sort_order INT DEFAULT 0,
    icon TEXT DEFAULT 'truck',
    title_uz TEXT,
    title_ru TEXT,
    title_en TEXT,
    desc_uz TEXT,
    desc_ru TEXT,
    desc_en TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE site_benefits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read site_benefits" ON site_benefits;
CREATE POLICY "Public read site_benefits" ON site_benefits FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert site_benefits" ON site_benefits;
CREATE POLICY "Allow insert site_benefits" ON site_benefits FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update site_benefits" ON site_benefits;
CREATE POLICY "Allow update site_benefits" ON site_benefits FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete site_benefits" ON site_benefits;
CREATE POLICY "Allow delete site_benefits" ON site_benefits FOR DELETE USING (true);

-- Default ma'lumotlar (jadval bo'sh bo'lsa)
INSERT INTO site_benefits (sort_order, icon, title_uz, title_ru, title_en, desc_uz, desc_ru, desc_en)
SELECT * FROM (VALUES
(1::int, 'truck', 'Tez Yetkazib Berish', 'Быстрая Доставка', 'Fast Delivery', '100$ dan yuqori buyurtmalar uchun bepul', 'Бесплатно при заказе от 100$', 'Free for orders over $100'),
(2::int, 'shield-check', 'Sifat Kafolati', 'Гарантия Качества', 'Quality Guarantee', 'Barcha mahsulotlarga 2 yillik kafolat', '2 года гарантии на все товары', '2-year warranty on all products'),
(3::int, 'credit-card', 'xavfsiz To''lov', 'Безопасная Оплата', 'Secure Payment', 'Humo, Uzcard va Visa orqali to''lov', 'Оплата через Humo, Uzcard и Visa', 'Pay via Humo, Uzcard and Visa')
) AS v(sort_order, icon, title_uz, title_ru, title_en, desc_uz, desc_ru, desc_en)
WHERE NOT EXISTS (SELECT 1 FROM site_benefits LIMIT 1);

-- ==================== 9. ALBUM_IMAGES (Albom sahifasi - qo'shimcha rasmlar) ====================
CREATE TABLE IF NOT EXISTS album_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url TEXT NOT NULL,
    title_uz TEXT,
    title_ru TEXT,
    title_en TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    format TEXT DEFAULT 'portrait',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE album_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read album_images" ON album_images;
CREATE POLICY "Public read album_images" ON album_images FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert album_images" ON album_images;
CREATE POLICY "Allow insert album_images" ON album_images FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update album_images" ON album_images;
CREATE POLICY "Allow update album_images" ON album_images FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete album_images" ON album_images;
CREATE POLICY "Allow delete album_images" ON album_images FOR DELETE USING (true);

-- ==================== TUGADI ====================
-- Barcha migratsiyalar muvaffaqiyatli bajarildi.
-- E-commerce: narx USD, ranglar UZ/RU/EN, About header rasmi settings orqali boshqariladi.
