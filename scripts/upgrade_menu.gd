extends CanvasLayer
signal chosen(id: String)

var offers: Array = []
var active: bool = false
var cards: Array[Button] = []
var _root: Control
var _title: Label
var _summary: Label
var _row: BoxContainer
var _lock: float = 0.0
var _focused: int = 0
var _stick_direction: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.035, 0.93)
	_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	margin.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	_title = _label("CHỌN NÂNG CẤP", 34)
	column.add_child(_title)
	_summary = _label("", 18)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size.y = 48
	column.add_child(_summary)
	_row = BoxContainer.new()
	_row.add_theme_constant_override("separation", 16)
	column.add_child(_row)
	for i in range(3):
		var card := Button.new()
		card.custom_minimum_size = Vector2(285, 310)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_font_size_override("font_size", 19)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_color_override("font_color", Color(0.9, 0.91, 0.85))
		for state in ["normal", "disabled", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.16, 0.14) if state in ["normal", "disabled"] else Color(0.2, 0.26, 0.2)
			style.border_color = Color(0.7, 0.76, 0.44) if state in ["focus", "hover"] else Color(0.28, 0.36, 0.29)
			style.set_border_width_all(3 if state == "focus" else 1)
			style.set_corner_radius_all(12)
			style.content_margin_left = 18
			style.content_margin_right = 18
			style.content_margin_top = 22
			style.content_margin_bottom = 22
			card.add_theme_stylebox_override(state, style)
		card.pressed.connect(choose.bind(i))
		card.focus_entered.connect(_focus_changed.bind(i))
		_row.add_child(card)
		cards.append(card)
	var hint := _label("Chuột: chọn thẻ  ·  Phím 1 / 2 / 3\nXbox: cần trái / D-pad để chọn, A xác nhận\nM / View: bật, tắt âm thanh", 16)
	column.add_child(hint)
	_root.hide()

func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.83, 0.87, 0.78))
	return label

func show_choices(options: Array, milestone: int, levels: Dictionary, wave_num: int = 0) -> void:
	offers = options
	active = true
	_lock = 0.25
	_focused = 0
	_stick_direction = 0
	if wave_num > 0:
		_summary.text = "Hoàn thành Wave %d  ·  Đã hạ %d quái  ·  Chọn 1 trong 3" % [wave_num, milestone]
	elif milestone == 0:
		_summary.text = "Nâng cấp khởi đầu  ·  Chọn 1 trong 3 để bắt đầu trận đấu"
	else:
		_summary.text = "Đã hạ %d quái  ·  Chọn 1 trong 3  ·  Trận đấu đang tạm dừng" % milestone
	for i in range(cards.size()):
		var entry: Dictionary = offers[i]
		cards[i].text = "%d   •   %s\n\n%s\n\n%s\n\nĐã chọn: %d lần" % [i + 1, entry.icon, entry.title, entry.description, levels.get(entry.id, 0)]
		cards[i].disabled = true
	_root.show()

func _process(delta: float) -> void:
	if not active:
		return
	if get_parent().has_node("GameMenu") and not get_parent().get_node("GameMenu").mode.is_empty():
		return
	_row.vertical = get_viewport().get_visible_rect().size.x < 960
	if _lock > 0.0:
		_lock -= delta
		if _lock <= 0.0:
			for card in cards:
				card.disabled = false
			cards[0].grab_focus()

func _focus_changed(index: int) -> void:
	_focused = index

func _input(event: InputEvent) -> void:
	if not active:
		return
	if get_parent().has_node("GameMenu") and not get_parent().get_node("GameMenu").mode.is_empty():
		return
	if event.is_action_pressed("toggle_audio"):
		get_parent().get_node("Audio").toggle_mute()
		get_viewport().set_input_as_handled()
		return
	if _lock > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			choose(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		var direction := int(signf(event.axis_value)) if absf(event.axis_value) > 0.55 else 0
		if direction != 0 and direction != _stick_direction:
			cards[posmod(_focused + direction, 3)].grab_focus()
		_stick_direction = direction
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP]:
			cards[posmod(_focused - 1, 3)].grab_focus()
		elif event.button_index in [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN]:
			cards[posmod(_focused + 1, 3)].grab_focus()
		elif event.button_index == JOY_BUTTON_A:
			choose(_focused)
		get_viewport().set_input_as_handled()

func choose(index: int) -> void:
	if not active or _lock > 0.0 or index < 0 or index >= offers.size():
		return
	active = false
	_root.hide()
	chosen.emit(offers[index].id)
