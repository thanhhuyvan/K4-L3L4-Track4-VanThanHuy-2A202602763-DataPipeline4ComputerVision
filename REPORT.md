# REPORT — Lab Day 9

> Điền **bằng lời và số liệu của chính bạn** (lấy từ đầu ra của `scripts/lab.sh step ...` và từ `report/evidence/*.json`). Bài làm công khai trên GitHub; giảng viên đối chiếu với lịch sử commit và với bài của các bạn khác. Mỗi câu 3 đến 8 dòng là đủ.

| | |
|---|---|
| Họ và tên | Văn Thành Huy |
| MSSV (đúng bằng `LAB_STUDENT_ID` trong `.env`) | `2A202602763` |
| GitHub | `thanhhuyvan` |
| Trip dùng cho bài tập sập và chạy lại (xem GUIDE, bước 5) | `trip-09608` |

## Kết quả cuối

- `dataset_version` của bạn: `754d04ff57ed`  (phải khớp `report/evidence/run_summary.json`)
- Số khung hình train / val / test của bạn: 665 / 200 / 154 (train / val / test)
- `report/verify.txt`: tạo bằng `python3 scripts/check_submission.py --save-verify` (phải có `27/27 checks passed`).
- Ảnh chụp trong `report/screenshots/`: `airflow_graph.png`, `minio_lake.png`, `metabase_dashboard.png`, và ảnh bài tập sập/chạy lại (log task đỏ thấy trip của bạn).

## Bước 1 · Bronze

### Câu 1
Liệt kê **ít nhất 4 khác biệt** giữa telemetry nguồn A và nguồn B mà bạn thấy ở bronze. Vì sao pipeline giữ **mỗi nguồn một bảng bronze** và để mọi cột ở dạng chữ, thay vì gộp và ép kiểu ngay?

Nguồn A dùng ts_utc (ISO UTC), speed_mps (m/s), heading_deg, lat/lon và gas/brake theo tỷ lệ. Nguồn B dùng timestamp_ms (epoch ms), spd_kmh (km/h), hdg, latitude/longitude và throttle_pct/brake_pct (%); đồng hồ B nhanh 1.500 ms. Bronze có 3.021 dòng A và 3.234 dòng B. Giữ bảng riêng và cột telemetry dạng chữ bảo toàn giá trị gốc, kể cả ô trống hoặc schema khác nhau, để chuẩn hóa lại và truy nguyên khi luật thay đổi.

## Bước 2 · Silver telemetry

### Câu 2
Pipeline đưa hai nguồn về một schema như thế nào (đơn vị, kiểu thời gian, **độ lệch đồng hồ**)? Bằng chứng nào trong kết quả bước 2 cho thấy đã đúng? Dán bảng quarantine của bạn (số dòng theo từng lý do, từng drive) và giải thích vì sao dòng lỗi vào `rejects` thay vì bị xoá.

Staging đổi tốc độ B bằng chia 3,6, bàn đạp bằng chia 100; timestamp B trừ offset 1.500 ms trước khi đổi epoch sang UTC. Mẫu đầu B ở 14:30:00.009 UTC, cách đầu video 9 ms; tốc độ tối đa A/B khoảng 71/100 km/h. Có 2.968 dòng sạch A, 3.181 dòng sạch B, tổng 6.149.

| Lý do | A | B |
|---|---:|---:|
| duplicate | 20 | 20 |
| speed_missing | 30 | 30 |
| speed_out_of_range | 3 | 3 |

Mỗi drive cách ly 53 dòng, tổng 106; sạch + cách ly = 6.255 dòng nhận về. Rejects giữ nguyên bằng chứng và lý do để sửa hoặc điều tra, thay vì mất dữ liệu im lặng.

### Câu 3
Vì sao test `max_gap_ms` là `warn` còn `in_range` là `error`? Kết quả thí nghiệm `break-gate` của bạn (`break_gate.json`): test nào bắt được, bao nhiêu dòng, và điều đó cho biết gì về vai trò của "cổng chất lượng"?

max_gap_ms là warn vì mất tín hiệu cảm biến có thể xảy ra thật: cần báo và xử lý ảnh lệch đồng bộ, không nhất thiết chặn toàn bộ drive. Tốc độ ngoài miền hợp lệ là error vì dữ liệu sai không được đi vào dataset. break_gate.json ghi khi nới luật lên 1.000 m/s, test in_range_silver_telemetry_speed_mps__70__0 bắt 6 dòng: PASS=5 WARN=1 ERROR=1. Khôi phục luật có PASS=6 WARN=1 ERROR=0; gate độc lập giúp bắt lỗi của bước làm sạch.

## Bước 3 · Silver frames

### Câu 4
Dựa vào `idempotency.json`: số dòng trước và sau hai lần chạy lại, và khi ghi kiểu `append`. Vì sao Delta `overwrite` theo partition (một trip) an toàn hơn xoá rồi ghi lại, nhất là khi giữa chừng có lỗi?

