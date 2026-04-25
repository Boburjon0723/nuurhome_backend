-- ============================================================
-- product_colors uchun RLS sozlash (rang saqlash xatoligini tuzatish)
-- Supabase: Dashboard > SQL Editor > New query > bu faylni paste qiling > Run
-- ============================================================

-- RLS yoqilgan bo'lsa, policy qo'shamiz
ALTER TABLE product_colors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read product_colors" ON product_colors;
CREATE POLICY "Public read product_colors" ON product_colors FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert product_colors" ON product_colors;
CREATE POLICY "Allow insert product_colors" ON product_colors FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update product_colors" ON product_colors;
CREATE POLICY "Allow update product_colors" ON product_colors FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow delete product_colors" ON product_colors;
CREATE POLICY "Allow delete product_colors" ON product_colors FOR DELETE USING (true);
