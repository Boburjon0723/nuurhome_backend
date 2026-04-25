-- stock_movements: buyurtma va rang bilan bog‘lash (CRM sotuv / qaytarish loglari)
-- Supabase SQL Editor da ishga tushiring.

ALTER TABLE public.stock_movements
    ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;

ALTER TABLE public.stock_movements
    ADD COLUMN IF NOT EXISTS color_key TEXT;

COMMENT ON COLUMN public.stock_movements.order_id IS 'Buyurtma bilan bog‘langan harakat (sotuv / qaytarish)';
COMMENT ON COLUMN public.stock_movements.color_key IS 'Rang bo‘yicha zaxira kaliti (mahsulot.colors/stock_by_color bilan mos)';

CREATE INDEX IF NOT EXISTS idx_stock_movements_order_id ON public.stock_movements(order_id);

-- Eski migratsiyada type cheklovida reversal bo‘lmasligi mumkin; CRM kodida reversal ishlatiladi.
ALTER TABLE public.stock_movements DROP CONSTRAINT IF EXISTS stock_movements_type_check;

ALTER TABLE public.stock_movements
    ADD CONSTRAINT stock_movements_type_check CHECK (
        type IN (
            'manual_adjustment',
            'sale',
            'restock',
            'return',
            'initial_entry',
            'reversal'
        )
    );
