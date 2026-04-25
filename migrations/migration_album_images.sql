-- ============================================================
-- album_images jadvali - Albom sahifasidagi qo'shimcha rasmlar
-- Mahsulot bo'lmagan rasmlar (lookbook, galereya) uchun
-- Supabase SQL Editor da bajarish: New query > paste > Run
-- ============================================================

CREATE TABLE IF NOT EXISTS album_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url TEXT NOT NULL,
    title_uz TEXT,
    title_ru TEXT,
    title_en TEXT,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
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
