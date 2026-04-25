-- Migration: Add email column to customers table
-- Purpose: Support real email authentication and display in CRM
-- Date: 2026-02-16

-- 1. Add email column if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='email') THEN
        ALTER TABLE public.customers ADD COLUMN email TEXT;
    END IF;
END $$;

-- 2. Add country column if it doesn't exist (used in auth but might be missing)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customers' AND column_name='country') THEN
        ALTER TABLE public.customers ADD COLUMN country TEXT;
    END IF;
END $$;

-- 3. Update existing records (optional)
-- UPDATE public.customers SET email = 'no-email@nuurhome.com' WHERE email IS NULL;

-- 4. Verify
-- SELECT * FROM public.customers LIMIT 5;
