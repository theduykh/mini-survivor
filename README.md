# Mini Survivor — Godot 4 / GDScript

Game 3D survivor cơ bản với nhân vật cầm súng, tự ngắm, tự bắn và Orc đuổi đánh.
Dùng model Kenney đã có trong project; renderer Compatibility.

## Dành cho AI agent và người phát triển

Bắt đầu từ [AGENTS.md](AGENTS.md), sau đó chỉ đọc phần liên quan trong
[kiến trúc dự án](docs/ARCHITECTURE.md) và [quy tắc kiểm thử tiết kiệm](docs/TESTING.md).
Không cần chạy toàn bộ kiểm thử cho mỗi chỉnh sửa; tài liệu kiểm thử có bảng chọn
test theo phạm vi thay đổi và lệnh chạy với log gọn.

## Chạy game

1. Mở `D:/game-code/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`.
2. Import `D:/game-code/mini-survivor/project.godot`, chọn Import & Edit.
3. Chờ import tài nguyên rồi nhấn **F5**, chọn **Bắt đầu** để vào trận.
4. Dùng **WASD / phím mũi tên** để di chuyển. Nhân vật tự quay về phía quái
   gần nhất trong tầm bắn và tự bắn, không cần chuột.
5. **R** bắt đầu lại toàn bộ lượt chơi, hồi đầy máu, xóa quái và đặt lại số hạ gục.
6. **F8** dừng game để quay lại editor.

Nếu dùng máy khác, cài Godot 4 Standard từ https://godotengine.org/download/windows/.
Không cần bản .NET.

## Luật chơi hiện tại

### Menu bắt đầu và tạm dừng

- Khi mở game: chọn **Bắt đầu**, **Âm thanh** hoặc **Thoát game**.
- **Esc** hoặc nút **Start/Menu** trên Xbox mở/đóng menu tạm dừng.
- Menu tạm dừng có **Tiếp tục**, **Chơi lại**, **Về màn hình bắt đầu**,
  **Âm thanh** và **Thoát game**. Chơi lại/về màn hình bắt đầu sẽ xóa tiến trình lượt hiện tại.
- Dùng chuột hoặc **↑/↓ + Enter**; Xbox dùng **cần trái/D-pad + A**,
  nút **B** quay lại trận từ menu tạm dừng.
- Tạm dừng giữ nguyên quái, đạn, máu, thời gian và nhịp spawn. Nhạc vẫn phát;
  có thể bật/tắt bằng nút trong menu hoặc **M / View**.
- Có thể mở menu tạm dừng trong lúc chọn nâng cấp. Khi tiếp tục, các lựa chọn
  được giữ nguyên và trận đấu chỉ chạy tiếp sau khi chọn nâng cấp.

Menu nằm trong `scripts/game_menu.gd`; kiểm thử bằng
`--headless --path . --script res://tests/menu_smoke.gd`.

### Tay cầm Xbox trên PC

Kết nối tay cầm với Windows qua USB hoặc kết nối không dây được tay cầm hỗ trợ,
chạy F5 và chọn cửa sổ game để chơi. Có thể cắm tay cầm khi game đang chạy.

- Cần trái: di chuyển analog; đẩy nhẹ đi chậm, đẩy hết đi nhanh.
- D-pad: di chuyển ở tốc độ tối đa.
- Nút Y: chơi lại toàn bộ lượt, tương đương phím R.
- Ngắm và bắn vẫn tự động, không cần cần phải hoặc cò RT.

HUD tự đổi hướng dẫn khi phát hiện tay cầm; bàn phím vẫn dùng được.
Vùng chết cần analog mặc định 0,2 để hạn chế trôi cần. Chỉnh **Controller Deadzone**
trên node World nếu cần. Khi đi chéo, tốc độ không vượt tốc độ tối đa.


