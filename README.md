# docker-ops-scripts

Docker 日常运维脚本集：磁盘被日志占满、镜像越积越多、容器备份没人管——这些常见事故的自动化解法。

全部 bash 脚本带中文注释、防误删设计（清理脚本默认不动数据卷、日志清空不重启容器），可独立使用，可挂 CRON。

## 快速开始

```bash
git clone https://github.com/lizs-eng/docker-ops-scripts.git
cd docker-ops-scripts
sudo ./scripts/docker_cleanup.sh        # 看看 docker 到底吃了多少磁盘
```

## 免费样章（本仓库）

| 脚本 | 用途 | 安全设计 |
|---|---|---|
| `docker_cleanup.sh` | 磁盘清理：悬空镜像/停止容器/构建缓存 | 默认不动数据卷，交互确认 |
| `docker_log_rotate.sh` | 日志治理：立即清空日志（不重启），可选配置新容器日志上限 | truncate 不中断服务 |
| `docker_backup_containers.sh` | 批量备份：镜像+启动参数+挂载卷，按日期归档 | 输出含恢复方法 |

## 完整版（¥19.9）

在免费样章之上追加 5 个脚本 + 3 份手册：

- **docker_update_container.sh**：镜像更新一键重建（自动提取端口/挂载/环境变量）
- **docker_monitor.sh**：资源占用 TOP + 崩溃容器 OOM 检测
- **docker_volume_backup.sh**：数据卷备份（临时容器方案，不依赖宿主机路径）
- **docker_compose_status.sh**：多 compose 项目状态巡检
- **手册**：安装依赖 / CRON 定时模板 / 常见报错速查（overlay2 膨胀、daemon.json 合并等）

→ 完整版与更多作品：[面包多小店](https://mbd.pub/o/engineer)

## 校准与许可

- 按 2026-10 的 Docker（24.x+）行为校准；需要 `jq`（update 脚本）
- 发现 bug 欢迎提 issue；许可：MIT（见 LICENSE）
