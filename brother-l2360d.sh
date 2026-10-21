#!/usr/bin/env bash
set -e

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Vui lòng chạy script với quyền sudo hoặc root."
  exit 1
fi

echo "[1/4] Kích hoạt kiến trúc i386 và cài đặt thư viện phụ thuộc..."
dpkg --add-architecture i386
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libc6:i386 libstdc++6:i386 wget gzip cups

echo "[2/4] Tải bộ cài Brother Printer Installer..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

INSTALLER_URL="https://download.brother.com/welcome/dlf006893/linux-brprinter-installer-2.2.4-1.gz"
wget -q --show-progress "$INSTALLER_URL" -O linux-brprinter-installer.gz
gunzip -f linux-brprinter-installer.gz

echo "[3/4] Cài đặt driver HL-L2360D (mặc định kết nối USB)..."
# Tự động trả lời: Y (đồng ý EULA) -> N (không đổi Device URI thủ công / giữ USB) -> N (bỏ qua in test)
printf 'y\ny\ny\ny\nn\nn\n' | bash linux-brprinter-installer HL-L2360D

echo "[4/4] Cấu hình tính năng in 2 mặt (Duplex) trên CUPS..."
systemctl restart cups
sleep 2

PRINTER_NAME=$(lpstat -p 2>/dev/null | awk '{print $2}' | grep -Ei "2360|HLL2360" | head -n 1)

if [ -n "$PRINTER_NAME" ]; then
  # Set ở cấp admin hệ thống
  lpadmin -p "$PRINTER_NAME" -o Duplex=DuplexNoTumble
  
  # Set cho CUPS default instance toàn hệ thống
  lpoptions -d "$PRINTER_NAME" -o Duplex=DuplexNoTumble
  
  # Set cho user đang chạy lệnh (hoặc SUDO_USER nếu chạy qua sudo)
  if [ -n "$SUDO_USER" ]; then
    su - "$SUDO_USER" -c "lpoptions -p $PRINTER_NAME -o Duplex=DuplexNoTumble"
  fi

  echo "[+] Đã kích hoạt in 2 mặt mặc định cho: $PRINTER_NAME"
else
  echo "[!] Chưa phát hiện tên máy in trong CUPS."
fi
