#!/usr/bin/env bash
# 容器批量备份：把运行中容器的镜像+启动参数+挂载卷打包到日期目录
# 用法：sudo ./docker_backup_containers.sh [备份目录，默认 /opt/docker-backup/日期]
# 恢复思路见输出提示（镜像 docker load，数据卷 tar 解回）
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行"; exit 1; }
STAMP=$(date +%F)
DEST="${1:-/opt/docker-backup/$STAMP}"
mkdir -p "$DEST"

CONTAINERS=$(docker ps --format '{{.Names}}')
[ -n "$CONTAINERS" ] || { echo "没有运行中的容器"; exit 0; }

echo "$CONTAINERS" | while read -r name; do
  echo "──── 备份 $name ────"
  # 1. 镜像
  image=$(docker inspect "$name" --format '{{.Config.Image}}')
  safe_image=$(echo "$image" | tr '/:' '__')
  docker save "$image" -o "$DEST/${name}__img__${safe_image}.tar"
  # 2. 启动参数（重建用）
  docker inspect "$name" > "$DEST/${name}__inspect.json"
  # 3. 挂载卷数据
  mounts=$(docker inspect "$name" --format '{{range .Mounts}}{{.Source}} {{end}}')
  for src in $mounts; do
    [ -d "$src" ] || continue
    tgt="$DEST/${name}__volumes$(echo "$src" | tr '/' '_').tar"
    tar -czf "$tgt" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null || echo "  (跳过无法读取的挂载: $src)"
  done
  echo "  完成"
done

echo
echo "✅ 全部备份到: $DEST"
du -sh "$DEST"
echo "恢复提示：镜像 docker load -i xxx.tar；数据卷 tar -xzf 解回原挂载路径；参数对照 inspect.json 重建容器"
