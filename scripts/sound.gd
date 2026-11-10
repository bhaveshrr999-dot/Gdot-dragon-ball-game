class_name GameSound
extends Node

var voices: Array[AudioStreamPlayer] = []
var cursor: int = 0
var streams: Dictionary = {}
var volume: float = 0.65

func _ready() -> void:
	for i in 10:
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
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

func _exit_tree() -> void:
	for player in voices:
		player.stop()
		player.stream = null
	streams.clear()
