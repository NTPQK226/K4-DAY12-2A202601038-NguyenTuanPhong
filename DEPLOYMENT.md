# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị token vào đây.**
> Repo này công khai — dán token vào là mất token.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Nguyễn Tuấn Phong |
| Mã học viên | 2A202601038 |
| Repo | https://github.com/NTPQK226/K4-DAY12-2A202601038-NguyenTuanPhong |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://day12-chat-boi6.onrender.com |
| Platform | Render |
| Ngày deploy | 2026-08-10 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | platform tự gán |
| `API_TOKEN` | ✅ | đặt trong dashboard Render khi tạo Blueprint |
| `REDIS_URL` | ✅ | Redis add-on của Render (tạo tự động qua render.yaml) |
| `BUCKET_CAPACITY` | ✅ | 10 |
| `REFILL_PER_MINUTE` | ✅ | 10 |
| `DAILY_BUDGET_USD` | ✅ | 1.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

```bash
# 1. Liveness
curl -i https://day12-chat-boi6.onrender.com/healthz

# 2. Readiness
curl -i https://day12-chat-boi6.onrender.com/readyz

# 3. Không token
curl -i -X POST https://day12-chat-boi6.onrender.com/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}'

# 4. Có token
curl -i -X POST https://day12-chat-boi6.onrender.com/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "X-Client-Id: sv-test" \
  -d '{"message":"Deploy là gì?"}'

# 5. Rate limit
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " -X POST https://day12-chat-boi6.onrender.com/chat \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "X-Client-Id: sv-test" \
    -d '{"message":"test"}'
done; echo
```

## Kết Quả Chạy Thật

```
(.venv) PS D:\AI20K\K4-DAY12-2A202601038-NguyenTuanPhong> python -c "                
>> import urllib.request, urllib.parse, json
>> 
>> URL = 'https://day12-chat-boi6.onrender.com'
>> token = 'zpXPwI8TEr_jz9DKO8Zq_qQgZXc-73bzdzfUTztwyPA'
>> 
>> def do_request(url, data=None, auth=False):
>>     body = json.dumps(data).encode() if data else None
>>     headers = {'Content-Type': 'application/json'}
>>     if auth:
>>         headers['Authorization'] = 'Bearer ' + token
>>         headers['X-Client-Id'] = 'sv-test'
>>     req = urllib.request.Request(url, data=body, headers=headers)
>>     try:
>>         res = urllib.request.urlopen(req)
>>         return res.status, res.read().decode()
>>     except urllib.request.HTTPError as e:
>>         return e.code, e.read().decode()
>> 
>> # 1. healthz
>> print('1. healthz:')
>> code, body = do_request(URL + '/healthz')
>> print(code, body)
>> 
>> # 2. readyz
>> print('2. readyz:')
>> code, body = do_request(URL + '/readyz')
>> print(code, body)
>> 
>> # 3. Khong co token -> 401
>> print('3. Khong co token:')
>> code, _ = do_request(URL + '/chat', {'message': 'Hello'})
>> print(code, '(mong 401)')
>> 
>> # 4. Co token -> 200
>> print('4. Co token:')
>> code, body = do_request(URL + '/chat', {'message': 'Deploy la gi?'}, auth=True)
>> print(code, body[:150] if len(body) > 150 else body)
>> 
>> # 5. Rate limit - 15 lan
>> print('5. Rate limit (mong 14x200 + 429):')
>> for i in range(15):
>>     code, _ = do_request(URL + '/chat', {'message': 'test'}, auth=True)
>>     print(code, end=' ')
>> print()
>> "
1. healthz:
200 {"status":"ok","service":"day12-chat-service","version":"1.0.0"}
2. readyz:
200 {"status":"ready","redis":true}
3. Khong co token:
401 (mong 401)
4. Co token:
200 {"reply":"Ngắn gọn: Deploy la gi phụ thuộc vào ba yếu tố — cấu hình qua biến môi trường, health check để orchestrator biết trạng thái, và giới hạn tài
5. Rate limit (mong 14x200 + 429):
200 200 200 200 200 200 200 200 200 429 429 429 429 200 429
```

## Ảnh Chụp Màn Hình

Ảnh dashboard Render trong thư mục `screenshots/`.
