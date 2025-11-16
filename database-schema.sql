-- ========================================
-- API密钥配额验证系统 - D1数据库初始化脚本
-- ========================================

-- 表1: 管理员表
CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- 表2: 租户表
CREATE TABLE IF NOT EXISTS tenants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,

  -- 配额限制
  max_products INTEGER DEFAULT 10,
  max_api_keys INTEGER DEFAULT 100,
  max_codes_per_product INTEGER DEFAULT 1000,

  -- 当前使用情况
  current_products INTEGER DEFAULT 0,
  current_api_keys INTEGER DEFAULT 0,

  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL
);

-- 表3: 租户账号表
CREATE TABLE IF NOT EXISTS tenant_accounts (
  id TEXT PRIMARY KEY,
  tenant_id TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,

  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE INDEX IF NOT EXISTS idx_tenant_accounts_username ON tenant_accounts(username);

-- 表4: API密钥表
CREATE TABLE IF NOT EXISTS api_keys (
  key TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT,
  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL,
  first_login_at TEXT,
  last_used_at TEXT,

  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE INDEX IF NOT EXISTS idx_keys_tenant ON api_keys(tenant_id);
CREATE INDEX IF NOT EXISTS idx_keys_user ON api_keys(user_id);

-- 表5: 用户表
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  api_key TEXT UNIQUE NOT NULL,
  tenant_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  last_login_at TEXT,

  FOREIGN KEY (api_key) REFERENCES api_keys(key),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE INDEX IF NOT EXISTS idx_users_apikey ON users(api_key);
CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);

-- 表6: 商品表
CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,

  name TEXT NOT NULL,
  description TEXT,

  default_calls INTEGER NOT NULL,
  default_days INTEGER NOT NULL,

  category TEXT,

  generated_codes_count INTEGER DEFAULT 0,

  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,

  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

CREATE INDEX IF NOT EXISTS idx_products_tenant ON products(tenant_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);

-- 表7: 兑换码表
CREATE TABLE IF NOT EXISTS redemption_codes (
  code TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  batch_id TEXT NOT NULL,

  created_by TEXT NOT NULL,
  creator_id TEXT NOT NULL,

  max_uses INTEGER DEFAULT 1,
  used_count INTEGER DEFAULT 0,

  expires_at TEXT,
  created_at TEXT NOT NULL,

  FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE INDEX IF NOT EXISTS idx_codes_product ON redemption_codes(product_id);
CREATE INDEX IF NOT EXISTS idx_codes_batch ON redemption_codes(batch_id);
CREATE INDEX IF NOT EXISTS idx_codes_creator ON redemption_codes(creator_id);

-- 表8: API密钥产品配额表
CREATE TABLE IF NOT EXISTS key_quotas (
  id TEXT PRIMARY KEY,
  api_key TEXT NOT NULL,
  product_id TEXT NOT NULL,

  quota_total INTEGER NOT NULL,
  quota_used INTEGER DEFAULT 0,

  activated_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,

  status TEXT DEFAULT 'active',
  source_codes TEXT,

  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,

  FOREIGN KEY (api_key) REFERENCES api_keys(key),
  FOREIGN KEY (product_id) REFERENCES products(id),

  UNIQUE(api_key, product_id)
);

CREATE INDEX IF NOT EXISTS idx_quotas_key ON key_quotas(api_key);
CREATE INDEX IF NOT EXISTS idx_quotas_product ON key_quotas(product_id);
CREATE INDEX IF NOT EXISTS idx_quotas_status ON key_quotas(status, expires_at);

-- 表9: 配置表
CREATE TABLE IF NOT EXISTS config (
  name TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- 插入默认管理员账号
-- 用户名: admin
-- 密码: admin123 (请在部署后立即修改)
-- 密码哈希使用 SHA-256(password + 'salt') 算法
INSERT OR IGNORE INTO admins (id, username, password_hash, created_at)
VALUES (
  'admin_default_001',
  'admin',
  'GR7mrJGQez9rgBazmSXGlokm4E0PnGHUDaf1aN1q5uc=',
  datetime('now')
);

-- 插入默认配置
INSERT OR IGNORE INTO config (name, value) VALUES ('system_version', '1.0.0');
INSERT OR IGNORE INTO config (name, value) VALUES ('jwt_secret', 'CHANGE_THIS_SECRET_KEY_IN_PRODUCTION');

-- 完成
SELECT 'Database initialized successfully!' as message;
