# Hướng dẫn cho AI agent

## Đọc tối thiểu trước khi làm

- Dự án game 3D survivor, **Godot 4.7.2 Standard / GDScript**, renderer Compatibility.
- Entry point: `project.godot` → `scenes/world.tscn`. Không cần .NET hoặc npm.
- Giao tiếp với người dùng bằng tiếng Việt; giữ thay đổi trong phạm vi yêu cầu.
- Đọc file này trước. Chỉ đọc mục liên quan trong [kiến trúc](docs/ARCHITECTURE.md)
  và [kiểm thử](docs/TESTING.md), rồi tìm code bằng `rg`.
- [README.md](README.md) là hướng dẫn chơi, chỉnh model và bảng kỹ năng chi tiết.
- Không đọc toàn bộ asset, `.godot/`, log hoặc tất cả test để khởi động tác vụ.
- Yêu cầu mới của người dùng ưu tiên hơn tài liệu; khi khác nhau, cập nhật code và
  tài liệu liên quan, không khôi phục thông số cũ theo lịch sử hội thoại.

## Luật chơi cần giữ nếu không được yêu cầu thay đổi

- Bắt đầu/chơi lại: chọn 1 trong 3 nâng cấp trước khi chiến đấu.
- Cơ chế wave:
  - Wave 1 spawn 20 quái, HP = 100.
  - Số lượng quái ở wave tiếp theo bằng wave trước đó + 20% (làm tròn). HP quái +20 mỗi wave (Wave 1: 100 HP, Wave 2: 120 HP...).
  - Thời gian để spawn toàn bộ quái của mỗi wave là 10 giây (interval = `10.0 / wave_total_enemies`).
  - Giới hạn tối đa 300 quái đồng thời trên sân: nếu đạt 300 quái thì spawner dừng và đợi người chơi tiêu diệt bớt quái mới spawn tiếp.
  - Tiêu diệt hết quái của wave sẽ mở menu chọn nâng cấp.
  - Tự động bắt đầu wave mới sau khi chọn xong nâng cấp.
- Sát thương súng cơ bản 100; nhân vật 100 HP; Orc cơ bản 100 HP, damage 10.
- Sinh quái ngẫu nhiên dọc theo dải trên cùng của map (X ±18, Z -27), tối đa 300 quái đồng thời trên sân.
- Sân 40×120, X ±20, Z ±60; không có chướng ngại vật trong sân.
- Tạm thời ẩn kỹ năng Đạn nảy, chỉ giữ Đạn xuyên thấu.
- Pause phải dừng chiến đấu, đạn, spawn, đồng hồ. Menu và nhạc vẫn hoạt động.
- Pause trong menu nâng cấp phải giữ lựa chọn; tiếp tục vẫn chờ chọn nâng cấp.
- Giữ hỗ trợ chuột/bàn phím và Xbox. Không đổi thao tác ngắm/bắn tự động.

## Quy trình sửa và phối hợp

1. Xác định phạm vi file, đọc trạng thái hiện tại; dùng `git status --short` nếu repo
   khả dụng. Không reset/ghi đè thay đổi chưa commit của người dùng hoặc agent khác.
2. Sửa nhỏ, theo cấu trúc hiện có. Tránh refactor không liên quan hoặc format toàn repo.
3. Khi nhiều agent cùng làm, thống nhất file mỗi bên phụ trách trước khi sửa;
   ưu tiên một bên tích hợp `world.gd`, `world.tscn` và các menu dùng chung.
   Không tự tạo thêm agent chỉ vì có tài liệu này.
4. Chạy kiểm tra tối thiểu theo [TESTING.md](docs/TESTING.md). Không mặc định chạy cả suite.
5. Báo cáo ngắn: thay đổi gì, file nào, kiểm tra nào đã chạy/kết quả, phần chưa kiểm tra.
   Không tuyên bố toàn bộ suite đạt khi chỉ chạy một phần.
6. Nếu bàn giao giữa chừng, ghi: mục tiêu, việc đã xong, file đã sửa, vấn đề còn lại,
   lệnh kiểm thử đã chạy và kết quả. Không chép nguyên log/hội thoại vào tài liệu.

## Tài nguyên và giới hạn thay đổi

- Scene/script tham chiếu model bằng đường dẫn `res://assets/...`; giữ nguyên đường dẫn
  trừ khi tác vụ yêu cầu đổi và đã cập nhật mọi tham chiếu.
- Không tự xóa asset, cache, `.uid`, `.import` hoặc license để “dọn dự án”.
  Khi được yêu cầu dọn: quét tham chiếu scene/script/resource, cả đường dẫn tải runtime
  và dependency của model/texture, rồi chỉ xóa trong phạm vi được giao.
- `.godot/` là cache/log/ảnh kiểm tra tạm; không dùng làm nơi lưu tài nguyên nguồn,
  không đưa vào bàn giao hoặc commit. Giữ license Kenney đi kèm asset.
- Sửa palette ở `arena_palette.gd`, không sửa hàng loạt material gốc Kenney.
- Không thay đổi runtime, tải asset mới, thêm plugin/dependency hoặc sinh lại audio
  nếu không cần thiết cho tác vụ.

## Tiết kiệm token và thời gian

- Tìm tên hàm/thuộc tính bằng `rg -n`, đọc đoạn liên quan thay vì in toàn file lớn.
- Thay đổi docs/chữ thuần: kiểm tra nội dung và link, **không chạy game test**.
- Thay đổi logic: mặc định 1 test sát phạm vi; chỉ thêm test thứ hai khi có liên kết
  hệ thống cần kiểm tra. Đây là mặc định, không phải giới hạn bỏ qua lỗi thực tế.
- Không viết test chỉ lặp lại phép gán đơn giản; thêm test cho hành vi/bug đáng giữ.
- Lưu output test vào `.godot/`; chỉ báo dòng tổng kết/lỗi. Thành công thì dừng.
- Không chạy lại cùng test nếu code liên quan chưa thay đổi và không có lỗi chưa rõ.
- Không chụp ảnh hoặc chạy renderer cho thay đổi logic thuần; UI/map chỉ kiểm tra
  hình ảnh cần thiết. Không chạy full suite chỉ để sửa tài liệu.
