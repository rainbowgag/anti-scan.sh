#!/bin/bash
# ==========================================
# 一键防扫 + VPS 基础防护脚本
# 兼容 CentOS 7/8 和 Ubuntu 20/22/24
# 功能：
# 1. 安装 fail2ban 并启用
# 2. 清理 SSH 爆破日志
# 3. 重启系统日志服务释放内存
# 4. 创建 1G swap（如果没有）
# ==========================================

echo "=== 0. 检测系统类型 ==="
if [ -f /etc/redhat-release ]; then
    OS="centos"
    PKG_UPDATE="yum update -y"
    PKG_INSTALL="yum install -y fail2ban"
    LOG_SERVICE="rsyslog"
elif [ -f /etc/lsb-release ] || [ -f /etc/issue ]; then
    OS="ubuntu"
    PKG_UPDATE="apt update -y && apt upgrade -y"
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
else
    echo "$LOG_SERVICE 未运行，跳过"
fi

echo "=== 6. 检查 swap，如果没有则创建 1G swap ==="
if ! swapon --show | grep -q swapfile; then
    echo "创建 swap..."
    rm -f /swapfile
    dd if=/dev/zero of=/swapfile bs=1M count=1024
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    # 永久挂载
    if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
    fi
    echo "swap 已创建并启用 1G"
else
    echo "swap 已存在，跳过"
fi

echo "=== 7. 防护完成 ==="
echo "fail2ban SSH 状态："
fail2ban-client status sshd
echo "当前内存情况："
free -h