| Đối tượng | Thuộc tính | Giá trị |
| --- | --- | --- |
| Nhân vật | HP | 100 |
| Súng | Sát thương cơ bản | 100 / phát |
| Súng | Nhịp bắn | 1 phát / giây |
| Súng | Tầm bắn | 28 đơn vị |
| Orc | HP cơ bản | 100, tăng 20 sau mỗi nâng cấp |
| Orc | Sát thương | 10 / lần đánh |
| Orc | Nhịp đánh | 1 lần / giây, có 0,25 giây chuẩn bị |
| Orc | Tốc độ | 2,2 đơn vị / giây |
| Spawn | Ngẫu nhiên dọc theo thanh rào chắn trên cùng (tối đa 500 quái) | Delay cơ bản 1 giây, giảm sau nâng cấp |

Nhân vật có 100 HP. Quái chỉ bắt đầu xuất hiện sau khi chọn nâng cấp khởi đầu.
HUD hiển thị HP, số hạ gục, số quái còn sống và thời gian sống sót.
Khi HP bằng 0, hiện GAME OVER: nhân vật ngừng bắn, quái ngừng đuổi/đánh,
cổng ngừng sinh quái. Nhấn R để bắt đầu lại.

Bia thử cũ không còn xuất hiện trong scene chính. Các file target.gd/target.tscn
được giữ lại để tham khảo hoặc dùng lại khi cần.

## Nâng cấp trong trận

Khi bắt đầu hoặc chơi lại, được chọn ngay **1 nâng cấp miễn phí** trước khi quái xuất hiện.
Thưởng tiếp theo tại tổng số hạ gục **50, 100, 150, 200, 250, 300, 350…**.
Nâng cấp khởi đầu không tiêu thụ mốc thưởng 50 quái.

Sau mỗi lần chọn nâng cấp (kể cả khởi đầu), delay spawn giảm **0,05 giây**:
1 → 0,95 → 0,90 → 0,85…; tối thiểu **0,05 giây**. Năm cổng luân phiên sinh từng quái.
HP quái cơ bản **100**, tăng **20 HP/nâng cấp**: sau lựa chọn đầu trận là 120 HP,
sau thưởng 50 quái là 140 HP. Quái mới dùng chỉ số hiện tại; quái sống được cộng
20 vào HP tối đa và HP hiện tại, giữ nguyên sát thương đã nhận; xác chết không hồi sinh.
Chơi lại đặt chỉ số về ban đầu rồi cho chọn nâng cấp khởi đầu mới.

Mỗi mốc tạm dừng chiến đấu, đạn và spawn; nhạc vẫn tiếp tục. Chọn **1 trong 3**
nâng cấp ngẫu nhiên bằng chuột, phím **1 / 2 / 3**, hoặc **cần trái / D-pad + A**
trên Xbox. Chọn xong trận đấu tiếp tục. R/Y chơi lại sẽ xóa toàn bộ nâng cấp.

| Nâng cấp | Hiệu quả mỗi lần chọn | Giới hạn |
| --- | --- | --- |
| Cường hóa | +30% sát thương hiện tại, làm tròn lên | Không giới hạn |
| Bắn nhanh | +20% tốc độ bắn hiện tại | 10 lần |
| Sinh lực | +25 HP tối đa và hồi 25 HP | Không giới hạn |
| Đạn đôi | Thêm 1 viên bắn thẳng phía trước | 3 lần |
| Liên thanh | Bắn thêm một loạt đạn sau 0,12 giây | 3 lần |
| Đạn chéo | Thêm 2 viên ở góc ±25° | 1 lần |
| Đạn xuyên | Xuyên thêm 1 quái, không xuyên tường | 5 lần |
| Đạn nảy | Tạm thời ẩn khỏi danh sách nâng cấp | Tạm ẩn |
| Chí mạng | +20 điểm phần trăm cơ hội gây sát thương gấp đôi | 5 lần, tối đa 100% |
| Hấp thụ | Hồi 2 HP mỗi khi hạ quái | Không giới hạn |
| Nhanh nhẹn | +15% tốc độ di chuyển hiện tại | 3 lần |

Các nâng cấp kết hợp được với nhau. Nâng cấp đã đạt giới hạn không xuất hiện lại.
Đạn nảy được ưu tiên trước đạn xuyên; mỗi viên chỉ gây sát thương một lần lên mỗi quái.
Các chỉ số trong bảng luật chơi là chỉ số khởi đầu, trước nâng cấp.

