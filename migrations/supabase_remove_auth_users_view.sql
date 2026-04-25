-- Ommaviy auth.users ko'rinishini olib tashlash (Supabase Advisors: auth_users_exposed).
-- SQL Editor → Run. Keyin frontend allaqachon author_display_name ishlatadi.

-- 1) Sharhda ko'rinadigan ism — email o'rniga jadvalda saqlanadi (anon API orqali email chiqmaydi)
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS author_display_name TEXT;

-- Eski qatorlar: ism yo'q bo'lsa umumiy yorliq
UPDATE public.reviews
SET author_display_name = 'Foydalanuvchi'
WHERE author_display_name IS NULL OR trim(author_display_name) = '';

-- 2) Xavfli view olib tashlash
DROP VIEW IF EXISTS public.auth_users CASCADE;
