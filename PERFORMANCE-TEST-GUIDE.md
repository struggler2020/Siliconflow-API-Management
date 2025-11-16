# 优化版 Worker 部署与并发测试指南

## 📋 快速概览

**优化内容：**
- ✅ 合并数据库查询（2次→1次）
- ✅ 缓存清理机制（防止内存泄漏）
- ✅ 可配置同步策略
- ✅ 性能监控（慢请求记录）
- ✅ 增强错误处理

**预期性能提升：**
- 查询次数：**-50%**
- 响应时间：**-10-30ms**
- QPS：**+20-50%**
- 内存稳定性：**显著提升**

---

## 🚀 部署步骤

### **步骤 1：验证代码变更**

查看优化内容：
```bash
git diff HEAD~1 worker-backend.js | head -100
```

关键变更：
- `handleVerifyMergedQuery` - 合并查询函数
- `incrementQuotaUsageOptimized` - 优化的配额更新
- `cleanupStaleEntries` - 缓存清理函数

### **步骤 2：配置优化参数（可选）**

编辑 `worker-backend.js` 的 CONFIG 部分：

```javascript
const CONFIG = {
  JWT_SECRET: 'CHANGE_THIS_IN_PRODUCTION',
  JWT_EXPIRES_IN: 86400,

  // 性能优化配置（可根据实际流量调整）
  QUOTA_SYNC_THRESHOLD: 100,      // 低流量: 100, 中流量: 200, 高流量: 500
  QUOTA_SYNC_INTERVAL: 300000,    // 低流量: 5分钟, 中流量: 10分钟, 高流量: 30分钟
  CACHE_CLEANUP_INTERVAL: 3600000, // 缓存清理间隔（1小时）
  CACHE_TTL: 600000,              // 缓存条目过期时间（10分钟）
  SLOW_REQUEST_THRESHOLD: 1000,   // 慢请求阈值（毫秒）
  USE_MERGED_QUERY: true,         // 启用合并查询优化（推荐）
};
```

**流量级别建议：**

| 流量级别 | 每日验证次数 | SYNC_THRESHOLD | SYNC_INTERVAL | 预期 QPS |
|---------|-------------|----------------|---------------|----------|
| **低** | <10,000 | 100 | 300000 (5分钟) | 100-500 |
| **中** | 10,000-100,000 | 200 | 600000 (10分钟) | 500-1000 |
| **高** | >100,000 | 500 | 1800000 (30分钟) | 1000-5000 |

### **步骤 3：部署到 Cloudflare**

**方法 A：使用 Wrangler CLI（推荐）**

```bash
# 1. 确保 wrangler 已登录
wrangler whoami

# 2. 部署 Worker
wrangler deploy

# 预期输出：
# ✨ Success! Uploaded 1 files (XX.XX KB)
# Published api-key-management
# https://api-key-management.161105069.workers.dev
```

**方法 B：通过 Dashboard**

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 进入 **Workers & Pages** → **api-key-management**
3. 点击 **Quick edit**
4. 复制粘贴整个 `worker-backend.js` 的内容
5. 点击 **Save and Deploy**

### **步骤 4：验证部署成功**

```bash
# 测试 Worker 是否响应
curl https://你的域名.workers.dev/

# 预期输出：
# User Interface
```

### **步骤 5：测试管理员登录**

```bash
curl -X POST https://你的域名.workers.dev/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 预期输出：
# {"success":true,"token":"eyJhbGci..."}
```

✅ **如果返回 token，说明部署成功！**

---

## 🧪 并发测试方案

### **测试准备**

#### **1. 准备测试数据**

运行完整测试脚本生成测试数据：
```bash
./test-api.sh
```

这会创建：
- 1 个租户
- 1 个 API 密钥
- 1 个商品
- 1 个兑换码（已兑换，产生配额）

**记录以下信息用于测试：**
```bash
# 从 test-api.sh 输出中提取
TENANT_ID="xxxxx"
API_KEY="sk_xxxx_xxxxx"
PRODUCT_ID="prod_xxxxx"
```

#### **2. 安装测试工具**

**选项 A：使用 k6（专业负载测试）**
```bash
# Mac
brew install k6

# Ubuntu
sudo apt install k6

# Windows
choco install k6
```

**选项 B：使用内置脚本（无需安装）**
```bash
chmod +x benchmark.sh
```

---

### **测试 1：基准性能测试（单请求延迟）**

使用内置脚本：
```bash
BASE_URL=https://你的域名.workers.dev \
TEST_API_KEY=sk_xxxx_xxxxx \
TEST_PRODUCT_ID=prod_xxxxx \
./benchmark.sh
```

**预期输出：**
```
[1/4] 测试单次请求延迟...
响应时间: 0.085s
状态码: 200

[2/4] 测试连续 10 次请求...
..........
平均响应时间: 0.073s
```

