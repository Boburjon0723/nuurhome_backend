-- ============================================================
-- album_images jadvaliga format ustuni qo'shish
-- Rasm formatini tanlash: portrait, square, landscape, large
-- Supabase SQL Editor da bajarish: New query > paste > Run
-- ============================================================

ALTER TABLE album_images ADD COLUMN IF NOT EXISTS format TEXT DEFAULT 'portrait';

-- Mavjud qatorlar uchun default
UPDATE album_images SET format = 'portrait' WHERE format IS NULL;
