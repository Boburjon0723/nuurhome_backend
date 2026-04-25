-- 1. Create product_colors table
CREATE TABLE IF NOT EXISTS product_colors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    hex_code TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Populate with 50+ colors
INSERT INTO product_colors (name, hex_code) VALUES
('Oltin', '#FFD700'),
('Kumush', '#C0C0C0'),
('Oq', '#FFFFFF'),
('Qora', '#000000'),
('Sutli', '#FFFDD0'),
('Bej', '#F5F5DC'),
('Kulrang', '#808080'),
('To''q kulrang', '#A9A9A9'),
('Jigarrang', '#A52A2A'),
('Shokolad', '#D2691E'),
('Yashil', '#008000'),
('Zumrad', '#50C878'),
('Zaytun', '#808000'),
('Ko''k', '#0000FF'),
('To''q ko''k', '#000080'),
('Firuza', '#40E0D0'),
('Moviy', '#ADD8E6'),
('Pushti', '#FFC0CB'),
('To''q pushti', '#FF00FF'),
('Binafsha', '#800080'),
('Liloviy', '#C8A2C8'),
('Qizil', '#FF0000'),
('To''q qizil', '#800000'),
('To''q sariq', '#FFA500'),
('Sariq', '#FFFF00'),
('Limon', '#FFF700'),
('Bronza', '#CD7F32'),
('Mis', '#B87333'),
('Shampan', '#F7E7CE'),
('Fil suyagi', '#FFFFF0'),
('Shaftoli', '#FFDAB9'),
('Marjon', '#FF7F50'),
('Yalpiz', '#98FF98'),
('Osmon rang', '#87CEEB'),
('Denim', '#1560BD'),
('Terrakota', '#E2725B'),
('Xantal', '#E1AD01'),
('Qahva', '#6F4E37'),
('Antratsit', '#383E42'),
('Vanil', '#F3E5AB'),
('Shaffof', 'transparent'),
('Kumushsimon', '#E5E4E2'),
('Oltinsimon', '#E6BE8A'),
('Melanj', '#808080'),
('Grafit', '#36454F'),
('Lavanda', '#E6E6FA'),
('Bordo', '#4F000B'),
('Karamel', '#AF6E4D'),
('Qaymoq', '#FFFDD0'),
('Haki', '#C3B091'),
('Firuzarang', '#00CED1'),
('Malina', '#E30B5D'),
('O''rik', '#FBCEB1'),
('Bodom', '#EFDECD'),
('Kahrabo', '#FFBF00')
ON CONFLICT (name) DO NOTHING;

-- 3. Update products table
-- Add colors array and multilingual fields
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS colors TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS name_uz TEXT,
ADD COLUMN IF NOT EXISTS name_ru TEXT,
ADD COLUMN IF NOT EXISTS name_en TEXT,
ADD COLUMN IF NOT EXISTS description_uz TEXT,
ADD COLUMN IF NOT EXISTS description_ru TEXT,
ADD COLUMN IF NOT EXISTS description_en TEXT;

-- Migrate existing single color strings to the array if needed
UPDATE products 
SET colors = ARRAY[color] 
WHERE color IS NOT NULL AND color != '' AND (colors IS NULL OR array_length(colors, 1) IS NULL);

-- 4. Update categories table for localization
ALTER TABLE categories
ADD COLUMN IF NOT EXISTS name_uz TEXT,
ADD COLUMN IF NOT EXISTS name_ru TEXT,
ADD COLUMN IF NOT EXISTS name_en TEXT;

-- 5. Update banners table for localization
ALTER TABLE banners
ADD COLUMN IF NOT EXISTS title_uz TEXT,
ADD COLUMN IF NOT EXISTS title_ru TEXT,
ADD COLUMN IF NOT EXISTS title_en TEXT,
ADD COLUMN IF NOT EXISTS subtitle_uz TEXT,
ADD COLUMN IF NOT EXISTS subtitle_ru TEXT,
ADD COLUMN IF NOT EXISTS subtitle_en TEXT;

-- 6. Update settings table for localization
ALTER TABLE settings
ADD COLUMN IF NOT EXISTS banner_text_uz TEXT,
ADD COLUMN IF NOT EXISTS banner_text_ru TEXT,
ADD COLUMN IF NOT EXISTS banner_text_en TEXT;

-- 7. Remove email from customers table as requested
ALTER TABLE customers DROP COLUMN IF EXISTS email;
