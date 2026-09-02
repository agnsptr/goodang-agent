CREATE TABLE goodang.audit_log (
  id          BIGSERIAL PRIMARY KEY,
  event       TEXT NOT NULL,
  actor       TEXT,
  payload     JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_audit_event ON goodang.audit_log(event, created_at DESC);
CREATE INDEX idx_audit_payload_gin ON goodang.audit_log USING gin(payload);
ALTER TABLE goodang.audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_read_authenticated ON goodang.audit_log FOR SELECT TO authenticated USING (true);
CREATE POLICY audit_write_service_role ON goodang.audit_log FOR INSERT TO service_role WITH CHECK (true);
REVOKE UPDATE, DELETE ON goodang.audit_log FROM authenticated, anon, service_role;
CREATE TRIGGER trg_forbid_audit_update BEFORE UPDATE ON goodang.audit_log FOR EACH ROW EXECUTE FUNCTION goodang.forbid_pos_tl_mutation();
CREATE TRIGGER trg_forbid_audit_delete BEFORE DELETE ON goodang.audit_log FOR EACH ROW EXECUTE FUNCTION goodang.forbid_pos_tl_mutation();
