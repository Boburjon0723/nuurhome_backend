-- ================================================
-- Add About Page Settings to Settings Table
-- ================================================

-- Hero Section
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_hero_title TEXT DEFAULT 'We bring elegance to your home';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_hero_subtitle TEXT DEFAULT 'Specializing in premium curtain accessories that transform your living space into a masterpiece of design and comfort.';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_hero_image TEXT DEFAULT 'https://images.unsplash.com/photo-1513694203232-719a280e022f?ixlib=rb-1.2.1&auto=format&fit=crop&w=1920&q=80';

-- Statistics (4 cards)
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat1_value TEXT DEFAULT '10,000+';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat1_label TEXT DEFAULT 'Happy Customers';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat2_value TEXT DEFAULT '15+';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat2_label TEXT DEFAULT 'Years Experience';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat3_value TEXT DEFAULT '5,000+';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat3_label TEXT DEFAULT 'Products';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat4_value TEXT DEFAULT '98%';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS stat4_label TEXT DEFAULT 'Positive Reviews';

-- Mission & Vision Section
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_title TEXT DEFAULT 'Crafting details that matter';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_text1 TEXT DEFAULT 'Started as a small family business, we have grown into a leading provider of high-quality curtain accessories. We believe that the smallest details can make the biggest difference in interior design.';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_text2 TEXT DEFAULT 'Our mission is to provide an extensive selection of stylish, durable, and affordable accessories that help our customers express their unique style.';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS about_mission_image TEXT DEFAULT 'https://images.unsplash.com/photo-1615800098779-1be4350c5957?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80';

-- Values Section (3 items)
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value1_title TEXT DEFAULT 'Premium Quality';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value1_desc TEXT DEFAULT 'We use only the finest materials to ensure durability and lasting beauty.';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value2_title TEXT DEFAULT 'Customer First';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value2_desc TEXT DEFAULT 'Your satisfaction is our top priority. We are here to help you every step of the way.';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value3_title TEXT DEFAULT 'Modern Design';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS value3_desc TEXT DEFAULT 'We constantly update our collections to reflect the latest trends in interior design.';

-- Verify columns added
SELECT 
  column_name, 
  data_type, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'settings' 
  AND column_name LIKE 'about_%' OR column_name LIKE 'stat%' OR column_name LIKE 'value%'
ORDER BY column_name;
