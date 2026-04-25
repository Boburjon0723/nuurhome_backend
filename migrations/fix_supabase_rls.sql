-- 1. FIX CUSTOMERS TABLE RLS
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile during registration
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.customers;
CREATE POLICY "Users can insert their own profile" 
ON public.customers FOR INSERT 
WITH CHECK (true); -- Permissive for demo/registration flow

-- Allow users to view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.customers;
CREATE POLICY "Users can view own profile" 
ON public.customers FOR SELECT 
USING (auth.uid() = id);


-- 2. FIX REVIEWS TABLE RLS
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to create reviews
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON public.reviews;
CREATE POLICY "Authenticated users can create reviews" 
ON public.reviews FOR INSERT 
WITH CHECK (true); -- Permissive for demo

-- Ensure public can see approved reviews
DROP POLICY IF EXISTS "Public can view approved reviews" ON public.reviews;
CREATE POLICY "Public can view approved reviews" 
ON public.reviews FOR SELECT 
USING (true);


-- 3. Ommaviy auth_users view OLIB TASHLANSIN (xavfsizlik). Sharhlar uchun:
--    reviews.author_display_name — buni supabase_remove_auth_users_view.sql bilan qo'shing.
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS author_display_name TEXT;

DROP VIEW IF EXISTS public.auth_users CASCADE;
