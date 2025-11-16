#!/bin/bash
# ========================================
# API密钥配额验证系统 - 快速性能测试脚本
# ========================================
# 使用 wrk 或 curl 进行简单的性能测试
# ========================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
BASE_URL="${BASE_URL:-https://api.yourdomain.com}"
TEST_API_KEY="${TEST_API_KEY:-sk_test_xxxxx}"
TEST_PRODUCT_ID="${TEST_PRODUCT_ID:-prod_test_xxxxx}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}API 性能测试脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "测试目标: ${GREEN}${BASE_URL}${NC}"
echo ""

# ========================================
# 测试 1: 单次请求延迟测试
# ========================================
echo -e "${YELLOW}[1/4] 测试单次请求延迟...${NC}"

RESPONSE=$(curl -w "\n响应时间: %{time_total}s\n状态码: %{http_code}\n" \
  -X POST "${BASE_URL}/api/verify" \
  -H "Content-Type: application/json" \
  -d "{\"key\":\"${TEST_API_KEY}\",\"product\":\"${TEST_PRODUCT_ID}\"}" \
  -s)

echo "$RESPONSE"
echo ""

# ========================================
# 测试 2: 连续 10 次请求
# ========================================
echo -e "${YELLOW}[2/4] 测试连续 10 次请求...${NC}"

TOTAL_TIME=0
SUCCESS_COUNT=0

for i in {1..10}; do
  RESPONSE_TIME=$(curl -w "%{time_total}" -o /dev/null -s \
    -X POST "${BASE_URL}/api/verify" \
    -H "Content-Type: application/json" \
    -d "{\"key\":\"${TEST_API_KEY}\",\"product\":\"${TEST_PRODUCT_ID}\"}")

  TOTAL_TIME=$(echo "$TOTAL_TIME + $RESPONSE_TIME" | bc)
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  echo -n "."
done

AVG_TIME=$(echo "scale=3; $TOTAL_TIME / 10" | bc)
echo ""
echo -e "平均响应时间: ${GREEN}${AVG_TIME}s${NC}"
echo ""

# ========================================
# 测试 3: 并发测试（使用 xargs）
# ========================================
echo -e "${YELLOW}[3/4] 测试并发 10 个请求...${NC}"

START_TIME=$(date +%s.%N)

seq 1 10 | xargs -P 10 -I {} curl -s -X POST "${BASE_URL}/api/verify" \
  -H "Content-Type: application/json" \
  -d "{\"key\":\"${TEST_API_KEY}\",\"product\":\"${TEST_PRODUCT_ID}\"}" \
  > /dev/null

END_TIME=$(date +%s.%N)
CONCURRENT_TIME=$(echo "$END_TIME - $START_TIME" | bc)

echo -e "并发 10 请求总时间: ${GREEN}${CONCURRENT_TIME}s${NC}"
echo -e "QPS 估算: ${GREEN}$(echo "scale=2; 10 / $CONCURRENT_TIME" | bc)${NC}"
echo ""

# ========================================
# 测试 4: wrk 压力测试（如果已安装）
# ========================================
if command -v wrk &> /dev/null; then
  echo -e "${YELLOW}[4/4] 使用 wrk 进行压力测试 (30秒)...${NC}"
  echo ""

  # 创建临时 Lua 脚本
  cat > /tmp/verify.lua <<EOF
wrk.method = "POST"
wrk.body   = '{"key":"${TEST_API_KEY}","product":"${TEST_PRODUCT_ID}"}'
wrk.headers["Content-Type"] = "application/json"
EOF

  # 运行 wrk 测试
  # -t12: 12 个线程
  # -c100: 100 个并发连接
  # -d30s: 持续 30 秒
  wrk -t12 -c100 -d30s \
    -s /tmp/verify.lua \
    "${BASE_URL}/api/verify"

  # 清理临时文件
  rm /tmp/verify.lua
else
  echo -e "${YELLOW}[4/4] wrk 未安装，跳过压力测试${NC}"
  echo -e "提示: 安装 wrk 以进行更详细的压力测试"
  echo -e "  Mac: ${GREEN}brew install wrk${NC}"
  echo -e "  Ubuntu: ${GREEN}sudo apt install wrk${NC}"
  echo ""
fi

# ========================================
# 测试完成
# ========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}测试完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "建议："
echo -e "  - 如需更详细的测试，使用: ${GREEN}k6 run load-test.js${NC}"
echo -e "  - 查看 Cloudflare Dashboard 实时监控"
echo -e "  - 检查 Worker 日志: ${GREEN}wrangler tail api-key-management${NC}"
echo ""

# ========================================
# 使用说明
# ========================================
: '
使用方法:

1. 基本用法:
   ./benchmark.sh

2. 自定义配置:
   BASE_URL=https://api.example.com \
   TEST_API_KEY=sk_xxxxx \
   TEST_PRODUCT_ID=prod_xxxxx \
   ./benchmark.sh

3. 安装依赖:
   # Mac
   brew install wrk

   # Ubuntu
   sudo apt install wrk

4. 权限:
   chmod +x benchmark.sh
'
