-- Supabase SQL: ustaxona uchun bir nechta rasm (JSON massiv URL)
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_images TEXT;

COMMENT ON COLUMN settings.about_mission_images IS 'JSON: ["https://...","https://..."] — Biz haqimizda karusel';
