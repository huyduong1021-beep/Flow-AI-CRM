# Flow — Đăng Facebook theo lịch

Soạn bài, tải ảnh/video, lên lịch. **Facebook tự đăng đúng giờ — máy bạn tắt vẫn lên.**

```
index.html  (một file, chạy trong trình duyệt)
    │
    ├── Soạn bài    — nội dung, ảnh, video, chọn giờ
    ├── Lịch đăng   — ngày · tuần · tháng · năm
    ├── Thư viện    — ảnh/video dùng lại mãi
    └── Thống kê    — thích, bình luận, chia sẻ, tiếp cận
    │
    │  Graph API gọi thẳng, không qua máy chủ nào
    ▼
Facebook  ← giữ bài đã lên lịch và tự đăng
```

## Không có máy chủ nào. Vì sao vẫn tự đăng được?

**Facebook tự lo việc lên lịch.** Graph API có tham số `scheduled_publish_time`:
gửi bài kèm mốc thời gian, Facebook giữ lại và tự đăng đúng giờ.

Nghĩa là không cần cron, không cần database, không cần backend. Bài đã lên lịch
nằm trên máy chủ Facebook — đóng trình duyệt, tắt máy, bài vẫn lên.

Ràng buộc của Facebook: sớm nhất **10 phút** nữa, muộn nhất **6 tháng**.

## App Secret không tham gia vào đây

App này **không cần** App Secret và sẽ không bao giờ hỏi tới nó. Secret chỉ dùng để
đổi token ngắn hạn thành token 60 ngày — mà việc đó không cần thiết:

- Bài đã lên lịch do Facebook giữ. Token hết hạn cũng không ảnh hưởng.
- Mỗi lần mở app, SDK tự lấy token mới từ phiên đăng nhập Facebook của bạn.

**Nếu App Secret của bạn từng bị chụp màn hình hay dán vào đâu đó, hãy vào
developers.facebook.com bấm Đặt lại.** App này không dùng nó, nhưng người khác thì có thể.

---

## Chạy

```bash
cd "AI post"
./serve.sh
```

Mở <http://localhost:8000>.

**Phải chạy qua localhost, không nhấp đúp vào file.** Facebook đối chiếu origin của
trang với Miền ứng dụng đã khai — `file://` không có origin nên đăng nhập sẽ hỏng.
App sẽ tự cảnh báo nếu bạn mở sai cách.

## Cấu hình Meta App (làm một lần)

App **Flow - Fanpage** (`876762305480694`) đã có sẵn. Cần khai 2 ô, **ở 2 trang khác nhau**.

### Trang Thông tin cơ bản — KHÔNG đụng gì cả

| Ô | Điền |
|---|---|
| **Miền ứng dụng** | *(để trống)* |
| **Vùng tên** | *(để trống)* |

> **Đừng cố khai `localhost` ở đây.** Ô Miền ứng dụng đòi tên miền thật có đuôi
> (`.com`, `.org`…) và sẽ báo *"Phải chứa miền cấp cao nhất"*. Facebook **tự động cho
> phép localhost** khi app ở chế độ Development — không cần khai, và cũng không khai được.
>
> **Ô Vùng tên nằm ngay cạnh và rất dễ nhầm.** Nó là tên định danh duy nhất trên *toàn
> Facebook*, không liên quan tới OAuth. Điền `localhost` vào đó sẽ báo *"Already used by
> some other app"*. Để trống.

### Chỗ duy nhất phải khai — Đăng nhập bằng Facebook → Cài đặt

Bật **3 công tắc** này:

| Công tắc | Đặt |
|---|---|
| **Đăng nhập OAuth ứng dụng** | Bật — công tắc tổng, tắt là mọi thứ dưới vô nghĩa |
| **Đăng nhập OAuth trên web** | Bật |
| **Đăng nhập bằng JavaScript SDK** | Bật — **app này gọi `FB.login()`, thiếu là hỏng hẳn** |

Rồi điền 2 ô:

| Ô | Điền | Lưu ý |
|---|---|---|
| **URI chuyển hướng OAuth hợp lệ** | `http://localhost:8000/` | URL đầy đủ, **có** `/` cuối |
| **Miền được phép cho JavaScript SDK** | `http://localhost:8000` | Origin, **không có** `/` cuối |

Để nguyên **Thực thi HTTPS** = Bật: Facebook miễn trừ localhost.

### Rồi trong app

**Kết nối trang** → đăng nhập → chọn fanpage (có nút **Chọn tất cả**). Xong.

**F5 không phải nối lại** — trong khoảng token còn sống.

Về việc "30 ngày không cần đăng nhập": **không làm được nếu không có máy chủ.** Đây là
giới hạn của Facebook, không phải lựa chọn của tôi:

- Token 60 ngày chỉ có khi đổi qua **App Secret** — mà Secret thì không được phép nằm
  trong trình duyệt.
- Luồng không có Secret chỉ nhận token sống **1–2 tiếng**.
- `FB.getLoginStatus()` (xin token mới lặng lẽ) cần **cookie bên thứ ba** của
  facebook.com. Brave và Safari chặn thẳng, Chrome tuỳ cài đặt — nên không tin được.

Thực tế bạn nhận được:

| Tình huống | Việc phải làm |
|---|---|
| F5 trong 1–2 tiếng | Không gì cả, vào thẳng |
| Token hết hạn, trong 30 ngày | Bấm **một lần** — không phải chọn lại trang |
| Quá 30 ngày | Đăng nhập và chọn trang lại |

Muốn thật sự 30 ngày không đụng tới thì phải có một máy chủ giữ App Secret để đổi
token dài hạn.

App ID `876762305480694` đã **nhúng sẵn trong code** — không phải nhập gì. Ô **Cấu hình**
chỉ dùng khi bạn muốn đổi sang một Meta App khác; đổi rồi vẫn có nút trả về mặc định.

> **Mấy trường Meta báo thiếu** (Biểu tượng 1024×1024, Chính sách quyền riêng tư,
> Hạng mục) là điều kiện để **App Review** — chỉ cần khi muốn người ngoài dùng app.
> App ở chế độ Development vẫn đăng bài thật lên fanpage mà bạn quản trị.

## Cấp quyền trang

