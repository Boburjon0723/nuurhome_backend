-- ============================================================
-- Mahsulotlardan o'chirilgan (mavjud bo'lmagan) ranglarni tozalash
-- Supabase: Dashboard > SQL Editor > New query > paste > Run
-- ============================================================

UPDATE products p
SET colors = COALESCE((
  SELECT array_agg(elem)
  FROM unnest(COALESCE(p.colors, '{}')) AS elem
  WHERE elem IN (SELECT name FROM product_colors)
), '{}')
WHERE p.colors IS NOT NULL 
  AND array_length(COALESCE(p.colors, '{}'), 1) > 0;
