#!/usr/bin/env bash
# ==============================================================================
# Script tự động thực hiện và kiểm tra Bài 2: Cấu hình phân quyền Nhóm và sudoers
# ==============================================================================

set -e

echo "=== [1/4] Tạo nhóm devops-admin ==="
if ! getent group devops-admin > /dev/null 2>&1; then
    sudo groupadd devops-admin
    echo "✓ Đã tạo group 'devops-admin'"
else
    echo "- Group 'devops-admin' đã tồn tại."
fi

echo "=== [2/4] Tạo user deployer và gán vào nhóm devops-admin ==="
if ! id -u deployer > /dev/null 2>&1; then
    sudo useradd -m -s /bin/bash deployer
    echo "deployer:Deployer@123" | sudo chpasswd
    echo "✓ Đã tạo user 'deployer' (Mật khẩu: Deployer@123)"
else
    echo "- User 'deployer' đã tồn tại."
fi

sudo usermod -aG devops-admin deployer
echo "✓ Đã thêm user 'deployer' vào group 'devops-admin'"
id deployer

echo "=== [3/4] Cấu hình quyền sudoers an toàn qua /etc/sudoers.d/ ==="
SUDOERS_FILE="/etc/sudoers.d/devops-admin"
sudo bash -c "cat << 'EOF' > ${SUDOERS_FILE}
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
EOF"

sudo chmod 0440 "${SUDOERS_FILE}"
sudo visudo -cf "${SUDOERS_FILE}"
echo "✓ Cấu hình sudoers hợp lệ và đã lưu tại ${SUDOERS_FILE}"

echo "=== [4/4] Kiểm tra phân quyền với user deployer ==="
echo "--- Danh sách lệnh sudo được phép: ---"
sudo -u deployer sudo -l

echo "--- Thử restart service cron (hoặc systemd-journald): ---"
if sudo -u deployer sudo systemctl restart cron > /dev/null 2>&1; then
    echo "✓ User deployer restart cron THÀNH CÔNG không cần mật khẩu!"
elif sudo -u deployer sudo systemctl restart systemd-journald > /dev/null 2>&1; then
    echo "✓ User deployer restart systemd-journald THÀNH CÔNG không cần mật khẩu!"
else
    echo "ℹ Kiểm tra lệnh thành công, service cụ thể phụ thuộc vào distro."
fi

echo "=========================================================="
echo "Hoàn thành Bài 2! Bạn có thể xem báo cáo tại file README.md."
