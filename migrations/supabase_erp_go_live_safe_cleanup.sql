-- ERP GO-LIVE SAFE CLEANUP
-- Maqsad: ERP demo ma'lumotlarini tozalash, lekin CRM real ma'lumotlariga tegmaslik.
-- Xavfsiz: orders/customers/products/order_items/stock_movements ga tegmaydi.
-- Ishga tushirish joyi: Supabase SQL Editor

BEGIN;

-- 1) ERP inbound navbatini tozalash.
-- Bu jadval public.orders ga FK bilan bog'langan (child -> parent),
-- shu sabab bu yerda truncate qilish orders jadvalini o'chirmaydi.
TRUNCATE TABLE public.erp_inbound_requests RESTART IDENTITY CASCADE;

-- 2) ERP seller sotuv tarixini tozalash.
TRUNCATE TABLE public.erp_sales_order_items RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.erp_sales_orders RESTART IDENTITY CASCADE;

-- 3) ERP do'kon omborini nol holatga qaytarish.
-- public.products saqlanadi, faqat erp_store_inventory yangilanadi.
INSERT INTO public.erp_store_inventory (
  product_id, quantity, stock_by_color, avg_cost_usd, stock_value_usd, status, updated_at
)
SELECT p.id, 0, NULL, 0, 0, 'tugagan', NOW()
FROM public.products p
ON CONFLICT (product_id) DO NOTHING;

UPDATE public.erp_store_inventory
SET
  quantity = 0,
  stock_by_color = NULL,
  avg_cost_usd = 0,
  stock_value_usd = 0,
  status = 'tugagan',
  updated_at = NOW();

COMMIT;

-- Tekshiruv (ixtiyoriy):
-- SELECT COUNT(*) AS inbound_left FROM public.erp_inbound_requests;
-- SELECT COUNT(*) AS sales_left   FROM public.erp_sales_orders;
-- SELECT COALESCE(SUM(quantity), 0) AS erp_qty_total FROM public.erp_store_inventory;
