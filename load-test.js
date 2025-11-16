// ========================================
// API密钥配额验证系统 - K6 负载测试脚本
// ========================================
// 安装: brew install k6 (Mac) 或访问 https://k6.io/docs/get-started/installation/
// 运行: k6 run load-test.js
// ========================================

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const verifyDuration = new Trend('verify_duration');
const successCounter = new Counter('successful_verifications');
const failureCounter = new Counter('failed_verifications');

// ========================================
// 配置区域 - 修改以下配置以匹配你的环境
// ========================================
const BASE_URL = __ENV.BASE_URL || 'https://api.yourdomain.com';
const TEST_API_KEY = __ENV.TEST_API_KEY || 'sk_test_xxxxx';
const TEST_PRODUCT_ID = __ENV.TEST_PRODUCT_ID || 'prod_test_xxxxx';

// ========================================
// 测试场景配置
// ========================================
export const options = {
  // 场景 1：渐进式负载测试（默认）
  stages: [
    { duration: '30s', target: 10 },   // 预热: 0 → 10 用户
    { duration: '1m', target: 50 },    // 负载增加: 10 → 50 用户
    { duration: '2m', target: 100 },   // 中等负载: 50 → 100 用户
    { duration: '2m', target: 200 },   // 高负载: 100 → 200 用户
    { duration: '1m', target: 500 },   // 压力测试: 200 → 500 用户
    { duration: '30s', target: 0 },    // 冷却: 500 → 0 用户
  ],

  // 性能阈值（如果不满足，测试标记为失败）
  thresholds: {
    'http_req_duration': [
      'p(50)<100',   // 50% 请求 < 100ms
      'p(95)<200',   // 95% 请求 < 200ms
      'p(99)<500',   // 99% 请求 < 500ms
    ],
    'http_req_failed': ['rate<0.01'],     // 错误率 < 1%
    'errors': ['rate<0.01'],              // 业务错误率 < 1%
    'verify_duration': ['p(95)<150'],     // 验证接口 95% < 150ms
  },

  // 可选：限制最大虚拟用户数
  // maxVUs: 1000,
};

// ========================================
// 其他测试场景（注释掉 options，取消以下注释以切换场景）
// ========================================

// 场景 2：恒定负载测试
/*
export const options = {
  vus: 100,              // 100 个虚拟用户
  duration: '5m',        // 持续 5 分钟
  thresholds: {
    'http_req_duration': ['p(95)<200'],
    'http_req_failed': ['rate<0.01'],
  },
};
*/

// 场景 3：突发流量测试
/*
export const options = {
  stages: [
    { duration: '10s', target: 1000 },  // 10 秒内激增到 1000 用户
    { duration: '1m', target: 1000 },   // 保持 1 分钟
    { duration: '10s', target: 0 },     // 快速降至 0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'],
    'http_req_failed': ['rate<0.05'],   // 允许 5% 错误率
  },
};
*/

// 场景 4：压力测试（找到崩溃点）
/*
export const options = {
  stages: [
    { duration: '2m', target: 500 },
    { duration: '3m', target: 1000 },
    { duration: '3m', target: 2000 },
    { duration: '3m', target: 5000 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    'http_req_failed': ['rate<0.1'],    // 允许 10% 错误率
  },
};
*/

// ========================================
// 测试函数
// ========================================
export default function () {
  // 测试验证接口（核心功能）
  testVerifyEndpoint();

  // 可选：测试其他接口
  // testLoginEndpoint();
  // testRedeemEndpoint();

  // 模拟真实用户行为：每次请求间隔 100-500ms
  sleep(Math.random() * 0.4 + 0.1);
}

// ========================================
// 验证接口测试
// ========================================
function testVerifyEndpoint() {
  const url = `${BASE_URL}/api/verify`;
  const payload = JSON.stringify({
    key: TEST_API_KEY,
    product: TEST_PRODUCT_ID,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: { name: 'VerifyAPI' }, // 标记用于分析
  };

  const start = Date.now();
  const res = http.post(url, payload, params);
  const duration = Date.now() - start;

  // 记录响应时间
  verifyDuration.add(duration);

  // 检查响应
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
    'has valid field': (r) => {
      try {
        const body = JSON.parse(r.body);
        return 'valid' in body;
      } catch {
        return false;
      }
    },
  });

  // 记录成功/失败
  if (success) {
    successCounter.add(1);

    // 验证业务逻辑
    try {
      const body = JSON.parse(res.body);
      if (body.valid === true) {
        // console.log(`✓ Valid: remaining=${body.remaining}`);
      } else if (body.valid === false) {
        // 配额耗尽也算成功（正常业务逻辑）
        // console.log(`✓ Quota exhausted`);
      } else {
        errorRate.add(1);
        console.error(`✗ Unexpected response: ${res.body}`);
      }
    } catch (e) {
      errorRate.add(1);
      console.error(`✗ JSON parse error: ${e.message}`);
    }
  } else {
    failureCounter.add(1);
    errorRate.add(1);
    console.error(`✗ Request failed: status=${res.status}, body=${res.body}`);
  }
}

