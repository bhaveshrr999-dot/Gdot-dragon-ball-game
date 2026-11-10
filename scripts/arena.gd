class_name BattleArena
extends Node3D

var breakables: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var palette: Color
var craters: Array[Node3D] = []

func generate(index: int) -> void:
	rng.seed = 781 + index
	palette = [Color("a87b53"), Color("d9d1b5"), Color("5dbd8a"), Color("502b32"), Color("f1f1f1"), Color("657181"), Color("615b8d")][index]
	Art.box(self, Vector3(0, -0.65, 0), Vector3(100, 1.25, 100), palette)
	var ring_color := Color(palette.lightened(0.25), 0.4)
	Art.ring(self, Vector3(0, 0.015, 0), 38, ring_color)
	if index == 1 or index == 4:
		Art.box(self, Vector3(0, -0.05, 0), Vector3(40, 0.2, 40), palette.lightened(0.12))
		for i in range(-4, 5):
			Art.box(self, Vector3(i * 5, 0.065, 0), Vector3(0.035, 0.015, 40), palette.darkened(0.2))
			Art.box(self, Vector3(0, 0.065, i * 5), Vector3(40, 0.015, 0.035), palette.darkened(0.2))
	if index == 4:
		for x in [-28, 28]:
			Art.box(self, Vector3(x, 5, -28), Vector3(2, 10, 2), Color("c9b37d"))
	else:
		for i in 60:
			var angle := rng.randf() * TAU
			var distance := rng.randf_range(12, 47)
			var pos := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
			var rock: MeshInstance3D
			if index == 5:
				var height := rng.randf_range(4, 17)
				rock = Art.box(self, pos + Vector3(0, height / 2, 0), Vector3(3.3, height, 3.3), palette.darkened(rng.randf() * 0.25))
				for y in int(height / 2):
					Art.box(rock, Vector3(0, y * 1.6 - height / 2 + 1, -1.66), Vector3(2.3, 0.45, 0.02), Color("94c3d8"))
			else:
				rock = Art.spike(self, pos + Vector3(0, 1.8, 0), rng.randf_range(3, 10), palette.darkened(rng.randf() * 0.3), Vector3(0, rng.randf() * 360, 0))
				rock.scale.x = rng.randf_range(0.7, 2.0)
			breakables.append(rock)
		if index == 2:
			for i in 14:
				var pos := Vector3(rng.randf_range(-38, 38), 0, rng.randf_range(-38, 38))
				if pos.length() < 10:
					continue
				Art.box(self, pos + Vector3(0, 2.6, 0), Vector3(0.3, 5, 0.3), Color("dad3ad"))
				Art.ball(self, pos + Vector3(0, 5.5, 0), 2.3, Color("57b7ce"))
		if index == 3:
			for i in 12:
				Art.box(self, Vector3(rng.randf_range(-36, 36), 0.02, rng.randf_range(-36, 36)), Vector3(1.2, 0.05, 15), Color("fa572e"))
	# Distant silhouettes keep the combat space readable.
	for i in 20:
		var a: float = i * TAU / 20
		Art.spike(self, Vector3(cos(a) * 65, 4, sin(a) * 65), rng.randf_range(16, 30), palette.darkened(0.4), Vector3(0, i * 37, 0))

func damage_environment(point: Vector3, radius: float) -> void:
	for rock in breakables.duplicate():
		if is_instance_valid(rock) and Vector2(rock.position.x - point.x, rock.position.z - point.z).length() < radius:
			breakables.erase(rock)
			var tween := create_tween()
			tween.tween_property(rock, "scale", Vector3.ZERO, 0.35)
			tween.tween_callback(rock.queue_free)
	var crater := Node3D.new()
	add_child(crater)
	crater.position = Vector3(point.x, 0.09, point.z)
	Art.ring(crater, Vector3.ZERO, minf(radius, 5), palette.darkened(0.6))
	craters.append(crater)
	if craters.size() > 24:
		craters.pop_front().queue_free()
