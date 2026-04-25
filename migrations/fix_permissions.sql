-- Enable RLS for categories and reviews
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- CATEGORIES POLICIES
-- Allow everyone to read categories
DROP POLICY IF EXISTS "Public can view categories" ON categories;
CREATE POLICY "Public can view categories" 
ON categories FOR SELECT 
USING (true);

-- Allow authenticated users (CRM) to insert/update/delete categories
-- For demo purposes, we'll allow this for 'authenticated' role.
-- If CRM uses anon key in some cases, we might need true for all, but let's try authenticated first.
DROP POLICY IF EXISTS "Authenticated can manage categories" ON categories;
CREATE POLICY "Authenticated can manage categories" 
ON categories FOR ALL 
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Fallback: If CRM login is not strictly enforced or acting as anon:
-- Uncomment the below if the above doesn't work for your setup
-- CREATE POLICY "Public can manage categories (DEMO)" ON categories FOR ALL USING (true);


-- REVIEWS POLICIES (Re-applying for completeness)
DROP POLICY IF EXISTS "Public can view approved reviews" ON reviews;
CREATE POLICY "Public can view approved reviews" 
ON reviews FOR SELECT 
USING (status = 'approved');

DROP POLICY IF EXISTS "Authenticated users can create reviews" ON reviews;
CREATE POLICY "Authenticated users can create reviews" 
ON reviews FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can view own reviews" ON reviews;
CREATE POLICY "Users can view own reviews" 
ON reviews FOR SELECT 
USING (auth.uid() = user_id);

-- Explicitly allow CRM dashboard (authenticated or anon admin) to see all reviews
DROP POLICY IF EXISTS "Enable read access for all users" ON reviews;
CREATE POLICY "Enable read access for all users" 
ON reviews FOR SELECT 
USING (true);

-- Allow CRM to update/delete reviews
DROP POLICY IF EXISTS "Enable write access for all users" ON reviews;
CREATE POLICY "Enable write access for all users" 
ON reviews FOR UPDATE 
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Enable delete access for all users" ON reviews;
CREATE POLICY "Enable delete access for all users" 
ON reviews FOR DELETE 
USING (true);

