CREATE TABLE goodang.payment (
  payment_id        TEXT PRIMARY KEY,
  transaction_id    TEXT NOT NULL,
  member_id         TEXT NOT NULL,
  method_code       TEXT NOT NULL,
  amount            NUMERIC(15,2) NOT NULL,
  status            TEXT NOT NULL,
  idempotency_key   TEXT UNIQUE NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  FOREIGN KEY (method_code) REFERENCES goodang.payment_method(method_code)
);
CREATE INDEX idx_payment_member ON goodang.payment(member_id, created_at DESC);
CREATE INDEX idx_payment_status ON goodang.payment(status);
ALTER TABLE goodang.payment ENABLE ROW LEVEL SECURITY;
CREATE POLICY pay_read_authenticated ON goodang.payment FOR SELECT TO authenticated USING (true);
CREATE POLICY pay_write_service_role ON goodang.payment FOR ALL TO service_role USING (true) WITH CHECK (true);
