-- Telegram Finance Tracker schema (PostgreSQL 13+). Safe to run twice.
-- All amounts are whole rupiah (BIGINT).

CREATE TABLE IF NOT EXISTS settings (
  singleton BOOLEAN PRIMARY KEY DEFAULT TRUE CHECK (singleton),
  timezone  TEXT NOT NULL DEFAULT 'Asia/Jakarta'
);
INSERT INTO settings (singleton) VALUES (TRUE) ON CONFLICT DO NOTHING;

-- Keyword -> category rules. Keywords are plain lowercase text (no wildcard characters), matched anywhere in the note.
CREATE TABLE IF NOT EXISTS category_rules (
  keyword  TEXT PRIMARY KEY CHECK (keyword ~ '^[a-z0-9 ]{2,30}$'),
  category TEXT NOT NULL CHECK (category ~ '^[a-z0-9-]{1,20}$')
);
INSERT INTO category_rules (keyword, category) VALUES
  ('grab', 'transport'), ('gojek', 'transport'), ('ojol', 'transport'), ('krl', 'transport'), ('mrt', 'transport'),
  ('transjakarta', 'transport'), ('bensin', 'transport'), ('pertamina', 'transport'), ('parkir', 'transport'), ('tol', 'transport'),
  ('makan', 'food'), ('kopi', 'food'), ('coffee', 'food'), ('warung', 'food'), ('resto', 'food'), ('gofood', 'food'), ('grabfood', 'food'),
  ('indomaret', 'groceries'), ('alfamart', 'groceries'), ('supermarket', 'groceries'), ('sayur', 'groceries'),
  ('listrik', 'bills'), ('pln', 'bills'), ('pdam', 'bills'), ('indihome', 'bills'), ('wifi', 'bills'), ('pulsa', 'bills'), ('paket data', 'bills'),
  ('netflix', 'entertainment'), ('spotify', 'entertainment'), ('youtube', 'entertainment'), ('bioskop', 'entertainment'), ('xxi', 'entertainment'),
  ('kos', 'rent'), ('sewa', 'rent'),
  ('apotek', 'health'), ('dokter', 'health'), ('obat', 'health'),
  ('kuliah', 'education'), ('buku', 'education'), ('spp', 'education')
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS budgets (
  category       TEXT PRIMARY KEY CHECK (category ~ '^[a-z0-9-]{1,20}$'),
  monthly_amount BIGINT NOT NULL CHECK (monthly_amount > 0)
);

CREATE TABLE IF NOT EXISTS transactions (
  id         BIGSERIAL PRIMARY KEY,
  chat_id    BIGINT,                                                   -- NULL for CSV imports
  kind       TEXT   NOT NULL CHECK (kind IN ('expense', 'income')),
  amount     BIGINT NOT NULL CHECK (amount > 0 AND amount <= 1000000000000),
  note       TEXT   NOT NULL CHECK (length(note) BETWEEN 1 AND 200),
  category   TEXT   NOT NULL CHECK (category ~ '^[a-z0-9-]{1,20}$'),
  source     TEXT   NOT NULL CHECK (source IN ('telegram', 'csv')),
  tx_date    DATE   NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted    BOOLEAN NOT NULL DEFAULT FALSE,
  dedupe_key TEXT UNIQUE                                                -- CSV rows only: re-importing a file adds nothing
);
CREATE INDEX IF NOT EXISTS transactions_date_idx ON transactions (tx_date) WHERE NOT deleted;

-- One row per budget threshold per month, so every alert is sent once
CREATE TABLE IF NOT EXISTS budget_alerts (
  month      DATE NOT NULL,
  category   TEXT NOT NULL,
  level      INT  NOT NULL CHECK (level IN (80, 100)),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (month, category, level)
);
