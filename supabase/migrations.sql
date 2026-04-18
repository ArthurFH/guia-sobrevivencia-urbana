-- ====================================================
-- Guia de Sobrevivência Urbana — Supabase Migrations
-- Executar no SQL Editor do Supabase (supabase.com)
-- ====================================================

-- Tabela alerts
CREATE TABLE IF NOT EXISTS alerts (
  id          TEXT        PRIMARY KEY
, tipo        TEXT        NOT NULL CHECK (tipo IN ('phishing','golpe','fraude','aviso'))
, titulo      TEXT        NOT NULL
, descricao   TEXT        NOT NULL
, pais        TEXT        NOT NULL CHECK (pais IN ('PT','BR','ambos'))
, ativo       BOOLEAN     DEFAULT true
, created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela changelog
-- Nota: tipo usa valores semânticos do site (golpe/lei/ferramenta/actualizacao)
CREATE TABLE IF NOT EXISTS changelog (
  id          TEXT        PRIMARY KEY
, data        DATE        NOT NULL
, tipo        TEXT        NOT NULL CHECK (tipo IN ('golpe','lei','ferramenta','actualizacao'))
, titulo      TEXT        NOT NULL
, descricao   TEXT        NOT NULL
, pais        TEXT        NOT NULL DEFAULT 'ambos' CHECK (pais IN ('PT','BR','ambos'))
, created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- RLS — activar segurança por linha
ALTER TABLE alerts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE changelog ENABLE ROW LEVEL SECURITY;

-- Políticas de leitura pública (anon)
CREATE POLICY "Public read alerts"      ON alerts    FOR SELECT USING (true);
CREATE POLICY "Public read changelog"   ON changelog FOR SELECT USING (true);

-- Políticas de escrita e remoção (uso pessoal via admin.html)
-- Nota: a segurança real é feita pela password no admin.html (uso interno)
CREATE POLICY "Public insert alerts"    ON alerts    FOR INSERT WITH CHECK (true);
CREATE POLICY "Public delete alerts"    ON alerts    FOR DELETE USING (true);
CREATE POLICY "Public update alerts"    ON alerts    FOR UPDATE USING (true);
CREATE POLICY "Public insert changelog" ON changelog FOR INSERT WITH CHECK (true);
CREATE POLICY "Public delete changelog" ON changelog FOR DELETE USING (true);
CREATE POLICY "Public update changelog" ON changelog FOR UPDATE USING (true);
