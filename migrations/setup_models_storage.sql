-- 'models' bucketini yaratish (agar mavjud bo'lmasa)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('models', 'models', true)
ON CONFLICT (id) DO NOTHING;

-- 'models' buketi uchun ochiq ko'rish (SELECT) ruxsatini berish
DROP POLICY IF EXISTS "Public can view models" ON storage.objects;
CREATE POLICY "Public can view models"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'models');

-- 'models' buketiga fayl yuklash (INSERT) ruxsatini berish
DROP POLICY IF EXISTS "Public can upload models" ON storage.objects;
CREATE POLICY "Public can upload models"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'models');
