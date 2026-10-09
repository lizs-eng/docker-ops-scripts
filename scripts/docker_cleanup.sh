#!/usr/bin/env bash
# Docker 磁盘清理：先看占用，再清垃圾（默认不动数据卷，防误删数据）
# 用法：sudo ./docker_cleanup.sh [-a 更彻底(含未使用镜像)] 
# 安全设计：数据卷永远不自动删；交互确认后才执行
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行"; exit 1; }

echo "===== 清理前磁盘占用 ====="
docker system df

EXTRA=""
if [ "${1:-}" = "-a" ]; then
  EXTRA="-a"
  echo "（-a 模式：将连同未被容器使用的镜像一起清理）"
fi

echo
echo "将执行：docker system prune $EXTRA（不动数据卷）"
read -r -p "确认？(yes/no): " ok
[ "$ok" = "yes" ] || { echo "已取消"; exit 0; }

docker system prune -f $EXTRA | tail -2

echo
echo "===== 清理后磁盘占用 ====="
docker system df
echo "提示：数据卷需手动清理，逐个确认：docker volume ls 然后 docker volume rm <名称>"
