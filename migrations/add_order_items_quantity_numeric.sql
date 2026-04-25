-- order_items.quantity: dona va kg (kasr) — vitrina + CRM
-- Supabase SQL Editor da bir marta ishga tushiring.

ALTER TABLE public.order_items
  ALTER COLUMN quantity TYPE NUMERIC(12, 3)
  USING (ROUND(quantity::numeric, 3));

ALTER TABLE public.order_items
  DROP CONSTRAINT IF EXISTS order_items_quantity_check;

ALTER TABLE public.order_items
  ADD CONSTRAINT order_items_quantity_check CHECK (quantity > 0);

COMMENT ON COLUMN public.order_items.quantity IS 'Dona yoki kg: mahsulot products.is_kg=true bo''lsa kg (kasr mumkin).';
