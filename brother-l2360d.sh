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
# Tìm tên máy in HL-L2360D đã đăng ký trong hệ thống CUPS
PRINTER_NAME=$(lpstat -p 2>/dev/null | awk '{print $2}' | grep -i "HLL2360D\|HL-L2360D" | head -n 1)

if [ -n "$PRINTER_NAME" ]; then
  # Thiết lập in đảo mặt cạnh dài (Long-Edge) làm mặc định
  lpadmin -p "$PRINTER_NAME" -o Duplex=DuplexNoTumble
  echo "[+] Đã kích hoạt in 2 mặt mặc định cho: $PRINTER_NAME"
else
  echo "[!] Cảnh báo: Không tìm thấy tên máy in trong danh sách CUPS. Hãy kiểm tra lại kết nối cáp USB."
fi

# Dọn dẹp thư mục tạm
rm -rf "$TEMP_DIR"
echo "[✓] Hoàn tất cài đặt driver và cấu hình in 2 mặt!"
