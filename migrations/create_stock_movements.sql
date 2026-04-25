-- Create table for tracking stock movements
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    change_amount NUMERIC(14, 2) NOT NULL,
    previous_stock NUMERIC(14, 2) NOT NULL,
    new_stock NUMERIC(14, 2) NOT NULL,
    reason TEXT,
    type TEXT NOT NULL CHECK (type IN ('manual_adjustment', 'sale', 'restock', 'return', 'initial_entry')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by TEXT -- Can be phone number or name from session
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON public.stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created ON public.stock_movements(created_at);

-- Enable RLS
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to manage movements (matching project style)
DROP POLICY IF EXISTS "stock_movements_crm_all" ON public.stock_movements;
CREATE POLICY "stock_movements_crm_all" ON public.stock_movements FOR ALL USING (true) WITH CHECK (true);
