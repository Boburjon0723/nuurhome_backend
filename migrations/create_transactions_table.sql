-- ============================================
-- Transactions Table for Moliya (Finance) Module
-- ============================================

-- Drop existing objects safely to avoid conflicts
DROP TRIGGER IF EXISTS trigger_order_transaction ON orders;
DROP FUNCTION IF EXISTS create_transaction_from_order() CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;

-- Create transactions table
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    category VARCHAR(100),
    description TEXT NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_type VARCHAR(50), -- 'order', 'purchase', 'manual', etc.
    reference_id UUID, -- Link to order_id or other reference
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    notes TEXT
);

-- Add indexes for performance
CREATE INDEX idx_transactions_date ON transactions(date DESC);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_category ON transactions(category);
CREATE INDEX idx_transactions_reference ON transactions(reference_type, reference_id);

-- Enable Row Level Security (RLS)
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY "Allow authenticated full access to transactions"
    ON transactions FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================
-- Automatic Transaction Creation from Orders
-- ============================================

CREATE OR REPLACE FUNCTION create_transaction_from_order()
RETURNS TRIGGER AS $$
DECLARE
    new_done boolean;
    old_done boolean;
BEGIN
    -- CRM / sayt: status odatda 'completed' (kichik); INSERTda OLD yo'q — TG_OP tekshiriladi
    new_done := LOWER(TRIM(COALESCE(NEW.status, ''))) = 'completed';
    IF TG_OP = 'UPDATE' THEN
        old_done := LOWER(TRIM(COALESCE(OLD.status, ''))) = 'completed';
    ELSE
        old_done := false;
    END IF;

    IF new_done AND NOT old_done THEN
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
            'Savdo',
            'Buyurtma #' || COALESCE(NEW.id::text, 'Noma''lum') || ' - ' || COALESCE(NEW.customer_name, 'Mijoz'),
            CURRENT_DATE,
            'order',
            NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic transaction creation
CREATE TRIGGER trigger_order_transaction
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION create_transaction_from_order();

-- ============================================
-- Sample Data
-- ============================================

INSERT INTO transactions (type, amount, category, description, date)
VALUES 
    ('income', 1250000, 'Savdo', 'Sotilgan mahsulotlar', CURRENT_DATE),
    ('expense', 450000, 'Xaridlar', 'Dala xizmati uchun to''lov', CURRENT_DATE - INTERVAL '1 day'),
    ('income', 850000, 'Savdo', 'Yangi mijoz buyurtmasi', CURRENT_DATE - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Transactions table created successfully!';
    RAISE NOTICE '📊 Moliya module is now ready to use';
    RAISE NOTICE '🔄 Automatic transaction trigger for completed orders is active';
END $$;
