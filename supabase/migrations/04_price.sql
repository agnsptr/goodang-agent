CREATE TABLE goodang.price (
  sku_code      TEXT NOT NULL,
  outlet_code   TEXT NOT NULL,
  selling_price NUMERIC(15,2) NOT NULL,
  service_fee   NUMERIC(15,2) DEFAULT 0,
  valid_from    TIMESTAMPTZ NOT NULL,
  valid_until   TIMESTAMPTZ,
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (sku_code, outlet_code, valid_from),
  FOREIGN KEY (sku_code) REFERENCES goodang.product(sku_code)
);
CREATE INDEX idx_price_outlet_active ON goodang.price(outlet_code, sku_code)
  WHERE is_active = true AND valid_until IS NULL;
ALTER TABLE goodang.price ENABLE ROW LEVEL SECURITY;
CREATE POLICY price_read_authenticated ON goodang.price FOR SELECT TO authenticated USING (true);
CREATE POLICY price_write_service_role ON goodang.price FOR ALL TO service_role USING (true) WITH CHECK (true);
