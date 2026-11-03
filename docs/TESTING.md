# Hướng dẫn kiểm thử có chọn lọc

Chỉ chạy kiểm thử khi sửa logic code. Không chạy toàn bộ test suite. Sửa docs/text thuần không chạy test.

## Chọn bài test theo phạm vi

| Thay đổi | Bài test ưu tiên |
| --- | --- |
| Wave, spawn, mốc quái, số lượng quái | `tests/wave_smoke.gd` |
| Cân bằng HP, sát thương, navigation, map | `tests/balance_smoke.gd` |
| Hiệu ứng & chỉ số các nâng cấp | `tests/upgrades_smoke.gd` |
| Đạn, va chạm, xuyên thấu, tầm bắn | `tests/projectile_smoke.gd` |
| Menu bắt đầu, pause, resume, reset | `tests/menu_smoke.gd` |
| Điều khiển tay cầm Xbox | `tests/controller_smoke.gd` |
| Tốc độ game 1x/2x | `tests/speed_smoke.gd` |
| Âm thanh & hiệu ứng trúng đòn/chết | `tests/feedback_audio_smoke.gd` |

## Lệnh chạy test trên Windows / PowerShell

Chạy từ thư mục gốc dự án:

```powershell
$godotExe = 'D:\game-code\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$testName = 'wave_smoke'
New-Item -ItemType Directory -Force .godot | Out-Null
$logPath = ".godot/$testName.log"
& $godotExe --headless --path . --script "res://tests/$testName.gd" --quit-after 2400 *> $logPath
$testExit = $LASTEXITCODE
Write-Output "Exit: $testExit"
Select-String -Path $logPath -Pattern 'ALL PASSED|FAILED|FAIL:|SCRIPT ERROR|ERROR:'
```

- **Đạt**: Exit code = 0, có dòng kết thúc `... TEST: ALL PASSED` và không có lỗi Script/Runtime Error.
- **Lỗi**: Chỉ đọc 20 dòng cuối hoặc thông báo lỗi đầu tiên bằng `Get-Content $logPath -Tail 20`.
