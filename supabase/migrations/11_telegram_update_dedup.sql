CREATE TABLE goodang.telegram_update_dedup (
  telegram_update_id BIGINT PRIMARY KEY,
  chat_id            BIGINT NOT NULL,
  user_id            BIGINT,
  received_at        TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_tud_chat ON goodang.telegram_update_dedup(chat_id, received_at DESC);
ALTER TABLE goodang.telegram_update_dedup ENABLE ROW LEVEL SECURITY;
CREATE POLICY tud_write_service_role
  ON goodang.telegram_update_dedup FOR INSERT TO service_role WITH CHECK (true);
REVOKE UPDATE, DELETE ON goodang.telegram_update_dedup FROM authenticated, anon, service_role;