**性能指标：**
- ✅ 优秀：<100ms
- ⚠️ 良好：100-200ms
- ❌ 需优化：>200ms

---

### **测试 2：渐进式负载测试（k6）**

编辑 `load-test.js` 设置测试参数：
```javascript
const BASE_URL = 'https://你的域名.workers.dev';
const TEST_API_KEY = 'sk_xxxx_xxxxx';
const TEST_PRODUCT_ID = 'prod_xxxxx';
```

运行测试：
```bash
k6 run load-test.js
```

**测试场景：**
```
30秒: 0 → 10 用户   (预热)
1分钟: 10 → 50 用户  (轻负载)
2分钟: 50 → 100 用户 (中负载)
2分钟: 100 → 200 用户 (高负载)
1分钟: 200 → 500 用户 (压力测试)
30秒: 500 → 0 用户   (冷却)
```

**预期输出：**
```
✓ status is 200 ......... 99.8%
✓ response time < 200ms .. 95.2%

http_req_duration.......: avg=85ms  p(95)=180ms p(99)=350ms
http_reqs...............: 50000 (833/s)
http_req_failed.........: 0.2%
```

**性能评估：**
- **P95 < 150ms**: ⭐⭐⭐⭐⭐ 优秀
- **P95 < 200ms**: ⭐⭐⭐⭐ 良好
- **P95 < 500ms**: ⭐⭐⭐ 可接受
- **P95 > 500ms**: ⭐⭐ 需优化

---

### **测试 3：恒定负载测试（稳定性）**

编辑 `load-test.js`，取消注释"场景2"：
```javascript
export const options = {
  vus: 100,              // 100 个虚拟用户
  duration: '5m',        // 持续 5 分钟
  thresholds: {
    'http_req_duration': ['p(95)<200'],
    'http_req_failed': ['rate<0.01'],
  },
};
```

运行：
```bash
k6 run load-test.js
```

**观察指标：**
- 错误率应保持 <1%
- P95 延迟应稳定
- 内存不应持续增长（查看 Dashboard）

---

### **测试 4：突发流量测试**

编辑 `load-test.js`，取消注释"场景3"：
```javascript
export const options = {
  stages: [
    { duration: '10s', target: 1000 },  // 10秒内激增到1000用户
    { duration: '1m', target: 1000 },   // 保持1分钟
    { duration: '10s', target: 0 },     // 快速降至0
  ],
};
```

**预期行为：**
- Cloudflare 自动扩容
- 响应时间略有增加但可接受
- 无请求失败

---

### **测试 5：压力测试（找到崩溃点）**

编辑 `load-test.js`，取消注释"场景4"：
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 500 },
    { duration: '3m', target: 1000 },
    { duration: '3m', target: 2000 },
    { duration: '3m', target: 5000 },
    { duration: '1m', target: 0 },
  ],
};
```

**目标：**
- 找到系统开始出现错误的点
- 记录最大可承受 QPS

---

## 📊 监控与分析

### **实时监控（Cloudflare Dashboard）**

1. 导航到 **Workers & Pages** → **api-key-management**
2. 点击 **Metrics** 标签

**关键指标：**
- **Requests/sec**: 当前 QPS
- **CPU Time**: 平均 CPU 使用时间
- **Errors**: 错误率
- **Success Rate**: 成功率

### **查看实时日志**

```bash
wrangler tail api-key-management
```

**日志类型：**

**慢请求日志：**
```json
{
  "type": "slow_request",
  "timestamp": "2025-11-16T10:30:45.123Z",
  "duration": 1250,
  "status": 200,
  "path": "/api/verify"
}
```

**缓存清理日志：**
```json
{
  "type": "cache_cleanup",
  "timestamp": "2025-11-16T11:00:00.000Z",
  "cleaned": 150,
  "remaining": 350
}
```

### **D1 数据库监控**

1. 导航到 **D1** → **api_key_management_db**
2. 点击 **Metrics** 标签

**关键指标：**
- **Rows read**: 读取行数（应减少）
- **Rows written**: 写入行数（应大幅减少）
- **Queries/sec**: 查询频率

**优化效果验证：**
```
优化前：10,000 次验证 = 10,000 次 UPDATE
优化后：10,000 次验证 = 100 次 UPDATE (减少 99%)
```

---

## 📈 性能对比

### **预期性能提升**

| 指标 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| **单次验证查询数** | 2 次 | 1 次 | -50% |
| **平均响应时间** | 80-100ms | 50-70ms | -30% |
| **P95 响应时间** | 150-200ms | 100-150ms | -25% |
| **理论 QPS** | 500-800 | 600-1000 | +25% |
| **D1 写入次数** | 10,000/万次验证 | 100/万次验证 | -99% |

### **实际测试结果对比**

完成测试后填写：

```
优化前（如果有基准数据）：
- P50: ___ ms
- P95: ___ ms
- QPS: ___ req/s
- 错误率: ___ %

