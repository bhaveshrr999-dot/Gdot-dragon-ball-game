class_name GameSound
extends Node

var voices: Array[AudioStreamPlayer] = []
var cursor: int = 0
var spatial_voices: Array[AudioStreamPlayer3D] = []
var spatial_cursor: int = 0
var streams: Dictionary = {}
var volume: float = 0.65

func _ready() -> void:
	for i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	for i in 6:
		var player := AudioStreamPlayer3D.new()
		player.unit_size = 8.0
		player.max_distance = 65.0
		player.panning_strength = 0.7
		add_child(player)
		spatial_voices.append(player)
	for name in ["hit", "blast", "beam", "transform", "menu", "dash", "explosion"]:
		streams[name] = load("res://assets/audio/" + name + ".wav")

func play(effect: String) -> void:
	if volume <= 0 or not streams.has(effect):
		return
	var player: AudioStreamPlayer = voices[cursor]
	cursor = (cursor + 1) % voices.size()
	player.stream = streams[effect]
	player.volume_db = linear_to_db(volume * 0.45)
	player.pitch_scale = randf_range(0.92, 1.08)
	player.play()

func play_at(effect: String, point: Vector3, pitch: float = 1.0) -> void:
	if volume <= 0 or not streams.has(effect): return
	var player := spatial_voices[spatial_cursor]
	spatial_cursor = (spatial_cursor + 1) % spatial_voices.size()
	player.global_position = point
	player.stream = streams[effect]
	player.volume_db = linear_to_db(volume * 0.65)
	player.pitch_scale = clampf(pitch, 0.65, 1.6)
	player.play()

func _exit_tree() -> void:
	for player in spatial_voices:
		player.stop()
		player.stream = null
	for player in voices:
		player.stop()
		player.stream = null
	streams.clear()
