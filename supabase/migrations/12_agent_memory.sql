-- Fase 4: Hermes memory (requires vector extension from 01_extensions.sql)
CREATE TABLE goodang.agent_memory (
  id           BIGSERIAL PRIMARY KEY,
  project_key  TEXT NOT NULL,
  memory_type  TEXT NOT NULL,
  content      JSONB NOT NULL,
  embedding    VECTOR(1536),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_am_project ON goodang.agent_memory(project_key, memory_type);
CREATE INDEX idx_am_embedding ON goodang.agent_memory USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
ALTER TABLE goodang.agent_memory ENABLE ROW LEVEL SECURITY;
CREATE POLICY am_read_authenticated ON goodang.agent_memory FOR SELECT TO authenticated USING (true);
CREATE POLICY am_write_service_role ON goodang.agent_memory FOR ALL TO service_role USING (true) WITH CHECK (true);
