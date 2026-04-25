-- ============================================================
-- YANGI SUPABASE LOYIHASI — TO'LIQ SXEMA (E-commerce + CRM)
-- Supabase Dashboard → SQL Editor → New query → bu faylni joylashtiring → Run
-- Xavfsiz qayta ishlatish: CREATE IF NOT EXISTS / DROP POLICY IF EXISTS
-- ============================================================

-- ==================== 1. KATEGORIYALAR ====================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_uz TEXT,
    name_ru TEXT,
    name_en TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read categories" ON categories;
CREATE POLICY "Public read categories" ON categories FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert categories" ON categories;
CREATE POLICY "Allow insert categories" ON categories FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update categories" ON categories;
CREATE POLICY "Allow update categories" ON categories FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete categories" ON categories;
CREATE POLICY "Allow delete categories" ON categories FOR DELETE USING (true);

-- ==================== 2. MAHSULOTLAR ====================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_uz TEXT,
    name_ru TEXT,
    name_en TEXT,
    description TEXT,
    description_uz TEXT,
    description_ru TEXT,
    description_en TEXT,
    price NUMERIC(12, 2) DEFAULT 0,
    sale_price NUMERIC(12, 2) DEFAULT 0,
    original_price NUMERIC(12, 2) DEFAULT 0,
    purchase_price NUMERIC(12, 2) DEFAULT 0,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    category TEXT,
    image_url TEXT,
    images TEXT[] DEFAULT '{}',
    color TEXT,
    colors TEXT[] DEFAULT '{}',
    size TEXT,
    stock INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    features JSONB DEFAULT '{}',
    rating NUMERIC(5, 2) DEFAULT 0,
    reviews INTEGER DEFAULT 0,
    model_3d_url TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_kg BOOLEAN NOT NULL DEFAULT false,
    stock_by_color JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read products" ON products;
CREATE POLICY "Public read products" ON products FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert products" ON products;
CREATE POLICY "Allow insert products" ON products FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update products" ON products;
CREATE POLICY "Allow update products" ON products FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete products" ON products;
CREATE POLICY "Allow delete products" ON products FOR DELETE USING (true);

-- ==================== 3. BANNERLAR ====================
CREATE TABLE IF NOT EXISTS banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT,
    title_uz TEXT,
    title_ru TEXT,
    title_en TEXT,
    subtitle TEXT,
    subtitle_uz TEXT,
    subtitle_ru TEXT,
    subtitle_en TEXT,
    image_url TEXT,
    link TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read banners" ON banners;
CREATE POLICY "Public read banners" ON banners FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert banners" ON banners;
CREATE POLICY "Allow insert banners" ON banners FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update banners" ON banners;
CREATE POLICY "Allow update banners" ON banners FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete banners" ON banners;
CREATE POLICY "Allow delete banners" ON banners FOR DELETE USING (true);

