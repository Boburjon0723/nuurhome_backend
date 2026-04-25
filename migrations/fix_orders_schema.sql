-- 1. orders jadvaliga user_id ustunini qo'shish (agar yo'q bo'lsa)
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- 2. RLS ni yoqish (ihtiyot chorasi)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 3. Eski siyosatlarni tozalash (xatolik bermasligi uchun)
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Authenticated users can create orders" ON orders;
DROP POLICY IF EXISTS "Public can view orders" ON orders;

-- 4. Yangi siyosatlar yaratish

-- Foydalanuvchi faqat o'zining user_id si bilan buyurtma yarata oladi
CREATE POLICY "Users can insert their own orders" 
ON orders 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Foydalanuvchi faqat o'z buyurtmalarini ko'ra oladi
CREATE POLICY "Users can view their own orders" 
ON orders 
FOR SELECT 
USING (auth.uid() = user_id);
