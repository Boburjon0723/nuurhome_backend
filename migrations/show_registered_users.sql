-- ============================================
-- Show Registered Users in CRM (Fixed Version)
-- ============================================
-- This script is idempotent - can be run multiple times safely

-- ============================================
-- 1. Drop existing objects to avoid conflicts
-- ============================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_last_login() CASCADE;
DROP FUNCTION IF EXISTS get_registered_users() CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- ============================================
-- 2. Create user_profiles table
-- ============================================

CREATE TABLE user_profiles (
    id UUID PRIMARY KEY,
    display_name TEXT,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Add foreign key to auth.users
ALTER TABLE user_profiles 
    ADD CONSTRAINT user_profiles_id_fkey 
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX idx_user_profiles_id ON user_profiles(id);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY "Allow authenticated to read profiles"
    ON user_profiles FOR SELECT
    TO authenticated
    USING (true);

-- ============================================
-- 3. Function to get registered users
-- ============================================

CREATE FUNCTION get_registered_users()
RETURNS TABLE (
    id UUID,
    email TEXT,
    display_name TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    total_orders BIGINT,
    total_spend NUMERIC
) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        au.id,
        au.email,
        COALESCE(
            up.display_name, 
            au.raw_user_meta_data->>'display_name', 
            au.raw_user_meta_data->>'name', 
            au.email, 
            au.phone,
            'Foydalanuvchi'
        ) as display_name,
        COALESCE(up.phone, au.raw_user_meta_data->>'phone', au.phone) as phone,
        au.created_at,
        au.last_sign_in_at,
        COUNT(DISTINCT o.id) as total_orders,
        COALESCE(SUM(o.total), 0) as total_spend
    FROM auth.users au
    LEFT JOIN user_profiles up ON au.id = up.id
    LEFT JOIN orders o ON (
        o.customer_email = au.email OR 
        o.customer_phone = au.phone OR
        o.customer_phone = up.phone
    )
    WHERE au.deleted_at IS NULL
    GROUP BY au.id, au.email, up.display_name, up.phone, au.phone, au.raw_user_meta_data, au.created_at, au.last_sign_in_at
    ORDER BY au.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_registered_users() TO authenticated;

-- ============================================
-- 4. Function to handle new user signup
-- ============================================

CREATE FUNCTION handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO user_profiles (id, display_name, email, phone)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'name'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone)
    )
    ON CONFLICT (id) DO UPDATE 
    SET 
        display_name = COALESCE(EXCLUDED.display_name, user_profiles.display_name),
        email = COALESCE(EXCLUDED.email, user_profiles.email),
        phone = COALESCE(EXCLUDED.phone, user_profiles.phone);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================
-- 5. Function to update last login time
-- ============================================

CREATE FUNCTION update_last_login()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE user_profiles
    SET last_login = NEW.last_sign_in_at
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for login updates
CREATE TRIGGER on_auth_user_login
    AFTER UPDATE OF last_sign_in_at ON auth.users
    FOR EACH ROW
    WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
    EXECUTE FUNCTION update_last_login();

-- ============================================
-- 6. Populate existing users (if any)
-- ============================================

INSERT INTO user_profiles (id, display_name, email, phone)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'display_name', raw_user_meta_data->>'name'),
    email,
    COALESCE(raw_user_meta_data->>'phone', phone)
FROM auth.users
WHERE deleted_at IS NULL
ON CONFLICT (id) DO UPDATE
SET 
    display_name = EXCLUDED.display_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone;

-- ============================================
-- Success message
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Success! Registered users function created and ready to use!';
    RAISE NOTICE '📊 CRM can now view real authenticated users';
    RAISE NOTICE '🔧 Run this query to test: SELECT * FROM get_registered_users();';
END $$;