-- ==================== 4. MIJOZLAR (auth bilan bog'lanishi mumkin) ====================
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY,
    name TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    country TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can insert their own profile" ON customers;
DROP POLICY IF EXISTS "Users can view own profile" ON customers;
DROP POLICY IF EXISTS "Public full customers" ON customers;
CREATE POLICY "Public full customers" ON customers FOR ALL USING (true) WITH CHECK (true);

-- ==================== 5. BUYURTMALAR ====================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    customer_name TEXT,
    customer_phone TEXT,
    customer_address TEXT,
    total NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status TEXT DEFAULT 'new',
    payment_status TEXT,
    payment_method_detail TEXT,
    receipt_url TEXT,
    note TEXT,
    source TEXT DEFAULT 'website',
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_deleted_at ON orders (deleted_at) WHERE deleted_at IS NOT NULL;

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public orders all" ON orders;
CREATE POLICY "Public orders all" ON orders FOR ALL USING (true) WITH CHECK (true);

-- ==================== 6. BUYURTMA QATORLARI ====================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name TEXT,
    quantity NUMERIC(12, 3) NOT NULL CHECK (quantity > 0),
    price NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(12, 2),
    color TEXT,
    size TEXT,
    image_url TEXT,
    line_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_line ON order_items(order_id, line_index);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public order_items all" ON order_items;
CREATE POLICY "Public order_items all" ON order_items FOR ALL USING (true) WITH CHECK (true);

-- ==================== 7. RANGLAR KATALOGI ====================
CREATE TABLE IF NOT EXISTS product_colors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    hex_code TEXT NOT NULL,
    name_uz TEXT,
    name_ru TEXT,
    name_en TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE product_colors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read product_colors" ON product_colors;
CREATE POLICY "Public read product_colors" ON product_colors FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow insert product_colors" ON product_colors;
CREATE POLICY "Allow insert product_colors" ON product_colors FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow update product_colors" ON product_colors;
CREATE POLICY "Allow update product_colors" ON product_colors FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow delete product_colors" ON product_colors;
CREATE POLICY "Allow delete product_colors" ON product_colors FOR DELETE USING (true);

-- DIQQAT: Bu INSERT ni production / mavjud bazada takror ishlatish — o‘chirib tashlangan
-- standart ranglarni qayta yaratadi (qator yo‘q bo‘lsa yangi INSERT bo‘ladi).
-- Faqat yangi o‘rnatishda ishlating; deploy pipeline da bu skriptni to‘liq qayta yurgizmang.

INSERT INTO product_colors (name, name_uz, name_ru, name_en, hex_code) VALUES
('Oltin', 'Oltin', 'Золотой', 'Gold', '#FFD700'),
('Kumush', 'Kumush', 'Серебристый', 'Silver', '#C0C0C0'),
('Oq', 'Oq', 'Белый', 'White', '#FFFFFF'),
('Qora', 'Qora', 'Чёрный', 'Black', '#000000'),
('Yashil', 'Yashil', 'Зелёный', 'Green', '#008000'),
('Ko''k', 'Ko''k', 'Синий', 'Blue', '#0000FF'),
('Qizil', 'Qizil', 'Красный', 'Red', '#FF0000'),
('Sariq', 'Sariq', 'Жёлтый', 'Yellow', '#FFFF00'),
('Pushti', 'Pushti', 'Розовый', 'Pink', '#FFC0CB'),
('Binafsha', 'Binafsha', 'Фиолетовый', 'Purple', '#800080')
ON CONFLICT (name) DO UPDATE SET
    name_uz = COALESCE(product_colors.name_uz, EXCLUDED.name_uz),
    name_ru = COALESCE(product_colors.name_ru, EXCLUDED.name_ru),
    name_en = COALESCE(product_colors.name_en, EXCLUDED.name_en);

-- ==================== 8. SOZLAMALAR ====================
CREATE TABLE IF NOT EXISTS settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_name TEXT DEFAULT 'Mening Do''konim',
    logo_url TEXT,
    banner_text TEXT,
    banner_text_uz TEXT,
    banner_text_ru TEXT,
    banner_text_en TEXT,
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
    latitude NUMERIC(10, 6),
    longitude NUMERIC(10, 6),
    hero_desktop_url TEXT,
    hero_mobile_url TEXT,
    about_hero_title TEXT,
    about_hero_subtitle TEXT,
    about_hero_image TEXT,
    stat1_value TEXT,
    stat1_label TEXT,
    stat2_value TEXT,
    stat2_label TEXT,
    stat3_value TEXT,
    stat3_label TEXT,
    stat4_value TEXT,
    stat4_label TEXT,
    about_mission_title TEXT,
    about_mission_text1 TEXT,
    about_mission_text2 TEXT,
    about_mission_image TEXT,
    about_mission_images TEXT,
    value1_title TEXT,
    value1_desc TEXT,
    value2_title TEXT,
    value2_desc TEXT,
    value3_title TEXT,
    value3_desc TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read Settings" ON settings;
DROP POLICY IF EXISTS "Admin Update Settings" ON settings;
DROP POLICY IF EXISTS "Allow all settings for CRM" ON settings;
CREATE POLICY "Allow all settings for CRM" ON settings FOR ALL USING (true) WITH CHECK (true);

INSERT INTO settings (site_name)
SELECT 'Mening Do''konim'
WHERE NOT EXISTS (SELECT 1 FROM settings LIMIT 1);

-- ==================== 9. SITE_BENEFITS ====================
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

-- ==================== 10. ALBOM RASMLARI ====================
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

-- ==================== 11. NEWSLETTER ====================
CREATE TABLE IF NOT EXISTS newsletter_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE newsletter_subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can subscribe" ON newsletter_subscriptions;
DROP POLICY IF EXISTS "Admins can view subscriptions" ON newsletter_subscriptions;
DROP POLICY IF EXISTS "Admins can manage subscriptions" ON newsletter_subscriptions;
DROP POLICY IF EXISTS "Public newsletter all" ON newsletter_subscriptions;
CREATE POLICY "Public newsletter all" ON newsletter_subscriptions FOR ALL USING (true) WITH CHECK (true);

-- ==================== 12. ALOQA XABARLARI ====================
CREATE TABLE IF NOT EXISTS contact_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    subject TEXT,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'read', 'replied')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    replied_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_contact_messages_created_at ON contact_messages(created_at DESC);

ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can insert contact messages" ON contact_messages;
CREATE POLICY "Public can insert contact messages" ON contact_messages FOR INSERT TO public WITH CHECK (true);
DROP POLICY IF EXISTS "Public can select contact messages" ON contact_messages;
CREATE POLICY "Public can select contact messages" ON contact_messages FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Public can update contact messages" ON contact_messages;
CREATE POLICY "Public can update contact messages" ON contact_messages FOR UPDATE TO public USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Public can delete contact messages" ON contact_messages;
CREATE POLICY "Public can delete contact messages" ON contact_messages FOR DELETE TO public USING (true);

