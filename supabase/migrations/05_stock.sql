CREATE TABLE goodang.stock (
  sku_code      TEXT NOT NULL,
  outlet_code   TEXT NOT NULL,
  quantity      NUMERIC(15,2) NOT NULL DEFAULT 0,
  reserved      NUMERIC(15,2) NOT NULL DEFAULT 0,
  version       INTEGER NOT NULL DEFAULT 1,
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (sku_code, outlet_code),
  FOREIGN KEY (sku_code) REFERENCES goodang.product(sku_code)
);
ALTER TABLE goodang.stock ENABLE ROW LEVEL SECURITY;
CREATE POLICY stock_read_authenticated ON goodang.stock FOR SELECT TO authenticated USING (true);
CREATE POLICY stock_write_service_role ON goodang.stock FOR ALL TO service_role USING (true) WITH CHECK (true);
