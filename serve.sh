#!/usr/bin/env bash
# Chạy app trên localhost.
#
# Vì sao cần: Facebook SDK không đăng nhập được từ file:// — nó phải đối chiếu
# origin của trang với App Domains đã khai trong Meta App. localhost là origin
# duy nhất Facebook chấp nhận mà không cần HTTPS.

set -euo pipefail
PORT="${1:-8000}"
cd "$(dirname "$0")"

echo ""
echo "  Flow đang chạy tại:  http://localhost:${PORT}"
echo ""
echo "  Nhớ khai trong Meta App (developers.facebook.com):"
echo "    Đăng nhập bằng Facebook → Cài đặt:"
echo "      • URI chuyển hướng OAuth hợp lệ:      http://localhost:${PORT}/"
echo "      • Miền được phép cho JavaScript SDK:  http://localhost:${PORT}"
echo "      • Bật: Đăng nhập OAuth ứng dụng, OAuth trên web, JavaScript SDK"
echo ""
echo "  Ctrl+C để dừng."
echo ""

# Chặn cache.
#
# http.server mặc định gửi Last-Modified và trả 304, nên trình duyệt giữ bản
# index.html cũ trong cache — sửa code xong mở lại vẫn thấy bản cũ, rất khó
# nhận ra. Ép no-store để mỗi lần tải là bản mới nhất.
python3 - "$PORT" <<'PY'
import sys, http.server, socketserver

PORT = int(sys.argv[1])

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Vứt header điều kiện TRƯỚC khi send_head() xử lý.
        #
        # Bỏ Last-Modified khỏi phản hồi là chưa đủ: send_head() so thẳng
        # If-Modified-Since với mtime của file rồi trả 304, không thèm nhìn
        # tới Cache-Control. Không cắt ở đây thì trình duyệt vẫn chạy bản cũ.
        for k in ("If-Modified-Since", "If-None-Match"):
            if k in self.headers:
                del self.headers[k]
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def send_header(self, key, value):
        # Bỏ Last-Modified: có nó là trình duyệt gửi If-Modified-Since và
        # nhận lại 304, tức là vẫn dùng bản cũ dù ta đã bảo no-store.
        if key.lower() == "last-modified":
            return
        super().send_header(key, value)

    def log_message(self, fmt, *args):
        # Chỉ log lỗi, không log từng file tĩnh cho đỡ rối
        if args and str(args[1]).startswith(("4", "5")):
            super().log_message(fmt, *args)

# Đa luồng: mỗi kết nối một luồng riêng. Trước đây TCPServer đơn luồng — một
# kết nối keep-alive của trình duyệt đang mở là chặn mọi request khác, server
# treo cứng. ThreadingHTTPServer tránh hẳn chuyện đó.
class Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

with Server(("", PORT), H) as s:
    try:
        s.serve_forever()
    except KeyboardInterrupt:
        print("\n  Đã dừng.\n")
PY
