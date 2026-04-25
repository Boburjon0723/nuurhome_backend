-- ============================================
-- Comprehensive Demo Data for TechGear CRM
-- ============================================

-- 1. Clear existing data (Optional, but better for a clean start)
-- TRUNCATE TABLE transactions, order_items, orders, employees, products, customers, categories CASCADE;

-- 2. Categories
INSERT INTO categories (name) VALUES 
('Laptops'), ('Smartphones'), ('Accessories'), ('Monitors'), ('Printers')
ON CONFLICT (name) DO NOTHING;

-- 3. Products
INSERT INTO products (name, stock, sale_price, purchase_price, category_id, is_active)
SELECT 
    'MacBook Pro 14', 15, 1999, 1500, id, true FROM categories WHERE name = 'Laptops'
UNION ALL
SELECT 
    'iPhone 15 Pro', 25, 1099, 800, id, true FROM categories WHERE name = 'Smartphones'
UNION ALL
SELECT 
    'AirPods Pro 2', 50, 249, 150, id, true FROM categories WHERE name = 'Accessories'
UNION ALL
SELECT 
    'Samsung Odyssey G7', 10, 699, 500, id, true FROM categories WHERE name = 'Monitors'
UNION ALL
SELECT 
    'HP LaserJet', 8, 299, 200, id, true FROM categories WHERE name = 'Printers'
ON CONFLICT DO NOTHING;

-- 4. Employees
INSERT INTO employees (name, position, monthly_salary, worked_days) VALUES 
('Anvar Karimov', 'Menejer', 5000, 22),
('Sardor Rahimov', 'Sotuvchi', 3000, 20),
('Malika Axmedova', 'Kassa', 2500, 22)
ON CONFLICT DO NOTHING;

-- 5. Customers (Manual)
INSERT INTO customers (name, phone, email) VALUES 
('Jasur Jumayev', '+998901234567', 'jasur@example.com'),
('Otabek Ismoilov', '+998912345678', 'otabek@example.com')
ON CONFLICT DO NOTHING;

-- 6. Transactions (Historical)
INSERT INTO transactions (type, amount, category, description, date) VALUES 
('income', 5000, 'Savdo', 'Yanvar oyi savdosi', '2026-01-25'),
('expense', 1500, 'Xaridlar', 'Yangi tovarlar xaridi', '2026-01-26'),
('income', 3000, 'Savdo', 'Korporativ mijoz to''lovi', '2026-02-01'),
('expense', 2000, 'Maoshlar', 'Yanvar oyi maoshlari', '2026-02-02'),
('income', 1200, 'Savdo', 'Bugungi tushum', CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- 7. Orders
-- Note: This is simplified. Real orders usually need order_items.
INSERT INTO orders (customer_name, total, status, created_at) VALUES 
('Jasur Jumayev', 1999, 'Completed', CURRENT_DATE - INTERVAL '2 days'),
('Otabek Ismoilov', 1099, 'Pending', CURRENT_DATE - INTERVAL '1 day'),
('Mehmon', 249, 'New', CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- Success notice
DO $$
BEGIN
    RAISE NOTICE '✅ Demo ma''lumotlar muvaffaqiyatli yuklandi!';
    RAISE NOTICE '🚀 Endi Dashboard va Statistika bo''limlarida ma''lumotlar ko''rinishi kerak.';
END $$;
