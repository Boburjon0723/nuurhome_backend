-- Create newsletter_subscriptions table
CREATE TABLE IF NOT EXISTS newsletter_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'active', -- active, unsubscribed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE newsletter_subscriptions ENABLE ROW LEVEL SECURITY;

-- Allow public to insert (anyone can subscribe)
DROP POLICY IF EXISTS "Anyone can subscribe" ON newsletter_subscriptions;
CREATE POLICY "Anyone can subscribe" 
ON newsletter_subscriptions FOR INSERT 
TO public
WITH CHECK (true);

-- Allow authenticated users to view
DROP POLICY IF EXISTS "Admins can view subscriptions" ON newsletter_subscriptions;
CREATE POLICY "Admins can view subscriptions" 
ON newsletter_subscriptions FOR SELECT 
TO authenticated 
USING (true);

-- Allow authenticated users to delete/update
DROP POLICY IF EXISTS "Admins can manage subscriptions" ON newsletter_subscriptions;
CREATE POLICY "Admins can manage subscriptions" 
ON newsletter_subscriptions FOR ALL 
TO authenticated 
USING (true);