// ========================================
// 管理员登录测试（示例）
// ========================================
function testLoginEndpoint() {
  const url = `${BASE_URL}/api/admin/login`;
  const payload = JSON.stringify({
    username: 'admin',
    password: 'admin123',
  });

  const params = {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: 'LoginAPI' },
  };

  const res = http.post(url, payload, params);

  check(res, {
    'login status is 200': (r) => r.status === 200,
    'login has token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return 'token' in body;
      } catch {
        return false;
      }
    },
  });
}

// ========================================
// 测试完成后的汇总
// ========================================
export function handleSummary(data) {
  console.log('\n========================================');
  console.log('测试总结');
  console.log('========================================\n');

  const metrics = data.metrics;

  // HTTP 请求统计
  if (metrics.http_reqs) {
    console.log(`总请求数: ${metrics.http_reqs.values.count}`);
    console.log(`请求速率: ${metrics.http_reqs.values.rate.toFixed(2)} req/s`);
  }

  // 响应时间
  if (metrics.http_req_duration) {
    const duration = metrics.http_req_duration.values;
    console.log(`\n响应时间统计:`);
    console.log(`  P50: ${duration['p(50)'].toFixed(2)}ms`);
    console.log(`  P95: ${duration['p(95)'].toFixed(2)}ms`);
    console.log(`  P99: ${duration['p(99)'].toFixed(2)}ms`);
    console.log(`  平均: ${duration.avg.toFixed(2)}ms`);
    console.log(`  最小: ${duration.min.toFixed(2)}ms`);
    console.log(`  最大: ${duration.max.toFixed(2)}ms`);
  }

  // 验证接口专用指标
  if (metrics.verify_duration) {
    const verify = metrics.verify_duration.values;
    console.log(`\n验证接口响应时间:`);
    console.log(`  P95: ${verify['p(95)'].toFixed(2)}ms`);
    console.log(`  平均: ${verify.avg.toFixed(2)}ms`);
  }

  // 成功率
  if (metrics.http_req_failed) {
    const failRate = metrics.http_req_failed.values.rate * 100;
    console.log(`\nHTTP 错误率: ${failRate.toFixed(2)}%`);
  }

  if (metrics.errors) {
    const errRate = metrics.errors.values.rate * 100;
    console.log(`业务错误率: ${errRate.toFixed(2)}%`);
  }

  // 成功/失败计数
  if (metrics.successful_verifications) {
    console.log(`\n成功验证: ${metrics.successful_verifications.values.count}`);
  }
  if (metrics.failed_verifications) {
    console.log(`失败验证: ${metrics.failed_verifications.values.count}`);
  }

  console.log('\n========================================\n');

  // 返回报告（可选：生成 HTML/JSON 报告）
  return {
    'stdout': '', // 已通过 console.log 输出
    'summary.json': JSON.stringify(data, null, 2),
    // 'summary.html': htmlReport(data), // 需要自定义函数
  };
}

// ========================================
// 使用说明
// ========================================
/*
基本用法:
  k6 run load-test.js

指定 URL 和测试数据:
  k6 run -e BASE_URL=https://api.example.com \
         -e TEST_API_KEY=sk_xxxxx \
         -e TEST_PRODUCT_ID=prod_xxxxx \
         load-test.js

生成 HTML 报告:
  k6 run --out json=results.json load-test.js
  # 然后使用 k6-reporter 生成 HTML

实时监控:
  k6 run --out influxdb=http://localhost:8086/k6 load-test.js

查看详细日志:
  k6 run --verbose load-test.js

快速测试（10秒）:
  k6 run --stage 10s:10 load-test.js

常见问题:
  Q: 如何增加并发用户数？
  A: 修改 options.stages 中的 target 值

  Q: 如何延长测试时间？
  A: 修改 options.stages 中的 duration 值

  Q: 测试失败了怎么办？
  A: 查看输出的错误信息，检查 BASE_URL 是否正确，API 是否可访问

  Q: 如何测试不同的接口？
  A: 复制 testVerifyEndpoint 函数，修改 URL 和 payload
*/
