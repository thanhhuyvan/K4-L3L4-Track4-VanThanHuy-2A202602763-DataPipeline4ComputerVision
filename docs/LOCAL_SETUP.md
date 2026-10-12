# Môi trường local Windows

MSSV: `2A202602763`. Cấu hình nằm trong `.env` (không commit).
Dữ liệu giải nén từ `dataset/day09-data.zip`; `check_data.py` xác nhận 6/6 SHA-256 khớp bản chuẩn.

Chạy từ thư mục gốc repo trong PowerShell:

```powershell
docker compose --profile orchestrate --profile bi up -d --build
python scripts/check_data.py
./scripts/lab.ps1 test
./scripts/lab.ps1 dbt debug
```

Image gốc thiếu Git. Đã bổ sung vào container local; nếu recreate container, cài lại để `dbt debug` đạt đầy đủ:

```powershell
docker compose exec -T -u root airflow bash -c 'apt-get update -qq && apt-get install -y --no-install-recommends git'
```

Các bước học chạy bằng wrapper PowerShell tương đương `lab.sh`:

```powershell
./scripts/lab.ps1 step 1 --reset
./scripts/lab.ps1 step 2
./scripts/lab.ps1 step 3
./scripts/lab.ps1 step 4
./scripts/lab.ps1 step 5
```

`--reset` xóa lake: chỉ dùng khi muốn bắt đầu lại theo GUIDE.

- Airflow: http://localhost:8080 — `admin` / `admin`.
- MinIO: http://localhost:9001 — `minioadmin` / `minioadmin`.
- Metabase: http://localhost:3000 — chạy `python scripts/setup_metabase.py` ở bước 5 sau khi warehouse có dữ liệu.
- Postgres: localhost:5433; user/password `lab` / `lab`.

Thư viện xử lý nằm trong `/home/airflow/lab-venv` của container, không cần GPU hay venv Python trên Windows.
Không sửa các file chấm điểm. Dữ liệu và `work/` được Git bỏ qua.
