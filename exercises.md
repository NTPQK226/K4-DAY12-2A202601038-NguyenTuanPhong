# Phiếu Phản Ánh — K4 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
>
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
> Họ và tên: Nguyễn Tuấn Phong  Mã học viên: 2A202601038

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Giả sử bạn deploy lên Render mà quên set biến `API_TOKEN` trên dashboard.
> Nếu `api_token` có giá trị mặc định `"changeme"`, app sẽ khởi động bình
> thường và chấp nhận mọi request với token `"changeme"`. Kẻ tấn công quét
> Internet sẽ tìm thấy endpoint công khai, thử token mặc định và trúng — tiền
> LLM của bạn bị đốt cháy ngay mà bạn không hay. Nếu `api_token` không có mặc
> định, app **chết ngay tại thời điểm khởi động**, bạn nhận được lỗi
> `ValidationError` trên màn hình — đúng lúc bạn đang theo dõi deploy — và kịp
> sửa trước khi ai đó phát hiện.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng log ví dụ:
> ```json
> {"event": "chat_completed", "severity": "INFO", "ts": "2026-08-10T10:30:00+00:00", "client_id": "sv01", "prompt_tokens": 3, "completion_tokens": 42, "usd_cost": 0.0000226}
> ```
>
> Hai việc `print()` không làm được:
> 1. **Lọc theo mức độ nghiêm trọng:** dùng `severity: INFO/WARNING/ERROR` để
>    filter log chỉ hiển thị WARNING trở lên trên Railway/Render dashboard, hoặc
>    cấu hình cảnh báo tự động khi severity = ERROR.
> 2. **Đếm/tính toán theo trường:** truy vấn được "tổng chi phí của client
>    sv01 trong ngày" bằng cách parse `usd_cost`, hoặc tìm request nào gây lỗi
>    bằng cách filter `client_id=sv01` và `severity=ERROR` — không thể làm với
>    `print()` vì dòng log không có cấu trúc máy đọc được.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ~950 MB |
| Multi-stage | 270 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Bản 1 stage chứa toàn bộ Python build toolchain (compiler C, pip cache,
> debug symbols, documentation generator...) dùng runtime không cần gì trong số
> đó. Multi-stage dùng stage `builder` để cài đặt dependency, rồi chỉ COPY
> thư mục `/install` (thành phẩm) sang stage `runtime`. Stage runtime chỉ giữ
> Python runtime và các thư viện đã cài — không có compiler, không có source
> pip, không có build cache. ~680MB chênh lệch chính là build toolchain,
> pip cache, và các file không cần thiết cho production.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Với Dockerfile hiện tại (đúng thứ tự):
> ```
> COPY requirements.txt .      → cache HIT nếu requirements.txt chưa đổi
> RUN pip install ...           → cache HIT nếu requirements.txt chưa đổi
> COPY app/ ./app/             → REBUILD vì file vừa sửa
> COPY utils/ ./utils/         → REBUILD
> ```
> Chỉ layer `pip install` được dùng lại từ cache. Code mới được copy vào.
>
> Nếu đặt `COPY . .` lên trước `RUN pip install`:
> ```
> COPY . .                      → REBUILD mỗi lần sửa bất kỳ file nào
> RUN pip install ...           → REBUILD mỗi lần sửa bất kỳ file nào
> ```
> Mọi thay đổi code đều làm **toàn bộ pip install bị chạy lại**, mất thêm vài
> phút mỗi lần build. Tốc độ phát triển giảm rõ rệt.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi sự kiện:
> 1. Code Python có lỗ hổng cho phép ghi file tùy ý (ví dụ: path traversal).
> 2. Kẻ tấn công khai thác lỗ hổng, ghi file setuid binary vào `/usr/bin/bash`
>    với owner root và setuid bit.
> 3. Kẻ tấn công exec vào container và chạy `/usr/bin/bash` — vì container chạy
>    bằng root, bash được setuid lên root và kẻ tấn công có shell root trên
>    máy host (do cơ chế user namespace không luôn được bật).
> 4. Từ shell root trong container, kẻ tấn công đọc secrets trên host,
>    leo thang ra toàn bộ hệ thống.
>
> Lệnh `USER appuser` **cắt đứt ở bước 2**: dù lỗ hổng tồn tại và kẻ tấn
> công khai thác được, file họ ghi cũng thuộc owner `appuser` — không có quyền
> ghi vào `/usr/bin/` (thuộc root). Setuid binary không tạo được, chuỗi tấn
> công dừng lại ở mức container.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng
một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

