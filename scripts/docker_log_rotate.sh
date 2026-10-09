#!/usr/bin/env bash
# Docker 日志治理：①立即清空现有容器日志（安全，不重启） ②可选 --configure 写入新容器日志上限
# 用法：sudo ./docker_log_rotate.sh              ← 只清空现有日志
#       sudo ./docker_log_rotate.sh --configure  ← 同时配置新容器的日志上限（需重启 docker，会中断容器！）
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行"; exit 1; }

# ── 立即清空现有日志（truncate 不中断服务）──
echo "===== 各容器日志大小 ====="
LOG_DIR="/var/lib/docker/containers"
TOTAL=0
for f in "$LOG_DIR"/*/*-json.log; do
  [ -f "$f" ] || continue
  SZ=$(du -m "$f" | cut -f1)
  TOTAL=$((TOTAL + SZ))
  [ "$SZ" -ge 1 ] && echo "  ${SZ}M  ${f}"
done
echo "合计约 ${TOTAL}M"

echo "清空全部容器日志（容器不中断）..."
find "$LOG_DIR" -name "*-json.log" -exec truncate -s 0 {} \;
echo "✅ 已清空"

# ── 可选：配置新容器的日志上限 ──
if [ "${1:-}" = "--configure" ]; then
  echo
  echo "⚠️  修改 daemon.json 并重启 docker——所有容器会中断几秒！"
  read -r -p "确认重启？(yes/no): " ok
  [ "$ok" = "yes" ] || { echo "跳过配置（现有日志已清空）"; exit 0; }
  if [ -f /etc/docker/daemon.json ]; then
    cp /etc/docker/daemon.json "/etc/docker/daemon.json.bak.$(date +%F)"
    echo "（已有 daemon.json，请人工合并 log-opts 后重启：备份在同目录）"
    cat <<'EOF'
需要合并的内容：
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
EOF
  else
    cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
    systemctl restart docker
    echo "✅ daemon.json 已写入并重启 docker（新容器日志自动轮转，单文件 10M×3）"
    echo "注意：只对新创建的容器生效，老容器需重建"
  fi
else
  echo
  echo "提示：以上是治标。要治本（新容器自动轮转），运行：sudo $0 --configure"
fi