Trip-00003 có 60 ảnh. Trước và sau hai lần chạy lại bảng có 1.246 dòng, fingerprint đều 6c7480dfde7e. Biến thể append ghi hai lần thành 120 dòng cho trip đó. Delta overwrite theo predicate trip_id thay partition bằng một commit nguyên tử; nếu ghi thất bại trước commit, phiên bản đã commit vẫn đọc được. Xóa rồi ghi tạo khoảng thời gian thiếu dữ liệu và có thể để trạng thái dở dang khi lỗi.

### Câu 5
Khung hình **đen** và khung hình **tối** khác nhau thế nào, pipeline xử lý khác nhau ra sao, bạn có đồng ý không? Dựa vào `threshold.json`: nếu chọn ngưỡng 0, 2, 6 thì bao nhiêu khung bị coi là trùng ở mỗi drive? Bạn chọn ngưỡng nào, vì sao, và ngưỡng đó phụ thuộc vào tốc độ xe thế nào?

| dHash khác tối đa | số khung trùng, drive A | số khung trùng, drive B |
|---|---|---|
| 0 | 61 | 8 |
| 2 | 149 | 53 |
| 6 | 363 | 244 |

Khung đen gần như không mang tín hiệu ảnh (mean luma dưới 12); khung tối có thể là đường hầm hoặc bóng râm thực, nên gắn cờ nhưng không loại chỉ vì tối. A/B có 6/4 ảnh đen; cờ tối giữ lại là 4/61 (các cờ có thể chồng lấp). Giữ cảnh tối giúp dataset phản ánh điều kiện vận hành.

Ngưỡng 2 là lựa chọn cân bằng trong lab: loại 149/53 ảnh gần trùng ở A/B. Ngưỡng 6 loại 363/244, có nguy cơ bỏ thay đổi thực; ngưỡng 0 chỉ bắt trùng rất sát. Khi xe chậm, ảnh liên tiếp vốn giống nhau nên cần đánh giá thêm khoảng thời gian và độ phủ cảnh, không coi một ngưỡng là tối ưu cho mọi tốc độ.

## Bước 4 · Gold

### Câu 6
Dựa vào `leakage.json`: chia theo khung hình làm bao nhiêu trip bị chia cắt, so với chia theo trip? Vì sao điều này làm điểm kiểm thử đẹp một cách giả tạo?

leakage.json ghi 1.019 ảnh thuộc 26 trip. Chia ngẫu nhiên theo ảnh làm cả 26 trip nằm ở nhiều split và có ảnh ở cả train lẫn test; chia theo trip có 0 trip bị chia cắt. Các ảnh gần thời gian giống nhau nên mô hình có thể nhớ cảnh đã thấy, làm điểm test tăng mà không chứng minh tổng quát sang chuyến mới. Thí nghiệm đo rò rỉ dữ liệu, không training hay đo mức tăng accuracy thực tế.

### Câu 7
Vì sao `dataset_version` là **băm nội dung** chứ không phải ngày giờ hay số đếm? Hai lần chạy liên tiếp cho kết quả gì? Vì sao `dataset_version` của bạn **khác** bạn bè dù cùng dữ liệu (liên hệ MSSV)?

Version 754d04ff57ed giữ nguyên qua các lần export, phục hồi và chạy lại. Code lấy SHA-256 của chuỗi frame_id|split được sắp theo frame_id, rồi lấy 12 ký tự đầu; không dùng thời gian chạy. MSSV được trộn vào md5(trip_id || MSSV) để xếp trip trong từng drive, nên đổi MSSV có thể đổi split và version. Đây không phải hash toàn bộ pixel hay telemetry: cùng IDs/split nhưng sửa nội dung ảnh có thể không đổi version; cần thêm checksum nội dung cho ứng dụng thực.

### Câu 8
Đọc phần `lineage` trong `manifest.json` của dataset bạn. Trả lời "dataset này được tạo từ dữ liệu nào?" bằng chính nội dung đó. Nếu một người hỏi 3 tháng sau, thông tin nào giúp tái tạo lại đúng dataset này?

Manifest của lần chạy cuối được lưu ở report/evidence/dataset_manifest.json. Lineage liệt kê phiên bản bronze.raw_telemetry_a, bronze.raw_telemetry_b, bronze.trips_raw, bronze.video_files; silver.frames, silver.telemetry, silver.frames_flagged và silver.frame_telemetry; kèm SHA-256 hai video đầu vào. Phiên bản lần chạy sạch: ba bảng Bronze telemetry/trips v0, video_files v1; Silver frames v25, telemetry/frames_flagged/frame_telemetry v0. SHA-256 video A là 636ba1a98dfc5ba665d1c935e1d2064e69f4df360ff9ffbd15795957d5e7e9aa; video B là bfa62703f645ff77a8578ae3fc74a00881140d38a404d43c8e2af265bbee9fdc. Dataset có 1.019 ảnh, MSSV 2A202602763 và split 665/200/154. Để tái tạo sau ba tháng cần dữ liệu nguồn đúng checksum, code/config và thư viện tương ứng, MSSV, luật lọc/split, cùng snapshot các bảng Delta được giữ lại. Reset xóa lịch sử Delta nên manifest riêng không đủ để time travel nếu bảng nguồn đã bị xóa.

