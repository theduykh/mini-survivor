# Mini Survivor — Godot 4 / GDScript

Game 3D survivor xây dựng trên Godot 4 (GDScript), renderer Compatibility, sử dụng asset Kenney. Nhân vật tự động ngắm và bắn quái vật Orc đang đuổi theo.

## Dành cho AI Agent và nhà phát triển

Vui lòng đọc [AGENTS.md](AGENTS.md) trước khi thực hiện tác vụ. Xem chi tiết cấu trúc tại [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) và hướng dẫn test tại [docs/TESTING.md](docs/TESTING.md).

## Điều khiển

| Thao tác | Bàn phím & Chuột | Tay cầm Xbox |
| --- | --- | --- |
| Di chuyển | WASD / Phím mũi tên | Cần trái (analog) / D-pad |
| Ngắm & Bắn | Tự động | Tự động |
| Đổi tốc độ game (1x / 2x) | Phím T / Click nút HUD | Nút X |
| Chơi lại (Restart) | Phím R | Nút Y |
| Tạm dừng (Pause) | Phím Esc | Nút Start / Menu |
| Bật / Tắt âm thanh | Phím M | Nút View / Back |
| Chọn nâng cấp | Phím 1, 2, 3 hoặc Click chuột | Cần trái / D-pad + Nút A |

## Luật chơi & Cơ chế Wave

1. **Khởi đầu**: Chọn 1 trong 3 nâng cấp miễn phí trước khi bước vào Wave 1.
2. **Cơ chế Wave**:
   - **Wave 1**: 20 quái Orc, HP mỗi con là 100.
   - **Wave tiếp theo**: Số lượng quái = số quái wave trước + 20% (làm tròn số nguyên).
   - **Máu quái**: Tăng +20 HP mỗi wave (`100 + 20 * (wave - 1)`: Wave 1 là 100, Wave 2 là 120, Wave 3 là 140...).
   - **Thời gian sinh quái**: Toàn bộ quái của mỗi wave được sinh đều trong **10 giây** (`interval = 10.0 / wave_total_enemies`).
   - **Giới hạn map**: Tối đa 300 quái sống đồng thời trên sân. Khi chạm mốc 300, spawner tạm dừng đợi người chơi diệt bớt mới sinh tiếp.
   - **Hoàn thành Wave**: Sau khi tiêu diệt sạch toàn bộ quái của wave, game tạm dừng và mở menu chọn 1 trong 3 nâng cấp.
   - **Tiếp tục**: Chọn nâng cấp xong sẽ tự động bắt đầu wave mới, nhịp delay spawn quái được reset trọn vẹn.

## Bảng chỉ số cơ bản

| Đối tượng | Thuộc tính | Giá trị cơ bản |
| --- | --- | --- |
| Nhân vật | HP tối đa | 100 |
| Súng | Sát thương | 100 / phát |
| Súng | Nhịp bắn | 1 phát / giây |
| Súng | Tầm bắn | 28 đơn vị |
| Súng | Tốc độ đạn | 18 đơn vị / giây |
| Orc | Sát thương | 10 / đòn đánh |
| Orc | Nhịp đánh | 1 đòn / giây (0.25 giây chuẩn bị) |
| Orc | Tốc độ di chuyển | 2.2 đơn vị / giây |
| Bản đồ | Kích thước sàn đấu | 40 × 120 (X ±20, Z ±60) |

## Danh sách nâng cấp (Upgrades)

| Kỹ năng | Tác dụng mỗi lần chọn | Giới hạn |
| --- | --- | --- |
| Cường hóa | +10% sát thương hiện tại (làm tròn) | Không giới hạn |
| Bắn nhanh | +10% tốc độ bắn hiện tại | 10 lần |
| Sinh lực | +25 HP tối đa và hồi ngay 25 HP | Không giới hạn |
| Đạn đôi | Thêm 1 viên bắn thẳng phía trước | 3 lần |
| Liên thanh | Bắn thêm một loạt đạn sau 0.12 giây | 3 lần |
| Đạn chéo | Thêm 2 viên ở góc ±25° (60% sát thương) | 3 lần |
| Đạn xuyên | Xuyên thêm 1 quái (sát thương giảm dần: 70%, 50%), không xuyên tường | 10 lần |
| Chí mạng | +15% tỉ lệ chí mạng | 5 lần (tối đa 75%) |
| ST chí mạng | +20% sát thương khi kích hoạt chí mạng | 10 lần |
| Hấp thụ | Hồi 2 HP mỗi khi hạ gục 1 quái | Không giới hạn |
| Nhanh nhẹn | +15% tốc độ di chuyển hiện tại | 10 lần |
| Đạn nảy | Tạm thời ẩn khỏi danh sách nâng cấp | Tạm ẩn |

*Lưu ý: Các kỹ năng đã đạt giới hạn sẽ không xuất hiện lại trong menu lựa chọn.*

## Cấu trúc thư mục tài nguyên chính

```text
scenes/              # Các scene chính (world.tscn, player.tscn, enemy.tscn, weapon.tscn, arena_map.tscn...)
scripts/             # Toàn bộ mã nguồn GDScript điều khiển gameplay, vũ khí, spawner, nâng cấp, menu
assets/models/kenney # 3D models GLB (mini-characters, mini-dungeon, mini-forest, kenney_blaster)
assets/audio/        # Âm thanh hiệu ứng và nhạc nền gốc
tests/               # Các bài smoke test có chọn lọc (wave_smoke, menu_smoke, upgrades_smoke...)
docs/                # Tài liệu kiến trúc và hướng dẫn kiểm thử
```
