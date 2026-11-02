# Âm thanh Mini Survivor

Các file WAV này được tổng hợp riêng cho project bằng `tools/generate_audio.gd`,
không lấy bản ghi hoặc sample nhạc từ bên ngoài.

- `blaster_shot.wav`: tiếng blaster điện tử, 0,24 giây.
- `orc_death.wav`: tiếng gầm trầm và tan biến, 0,7 giây.
- `survivor_loop.wav`: nhạc điện tử 140 BPM, 16 ô nhịp, khoảng 27,43 giây,
  bass dồn, kick/snare/hi-hat và arpeggio giọng thứ. Tự lặp khi chơi.

Định dạng mono PCM 16-bit, 32 kHz. Âm lượng được cân riêng trên node Audio
trong world.tscn. M hoặc nút Back/View của Xbox bật/tắt toàn bộ âm thanh.
Game Over giảm nhạc; chơi lại khởi động một lượt nhạc mới.

Có thể thay các WAV hoặc đổi AudioStream trong game_audio.gd để dùng bộ âm thanh khác.
Chạy lại bộ tạo âm thanh bằng Godot:
`--headless --path . --script res://tools/generate_audio.gd`