Vào [business.facebook.com](https://business.facebook.com) → **Cài đặt** → **Trang** →
đảm bảo tài khoản bạn có vai trò **Quản trị viên**. Thiếu quyền thì trang vẫn hiện
trong danh sách nhưng bị làm mờ, không chọn được.

---

## Dùng

### Soạn bài

- **Lưu nháp** — nằm trên máy bạn, chưa đụng tới Facebook. Soạn được cả khi chưa kết nối.
- **Đăng ngay** — lên Facebook lập tức.
- **Lên lịch** — Facebook giữ bài và tự đăng đúng giờ.

Ảnh/video kéo thả thẳng vào ô. File nằm trong máy cho tới lúc bấm Đăng, rồi đi thẳng
lên Facebook trong chính request đăng bài — không qua kho trung gian nào.

**Ràng buộc của Facebook về media:** một bài là ảnh **hoặc** video, không trộn.
Tối đa 10 ảnh, hoặc đúng 1 video. App chặn sẵn.

### Thư viện

Mọi ảnh/video bạn đính vào bài **tự động vào thư viện và ở lại đó**. Bài đăng xong,
xoá bài, gỡ ảnh ra khỏi bài — file vẫn còn. Chỉ mất khi bạn tự xoá trong tab Thư viện.

Trong ô soạn bài, bấm **Chọn từ thư viện** để lấy lại ảnh cũ mà không phải tải lên lần nữa.
Mỗi file hiện số lần đã dùng, nên biết cái nào hay xài và cái nào bỏ quên.

File nằm trong `IndexedDB` của trình duyệt. Tab Thư viện hiện tổng dung lượng đang chiếm
so với hạn mức trình duyệt cho phép.

> **Xoá dữ liệu duyệt web là mất sạch thư viện.** File chỉ nằm trên máy này, không có
> bản sao ở đâu khác.

### Lịch đăng

Lịch tháng là mặc định. Ngày của tháng khác để trống hẳn cho khỏi nhầm. Bấm một ngày
để xem chi tiết, bấm ô giờ trống để soạn bài vào đúng khung đó.

Bài đã lên lịch và đã đăng **đọc ngược từ Facebook** — nên nếu bạn sửa bài trên điện
thoại, app vẫn thấy đúng. Chỉ bản nháp mới nằm trên máy.

### Thống kê

| Chỉ số | Nghĩa |
|---|---|
| **Lượt xem** | Số lần bài hiện ra (`post_impressions`). Bài video hiện thêm lượt xem video. |
| **Tiếp cận** | Số người riêng biệt đã thấy. Kèm tần suất — mỗi người thấy mấy lần. |
| **Tương tác** | Thích + bình luận + chia sẻ |
| **Tỉ lệ tương tác** | Tương tác chia cho tiếp cận |
| **Hiệu quả** | Bài này so với chính các bài khác của bạn |

**Hiệu quả** lấy **trung vị** của các bài trong khoảng đang xem làm mốc:

| Mức | Nghĩa |
|---|---|
| ▲▲ Xuất sắc | ≥ 1.8× trung vị |
| ▲ Trên mức | ≥ 1.05× |
| — Trung bình | 0.6 – 1.05× |
| ▼ Dưới mức | < 0.6× |

Dùng trung vị chứ không phải trung bình: **một bài viral kéo trung bình lên**, làm mọi
bài còn lại đều trông kém dù chúng bình thường.

Thích, bình luận, chia sẻ luôn có — chúng đến từ chính bài đăng.

**Tiếp cận và lượt xem** đến từ Insights, cần:
- Quyền `pages_read_engagement` trong token
- Vai trò **Quản trị viên** trên trang
- Trang **đủ điều kiện nhận Insights** (Facebook yêu cầu lượng theo dõi tối thiểu)

Thiếu bất kỳ điều nào thì hai số này hiện 0, và app sẽ **hiện nguyên văn lỗi Facebook
trả về** ngay dưới các ô số liệu thay vì để bạn đoán.

> Vừa cấp thêm quyền cho trang? Bấm **Kết nối trang** đăng nhập lại — token cũ không
> tự cập nhật quyền mới.

---

## Chưa có

**AI sinh nội dung** và **Google Sheet** cần một máy chủ giữ khoá API — không làm được
từ trình duyệt mà không phơi khoá ra. Đăng bài và lên lịch thì không cần, nên đã chạy
thật ngay.

---

## Xử lý sự cố

**Nút "Đăng nhập bằng Facebook" bị mờ.** Đang mở bằng `file://` — chạy `./serve.sh`
rồi vào qua `http://localhost:8000`.

**`ERR_CONNECTION_REFUSED` khi mở localhost:8000.** Server chưa chạy. Mở Terminal,
chạy `./serve.sh`, và **để nguyên cửa sổ đó** — đóng là server tắt.

**Popup báo "Đăng nhập bằng JavaScript SDK chưa được bật".** Đúng cái công tắc quan
trọng nhất ở trang *Đăng nhập bằng Facebook → Cài đặt*.

**"URL bị chặn: URL chuyển hướng này không được đưa vào danh sách trắng".**
Chưa khai `http://localhost:8000/`. Dấu `/` cuối phải có, cổng phải khớp.

**"Phải chứa miền cấp cao nhất (.com hoặc .org)"** ở ô **Miền ứng dụng**.
Đừng cố khai `localhost` vào đó — ô này chỉ nhận tên miền thật. **Để trống**;
Facebook tự cho phép localhost ở chế độ Development.

**"Already used by some other app"** ở ô **Vùng tên**.
Điền nhầm ô. Vùng tên phải duy nhất toàn Facebook và không liên quan tới OAuth.
Để trống.

**"Can't load URL: miền của URL này không nằm trong Miền ứng dụng".**
Kiểm tra **URI chuyển hướng OAuth** ở trang *Đăng nhập bằng Facebook → Cài đặt* —
phải đúng `http://localhost:8000/`, khớp cổng, có `/` cuối.

**Popup mở rồi đóng ngay.** Trình duyệt chặn popup, hoặc trình chặn quảng cáo đang
chặn `connect.facebook.net`.

**Trang hiện ra nhưng bị mờ.** Tài khoản không có quyền `CREATE_CONTENT` trên trang đó.

**"Phiên đăng nhập đã hết hạn" (mã 190).** Bấm Kết nối trang để đăng nhập lại. Bài đã
lên lịch không bị ảnh hưởng — Facebook đang giữ chúng.

**"Bài trùng nội dung" (mã 506).** Facebook chặn đăng lặp cùng một nội dung.

**Lên lịch báo lỗi 10 phút.** Facebook không nhận mốc thời gian gần hơn 10 phút.

## Dữ liệu nằm ở đâu

| Thứ | Chỗ |
|---|---|
| App ID | **Hằng số trong code** (`APP_ID`) — đổi app thì sửa thẳng dòng đó |
| Bản nháp | `localStorage` |
| **Thư viện ảnh/video** | `IndexedDB` — ở lại tới khi bạn tự xoá |
| Trang đã chọn + token | `localStorage` — hết hạn sau 30 ngày |
| Bài đã lên lịch & đã đăng | **Facebook** |

**Token nằm trong `localStorage`.** Ban đầu tôi chỉ lưu id trang và xin token mới mỗi
lần mở — nghe an toàn hơn, nhưng cách đó cần cookie bên thứ ba nên gần như luôn hỏng.
Token trong `localStorage` của chính máy bạn, sống 1–2 tiếng, và app chỉ chạy trên
`localhost` — đổi lại là app dùng được.

**App ID không phải bí mật.** Nó nằm lộ thiên trong mọi request tới Facebook; ai xem mã
nguồn trang cũng thấy. Không có gì để giấu ở đây. Thứ bảo vệ bạn là app chỉ chạy trên
máy bạn.
