extends CanvasLayer
## Always processes UI; the world, projectiles and timers stay pausable.
var mode: String = ""
var panel: Control
var title: Label
var subtitle: Label
var buttons: Array[Button] = []
var actions: Array[String] = []
var focused: int = 0
var stick: int = 0
var upgrade_was_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	panel = Control.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.03, 0.9)
	panel.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	title = label("", 38)
	column.add_child(title)
	subtitle = label("", 18)
	column.add_child(subtitle)
	for i in range(5):
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 54)
		button.add_theme_font_size_override("font_size", 21)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.17, 0.14) if state == "normal" else Color(0.22, 0.29, 0.2)
			style.border_color = Color(0.7, 0.76, 0.44)
			style.set_border_width_all(2 if state == "focus" else 0)
			style.set_corner_radius_all(10)
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(activate.bind(i))
		button.focus_entered.connect(func(): focused = i)
		column.add_child(button)
		buttons.append(button)
	column.add_child(label("↑ / ↓ hoặc cần trái / D-pad: chọn\nEnter / A: xác nhận · Esc / Start: tạm dừng\nWASD / cần trái: di chuyển · Tự ngắm và bắn", 16))
	panel.hide()

func label(text: String, size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color(0.87, 0.9, 0.8))
	return result

func open(next_mode: String) -> void:
	mode = next_mode
	if mode == "pause":
		upgrade_was_open = get_parent().get_node("UpgradeMenu").active
		get_parent().get_node("UpgradeMenu").hide()
	get_tree().paused = true
	get_parent().get_node("HUD").hide()
	title.text = "MINI SURVIVOR" if mode == "start" else "TẠM DỪNG"
	subtitle.text = "Chọn một nâng cấp ngay khi bắt đầu\nNhận thêm nâng cấp mỗi 50 quái\n" if mode == "start" else "Trận đấu đã tạm dừng\nTiến trình được giữ nguyên khi tiếp tục\n"
	actions.assign(["play", "sound", "quit"] if mode == "start" else ["resume", "restart", "home", "sound", "quit"])
	refresh_buttons()
	panel.show()
	focused = 0
	stick = 0
	buttons[0].grab_focus()

func refresh_buttons() -> void:
	var names := {"play": "Bắt đầu", "resume": "Tiếp tục", "restart": "Chơi lại", "home": "Về màn hình bắt đầu", "quit": "Thoát game", "sound": "Âm thanh: " + ("Tắt" if get_parent().get_node("Audio").muted else "Bật")}
	for i in range(buttons.size()):
		buttons[i].visible = i < actions.size()
		if i < actions.size(): buttons[i].text = names[actions[i]]

func resume() -> void:
	mode = ""
	panel.hide()
	get_parent().get_node("HUD").show()
	get_parent().get_node("UpgradeMenu").show()
	get_tree().paused = upgrade_was_open
	if upgrade_was_open:
		var upgrade = get_parent().get_node("UpgradeMenu")
		upgrade.cards[upgrade._focused].grab_focus()
	upgrade_was_open = false

func upgrade_opened() -> void:
	# A kill and a pause input can occur in the same frame.
	if mode == "pause":
		upgrade_was_open = true
		get_parent().get_node("UpgradeMenu").hide()

func activate(index: int) -> void:
	if mode.is_empty() or index >= actions.size(): return
	match actions[index]:
		"play":
			resume()
			get_parent().begin_run()
		"resume": resume()
		"restart": get_parent().restart_game()
		"home": get_parent().restart_game(true)
		"sound":
			get_parent().get_node("Audio").toggle_mute()
			refresh_buttons()
		"quit": get_tree().quit()

func _input(event: InputEvent) -> void:
	var pause_pressed: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if pause_pressed:
		if mode == "pause": resume()
		elif mode.is_empty(): open("pause")
		get_viewport().set_input_as_handled()
		return
	if mode.is_empty(): return
	if event.is_action_pressed("toggle_audio"):
		get_parent().get_node("Audio").toggle_mute()
		refresh_buttons()
	var direction := 0
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP, KEY_W]: direction = -1
		elif event.keycode in [KEY_DOWN, KEY_S]: direction = 1
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: activate(focused)
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_UP: direction = -1
		elif event.button_index == JOY_BUTTON_DPAD_DOWN: direction = 1
		elif event.button_index == JOY_BUTTON_A: activate(focused)
		elif event.button_index == JOY_BUTTON_B and mode == "pause": resume()
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		var next := int(signf(event.axis_value)) if absf(event.axis_value) > 0.55 else 0
		if next != stick: direction = next
		stick = next
	if direction != 0:
		focused = posmod(focused + direction, actions.size())
		buttons[focused].grab_focus()
	# Mouse events must reach buttons; keyboard/controller events are handled here.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
