-- ============================================
-- Employees Table for Xodimlar (HR) Module
-- ============================================

-- Drop existing table if needed
DROP TABLE IF EXISTS employees CASCADE;

-- Create employees table
CREATE TABLE employees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    position TEXT NOT NULL,
    monthly_salary DECIMAL(10, 2) NOT NULL CHECK (monthly_salary >= 0),
    bonus_percent DECIMAL(5, 2) DEFAULT 0 CHECK (bonus_percent >= 0 AND bonus_percent <= 100),
    worked_days INTEGER DEFAULT 0 CHECK (worked_days >= 0),
    rest_days INTEGER DEFAULT 0 CHECK (rest_days >= 0),
    hire_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_employees_name ON employees(name);
CREATE INDEX idx_employees_position ON employees(position);
CREATE INDEX idx_employees_created_at ON employees(created_at DESC);

-- Enable RLS
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY "Allow authenticated full access to employees"
    ON employees FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_employees_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS trigger_employees_updated_at ON employees;
CREATE TRIGGER trigger_employees_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW
    EXECUTE FUNCTION update_employees_updated_at();

-- Insert sample data (optional)
INSERT INTO employees (name, position, monthly_salary, bonus_percent, worked_days, rest_days)
VALUES 
    ('Aziz Rahimov', 'Manager', 5000000, 10, 22, 0),
    ('Dilnoza Karimova', 'Accountant', 3500000, 5, 22, 0),
    ('Bobur Aliyev', 'Sales Representative', 3000000, 15, 20, 2)
ON CONFLICT DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Employees table created successfully!';
    RAISE NOTICE '📊 Xodimlar module is now ready to use';
    RAISE NOTICE '👥 Sample employees added for testing';
END $$;
