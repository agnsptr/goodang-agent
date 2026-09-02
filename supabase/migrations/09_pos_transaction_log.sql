CREATE OR REPLACE FUNCTION goodang.forbid_pos_tl_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'POS_TRANSACTION_LOG is append-only. UPDATE/DELETE forbidden.'
    USING HINT = 'Insert reversal entry with negative line_amount instead.';
END;
$$ LANGUAGE plpgsql;

CREATE TABLE goodang.pos_transaction_log (
  transaction_id    TEXT PRIMARY KEY,
  transaction_date  TIMESTAMPTZ NOT NULL,
  outlet_code       TEXT NOT NULL,
  member_id         TEXT NOT NULL,
  member_name       TEXT NOT NULL,
  payment_method    TEXT NOT NULL,
  sku_code          TEXT NOT NULL,
  product_name      TEXT NOT NULL,
  uom               TEXT NOT NULL,
  qty               NUMERIC(15,2) NOT NULL,
  cooked_qty        NUMERIC(15,2) DEFAULT 0,
  selling_price     NUMERIC(15,2) NOT NULL,
  service_fee       NUMERIC(15,2) DEFAULT 0,
  line_amount       NUMERIC(15,2) NOT NULL,
  remarks           TEXT,
  created_by        TEXT NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  immutable         BOOLEAN DEFAULT true
);
CREATE INDEX idx_pos_tl_member ON goodang.pos_transaction_log(member_id, transaction_date DESC);
CREATE INDEX idx_pos_tl_outlet ON goodang.pos_transaction_log(outlet_code, transaction_date DESC);
CREATE INDEX idx_pos_tl_date ON goodang.pos_transaction_log(transaction_date DESC);
ALTER TABLE goodang.pos_transaction_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY pos_tl_read_authenticated ON goodang.pos_transaction_log FOR SELECT TO authenticated USING (true);
CREATE POLICY pos_tl_insert_service_role ON goodang.pos_transaction_log FOR INSERT TO service_role WITH CHECK (true);
REVOKE UPDATE, DELETE ON goodang.pos_transaction_log FROM authenticated, anon, service_role;
CREATE TRIGGER trg_forbid_pos_tl_update BEFORE UPDATE ON goodang.pos_transaction_log FOR EACH ROW EXECUTE FUNCTION goodang.forbid_pos_tl_mutation();
CREATE TRIGGER trg_forbid_pos_tl_delete BEFORE DELETE ON goodang.pos_transaction_log FOR EACH ROW EXECUTE FUNCTION goodang.forbid_pos_tl_mutation();
