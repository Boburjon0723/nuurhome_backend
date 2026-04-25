-- Fix Order Deletion and Receipt Storage Issues

-- 1. Enable DELETE access for orders (currently blocked by RLS)
DROP POLICY IF EXISTS "Public can delete orders" ON orders;
CREATE POLICY "Public can delete orders"
ON orders FOR DELETE
TO public
USING (true);

-- 1b. Enable UPDATE access for orders (for receipt_url updates)
DROP POLICY IF EXISTS "Public can update orders" ON orders;
CREATE POLICY "Public can update orders"
ON orders FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- 2. Ensure receipts storage bucket exists and is public
INSERT INTO storage.buckets (id, name, public) 
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 3. Allow public to UPLOAD files to receipts bucket
DROP POLICY IF EXISTS "Public can upload receipts" ON storage.objects;
CREATE POLICY "Public can upload receipts"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'receipts');

-- 4. Allow public to VIEW files from receipts bucket
DROP POLICY IF EXISTS "Public can view receipts" ON storage.objects;
CREATE POLICY "Public can view receipts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'receipts');

-- 5. Allow public to UPDATE receipt files (in case of re-upload)
DROP POLICY IF EXISTS "Public can update receipts" ON storage.objects;
CREATE POLICY "Public can update receipts"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'receipts')
WITH CHECK (bucket_id = 'receipts');

-- 6. Allow public to DELETE receipt files (for cleanup)
DROP POLICY IF EXISTS "Public can delete receipts" ON storage.objects;
CREATE POLICY "Public can delete receipts"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'receipts');
