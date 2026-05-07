# 🛡️ Anti‑Scan VPS 防扫防护脚本

一个**通用的一键防扫/防爆破/内存优化脚本**，用于保护你的 VPS 不被 SSH 爆破、减少日志占用、增加 swap，适合运行代理节点（如 x‑ui/xray/Clash 订阅服务）的服务器。

📌 支持 **Ubuntu / CentOS（7/8）**  
📌 不修改 SSH 端口（保留 22，不会锁死自己）  
📌 自动安装 fail2ban + 配置 SSH 防爆破  
📌 自动创建 1G swap（如果不存在）  
📌 清理爆破日志、系统日志、x‑ui/xray 日志、Docker 日志  
📌 显示当前防护状态和内存使用情况

---

## 🚀 功能说明

| 功能 | 说明 |
|------|------|
| fail2ban 安装与启动 | 防止 SSH 爆破 |
| SSH 防护规则 | 5 次失败封 IP 24 小时 |
| 清理 SSH 爆破日志 | 清空 /var/log/btmp 等日志 |
| 自动创建 swap | 强化低内存 VPS 稳定性 |
| x‑ui/xray 日志清理 | 避免长期日志占用内存 |
| Docker 日志清理 | 减少 Docker 容器日志空间 |
| 兼容多个 Linux 发行版 | Ubuntu / CentOS 皆可 |

---

## 📥 下载与执行

你可以用以下命令一键获取并执行：

```bash
curl -O https://raw.githubusercontent.com/rainbowgag/anti-scan.sh/refs/heads/main/anti-scan.sh
chmod +x anti-scan.sh
sudo ./anti-scan.sh
