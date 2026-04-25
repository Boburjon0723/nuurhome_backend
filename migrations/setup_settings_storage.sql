-- About sahifasi header rasmlari uchun Supabase Storage bucket
-- CRM dan rasm yuklash uchun 'settings' bucket yaratish

INSERT INTO storage.buckets (id, name, public)
VALUES ('settings', 'settings', true)
ON CONFLICT (id) DO NOTHING;

-- Authenticated foydalanuvchilar yuklash uchun
DROP POLICY IF EXISTS "Auth can upload settings" ON storage.objects;
CREATE POLICY "Auth can upload settings"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'settings');

-- Hamma foydalanuvchilar o'qish uchun (public rasm)
DROP POLICY IF EXISTS "Public can view settings" ON storage.objects;
CREATE POLICY "Public can view settings"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'settings');
