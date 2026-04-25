-- Add image_url column to categories table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'image_url') THEN
        ALTER TABLE categories ADD COLUMN image_url TEXT;
    END IF;
END $$;

-- Success notice
DO $$
BEGIN
    RAISE NOTICE '✅ image_url column added to categories table successfully!';
END $$;
