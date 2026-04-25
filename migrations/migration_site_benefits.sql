-- ============================================================
-- site_benefits jadvali - Bosh sahifadagi foyda kartalari
-- Supabase SQL Editor da bajarish: New query > paste > Run
-- ============================================================

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

INSERT INTO site_benefits (sort_order, icon, title_uz, title_ru, title_en, desc_uz, desc_ru, desc_en)
SELECT * FROM (VALUES
(1::int, 'truck', 'Tez Yetkazib Berish', 'Быстрая Доставка', 'Fast Delivery', '100$ dan yuqori buyurtmalar uchun bepul', 'Бесплатно при заказе от 100$', 'Free for orders over $100'),
(2::int, 'shield-check', 'Sifat Kafolati', 'Гарантия Качества', 'Quality Guarantee', 'Barcha mahsulotlarga 2 yillik kafolat', '2 года гарантии на все товары', '2-year warranty on all products'),
(3::int, 'credit-card', 'xavfsiz To''lov', 'Безопасная Оплата', 'Secure Payment', 'Humo, Uzcard va Visa orqali to''lov', 'Оплата через Humo, Uzcard и Visa', 'Pay via Humo, Uzcard and Visa')
) AS v(sort_order, icon, title_uz, title_ru, title_en, desc_uz, desc_ru, desc_en)
WHERE NOT EXISTS (SELECT 1 FROM site_benefits LIMIT 1);
