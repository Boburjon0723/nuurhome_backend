-- ============================================
-- CRM Backend Enhancements
-- ============================================
-- Purpose: Add accounting system, inventory tracking, and automatic data synchronization
-- Created: 2026-02-05

-- ============================================
-- 1. TRANSACTIONS TABLE ENHANCEMENTS
-- ============================================

-- Ensure transactions table exists with proper structure
CREATE TABLE IF NOT EXISTS transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    category VARCHAR(100),
    description TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_type VARCHAR(50), -- 'order', 'purchase', 'manual', etc.
    reference_id UUID, -- Link to order_id or other reference
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    notes TEXT
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON transactions(reference_type, reference_id);

-- ============================================
-- 2. INVENTORY MOVEMENTS TABLE
-- ============================================

-- Track all stock movements
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('purchase', 'sale', 'return', 'adjustment', 'damage')),
    quantity INTEGER NOT NULL,
    previous_stock INTEGER NOT NULL,
    new_stock INTEGER NOT NULL,
    unit_cost DECIMAL(10, 2),
    reference_type VARCHAR(50), -- 'order', 'purchase_order', 'manual'
    reference_id UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Indexes for inventory movements
CREATE INDEX IF NOT EXISTS idx_inventory_product ON inventory_movements(product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_type ON inventory_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_inventory_date ON inventory_movements(created_at DESC);

-- ============================================
-- 3. ORDER ITEMS TABLE (IF NOT EXISTS)
-- ============================================

CREATE TABLE IF NOT EXISTS order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * price) STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);

-- ============================================
-- 4. FUNCTION: Automatically create transaction from order
-- ============================================

CREATE OR REPLACE FUNCTION create_transaction_from_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create transaction when order is completed/paid
    IF NEW.status = 'Completed' AND (OLD.status IS NULL OR OLD.status != 'Completed') THEN
        INSERT INTO transactions (
            type,
            amount,
            category,
            description,
            date,
            reference_type,
            reference_id
        ) VALUES (
            'income',
            NEW.total,
            'Sales',
            'Order #' || NEW.id || ' - ' || COALESCE(NEW.customer_name, 'Customer'),
            CURRENT_DATE,
            'order',
            NEW.id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic transaction creation
DROP TRIGGER IF EXISTS trigger_order_transaction ON orders;
CREATE TRIGGER trigger_order_transaction
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION create_transaction_from_order();

-- ============================================
-- 5. FUNCTION: Update product stock on order completion
-- ============================================

CREATE OR REPLACE FUNCTION update_stock_on_order()
RETURNS TRIGGER AS $$
DECLARE
    item RECORD;
BEGIN
    -- When order status changes to Completed
    IF NEW.status = 'Completed' AND (OLD.status IS NULL OR OLD.status != 'Completed') THEN
        -- Loop through order items
        FOR item IN 
            SELECT product_id, quantity 
            FROM order_items 
            WHERE order_id = NEW.id
        LOOP
            -- Update product stock
            UPDATE products
            SET stock = stock - item.quantity
            WHERE id = item.product_id AND stock >= item.quantity;
            
            -- Record inventory movement
            INSERT INTO inventory_movements (
                product_id,
                movement_type,
                quantity,
                previous_stock,
                new_stock,
                reference_type,
                reference_id
            )
            SELECT 
                item.product_id,
                'sale',
                -item.quantity,
                stock + item.quantity,
                stock,
                'order',
                NEW.id
            FROM products
            WHERE id = item.product_id;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for stock update
DROP TRIGGER IF EXISTS trigger_order_stock_update ON orders;
CREATE TRIGGER trigger_order_stock_update
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_on_order();

-- ============================================
-- 6. FUNCTION: Calculate profit/loss
-- ============================================

CREATE OR REPLACE FUNCTION calculate_profit_loss(
    start_date DATE DEFAULT NULL,
    end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_income DECIMAL(10, 2),
    total_expense DECIMAL(10, 2),
    net_profit DECIMAL(10, 2),
    period_start DATE,
    period_end DATE
) AS $$
BEGIN
    -- Default to current month if no dates provided
    start_date := COALESCE(start_date, DATE_TRUNC('month', CURRENT_DATE)::DATE);
    end_date := COALESCE(end_date, CURRENT_DATE);
    
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expense,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) as net_profit,
        start_date as period_start,
        end_date as period_end
    FROM transactions
    WHERE date BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. VIEW: Product Stock Status
-- ============================================

CREATE OR REPLACE VIEW product_stock_status AS
SELECT 
    p.id,
    p.name,
    p.stock,
    p.min_stock,
    CASE 
        WHEN p.stock = 0 THEN 'out_of_stock'
        WHEN p.stock <= p.min_stock THEN 'low_stock'
        ELSE 'in_stock'
    END as stock_status,
    COALESCE(
        (SELECT SUM(quantity) 
         FROM inventory_movements 
         WHERE product_id = p.id AND movement_type = 'sale' 
         AND created_at >= NOW() - INTERVAL '30 days'), 
        0
    ) as sold_last_30_days,
    p.sale_price,
    p.purchase_price,
    (p.sale_price - p.purchase_price) as profit_per_unit
FROM products p;

-- ============================================
-- 8. Default Categories for Transactions
-- ============================================

-- Add some default categories if not exists
INSERT INTO settings (id, setting_key, setting_value)
VALUES (gen_random_uuid(), 'transaction_categories_income', '["Sales", "Services", "Other Income"]')
ON CONFLICT DO NOTHING;

INSERT INTO settings (id, setting_key, setting_value)
VALUES (gen_random_uuid(), 'transaction_categories_expense', '["Purchases", "Salaries", "Rent", "Utilities", "Marketing", "Other Expense"]')
ON CONFLICT DO NOTHING;

-- ============================================
-- 9. Enable Row Level Security (RLS)
-- ============================================

-- Enable RLS on new tables
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;

-- Create policies (allow authenticated users full access for now)
CREATE POLICY "Allow authenticated full access to transactions"
    ON transactions FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow authenticated full access to inventory_movements"
    ON inventory_movements FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

SELECT 'Backend enhancements successfully applied!' as message,
       'Tables: transactions, inventory_movements, order_items' as tables_created,
       'Triggers: Auto-transaction on order, Auto-stock-update on order' as triggers_created,
       'Functions: calculate_profit_loss()' as functions_created;
