-- Buyurtma oxirgi o'zgarishi (hisobotlar: tugallangan sana).
-- Agar `orders.updated_at` yo'q bo'lsa yoki avto yangilanmasa, ishga tushiring.

ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- Mavjud qatorlar uchun boshlang'ich qiymat
UPDATE orders SET updated_at = COALESCE(updated_at, created_at, NOW()) WHERE updated_at IS NULL;

-- Kelajakda har UPDATE da yangilanishi (Postgres trigger)
CREATE OR REPLACE FUNCTION set_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE PROCEDURE set_orders_updated_at();
