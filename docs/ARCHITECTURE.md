# Kiến trúc và các điểm tích hợp

Tài liệu mô tả cấu trúc hiện tại. Chỉ đọc phần phù hợp với tác vụ;
thông số gameplay tóm tắt trong [AGENTS.md](../AGENTS.md), bảng kỹ năng trong
[README.md](../README.md). Code và yêu cầu mới nhất quyết định hành vi thực tế.

## Bản đồ file

| Phạm vi | File chính | Trách nhiệm |
| --- | --- | --- |
| Vòng chơi | `scripts/world.gd`, `scenes/world.tscn` | Input bindings, spawn chung, kills, nâng cấp, HP scaling, camera, A*, HUD, reset |
| Nhân vật | `scripts/player.gd`, `scenes/player.tscn` | Di chuyển analog, animation, HP, chọn mục tiêu và xoay súng |
| Súng | `scripts/weapon.gd`, `scenes/weapon.tscn` | Cooldown, các loạt đạn, chí mạng, đầu nòng, tín hiệu `fired` |
| Đạn | `scripts/projectile.gd`, `scenes/projectile.tscn` | ShapeCast quét đường bay, impact, xuyên/nảy, range |
| Orc | `scripts/enemy.gd`, `scenes/enemy.tscn` | Đuổi theo A*, cận chiến có windup, HP, chết |
| Hiệu ứng | `scripts/enemy_feedback.gd`, `shaders/enemy_damage.gdshader` | Flash, recoil, dissolve riêng từng Orc |
| Cổng | `scripts/spawner.gd`, `scenes/spawner.tscn` | Model wall-opening, SpawnPoint, `spawn_one()` |
| Kỹ năng | `scripts/upgrades.gd` | Catalog, lọc giới hạn, chọn 3 ngẫu nhiên, áp hiệu quả |
| Menu nâng cấp | `scripts/upgrade_menu.gd` | 3 thẻ, khóa input ngắn, phím 1/2/3, Xbox |
| Start/pause | `scripts/game_menu.gd` | UI tạo bằng code, start/resume/restart/home/mute/quit |
| Map | `scenes/arena_map.tscn`, `scripts/arena_palette.gd` | Model trang trí và palette nâu đất dịu |
| Âm thanh | `scripts/game_audio.gd`, `assets/audio/` | Nhạc lặp, bắn, chết, mute |
| Công cụ | `tools/generate_audio.gd` | Tạo WAV gốc; không cần chạy khi phát triển thông thường |

`target.gd` / `target.tscn` là bia thử cũ, không nằm trong scene chính.
Model thực tế: Kenney mini-characters, mini-dungeon, mini-forest, kenney_blaster;
ưu tiên GLB. Không quét toàn bộ các bản định dạng khác cho tác vụ logic.

## Luồng trận và pause

1. World tạo `GameMenu` khi `_ready()`, mở màn hình start và pause cây scene.
2. Nút Bắt đầu gọi `begin_run()` → `starting_upgrade = true` → mở lựa chọn miễn phí.
3. `UpgradeMenu.choose()` phát `chosen(id)` → World kiểm tra lựa chọn, áp kỹ năng,
   tăng số nâng cấp, HP quái và nhịp spawn. Lựa chọn khởi đầu không tăng mốc 50.
4. `enemy.died` → `_enemy_killed()` → cộng kills, phát âm thanh, hồi HP hấp thụ,
   xếp lịch mở nâng cấp bằng deferred call nếu đạt mốc.
5. `_choose_upgrade()` xử lý mốc tiếp theo và gọi lại `_queue_upgrade()` để không
   bỏ mất thưởng khi nhiều mốc đã vượt qua trong cùng đợt.
6. Nhân vật hết máu → `_game_over()` dừng timer và giảm nhạc; reset reload scene.

`running` không đồng nghĩa với “đang mô phỏng”: ở menu, `SceneTree.paused` vẫn có
thể true khi `running` true. GameMenu, UpgradeMenu, Audio xử lý khi pause;
World/nhân vật/đạn/timer kế thừa chế độ pausable. Không đặt World thành ALWAYS.

