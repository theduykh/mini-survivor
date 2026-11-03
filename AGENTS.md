# Hướng dẫn cho AI agent

## Đọc tối thiểu trước khi làm
- Dự án: Game 3D survivor, **Godot 4.7.2 Standard / GDScript**, renderer Compatibility.
- Entry point: `project.godot` → `scenes/world.tscn`. Không cần .NET hoặc npm.
- Giao tiếp bằng tiếng Việt; chỉ sửa trong phạm vi yêu cầu.
- Chỉ đọc phần liên quan trong [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) và [docs/TESTING.md](docs/TESTING.md).
- Yêu cầu mới của người dùng luôn ưu tiên hơn tài liệu cũ. Khi có thay đổi, cập nhật cả code và docs liên quan.

## Luật chơi cốt lõi
- **Khởi đầu/chơi lại**: Chọn 1 trong 3 nâng cấp miễn phí trước khi Wave 1 bắt đầu.
- **Cơ chế Wave**:
  - Wave 1: 20 quái, HP = 100.
  - Wave tiếp theo: Số quái = wave trước + 20% (làm tròn số nguyên). HP quái = `100 + 20 * (wave - 1)`.
  - Toàn bộ quái của mỗi wave spawn trong 10 giây (`interval = 10.0 / wave_total_enemies`).
  - Giới hạn map: Tối đa 300 quái đồng thời trên sân. Nếu đạt 300, spawner dừng chờ người chơi diệt bớt mới spawn tiếp.
  - Tiêu diệt sạch toàn bộ quái của wave sẽ mở menu chọn 1 trong 3 nâng cấp.
  - Chọn nâng cấp xong sẽ tự động bắt đầu wave tiếp theo.
- **Chiến đấu**:
  - Nhân vật: 100 HP, tự động ngắm & bắn quái gần nhất trong tầm 28.
  - Súng: 100 sát thương cơ bản, nhịp bắn 1 phát/giây, tốc độ đạn 18.
  - Orc: 10 sát thương, nhịp đánh 1 lần/giây (windup 0.25s), tốc độ 2.2.
  - Đạn nảy tạm thời ẩn, chỉ giữ Đạn xuyên thấu.
- **Bản đồ**: Sân phẳng 40×120 (X ±20, Z ±60), không vật cản trong sân; quái spawn ở dải trên cùng (X ±18, Z -27).
- **Hệ thống**: Hỗ trợ bàn phím/chuột và tay cầm Xbox; phím T chuyển tốc độ 1x/2x; phím Esc mở menu tạm dừng (pause dừng chiến đấu, quái, đạn và spawner).

## Quy trình làm việc tiết kiệm token
1. `git status --short` để xem thay đổi hiện tại.
2. Dùng `git grep -n` tìm kiếm code, chỉ đọc đoạn liên quan, không in toàn bộ file lớn.
3. Sửa tối thiểu, đúng trọng tâm. Không refactor ngoài yêu cầu.
4. **Kiểm tra tiết kiệm**:
   - Đổi docs/text: Chỉ review diff, **tuyệt đối không chạy test game**.
   - Đổi logic: Mặc định chạy tối đa 1 test liên quan (xem [docs/TESTING.md](docs/TESTING.md)).
   - Lưu output test vào `.godot/`, chỉ lấy dòng tổng kết `ALL PASSED` hoặc lỗi.
5. Báo cáo ngắn gọn: thay đổi gì, file nào, kết quả test (nếu có chạy).
