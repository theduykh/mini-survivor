# Kiểm tra có chọn lọc

Mục tiêu: đủ bằng chứng cho thay đổi, hạn chế token và thời gian. Không mặc định
chạy toàn bộ test hoặc tạo test mới cho mọi chỉnh sửa.

## Chọn kiểm tra nhỏ nhất phù hợp

| Thay đổi | Kiểm tra đầu tiên | Chỉ mở rộng khi cần |
| --- | --- | --- |
| Docs, comment, chữ hướng dẫn | Đọc diff, kiểm tra link/giá trị | Không chạy Godot nếu không đổi code/scene |
| HP, damage, mốc thưởng, spawn, kích thước map | `balance_smoke.gd` | `map_smoke.gd` nếu đổi camera/biên; `upgrades_smoke.gd` nếu đổi kỹ năng |
| Hiệu quả/nhiều loại kỹ năng | `upgrades_smoke.gd` | `projectile_smoke.gd` nếu đổi va chạm |
| Đạn, sweep, tường, range | `projectile_smoke.gd` | `upgrades_smoke.gd` nếu ảnh hưởng xuyên/nảy/nhiều viên |
| Start, pause, resume, reset | `menu_smoke.gd` | `balance_smoke.gd` nếu đổi thưởng khởi đầu |
| Input/gamepad/di chuyển analog | `controller_smoke.gd` | `menu_smoke.gd` nếu đổi input menu |
| Tốc độ game (x2) | `speed_smoke.gd` | `menu_smoke.gd` nếu ảnh hưởng pause |
| Camera/map | `map_smoke.gd` | Một ảnh render/chơi thử khi cần xác nhận bố cục |
| Hit/death/audio | `feedback_audio_smoke.gd` | Render/nghe thử phần đã đổi nếu cần |
| Auto aim/fire, melee, game over | `survivor_smoke.gd` | Test cụ thể của hệ thống liên quan |

Mặc định chọn **1 test**, thêm test khi có ảnh hưởng cụ thể. Chỉ chạy full suite
khi người dùng yêu cầu, thay đổi rộng qua nhiều hệ thống hoặc chuẩn bị bản phát hành.
Khi đã đạt, không lặp lại nếu không có sửa đổi mới liên quan hay lỗi chưa giải thích.
Nếu hành vi chủ ý thay đổi, cập nhật assertion tương ứng; không bỏ test hoặc làm yếu
assertion chỉ để đạt. Test mới nên kiểm tra hành vi có nguy cơ hồi quy thực tế.

## Chạy một test trên Windows / PowerShell

Chạy từ thư mục project. Đường dẫn dưới đây là executable hiện có trên máy này;
máy khác thay bằng Godot console phù hợp, không tự tải engine mới.

```powershell
$godotExe = 'D:\game-code\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$testName = 'balance_smoke'
New-Item -ItemType Directory -Force .godot | Out-Null
$logPath = ".godot/$testName.log"
& $godotExe --headless --path . --script "res://tests/$testName.gd" --quit-after 2400 *> $logPath
$testExit = $LASTEXITCODE
Write-Output "Exit: $testExit"
Select-String -Path $logPath -Pattern 'ALL PASSED|FAILED|FAIL:|SCRIPT ERROR|ERROR:'
```

Đạt khi **exit=0**, có dòng kết thúc `... TEST: ALL PASSED` của đúng test và không
có script/runtime error. `--quit-after` chỉ là giới hạn số frame, không thay thế
timeout theo thời gian thực. Exit=0 nhưng thiếu dòng kết thúc vẫn là chưa xác nhận
đạt (có thể đã bị giới hạn frame ngắt). Nếu cần, đặt timeout ở công cụ chạy lệnh.

Khi lỗi, chỉ đọc đoạn quanh lỗi đầu tiên hoặc `Get-Content $logPath -Tail 50`.
Không đổ toàn bộ log vào hội thoại; phân biệt parse error, lỗi assertion và môi trường.
Nếu thiếu import ở checkout mới, chạy import một lần:

```powershell
& $godotExe --headless --path . --editor --import *> .godot/import.log
```

Không xóa cache/reimport mỗi lần test. Không coi cảnh báo shutdown audio là bằng chứng
test đạt hoặc thất bại; kiểm tra nguyên nhân nếu nó mới xuất hiện. Test tự tạo world
nên giải phóng scene và chờ vài physics frame để audio dọn buffer trước khi thoát.

## Hình ảnh và kiểm tra thủ công

- Headless không xác nhận bố cục/độ đẹp, âm nghe thực tế hay controller phần cứng.
- UI/map đổi đáng kể: render hoặc chơi thử đúng màn hình đã đổi; thường 1–2 ảnh đủ.
- Lưu log/ảnh/script preview tạm trong `.godot/`, không sửa gameplay để chụp ảnh.
- Không mở cửa sổ render chỉ để kiểm tra thay đổi docs, công thức HP hoặc damage.
- Bàn giao ghi rõ test đã chạy và phần chưa kiểm tra; không nhắc lại tất cả dòng PASS.