优化后：
- P50: ___ ms  (预期 50-70ms)
- P95: ___ ms  (预期 100-150ms)
- QPS: ___ req/s  (预期 600-1000)
- 错误率: ___ %  (预期 <0.1%)
```

---

## 🔧 性能调优建议

### **如果 P95 > 200ms**

**原因分析：**
1. D1 查询慢 → 检查索引是否生效
2. 网络延迟高 → 检查测试地点是否远离 Cloudflare 节点
3. 并发过高 → 降低并发用户数

**解决方案：**
```bash
# 检查 D1 查询执行计划
# 在 D1 Console 中执行：
EXPLAIN QUERY PLAN
SELECT k.key, k.status, t.status, q.quota_total, q.quota_used
FROM api_keys k
JOIN tenants t ON k.tenant_id = t.id
LEFT JOIN key_quotas q ON q.api_key = k.key
WHERE k.key = ?;

# 应该显示 "USING INDEX"
```

### **如果错误率 > 1%**

**可能原因：**
1. D1 限流 → 检查免费套餐限制
2. Worker 超时 → 检查 CPU 时间限制
3. 数据库连接问题 → 检查 D1 绑定

**解决方案：**
- 升级到付费套餐（$5/月）
- 优化 SQL 查询
- 添加重试机制

### **如果 QPS < 500**

**优化方向：**
1. 确保 `USE_MERGED_QUERY = true`
2. 增加 `QUOTA_SYNC_THRESHOLD` 到 200-500
3. 考虑添加 Cloudflare KV 缓存（高级优化）

---

## 🎯 性能优化路线图

### **已实施（当前版本）**
- ✅ 合并数据库查询
- ✅ 内存计数器
- ✅ 缓存清理机制
- ✅ 可配置同步策略
- ✅ 性能监控

### **短期优化（1-3天）**
- 🔧 根据测试结果调整 CONFIG 参数
- 🔧 优化 SQL 索引（如需要）
- 🔧 添加请求采样（减少日志量）

### **中期优化（1-2周）**
- 🚀 使用 Cloudflare KV 缓存热点数据
- 🚀 实施请求去重（防止重复验证）
- 🚀 添加限流保护

### **长期优化（1-3个月）**
- 🌟 使用 Durable Objects（强一致性）
- 🌟 读写分离架构
- 🌟 多区域部署

---

## 📋 测试检查清单

部署前：
- [ ] 修改 JWT_SECRET 为生产环境密钥
- [ ] 配置自定义域名（绕过 workers.dev 限制）
- [ ] 更新管理员默认密码
- [ ] 确认 D1 数据库绑定正确

基准测试：
- [ ] 单次请求延迟 <100ms
- [ ] 连续10次请求平均 <80ms
- [ ] 管理员登录成功
- [ ] 验证接口正常返回

负载测试：
- [ ] 100 VUs 时 P95 <200ms
- [ ] 500 VUs 时错误率 <1%
- [ ] 突发流量测试无崩溃
- [ ] 5分钟稳定性测试无内存泄漏

监控验证：
- [ ] 慢请求日志正常记录
- [ ] 缓存清理日志定期出现
- [ ] D1 写入次数大幅减少
- [ ] Dashboard 指标正常显示

---

## 🆘 常见问题

### Q1: 部署后仍然看到"Cannot find name 'env'"错误
A: 这只是 TypeScript 类型检查警告，不影响运行。可以忽略或添加类型声明。

### Q2: 测试时提示 "API密钥不存在"
A: 确保先运行 `./test-api.sh` 生成测试数据，并使用输出的 API_KEY 和 PRODUCT_ID。

### Q3: k6 测试全部失败
A: 检查 `load-test.js` 中的 BASE_URL、TEST_API_KEY、TEST_PRODUCT_ID 是否正确。

### Q4: 性能没有明显提升
A: 确认 `CONFIG.USE_MERGED_QUERY = true`，并查看 Worker 日志确认使用了优化版本。

### Q5: 中国大陆无法访问测试URL
A: 参考 `CHINA-ACCESS-GUIDE.md` 配置自定义域名。

---

## 📚 相关文档

- **CONCURRENCY-ANALYSIS.md** - 完整的并发能力分析报告
- **load-test.js** - k6 负载测试脚本
- **benchmark.sh** - 快速性能测试脚本
- **DEPLOYMENT.md** - 详细部署指南
- **CHINA-ACCESS-GUIDE.md** - 中国访问配置

---

**祝测试顺利！🚀**

如有问题，查看 Worker 日志：
```bash
wrangler tail api-key-management
```

或在 GitHub Issues 提问。
