-- ═══════════════════════════════════════════════════════════════
-- HEARTOM 管理システム Supabase スキーマ
-- Supabaseダッシュボード > SQL Editor で実行してください
-- ═══════════════════════════════════════════════════════════════

-- UUID拡張を有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────
-- 1. オープンボード顧客テーブル
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ob_customers (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ob_customers_name_idx ON ob_customers ((data->>'顧客名'));
CREATE INDEX IF NOT EXISTS ob_customers_status_idx ON ob_customers ((data->>'商談ステータス'));
CREATE INDEX IF NOT EXISTS ob_customers_updated_idx ON ob_customers (updated_at DESC);

-- ─────────────────────────────────────────
-- 2. 着工管理プロジェクトテーブル
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS kj_projects (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS kj_projects_name_idx ON kj_projects ((data->>'物件名'));
CREATE INDEX IF NOT EXISTS kj_projects_updated_idx ON kj_projects (updated_at DESC);

-- ─────────────────────────────────────────
-- 3. 営業MTGレコードテーブル
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mtg_records (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS mtg_records_name_idx ON mtg_records ((data->>'顧客名'));
CREATE INDEX IF NOT EXISTS mtg_records_updated_idx ON mtg_records (updated_at DESC);

-- ─────────────────────────────────────────
-- 4. アプリ設定テーブル（キーバリュー）
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 5. 受付アクティビティログ
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  customer_name TEXT,
  staff TEXT,
  event_name TEXT,
  at TIMESTAMPTZ DEFAULT NOW(),
  data JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS activity_log_at_idx ON activity_log (at DESC);
CREATE INDEX IF NOT EXISTS activity_log_name_idx ON activity_log (customer_name);

-- ─────────────────────────────────────────
-- 6. updated_at 自動更新トリガー
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ob_customers_updated_at
  BEFORE UPDATE ON ob_customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER kj_projects_updated_at
  BEFORE UPDATE ON kj_projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER mtg_records_updated_at
  BEFORE UPDATE ON mtg_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────
-- 7. Row Level Security（RLS）設定
-- GASはservice_role keyで直接アクセス（RLS bypass）
-- フロントエンドからの直接アクセスは今後実装予定
-- ─────────────────────────────────────────
ALTER TABLE ob_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE kj_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE mtg_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- service_role（GAS使用）は RLS をバイパスするため追加ポリシー不要
-- 将来フロントエンド直接アクセス時は以下を追加：
-- CREATE POLICY "allow_authenticated" ON ob_customers FOR ALL TO authenticated USING (true);
