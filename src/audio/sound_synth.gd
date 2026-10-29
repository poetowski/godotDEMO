class_name SoundSynth
extends RefCounted
## Sounds made in code, like the models: short mono 16-bit clips built from
## noise, sines and envelopes, the same every time for the same variant.
## Footsteps on grass and in water, swimming strokes, a wind loop, birdsong and crickets.
## Placeholders until real recordings or a sound designer's work arrive.

const RATE := 22050


## A footstep: a soft low thump with a rustle on grass, a splash in water.
static func footstep(surface: StringName, variant: int) -> AudioStreamWAV:
	var rng := _rng(101 + variant + (50 if surface == &"water" else 0))
	var length := 0.2 if surface == &"water" else 0.12
	var samples := PackedFloat32Array()
	samples.resize(int(length * RATE))
	var low := 0.0
	var thump_pitch := rng.randf_range(70.0, 110.0)
	for k in samples.size():
		var t := float(k) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		if surface == &"water":
			# Bright, bubbling noise that swells briefly and fades.
			var bubble := 0.6 + 0.4 * sin(TAU * rng.randf_range(30.0, 60.0) * t)
			low = lerpf(low, noise, 0.55)
			samples[k] = (noise - low) * bubble * _envelope(t, 0.01, length) * 0.7
		else:
			low = lerpf(low, noise, 0.18)
			var rustle := low * _envelope(t, 0.004, length * 0.9) * 0.6
			var thump := sin(TAU * thump_pitch * t) * _envelope(t, 0.002, 0.05) * 0.5
			samples[k] = rustle + thump
	return _wav(samples, false)


## A swimming stroke: a burst of bubbles as the hand pulls through the
## water, over a soft, low wash. Many small bubbles, each a short tone
## gliding up as it rises, most early in the stroke and thinning out. Not
## `strong`: a few gentle bubbles from a paddling hand.
static func swim_stroke(variant: int, strong: bool) -> AudioStreamWAV:
	var rng := _rng(301 + variant + (0 if strong else 40))
	var length := 0.6 if strong else 0.4
	var samples := PackedFloat32Array()
	samples.resize(int(length * RATE))
	var bubbles: Array[Vector4] = []
	for k in rng.randi_range(10, 16) if strong else rng.randi_range(3, 5):
		# When (s, bunched early), pitch (Hz), how long (s), how loud.
		var start := pow(rng.randf(), 1.8) * length * 0.75
		bubbles.append(Vector4(start, rng.randf_range(260.0, 820.0), rng.randf_range(0.03, 0.07), rng.randf_range(0.12, 0.3)))
	var low := 0.0
	for k in samples.size():
		var t := float(k) / RATE
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.04)
		var wash := low * _envelope(t, 0.04, length) * (0.35 if strong else 0.2)
		var sound := wash
		for bubble in bubbles:
			var since := t - bubble.x
			if since > 0.0 and since < bubble.z:
				var pitch := bubble.y * (1.0 + 6.0 * since)
				sound += sin(TAU * pitch * since) * _envelope(since, 0.003, bubble.z) * bubble.w
		samples[k] = sound
	return _wav(samples, false)


## A wind loop of `seconds`: low rushing noise rising and falling slowly,
## its ends blended so it loops without a seam.
static func wind(seconds: float = 8.0) -> AudioStreamWAV:
	var rng := _rng(7)
	var count := int(seconds * RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low := 0.0
	var lower := 0.0
	for k in count:
		var t := float(k) / RATE
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.04)
		lower = lerpf(lower, low, 0.08)
		var gust := 0.55 + 0.3 * sin(TAU * t / seconds) + 0.15 * sin(TAU * 3.0 * t / seconds + 1.3)
		samples[k] = lower * gust * 6.0
	var blend := int(0.5 * RATE)
	for k in blend:
		var mix := float(k) / blend
		samples[k] = samples[k] * mix + samples[count - blend + k] * (1.0 - mix)
	return _wav(samples.slice(0, count - blend), true)


## A bird's call: two to four quick whistled notes sliding in pitch.
static func bird(variant: int) -> AudioStreamWAV:
	var rng := _rng(301 + variant)
	var notes := rng.randi_range(2, 4)
	var note_length := rng.randf_range(0.07, 0.13)
	var gap := rng.randf_range(0.03, 0.07)
	var samples := PackedFloat32Array()
	samples.resize(int(notes * (note_length + gap) * RATE))
	var phase := 0.0
	for n in notes:
		var start := rng.randf_range(2600.0, 4200.0)
		var finish := start * rng.randf_range(0.7, 1.35)
		var first := int(n * (note_length + gap) * RATE)
		for k in int(note_length * RATE):
			var t := float(k) / RATE
			var pitch := lerpf(start, finish, t / note_length)
			phase += TAU * pitch / RATE
			samples[first + k] = sin(phase) * _envelope(t, 0.01, note_length) * 0.35
	return _wav(samples, false)


## A cricket's chirp: a quick train of high pulses.
static func cricket(variant: int) -> AudioStreamWAV:
	var rng := _rng(401 + variant)
	var pitch := rng.randf_range(4200.0, 5200.0)
	var pulses := rng.randi_range(3, 5)
	var pulse := 0.018
	var samples := PackedFloat32Array()
	samples.resize(int(pulses * pulse * 2.0 * RATE))
	for p in pulses:
		var first := int(p * pulse * 2.0 * RATE)
		for k in int(pulse * RATE):
			var t := float(k) / RATE
			samples[first + k] = sin(TAU * pitch * t) * _envelope(t, 0.002, pulse) * 0.18
	return _wav(samples, false)


## Rises over `attack` seconds, then dies away by `length`.
static func _envelope(t: float, attack: float, length: float) -> float:
	if t < attack:
		return t / attack
	return pow(maxf(0.0, 1.0 - (t - attack) / maxf(length - attack, 0.0001)), 2.0)


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _wav(samples: PackedFloat32Array, looping: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for k in samples.size():
		data.encode_s16(k * 2, int(clampf(samples[k], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