GameMenu nhớ `upgrade_was_open`, ẩn menu nâng cấp khi pause; resume trả lại menu
đó và vẫn giữ pause. UpgradeMenu không xử lý input khi GameMenu đang mở.
Khóa 0,25 giây tránh nút đang nhấn chọn nhầm kỹ năng; test phải chờ khóa kết thúc.

`restart_game()` dùng `skip_start_once` static để bỏ màn hình start nhưng vẫn cho
chọn nâng cấp đầu trận. Về màn hình bắt đầu reload với flag ngược lại.
Mute là static của GameAudio nên giữ qua reload trong cùng phiên, không phải save lâu dài.

## Combat: các invariant quan trọng

- `spawn_enemy()` gán HP, player, arena và vị trí **trước** `add_child()`;
  tránh collider xuất hiện tạm tại gốc và đẩy nhân vật.
- Groups: `enemies` chỉ quái sống, `corpses` xác đang tan biến, `projectiles` đạn.
  Quái chết rời group mục tiêu và tắt collider trước khi kết thúc dissolve.
- Collision layers: world=1, enemies=2, player=4. Projectile sweep mask=3.
- Player chọn quái gần nhất theo XZ; damage chỉ áp khi viên đạn va chạm.
- Projectile bay theo +Z; model bullet-foam-tip xoay riêng để đầu model khớp hướng.
  Không thay ShapeCast bằng kiểm tra tại một điểm, dễ xuyên tường khi đạn nhanh.
- Mỗi viên chỉ gây damage một lần lên mỗi quái; ricochet ưu tiên trước pierce;
  không xuyên tường. Tầm bay vẫn được trừ sau khi đổi hướng.
- Multishot dùng timer có pause; âm bắn theo loạt, không theo từng viên phụ.
- Súng gắn arm-right bằng BoneAttachment3D tạo runtime; animation cầm súng được
  trộn vào bản sao clip. Không sửa animation/material dùng chung của model nguồn.
- `upgrades.gd` quản lý caps; luôn giữ đủ lựa chọn hợp lệ cho các mốc dài hạn.
  Hấp thụ HP được thực hiện trong World khi kill, không trong `Upgrades.apply()`.

## Map và camera

| Thành phần | Hiện tại |
| --- | --- |
| Vùng chiến đấu / collider | X ±20, Z ±30 (40×60) |
| Ground mesh và shape | 64×96 |
| Lưới A* | `Rect2i(-19, -29, 39, 59)` |
| Giới hạn camera mặt đất | `Rect2(-24, -36, 48, 72)` |
| Cổng | X = -16, -8, 0, 8, 16; Z = -27 |
| Camera | Trực giao, view size 26, offset (0,0,-8) |

Spawn theo thứ tự node con Spawners, không nhất thiết từ trái qua phải.
Camera clamp theo footprint bốn góc viewport trên mặt đất, có xử lý tỷ lệ màn hình.
Nếu đổi map: cập nhật cùng lúc ground, biên collider, A*, cổng, cảnh quan và camera.
Giữ cây/props ngoài sân; dịch vị trí thay vì kéo méo model cây khi mở rộng map.

## Các điểm dễ hiểu sai khi kiểm tra

- `show_start_menu = false` trước `add_child(world)` được một số test dùng để bỏ
  toàn bộ luồng start; nó **không** tự cấp nâng cấp đầu trận. Muốn test gameplay thực
  phải gọi `begin_run()` hoặc thao tác Bắt đầu. Xem `balance_smoke.gd` và `menu_smoke.gd`.
- Damage mặc định của projectile tạo trực tiếp có thể khác weapon; súng truyền
  damage vào projectile khi bắn. Không sửa kỳ vọng test bằng thay số hàng loạt.
- Trước lựa chọn khởi đầu Orc có base HP100; trong trận sau lựa chọn là HP120.
- Các mô tả “đã kiểm tra” trong README là lịch sử, không bảo đảm code mới đã được test.
