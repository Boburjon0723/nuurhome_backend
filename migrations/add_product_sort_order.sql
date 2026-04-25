-- Vitrinada kategoriya ichidagi mahsulot tartibi (CRM dan keyin yangilanadi)
ALTER TABLE products ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;
COMMENT ON COLUMN products.sort_order IS 'Katalog tartibi: kichik raqam yuqorida; 0 = standart';
