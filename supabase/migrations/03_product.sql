CREATE TABLE goodang.product (
  sku_code      TEXT PRIMARY KEY,
  product_name  TEXT NOT NULL,
  uom           TEXT NOT NULL,
  category      TEXT,
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_product_name_trgm ON goodang.product USING gin (product_name gin_trgm_ops);
CREATE INDEX idx_product_category ON goodang.product(category);
ALTER TABLE goodang.product ENABLE ROW LEVEL SECURITY;
CREATE POLICY product_read_authenticated ON goodang.product FOR SELECT TO authenticated USING (true);
CREATE POLICY product_write_service_role ON goodang.product FOR ALL TO service_role USING (true) WITH CHECK (true);
