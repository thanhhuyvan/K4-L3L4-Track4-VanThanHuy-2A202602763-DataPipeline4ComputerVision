# Stage 5 — Warehouse, Airflow, Metabase

MSSV: `2A202602763`.

- Warehouse có đủ 6 mart, gallery 1.019 dòng; module 5 đạt 2/2.
- DAG `stage5_pipeline` thành công, 37 task instances gồm 26 partition ảnh.
- Lỗi mô phỏng: `trip-09608`, mapped index 25. Dùng phần số MSSV `202602763 % 26 = 25`; công thức `int(MSSV)` trong GUIDE không hỗ trợ MSSV có chữ. Đây là cách thích nghi local, cần xác nhận với giảng viên nếu yêu cầu cách chọn khác.
- Lần chạy `stage5_fail_once`: 29 success, 1 failed, 7 upstream_failed. Log chứa `simulated crash while extracting trip-09608`.
- Clear qua REST API Airflow (không thao tác tay trong UI): chỉ task failed và downstream bị chặn. Dry-run xác nhận scope 8; các task success giữ nguyên. Sau phục hồi 37/37 success; chỉ `silver_frames[25]` có try_number 2.
- Đã tắt `LAB_FAIL_ONCE` sau bài tập.
- Sau khi người dùng yêu cầu hoàn tất bài nộp, đã chạy submission_reset thành công và submission_clean_pipeline từ lake trống thành công; ảnh airflow_graph.png ghi nhận lần chạy này.

Dashboard: http://localhost:3000/dashboard/2. Tài khoản lab: `lab@example.com`, mật khẩu `Day9-lab-pass!`.
Câu hỏi riêng: trip nào có tỷ lệ ảnh bị loại cao nhất? SQL ở `evidence/metabase_question.sql`. Trip `trip-04622` thuộc drive A bị loại 34/60 ảnh (56,7%), còn 26 ảnh. Đây là tỷ lệ loại cuối cùng, không cộng các cờ chất lượng vì một ảnh có thể mang nhiều cờ.

Ảnh thật trong `screenshots/`: Graph thành công, log lỗi, Graph phục hồi, MinIO, dashboard và câu hỏi riêng.
Bằng chứng trạng thái, scope clear, log gốc trong `evidence/airflow_*`.

Bốn thí nghiệm đã có `idempotency.json`, `break_gate.json`, `leakage.json`, `threshold.json`.
Báo cáo nộp `REPORT.md` đã hoàn thiện với số liệu đo và khai báo AI. Lịch sử commit đóng gói bằng chứng theo stage sau khi thực hiện.