-- ==================== 13. SHARHLAR ====================
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    author_display_name TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view approved reviews" ON reviews;
CREATE POLICY "Public can view approved reviews" ON reviews FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON reviews;
CREATE POLICY "Authenticated users can create reviews" ON reviews FOR INSERT WITH CHECK (true);

-- ==================== 14. MOLIYA (TRANSACTIONS) ====================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    category VARCHAR(100),
    description TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_type VARCHAR(50),
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated full access to transactions" ON transactions;
DROP POLICY IF EXISTS "Public transactions all" ON transactions;
CREATE POLICY "Public transactions all" ON transactions FOR ALL USING (true) WITH CHECK (true);

-- ==================== 15. INVENTORY MOVEMENTS (ixtiyoriy) ====================
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('purchase', 'sale', 'return', 'adjustment', 'damage')),
    quantity INTEGER NOT NULL,
    previous_stock INTEGER NOT NULL,
    new_stock INTEGER NOT NULL,
    unit_cost DECIMAL(12, 2),
    reference_type VARCHAR(50),
    reference_id UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow inventory movements" ON inventory_movements;
CREATE POLICY "Allow inventory movements" ON inventory_movements FOR ALL USING (true) WITH CHECK (true);

-- ==================== 16. XODIMLAR ====================
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    position TEXT NOT NULL,
    monthly_salary DECIMAL(12, 2) NOT NULL CHECK (monthly_salary >= 0),
    bonus_percent DECIMAL(5, 2) DEFAULT 0 CHECK (bonus_percent >= 0 AND bonus_percent <= 100),
    worked_days INTEGER DEFAULT 0 CHECK (worked_days >= 0),
    rest_days INTEGER DEFAULT 0 CHECK (rest_days >= 0),
    hire_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated full access to employees" ON employees;
DROP POLICY IF EXISTS "Public employees all" ON employees;
CREATE POLICY "Public employees all" ON employees FOR ALL USING (true) WITH CHECK (true);

-- ==================== 17. STORAGE BUCKETS ====================
INSERT INTO storage.buckets (id, name, public) VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) VALUES ('settings', 'settings', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) VALUES ('models', 'models', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies: products
DROP POLICY IF EXISTS "Public can view products bucket" ON storage.objects;
CREATE POLICY "Public can view products bucket"
ON storage.objects FOR SELECT TO public USING (bucket_id = 'products');

DROP POLICY IF EXISTS "Public can upload products bucket" ON storage.objects;
CREATE POLICY "Public can upload products bucket"
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'products');

DROP POLICY IF EXISTS "Public can update products bucket" ON storage.objects;
CREATE POLICY "Public can update products bucket"
ON storage.objects FOR UPDATE TO public USING (bucket_id = 'products') WITH CHECK (bucket_id = 'products');

DROP POLICY IF EXISTS "Public can delete products bucket" ON storage.objects;
CREATE POLICY "Public can delete products bucket"
ON storage.objects FOR DELETE TO public USING (bucket_id = 'products');

-- settings bucket
DROP POLICY IF EXISTS "Auth can upload settings" ON storage.objects;
CREATE POLICY "Auth can upload settings"
ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'settings');

DROP POLICY IF EXISTS "Public can view settings" ON storage.objects;
CREATE POLICY "Public can view settings"
ON storage.objects FOR SELECT TO public USING (bucket_id = 'settings');

DROP POLICY IF EXISTS "Public upload settings" ON storage.objects;
CREATE POLICY "Public upload settings"
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'settings');

-- receipts
DROP POLICY IF EXISTS "Public can upload receipts" ON storage.objects;
CREATE POLICY "Public can upload receipts"
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'receipts');

DROP POLICY IF EXISTS "Public can view receipts" ON storage.objects;
CREATE POLICY "Public can view receipts"
ON storage.objects FOR SELECT TO public USING (bucket_id = 'receipts');

DROP POLICY IF EXISTS "Public can update receipts" ON storage.objects;
CREATE POLICY "Public can update receipts"
ON storage.objects FOR UPDATE TO public USING (bucket_id = 'receipts') WITH CHECK (bucket_id = 'receipts');

DROP POLICY IF EXISTS "Public can delete receipts" ON storage.objects;
CREATE POLICY "Public can delete receipts"
ON storage.objects FOR DELETE TO public USING (bucket_id = 'receipts');

-- models
DROP POLICY IF EXISTS "Public can view models" ON storage.objects;
CREATE POLICY "Public can view models"
ON storage.objects FOR SELECT TO public USING (bucket_id = 'models');

DROP POLICY IF EXISTS "Public can upload models" ON storage.objects;
CREATE POLICY "Public can upload models"
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'models');

-- ==================== 18. SHARHLAR: auth.users VIEW YO'Q ====================
-- Email o'rniga author_display_name clientda yoziladi (Supabase auth_users_exposed xavfisizligi).

-- ==================== TUGADI ====================
-- Keyingi qadam: .env da yangi Supabase URL va ANON KEY ni qo'ying.
-- Eski bazadan ma'lumot: Table Editor → CSV export/import yoki SQL dump.
