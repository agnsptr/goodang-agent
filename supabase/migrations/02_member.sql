CREATE TABLE goodang.member (
  member_id       TEXT PRIMARY KEY,
  member_name     TEXT NOT NULL,
  phone           TEXT,
  outlet_code     TEXT NOT NULL,
  plafon          NUMERIC(15,2) DEFAULT 0,
  payment_limit   NUMERIC(15,2) DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_member_outlet ON goodang.member(outlet_code);
CREATE INDEX idx_member_phone ON goodang.member(phone) WHERE phone IS NOT NULL;
ALTER TABLE goodang.member ENABLE ROW LEVEL SECURITY;
-- CS dashboard: scope by outlet_code JWT claim (docs/14). service_role bypasses RLS.
CREATE POLICY member_read_authenticated
  ON goodang.member FOR SELECT TO authenticated
  USING (outlet_code = (auth.jwt() ->> 'outlet_code'));
CREATE POLICY member_write_service_role
  ON goodang.member FOR ALL TO service_role USING (true) WITH CHECK (true);
