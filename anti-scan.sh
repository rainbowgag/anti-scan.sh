#!/bin/bash
# ==========================================
# 一键防扫 + VPS + x-ui/xray 内存优化脚本
# 兼容 CentOS 7/8 和 Ubuntu 20/22/24
# ==========================================

echo "=== 0. 检测系统类型 ==="
if [ -f /etc/redhat-release ]; then
    OS="centos"
    PKG_UPDATE="yum update -y"
    PKG_INSTALL="yum install -y fail2ban"
    LOG_SERVICE="rsyslog"
elif [ -f /etc/lsb-release ] || [ -f /etc/issue ]; then
    OS="ubuntu"
    PKG_UPDATE="apt update && apt upgrade -y"
    PKG_INSTALL="apt install -y fail2ban"
    LOG_SERVICE="rsyslog"
else
    echo "不支持的系统"
    exit 1
fi
echo "检测到系统: $OS"

echo "=== 1. 更新系统 & 安装 fail2ban ==="
$PKG_UPDATE
$PKG_INSTALL

echo "=== 2. 启用 fail2ban 服务 ==="
systemctl enable fail2ban
systemctl start fail2ban

echo "=== 3. 配置 fail2ban SSH 规则 ==="
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = systemd
maxretry = 5
findtime = 10m
bantime = 24h
EOF
systemctl restart fail2ban

echo "=== 4. 清理 SSH 爆破历史日志 ==="
cat /dev/null > /var/log/btmp
rm -f /var/log/btmp-* 2>/dev/null

echo "=== 5. 重启系统日志服务释放内存 ==="
if systemctl is-active --quiet $LOG_SERVICE; then
    systemctl restart $LOG_SERVICE
fi

echo "=== 6. 检查 swap，如果没有则创建 1G swap ==="
if ! swapon --show | grep -q swapfile; then
    echo "创建 swap..."
    rm -f /swapfile
    dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
    fi
    echo "swap 已创建并启用 1G"
else
    echo "swap 已存在，跳过"
fi

echo "=== 7. x-ui / xray 内存优化 ==="
# 限制 x-ui 日志文件
XUI_LOGS=(/www/x-ui/x-ui.db /www/x-ui/x-ui.log)
for f in "${XUI_LOGS[@]}"; do
    if [ -f "$f" ]; then
        truncate -s 0 "$f"
    fi
done

# 限制 xray 日志
XRAY_LOGS=$(find /etc/xray /usr/local/xray /root/ -type f -name "*.log" 2>/dev/null)
for f in $XRAY_LOGS; do
    truncate -s 0 "$f"
done

echo "=== 8. 清理 Docker 容器日志（如果有 Docker） ==="
if command -v docker >/dev/null 2>&1; then
    DOCKER_LOGS=$(find /var/lib/docker/containers/ -type f -name "*-json.log" 2>/dev/null)
    for f in $DOCKER_LOGS; do
        truncate -s 0 "$f"
    done
fi

echo "=== 9. 完成 ==="
echo "fail2ban SSH 状态："
fail2ban-client status sshd || echo "fail2ban-client 未找到或服务未运行"
echo "当前内存情况："
free -h

echo "=== 建议 ==="
echo "1. 定期更新系统及 x-ui/xray"
echo "2. 使用 SSH key，禁止密码登录"
echo "3. 观察 fail2ban 封禁情况：fail2ban-client status sshd"
