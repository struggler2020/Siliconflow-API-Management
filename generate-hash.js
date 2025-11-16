// 生成密码哈希（与 Worker 逻辑完全一致）
const crypto = require('crypto');

async function hashPassword(password) {
  const data = Buffer.from(password + 'salt', 'utf-8');
  const hash = crypto.createHash('sha256').update(data).digest();
  return hash.toString('base64');
}

async function main() {
  const password = process.argv[2] || 'admin123';
  const hash = await hashPassword(password);

  console.log('\n========================================');
  console.log('密码哈希生成工具');
  console.log('========================================');
  console.log(`密码: ${password}`);
  console.log(`哈希: ${hash}`);
  console.log('\n执行以下 SQL 更新数据库：');
  console.log('========================================');
  console.log(`UPDATE admins SET password_hash = '${hash}' WHERE username = 'admin';`);
  console.log('========================================\n');

  console.log('或者插入新管理员：');
  console.log('========================================');
  console.log(`INSERT INTO admins (id, username, password_hash, created_at)`);
  console.log(`VALUES ('admin_default_001', 'admin', '${hash}', datetime('now'));`);
  console.log('========================================\n');
}

main();
