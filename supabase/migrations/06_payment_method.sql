CREATE TABLE goodang.payment_method (
  method_code   TEXT PRIMARY KEY,
  method_name   TEXT NOT NULL,
  is_active     BOOLEAN DEFAULT true
);
ALTER TABLE goodang.payment_method ENABLE ROW LEVEL SECURITY;
CREATE POLICY pm_read_authenticated ON goodang.payment_method FOR SELECT TO authenticated USING (true);
CREATE POLICY pm_write_service_role ON goodang.payment_method FOR ALL TO service_role USING (true) WITH CHECK (true);