Lấy cảm hứng từ [các kỹ năng Archero](https://apps.apple.com/us/story/id1470165753);
thông số được đặt riêng cho project này. Chỉnh danh sách, mô tả và hiệu quả trong
`scripts/upgrades.gd`; giao diện nằm trong `scripts/upgrade_menu.gd`.
Kiểm thử bằng `--headless --path . --script res://tests/upgrades_smoke.gd`.

## Cơ chế chiến đấu

- Nhân vật chọn quái sống gần nhất theo khoảng cách trên mặt phẳng XZ trong tầm bắn.
- Không có quái thì không bắn; quái chết được loại khỏi danh sách mục tiêu ngay.
- Quái gần nhất có thể đang sau vật cản: súng vẫn ngắm nó, nhưng đạn dừng ở vật cản.
- Đạn dùng model `bullet-foam-tip.glb`, bay từ đầu nòng với tốc độ 18 đơn vị/giây.
  Sát thương chỉ xảy ra khi viên đạn chạm mục tiêu. Đạn bay thẳng theo hướng bắn
  ban đầu, không tự đuổi theo quái; quái đang di chuyển có thể né được.
- Mỗi bước bay dùng ShapeCast3D quét cả đoạn đường để tránh xuyên quái/tường
  khi đạn bay nhanh. Đạn biến mất khi trúng hoặc bay hết tầm 28 đơn vị.
- Quái dùng animation walk, attack-melee-right và die; thân nhân vật giữ dáng cầm súng
  trong khi chân vẫn phát animation đi bộ.
- Orc tìm đường trên sân phẳng bằng lưới A* trên mặt phẳng XZ, cập nhật
  mỗi 0,4 giây. Collider ngăn quái xuyên sàn, biên map, nhân vật và các quái khác.
- Đòn cận chiến kiểm tra lại khoảng cách và đường tới nhân vật sau thời gian chuẩn bị:
  chạy ra khỏi tầm đánh có thể né đòn, quái không đánh xuyên khối cản.
- Orc chết không chặn đạn/đường đi; model biến mất sau animation chết khoảng 1 giây.

Nhịp spawn hiện lớn hơn khả năng hạ quái của một khẩu súng. Đây là đúng các thông số
đã yêu cầu; di chuyển để kéo quái và né các đòn đánh.

## Các file chính và chỗ chỉnh thông số

| File / node | Vai trò / thuộc tính trong Inspector |
| --- | --- |
| `scenes/world.tscn` | Sàn, vật cản, camera, HUD, Enemies, Spawners |
| `scripts/world.gd` | Lượt chơi, HUD, điểm hạ gục, tìm đường, Game Over và chơi lại |
| `scenes/player.tscn` → Player | Max Health, Speed, model nhân vật, animation và điểm cầm súng |
| `scripts/player.gd` | Di chuyển, máu, chọn quái gần nhất và xoay người |
| `scenes/weapon.tscn` → Weapon | Gun Model, Shot Interval = 1, Damage = 100, Shot Range |
| `scripts/weapon.gd` | Tự bắn, giới hạn nhịp, tạo đạn và giật súng |
| `scenes/projectile.tscn` | Model bullet-foam-tip, kích thước đạn và hình cầu quét va chạm |
| `scripts/projectile.gd` | Bay thẳng, quét va chạm, sát thương khi trúng và tự xóa |
| `scenes/enemy.tscn` → Orc | Max Health = 100, Damage = 10, Speed, Attack Interval / Range / Windup |
| `scripts/enemy.gd` | Đi tới nhân vật, đánh, nhận sát thương và chết |
| `scenes/world.tscn` → World | Spawn Interval = 1; một timer chung luân phiên các cổng |
| `scenes/spawner.tscn` → OrcGate | Điểm SpawnPoint trên mặt đất |
| `scripts/spawner.gd` | Tạo 1 Orc khi timer chung chọn đến cổng |

Muốn đổi vị trí cổng: mở world.tscn, chỉnh Transform của các node dưới Spawners.
SpawnPoint là vị trí local phía trước cổng, quay theo hướng của cổng.
Camera hướng về phía bắc, có giới hạn theo toàn bộ khung nhìn mặt đất.
Sân chơi đã bỏ các khối cản; lưới tìm đường phủ sàn phẳng X từ -19 đến 19, Z từ -29 đến 29.

## Đặt model Kenney ở đâu?

Giữ model trong `assets/models/kenney/`, mỗi bộ asset một thư mục riêng:

```text
assets/models/kenney/
  mini-characters/Models/GLB format/character-male-c.glb
  kenney_blaster/Models/GLB format/blaster-a.glb
  mini-dungeon/Models/GLB format/character-orc.glb
  mini-dungeon/Models/GLB format/wall-opening.glb
```

Ưu tiên GLB/glTF. Copy cả thư mục model, texture và file .bin đi kèm nếu có,
giữ nguyên đường dẫn tương đối và giữ license gốc. Godot tự import khi quay lại
editor. Không đặt tài nguyên gốc trong `.godot/` vì đây là thư mục cache.

### Đổi model nhân vật

Mở player.tscn, chọn Player, kéo GLB vào **Character Model**. Chỉnh **Model Scale**,
**Model Y Offset**, **Model Yaw Degrees** nếu cần. Giữ CharacterBody3D và collider;
chỉnh kích thước collider nếu model mới cao/thấp khác nhiều.

Trong nhóm Locomotion Animation, Idle Animation và Move Animation mặc định là
`idle` và `walk`. Đổi Move Animation sang `sprint` nếu muốn dáng chạy. Move Animation
Speed điều chỉnh nhịp chân, còn Speed điều chỉnh tốc độ di chuyển.

### Đổi súng và chỉnh cách cầm

Mở weapon.tscn, chọn Weapon, kéo GLB súng khác vào **Gun Model**.
Chỉnh **Gun Scale**, **Gun Offset**, **Gun Rotation Degrees** cho vừa tay;
**Muzzle Offset** phải trùng đầu nòng. Thay model không tự đổi vị trí Muzzle.

**Projectile Speed** trên Weapon điều chỉnh tốc độ bay, mặc định 18 đơn vị/giây.
Đổi hình/kích thước viên đạn trong projectile.tscn → Model. Asset gốc dài theo
trục +Y nên model được xoay 90° quanh X để đầu đạn hướng theo +Z của projectile.
Scale mặc định 6 giúp nhìn rõ viên đạn với camera hiện tại; chỉnh SphereShape3D
trong Sweep nếu thay đổi đáng kể độ dày viên đạn. Nhịp bắn vẫn 1 phát/giây,
sát thương cơ bản 100; Shot Range quyết định quãng đường bay tối đa.

Súng được gắn lúc chạy theo cấu trúc:

```text
Skeleton3D
  RightHandAttachment (BoneAttachment3D, bone arm-right)
    GunGrip
      Weapon
        model súng
        Muzzle (Marker3D)
```

Model hiện chỉ có xương cánh tay, nên Hand Offset đưa điểm cầm từ vai ra bàn tay.
Hand Bone, Hand Offset và Hand Rotation Degrees nằm trên Player → Weapon.
Script chép track tay phải từ holding-right vào bản sao idle/walk; model và clip
nguồn không bị sửa. Các node sinh lúc chạy có thể xem trong Scene → Remote.

## Kiểm tra

Đã kiểm tra bằng Godot 4.7.2: năm cổng spawn đúng nhịp, không dịch chuyển nhân vật
khi spawn, tự chọn quái gần nhất, tự bắn không cần chuột, 100 damage/phát, đúng
1 giây giữa hai phát, hạ Orc theo HP và cấp nâng hiện tại và đổi mục tiêu; quái vòng qua vật cản,
đánh 10 damage theo nhịp, né được đòn khi chạy ra xa; chết và R khởi động lại.
Có render ảnh để kiểm tra model Orc, cổng spawn, súng và HUD.
Đạn bay cũng đã được kiểm tra: hướng đầu model, di chuyển trước khi gây sát thương,
sát thương đúng một lần, không xuyên tường mỏng ở tốc độ cao, không trúng người bắn
và tự xóa khi hết tầm. Đã render ảnh viên bullet-foam-tip trong lúc bay.

Chạy lại bộ kiểm tra tích hợp trong PowerShell từ thư mục project:

```powershell
& 'D:\game-code\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/survivor_smoke.gd
& 'D:\game-code\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/projectile_smoke.gd
```

## Tài liệu

- https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html
- https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html
- https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
- https://kenney.nl/assets/mini-characters
- https://kenney.nl/assets/mini-dungeon

## Map rừng và di tích

`scenes/arena_map.tscn` là scene trang trí có thể mở và chỉnh từng model trong editor.
Nó kết hợp mini-forest (cây, bụi cây, nền cỏ, đá, lều) và mini-dungeon (lát đá,
tường viền, cột và rương). Phần sân 40×60 ở giữa trống để chiến đấu. Cây và đồ
trang trí lớn đặt ngoài sân; không thêm collider cản đường bên trong sân.

Năm cổng nằm ở X = -16, -8, 0, 8, 16 và Z = -27, hướng vào sân.
Map có nền mở rộng 64×96 và vùng cảnh quan xung quanh để khung nhìn không lộ nền trống.

Trên node World:
- **Camera Map Bounds**: giới hạn phần mặt đất được nhìn thấy, mặc định X từ -24 đến 24, Z từ -36 đến 36.
- **Camera View Size**: độ rộng khung nhìn theo thiết lập camera trực giao, mặc định 26.
- **Camera Offset**: độ lệch theo nhân vật, mặc định (0, 0, -8).

Camera dừng theo biên khi nhân vật sát cạnh. Giới hạn tính từ cả bốn góc viewport,
được áp dụng sau bước làm mượt và điều chỉnh zoom nếu cửa sổ quá rộng/hẹp.
Đã kiểm tra các góc/cạnh map ở 16:9, cửa sổ dọc và ultrawide.
Chạy kiểm tra bằng `--headless --path . --script res://tests/map_smoke.gd`.

Nền chính hiện dùng model patch-dirt với màu nâu đất dịu. Script arena_palette.gd áp màu cục bộ cho cảnh: nền đất nâu, đá xám ấm, cây xanh trầm; không sửa asset gốc. Có thể chỉnh Dirt Tint / Stone Tint / Foliage Tint trên ArenaMap trong Inspector. Ánh sáng mặt trời và ánh sáng môi trường đã giảm để hạn chế chói.


## Hiệu ứng chiến đấu và âm thanh

- Orc trúng đạn: thân giật nhẹ và nháy cam ngắn trong 0,18 giây.
- Orc chết: phát animation chết, model rã dần thành các mảnh trong khoảng 0,8 giây
  rồi được xóa. Quái bị loại khỏi mục tiêu và tắt va chạm ngay khi HP về 0.
- Có tiếng blaster cho mỗi phát bắn và tiếng gầm trầm khi Orc chết.
- Nhạc nền điện tử gốc 140 BPM, 16 ô nhịp (~27,43 giây), tự lặp. Nhạc hạ âm lượng
  khi Game Over và bắt đầu lại khi chơi lượt mới.
- **M** hoặc **View/Back** trên Xbox bật/tắt toàn bộ âm thanh; trạng thái được giữ
  khi nhấn R/Y chơi lại trong cùng phiên chạy.

Chỉnh âm lượng riêng tại `world.tscn → Audio`: Music Volume Db, Shot Volume Db,
Death Volume Db. Giá trị càng âm thì càng nhỏ. Âm thanh WAV ở `assets/audio/`,
được tổng hợp riêng bằng `tools/generate_audio.gd` (không dùng sample bên ngoài).

Hiệu ứng nằm trong `scripts/enemy_feedback.gd` và `shaders/enemy_damage.gdshader`.
Mỗi Orc có material hiệu ứng riêng nên trúng một quái không làm các quái khác nháy.
Chỉnh Flash Duration / Dissolve Duration tại `enemy.tscn → Feedback`.

Đã kiểm tra các sự kiện âm thanh, nhạc lặp, mute/unmute, hạ nhạc khi chết,
hiệu ứng độc lập giữa các quái và dọn xác sau tan biến. Đã render hit/dissolve
bằng renderer thật. Bộ kiểm tra: `tests/feedback_audio_smoke.gd`.

