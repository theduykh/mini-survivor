# Kiến trúc hệ thống

## Bản đồ file

| Thành phần | File chính | Chức năng |
| --- | --- | --- |
| Vòng chơi & Wave | `scripts/world.gd`, `scenes/world.tscn` | Quản lý wave, spawn timer, kill counter, camera, A*, HUD, pause/reset |
| Nhân vật | `scripts/player.gd`, `scenes/player.tscn` | Di chuyển, máu, tự tìm mục tiêu gần nhất và xoay súng |
| Vũ khí | `scripts/weapon.gd`, `scenes/weapon.tscn` | Nhịp bắn, đạn đôi/chéo/liên thanh, chí mạng, tạo đạn |
| Đạn | `scripts/projectile.gd`, `scenes/projectile.tscn` | ShapeCast3D quét va chạm, bay thẳng, xuyên thấu, tầm bắn |
| Quái vật (Orc) | `scripts/enemy.gd`, `scenes/enemy.tscn` | Đuổi theo A*, cận chiến có windup, nhận sát thương, chết |
| Cổng sinh quái | `scripts/spawner.gd`, `scenes/spawner.tscn` | Vị trí spawn dọc cạnh trên của map |
| Nâng cấp | `scripts/upgrades.gd` | Danh mục kỹ năng, giới hạn cấp, chọn ngẫu nhiên 3 thẻ, áp hiệu quả |
| Menu nâng cấp | `scripts/upgrade_menu.gd` | UI 3 thẻ chọn nâng cấp, hỗ trợ phím 1/2/3 và Xbox |
| Menu chính / Pause | `scripts/game_menu.gd` | Start, pause, resume, restart, home, mute âm thanh |
| Bản đồ | `scenes/arena_map.tscn`, `scripts/arena_palette.gd` | Mô hình trang trí, palette màu môi trường |
| Âm thanh | `scripts/game_audio.gd`, `assets/audio/` | Nhạc nền, tiếng bắn, tiếng quái chết, mute |

## Luồng vận hành vòng chơi (Game Loop)

1. **Khởi động**: Khi vào game, hiển thị `GameMenu` ở chế độ Start (cây scene tạm dừng).
2. **Nâng cấp khởi đầu**: Nhấn Bắt đầu → mở `UpgradeMenu` cho chọn 1 trong 3 nâng cấp miễn phí.
3. **Bắt đầu Wave 1**: Sau khi chọn nâng cấp đầu trận, game tự động khởi chạy Wave 1 (20 quái, 100 HP, spawn trong 10 giây).
4. **Cơ chế sinh quái trong Wave**:
   - Spawner chia đều số quái của wave trong 10 giây (`interval = 10.0 / wave_total_enemies`).
   - Giới hạn map: Tối đa 300 quái sống đồng thời. Khi đạt 300, spawner dừng và đợi người chơi tiêu diệt bớt quái mới tiếp tục sinh.
   - Khi đã sinh đủ số quái của wave, spawner dừng hẳn.
5. **Hoàn thành Wave & Level Up**:
   - Khi người chơi tiêu diệt toàn bộ quái của wave (`kills >= next_upgrade_kills`), trận đấu tạm dừng và mở `UpgradeMenu`.
   - Kết thúc wave, thời gian delay spawn quái được reset lại.
6. **Chuyển Wave tiếp theo**:
   - Chọn xong nâng cấp, game tự động unpause và bắt đầu wave tiếp theo.
   - Số quái wave mới = quái wave trước + 20% (làm tròn số nguyên).
   - HP quái mới = `100 + 20 * (wave - 1)`.
7. **Game Over & Chơi lại**: Khi nhân vật hết máu, dừng spawner, nhạc hạ âm lượng. Nhấn R / phím Y để restart.

## Thông số kỹ thuật cốt lõi

- **Bản đồ**: Sân 40×120 (X ±20, Z ±60); Ground 64×192; A* Grid `Rect2i(-19, -59, 39, 119)`.
- **Camera**: Trực giao, view size 26.0, offset (0, 0, -8), giới hạn map `Rect2(-24, -66, 48, 132)`.
- **Collision Layers**: World = 1, Enemies = 2, Player = 4. Projectile sweep mask = 3.
- **Groups**: `enemies` (quái sống), `corpses` (xác đang tan biến), `projectiles` (đạn đang bay).
- **Spawn Gates**: 5 cổng tại Z = -27, X từ -18 đến 18; luân phiên sinh quái.
