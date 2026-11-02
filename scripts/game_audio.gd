extends Node

@export_range(-40.0, 0.0) var music_volume_db: float = -13.0
@export_range(-40.0, 0.0) var shot_volume_db: float = -7.0
@export_range(-40.0, 0.0) var death_volume_db: float = -15.0
static var muted: bool = false
var music: AudioStreamPlayer
var shot: AudioStreamPlayer
var death: AudioStreamPlayer

func _ready() -> void:
	music = _make_player("Music", preload("res://assets/audio/survivor_loop.wav"), music_volume_db, 1)
	var loop := music.stream.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	music.stream = loop
	shot = _make_player("Shot", preload("res://assets/audio/blaster_shot.wav"), shot_volume_db, 2)
	death = _make_player("Death", preload("res://assets/audio/orc_death.wav"), death_volume_db, 4)
	music.play()
	music.stream_paused = muted

func _make_player(node_name: String, stream: AudioStream, volume: float, voices: int) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.name = node_name
	audio.stream = stream
	audio.volume_db = volume
	audio.max_polyphony = voices
	add_child(audio)
	return audio

func play_shot(_projectile: Node3D) -> void:
	if not muted:
		shot.play()

func play_death() -> void:
	if not muted:
		death.play()

func game_over() -> void:
	create_tween().tween_property(music, "volume_db", music_volume_db - 10.0, 0.6)

func toggle_mute() -> void:
	muted = not muted
	music.stream_paused = muted
	if muted:
		shot.stop()
		death.stop()

func _exit_tree() -> void:
	for audio in [music, shot, death]:
		if is_instance_valid(audio):
			audio.stop()
			audio.stream = null