> `WWW-Authenticate: Bearer` báo cho client biết header nào cần gửi và scheme
> nào được chấp nhận. Không có header này, trình duyệt hoặc thư viện HTTP không
> tự biết cách thử lại với credential đúng — nó chỉ hiển thị màn trắng cho
> người dùng. RFC 6750 quy định server phải gửi header này trong response 401.
>
> Trả cùng một thông báo cho cả ba trường hợp vì nguyên nhân bảo mật: nếu server
> phân biệt "thiếu header" vs "sai token", kẻ dò token có thể thu hẹp không
> gian tìm kiếm — biết được token đã đúng prefix hay suffix chưa. Một thông
> báo chung không cho kẻ tấn công biết gì thêm ngoài "xác thực thất bại",
> buộc hắn phải thử lại từ đầu hoàn toàn.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

> Sau 10 phút im lặng:
> - refill_per_second = 10/60 = 1/6 token/giây
> - tokens nạp thêm = 600 giây × 1/6 = 100 tokens
> - Với `min(capacity, ...)`: tokens = min(10, 10 + 100) = **10 tokens**
> → Client gửi được **10 request** trước khi bị 429.
>
> Nếu bỏ `min(capacity, ...)`: tokens = 10 + 100 = 110 tokens
> → Client gửi được **110 request** trước khi bị 429.
>
> Không có `min(capacity, ...)` là lỗi bảo mật nghiêm trọng: một client im
> lặng đủ lâu (ví dụ 1 giờ → 600 tokens) rồi bắn 600 request trong 1 giây,
> vượt rate limit vô hiệu hóa.

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

> - **$30/tháng**: Sự cố từ 2h sáng → thiệt hại tối đa $30. Service **không tự
>   hồi phục** cho đến ngày 1 tháng sau — có thể là 29 ngày trôi qua trước
>   khi budget reset. Đến lúc đó, toàn bộ ngân sách đã bị đốt cháy.
>
> - **$1/ngày**: Sự cố từ 2h sáng → thiệt hại tối đa $1. Service **tự hồi
>   phục vào 00:00 UTC ngày hôm sau** khi key Redis `spend:<client>:<YYYY-MM-DD>`
>   chuyển sang ngày mới. Không cần can thiệp thủ công, không cần reset thủ
>   công. Service trả lại bình thường sáng hôm sau.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> 1. Redis mất kết nối (lỗi mạng hoặc restart Redis pod).
> 2. Container A nhận request tiếp theo, gọi endpoint gộp → kết nối Redis thất
>    bại → trả 503.
> 3. Container B và C cũng nhận request, lần lượt trả 503.
> 4. Orchestrator/kubelet thấy **3 container liên tục trả 503** trên liveness
>    probe → restart cả 3 container cùng lúc.
> 5. Redis quay lại sau 30 giây — nhưng **không còn container nào đang chạy**
>    (đang restart hoặc đang khởi động lại).
> 6. Redis chạy, nhưng không có container nào phục vụ → toàn bộ service down.
>
> Tách `/healthz` (chỉ check process) và `/readyz` (check dependency):
> - Redis chết → `/healthz` vẫn 200 → container **không restart**
> - Redis chết → `/readyz` trả 503 → load balancer **ngừng gửi traffic**
> - Redis quay lại → `/readyz` trả 200 → load balancer **quay lại gửi traffic**
> - Không restart, service tự phục hồi ngay khi Redis online.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> **Lỗi:** Health check timeout — Render không nhận được phản hồi từ `/healthz`
> trong thời gian quy định, container bị đánh dấu là failed.
>
> **Nguyên nhân:** App đang bind vào `127.0.0.1` thay vì `0.0.0.0` trong lệnh
> khởi động, khiến health check từ Render (bên ngoài container) không kết nối
> được. Tôi phát hiện bằng cách xem log trên Render dashboard và thấy
> `Connection refused 127.0.0.1:8000`.
>
> **Sửa:** Cập nhật `docker-compose.yml` và `Dockerfile` CMD để uvicorn bind
> `--host 0.0.0.0` thay vì default `127.0.0.1`:
> ```
> CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
> ```
> Sau đó push lên GitHub, Render tự deploy lại với image mới.
