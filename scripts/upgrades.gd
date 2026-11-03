extends RefCounted
## Inspired by Archero; these values are tuned for this prototype.
const ALL := [
	{"id": "attack", "title": "Cường hóa", "icon": "ATK", "description": "+30% sát thương mỗi viên đạn.\nCó thể cộng dồn.", "limit": 0},
	{"id": "haste", "title": "Bắn nhanh", "icon": "SPD", "description": "+20% tốc độ bắn.\nTối đa 10 lần.", "limit": 10},
	{"id": "vitality", "title": "Sinh lực", "icon": "HP+", "description": "+25 máu tối đa và hồi 25 máu.\nCó thể cộng dồn.", "limit": 0},
	{"id": "front", "title": "Đạn đôi", "icon": "II", "description": "Thêm 1 viên đạn bắn thẳng.\nMỗi viên giữ nguyên sát thương. Tối đa 3 lần.", "limit": 3},
	{"id": "burst", "title": "Liên thanh", "icon": "2x", "description": "Mỗi lượt bắn thêm một loạt đạn\nsau 0,12 giây. Tối đa 3 lần.", "limit": 3},
	{"id": "diagonal", "title": "Đạn chéo", "icon": "W", "description": "Thêm 2 viên bắn chéo hai bên\nở góc 25 độ.", "limit": 1},
	{"id": "piercing", "title": "Đạn xuyên", "icon": ">>>", "description": "Đạn xuyên thêm 1 quái.\nTối đa 5 lần; không xuyên tường.", "limit": 5},
	{"id": "ricochet", "title": "Đạn nảy", "icon": "RICO", "description": "Đạn nảy thêm 1 lần sang quái\ntrong 8 đơn vị. Tối đa 5 lần.", "limit": 5},
	{"id": "critical", "title": "Chí mạng", "icon": "CRIT", "description": "+20 điểm % chí mạng x2 sát thương.\nTối đa 100% cơ hội chí mạng.", "limit": 5},
	{"id": "vampire", "title": "Hấp thụ", "icon": "+HP", "description": "Hồi 2 máu mỗi khi hạ quái.\nCó thể cộng dồn.", "limit": 0},
	{"id": "agility", "title": "Nhanh nhẹn", "icon": "MOVE", "description": "+15% tốc độ di chuyển.\nTối đa 3 lần.", "limit": 3},
]

static func offers(levels: Dictionary) -> Array:
	var available: Array = []
	for entry in ALL:
		if entry.id == "ricochet":
			continue # Tạm thời ẩn skill đạn nảy
		if entry.limit == 0 or levels.get(entry.id, 0) < entry.limit:
			available.append(entry)
	available.shuffle()
	return available.slice(0, 3)

static func apply(id: String, player: CharacterBody3D) -> void:
	var weapon = player._weapon
	match id:
		"attack": weapon.damage = int(ceil(weapon.damage * 1.3))
		"haste":
			weapon.shot_interval = maxf(0.05, weapon.shot_interval / 1.2)
			weapon._cooldown = minf(weapon._cooldown, weapon.shot_interval)
		"vitality":
			player.max_health += 25
			player.heal(25)
		"front": weapon.front_projectiles += 1
		"burst": weapon.burst_count += 1
		"diagonal": weapon.diagonal_shots = true
		"piercing": weapon.pierce_count += 1
		"ricochet": weapon.ricochet_count += 1
		"critical": weapon.critical_chance = minf(1.0, weapon.critical_chance + 0.2)
		"agility": player.speed *= 1.15
		# Vampire healing is applied by World on each kill.
