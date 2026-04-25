-- Create the storage bucket 'receipts' if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS for objects
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Allow public to Upload (INSERT) files to 'receipts' bucket
DROP POLICY IF EXISTS "Public can upload receipts" ON storage.objects;
CREATE POLICY "Public can upload receipts"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'receipts');

-- Allow public to View (SELECT) files from 'receipts' bucket
DROP POLICY IF EXISTS "Public can view receipts" ON storage.objects;
CREATE POLICY "Public can view receipts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'receipts');
