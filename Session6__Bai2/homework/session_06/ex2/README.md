# Báo Cáo Bài 2: Cấu hình phân quyền Nhóm và sudoers bằng visudo

- **Môn học:** IT_209 - Quản trị Hệ thống Linux / DevOps Foundation
- **Bài tập:** Session 06 - Bài 2
- **Học viên thực hiện:** Deployer Admin
- **Đường dẫn thư mục nộp:** `homework/session_06/ex2/`

---

## 1. Mục tiêu bài lab

1. Nắm vững kỹ năng quản lý tài khoản người dùng (`User`) và nhóm (`Group`) trong Linux.
2. Hiểu rõ cơ chế cấp phát đặc quyền qua `sudo` và tệp cấu hình an toàn `/etc/sudoers`.
3. Cấu hình phân quyền tối thiểu (Principle of Least Privilege) cho nhóm vận hành chỉ thực hiện một số lệnh `systemctl` cụ thể mà không cần cấp quyền root toàn hệ thống và không yêu cầu nhập mật khẩu (`NOPASSWD`).

---

## 2. Quy trình thực hiện

### Bước 1: Tạo nhóm `devops-admin` và người dùng `deployer`

Chạy các lệnh quản trị sau với quyền `root` (hoặc tiền tố `sudo`):

```bash
# 1. Tạo nhóm devops-admin mới
sudo groupadd devops-admin

# 2. Tạo tài khoản deployer mới
sudo adduser deployer

# 3. Thêm tài khoản deployer vào nhóm phụ devops-admin (-aG)
sudo usermod -aG devops-admin deployer

# 4. Kiểm tra lại thông tin user deployer và các nhóm liên kết
id deployer
```

> **Kết quả kiểm tra `id deployer`:**
> ```text
> uid=1001(deployer) gid=1001(deployer) groups=1001(deployer),1002(devops-admin)
> ```

---

### Bước 2: Cấu hình phân quyền đặc quyền trong `/etc/sudoers`

Sử dụng lệnh an toàn `visudo` để kiểm tra cú pháp trước khi lưu, tránh nguy cơ làm lỗi file sudoers khiến hệ thống mất quyền sudo:

```bash
sudo visudo
```

*(Hoặc tạo file cấu hình riêng biệt chuẩn Best Practice trong `/etc/sudoers.d/devops-admin`: `sudo visudo -f /etc/sudoers.d/devops-admin`)*

Thêm dòng quy tắc phân quyền sau vào cuối tệp:

```sudoers
%devops-admin ALL=(ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

#### Giải thích chi tiết cú pháp sudoers:
- `%devops-admin`: Ký tự `%` biểu thị đây là một **Group** (nhóm người dùng), áp dụng cho mọi thành viên thuộc nhóm `devops-admin`.
- `ALL=`: Quy tắc có hiệu lực trên tất cả các máy host.
- `(ALL)`: Cho phép thực thi lệnh dưới tư cách bất kỳ user/group nào (thông thường là `root`).
- `NOPASSWD:`: Không yêu cầu người dùng nhập mật khẩu khi chạy các lệnh nằm sau chỉ thị này.
- `/usr/bin/systemctl start *, /usr/bin/systemctl stop *, ...`: Chỉ định đường dẫn nhị phân tuyệt đối an toàn và các tham số lệnh được phép chạy.

---

### Bước 3: Đăng nhập tài khoản `deployer` và kiểm tra quyền hạn

Chuyển sang tài khoản `deployer`:
```bash
su - deployer
```

Kiểm tra danh sách lệnh đặc quyền mà `deployer` được phép thực thi:
```bash
sudo -l
```

Chạy thử lệnh khởi động lại dịch vụ hệ thống `cron` không cần mật khẩu:
```bash
sudo systemctl restart cron
```

Kiểm tra trạng thái dịch vụ sau khi restart:
```bash
sudo systemctl status cron
```

---

## 3. Kết quả thực thi thực tế (Console Output)

### 3.1. Kết quả lệnh `sudo -l` của user `deployer`

```text
deployer@linux-lab:~$ sudo -l
Matching Defaults entries for deployer on linux-lab:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User deployer may run the following commands on linux-lab:
    (ALL) NOPASSWD: /usr/bin/systemctl start *, /usr/bin/systemctl stop *, /usr/bin/systemctl restart *, /usr/bin/systemctl status *
```

### 3.2. Kết quả kiểm tra lệnh được phép (`systemctl restart cron`)

```text
deployer@linux-lab:~$ sudo systemctl restart cron
deployer@linux-lab:~$ echo $?
0

deployer@linux-lab:~$ sudo systemctl status cron
● cron.service - Regular background program processing daemon
     Loaded: loaded (/lib/systemd/system/cron.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2026-10-05 21:55:00 UTC; 5s ago
       Docs: man:cron(8)
   Main PID: 24512 (cron)
      Tasks: 1 (limit: 4616)
     Memory: 1.1M
        CPU: 12ms
     CGroup: /system.slice/cron.service
             └─24512 /usr/sbin/cron -f
```
*Nhận xét: Lệnh restart dịch vụ cron thực hiện thành công tức thì mà hoàn toàn không bị nhắc nhập mật khẩu.*

---

### 3.3. Kiểm thử an ninh: Thử nghiệm thực thi lệnh ngoài phạm vi cho phép

Để chứng minh tài khoản `deployer` không có toàn quyền `root` và bị kiểm soát an ninh nghiêm ngặt:

```text
deployer@linux-lab:~$ sudo cat /etc/shadow
[sudo] password for deployer: 
Sorry, user deployer is not allowed to execute '/usr/bin/cat /etc/shadow' as root on linux-lab.

deployer@linux-lab:~$ sudo apt update
Sorry, user deployer is not allowed to execute '/usr/bin/apt update' as root on linux-lab.
```
*Nhận xét: Khi user `deployer` cố tình gọi các lệnh không được khai báo trong `/etc/sudoers`, hệ thống ngay lập tức từ chối quyền truy cập (Permission Denied).*

---

## 4. Kết luận

- Đã cấu hình thành công nhóm `devops-admin` và user `deployer`.
- Cấu hình sudoers chính xác theo nguyên tắc đặc quyền tối thiểu (Least Privilege).
- User `deployer` có thể tự động hóa việc deploy và quản lý service (`start`, `stop`, `restart`, `status`) trơn tru mà không làm lộ quyền root hay mật khẩu quản trị.
