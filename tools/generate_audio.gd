extends SceneTree
## Original procedural audio. Run manually to regenerate the shipped WAV files.
const RATE := 32000
const BPM := 140.0
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	call_deferred("run")

func save_audio(name: String, samples: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	var peak := 0.0
	var energy := 0.0
	for i in range(samples.size()):
		var value := clampf(samples[i], -0.95, 0.95)
		peak = maxf(peak, absf(value))
		energy += value * value
		bytes.encode_s16(i * 2, int(value * 32767.0))
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = RATE
	audio.data = bytes
	var error := audio.save_to_wav("res://assets/audio/" + name + ".wav")
	print(name, ": ", float(samples.size()) / RATE, "s, peak=", peak, " rms=", sqrt(energy / samples.size()), " save=", error)

func frequency(midi: int) -> float:
	return 440.0 * pow(2.0, (float(midi) - 69.0) / 12.0)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	rng.seed = 72419
	var shot := PackedFloat32Array()
	shot.resize(int(RATE * 0.24))
	for i in range(shot.size()):
		var t := float(i) / RATE
		var phase := TAU * (180.0 * t + 960.0 * 0.035 * (1.0 - exp(-t / 0.035)))
		var tone := sin(phase) * 0.55 + sin(phase * 1.99) * 0.12
		var noise := rng.randf_range(-1, 1) * 0.45 * exp(-t * 80.0)
		shot[i] = tanh((tone * exp(-t * 22.0) + noise) * 1.5) * minf(t * 1500, 1.0) * minf((0.24 - t) * 100, 1.0) * 0.8
	save_audio("blaster_shot", shot)
	var death := PackedFloat32Array()
	death.resize(int(RATE * 0.7))
	var low_noise := 0.0
	for i in range(death.size()):
		var t := float(i) / RATE
		low_noise = lerpf(low_noise, rng.randf_range(-1, 1), 0.08)
		var phase := TAU * (95.0 * t - 35.0 * t * t)
		var growl := sin(phase + sin(phase * 0.48) * 2.0) * 0.48 + sin(phase * 2.1) * 0.12 + low_noise * 0.65
		var envelope := minf(t * 60, 1.0) * pow(maxf(0.0, 1.0 - t / 0.7), 1.5)
		death[i] = tanh(growl * 1.7) * envelope * 0.75
	save_audio("orc_death", death)
	# Sixteen bars: dark minor arpeggios, pulsing bass, kick/snare and hats.
	var beat := 60.0 / BPM
	var duration := beat * 64
	var music := PackedFloat32Array()
	music.resize(int(round(duration * RATE)))
	var roots := [38, 34, 36, 37]
	var notes := [0, 7, 3, 12, 0, 10, 7, 1]
	var bass_phase := 0.0
	var arp_phase := 0.0
	var previous_noise := 0.0
	for i in range(music.size()):
		var t := float(i) / RATE
		var beats := t / beat
		var bar := int(beats / 4)
		var root_note: int = roots[int(bar / 4) % roots.size()]
		var beat_time := fmod(t, beat)
		var eighth_time := fmod(t, beat * 0.5)
		var sixteenth_time := fmod(t, beat * 0.25)
		var kick := sin(TAU * (48 * beat_time + 110 * 0.022 * (1 - exp(-beat_time / 0.022)))) * exp(-beat_time * 18) * 0.6
		var noise := rng.randf_range(-1, 1)
		var high_noise := (noise - previous_noise) * 0.5
		previous_noise = noise
		var snare := 0.0
		if int(beats) % 4 == 1 or int(beats) % 4 == 3:
			snare = (high_noise * 0.28 + sin(TAU * 185 * beat_time) * 0.17) * exp(-beat_time * 22)
		var hats := high_noise * exp(-eighth_time * 95) * (0.12 if int(beats * 2) % 2 == 1 else 0.07)
		var bass_note := root_note + (12 if int(beats * 2) % 8 == 6 else 0)
		bass_phase += TAU * frequency(bass_note) / RATE
		var bass := (sin(bass_phase) + sin(2 * bass_phase) * 0.3) * 0.23 * exp(-eighth_time * 9) * minf(eighth_time * 700, 1)
		var arp_note: int = root_note + 24 + notes[int(beats * 4) % notes.size()]
		arp_phase += TAU * frequency(arp_note) / RATE
		var arp := (sin(arp_phase) + sin(arp_phase * 2) * 0.25) * exp(-sixteenth_time * 25) * minf(sixteenth_time * 700, 1) * 0.085
		# Soft pad swells add tension without overwhelming combat sounds.
		var bar_time := fmod(t, beat * 4)
		var pad_envelope := sin(PI * bar_time / (beat * 4)) * 0.035
		var pad := (sin(TAU * frequency(root_note + 12) * t) + sin(TAU * frequency(root_note + 15) * t) + sin(TAU * frequency(root_note + 19) * t)) * pad_envelope
		var edge_fade := minf(1.0, minf(t / 0.004, (duration - t) / 0.004))
		music[i] = tanh((kick + snare + hats + bass + arp + pad) * 1.2) * 0.8 * edge_fade
	save_audio("survivor_loop", music)
	quit()