## Bước 5 · Điều phối và phục vụ

### Câu 9
Mô tả chính xác điều xảy ra khi trip của bạn sập rồi chạy lại: bao nhiêu task chuyển đỏ, bao nhiêu task `upstream_failed`, bạn clear gì, dữ liệu có nhân đôi không, `dataset_version` có đổi không? Bằng chứng (ảnh, số) là gì?

Dùng phần số 202602763 % 26 = 25 để chọn trip-09608, vì int('2A202602763') trong hướng dẫn không hợp lệ. Run stage5_fail_once có 1 failed, 7 upstream_failed, 29 success. Qua REST API Airflow đã preview rồi clear task lỗi và 7 downstream bị chặn (không thao tác tay trên UI); 25 task ảnh thành công giữ nguyên. Sau phục hồi 37/37 success, chỉ silver_frames[25] có try_number 2. 1.246 dòng ảnh Silver và 1.019 ảnh Gold không nhân đôi, version vẫn 754d04ff57ed. Bằng chứng là log lỗi, Graph phục hồi và airflow_recovery.json. Lần chạy submission_clean_pipeline bổ sung kiểm chứng DAG từ lake trống sau submission_reset.

### Câu 10
Nâng từ 2 drive lên **500 xe mỗi ngày**: ba thành phần nào của pipeline này sẽ vỡ đầu tiên, và bạn thay bằng gì (nối với slide 12, 22, 23)?

Đây là dự đoán kiến trúc, chưa benchmark 500 xe. (1) Decode video trên một container và silver_frames chạy tuần tự sẽ nghẽn CPU/I/O: dùng worker phân tán, queue, giới hạn tài nguyên và phân phối theo trip. (2) Một file DuckDB là nút nghẽn ghi đồng thời: trong lab đã gặp file lock khi truy vấn lúc dbt chạy; quy mô lớn nên dùng engine phân tán hoặc warehouse quản lý phù hợp trên object storage/Delta. (3) Kho ảnh và gallery/BI sẽ tăng tải metadata, mạng và Postgres: dùng object storage có khả năng mở rộng, ảnh thumbnail, nạp mart tăng dần, index và tổng hợp trước. Airflow chỉ điều phối, không nên truyền video nặng qua XCom.

## Câu hỏi riêng của bạn trên Metabase

Câu SQL bạn thêm vào dashboard và điều nó cho biết:

Câu hỏi: trip nào có tỷ lệ ảnh bị loại cao nhất? SQL nằm trong report/evidence/metabase_question.sql và được thêm vào dashboard /dashboard/2.

```sql
select drive_id, trip_id, frames, frames_kept,
       round(100.0*(frames-frames_kept)/nullif(frames,0),1) as dropped_pct
from marts.mart_trip_summary
order by dropped_pct desc, trip_id;
```

Trip-04622 của A mất 34/60 ảnh (56,7%), còn 26 ảnh. Tỷ lệ dựa trên tập ảnh giữ cuối cùng; không cộng từng cờ vì một ảnh có thể mang nhiều cờ.

## Nhìn lại

Điều bạn thấy bất ngờ nhất, điều gì còn chưa rõ, và một lỗi dữ liệu mà bạn nghĩ pipeline **chưa** bắt được (nếu có). Tối đa 8 dòng.

Quan sát đáng chú ý: 61 ảnh tối của drive B được giữ theo cờ tối, trong khi ảnh đen bị loại; chất lượng không đồng nghĩa chỉ chọn cảnh sáng. Thử nghiệm chỉ chứng minh không có trip rải giữa các split, chưa chứng minh không còn cảnh tương tự giữa những trip khác nhau. Pipeline cũng chưa kiểm chứng semantic correctness của GPS, đối tượng nguy hiểm hiếm hoặc calibration camera. Các nhận xét này là phân tích từ kết quả lab, chưa được kiểm nghiệm bằng mô hình.

## Hỗ trợ AI và lịch sử thực hiện

Codex hỗ trợ cấu hình môi trường, chạy lệnh, thu thập bằng chứng, tạo câu SQL và soạn báo cáo từ kết quả thực. Mã pipeline và các file chấm điểm giữ nguyên. Báo cáo là bản được AI hỗ trợ soạn, cần người nộp đọc và hiểu trước vấn đáp. Các commit được đóng gói theo stage sau khi đã chạy các stage; không giả định chúng được tạo ngay lúc chạy.
