-- Create reviews table if it doesn't exist
CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS author_display_name TEXT;

-- RLS Policies
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Allow public read of approved reviews
DROP POLICY IF EXISTS "Public can view approved reviews" ON reviews;
CREATE POLICY "Public can view approved reviews" 
ON reviews FOR SELECT 
USING (status = 'approved');

-- Allow authenticated users to create reviews
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON reviews;
CREATE POLICY "Authenticated users can create reviews" 
ON reviews FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Allow users to view their own reviews (even if pending)
DROP POLICY IF EXISTS "Users can view own reviews" ON reviews;
CREATE POLICY "Users can view own reviews" 
ON reviews FOR SELECT 
USING (auth.uid() = user_id);

-- ALLOW FULL ACCESS FOR DEMO PURPOSES (So CRM can see pending reviews)
DROP POLICY IF EXISTS "Enable read access for all users" ON reviews;
CREATE POLICY "Enable read access for all users" 
ON reviews FOR SELECT 
USING (true);

-- Add reviews count and rating to products table (optional, for performance)
-- We can also calculate this on the fly.
