CREATE TABLE goodang.order_draft (
  order_id       TEXT PRIMARY KEY,
  status         TEXT NOT NULL,
  member_id      TEXT NOT NULL,
  member_name    TEXT NOT NULL,
  payment_method TEXT,
  subtotal       NUMERIC(15,2) DEFAULT 0,
  service_fee    NUMERIC(15,2) DEFAULT 0,
  total          NUMERIC(15,2) DEFAULT 0,
  version        INTEGER NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE goodang.order_draft_item (
  id             BIGSERIAL PRIMARY KEY,
  order_id       TEXT NOT NULL,
  sku_code       TEXT NOT NULL,
  product_name   TEXT NOT NULL,
  uom            TEXT NOT NULL,
  qty            NUMERIC(15,2) NOT NULL,
  selling_price  NUMERIC(15,2) NOT NULL,
  service_fee    NUMERIC(15,2) DEFAULT 0,
  line_amount    NUMERIC(15,2) NOT NULL,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  FOREIGN KEY (order_id) REFERENCES goodang.order_draft(order_id) ON DELETE CASCADE
);
CREATE INDEX idx_odi_order ON goodang.order_draft_item(order_id);
ALTER TABLE goodang.order_draft ENABLE ROW LEVEL SECURITY;
ALTER TABLE goodang.order_draft_item ENABLE ROW LEVEL SECURITY;
CREATE POLICY od_read_authenticated ON goodang.order_draft FOR SELECT TO authenticated USING (true);
CREATE POLICY od_write_service_role ON goodang.order_draft FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY odi_read_authenticated ON goodang.order_draft_item FOR SELECT TO authenticated USING (true);
CREATE POLICY odi_write_service_role ON goodang.order_draft_item FOR ALL TO service_role USING (true) WITH CHECK (true);
