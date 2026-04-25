-- Contact Messages & Company Settings Migration
-- Run this script in Supabase SQL Editor

-- 1. Create contact_messages table
CREATE TABLE IF NOT EXISTS contact_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  subject text,
  message text NOT NULL,
  status text DEFAULT 'new' CHECK (status IN ('new', 'read', 'replied')),
  created_at timestamp with time zone DEFAULT now(),
  read_at timestamp with time zone,
  replied_at timestamp with time zone
);

-- 2. Add new columns to settings table
ALTER TABLE settings ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS latitude numeric(10, 6);
ALTER TABLE settings ADD COLUMN IF NOT EXISTS longitude numeric(10, 6);

-- 3. Set up RLS policies for contact_messages
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Allow public to INSERT (website can submit messages)
DROP POLICY IF EXISTS "Public can insert contact messages" ON contact_messages;
CREATE POLICY "Public can insert contact messages"
ON contact_messages FOR INSERT
TO public
WITH CHECK (true);

-- Allow public to SELECT (CRM can read messages)
DROP POLICY IF EXISTS "Public can select contact messages" ON contact_messages;
CREATE POLICY "Public can select contact messages"
ON contact_messages FOR SELECT
TO public
USING (true);

-- Allow public to UPDATE (CRM can mark as read/replied)
DROP POLICY IF EXISTS "Public can update contact messages" ON contact_messages;
CREATE POLICY "Public can update contact messages"
ON contact_messages FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

-- Allow public to DELETE (CRM can delete messages)
DROP POLICY IF EXISTS "Public can delete contact messages" ON contact_messages;
CREATE POLICY "Public can delete contact messages"
ON contact_messages FOR DELETE
TO public
USING (true);

-- 4. Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_contact_messages_created_at ON contact_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contact_messages_status ON contact_messages(status);
