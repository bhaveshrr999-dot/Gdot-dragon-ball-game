class_name TouchControls
extends Control

signal action_pressed(action)
signal action_released(action)
var movement := Vector2.ZERO
var fingers: Dictionary = {}
var stick_finger: int = -1
var stick_origin := Vector2(155, 556)
var stick_point := Vector2.ZERO
var edit_layout: bool = false
var input_enabled: bool = true
var actions := {"medium": Vector2(1197, 443), "guard": Vector2(1010, 507), "dash": Vector2(900, 578), "light": Vector2(1122, 514), "heavy": Vector2(1197, 581), "blast": Vector2(1092, 623), "special": Vector2(968, 654), "ultimate": Vector2(1170, 673), "transform": Vector2(850, 674), "charge": Vector2(780, 598), "up": Vector2(300, 540), "down": Vector2(300, 632)}
var titles := {"medium":"MEDIUM", "guard":"GUARD", "dash":"VANISH", "light":"PUNCH", "heavy":"KICK", "blast":"KI", "special":"SPECIAL", "ultimate":"ULT", "transform":"FORM", "charge":"CHARGE", "up":"↑", "down":"↓"}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or (not input_enabled and not edit_layout):
		return
	if event is InputEventScreenTouch:
		var point: Vector2 = event.position
		if event.pressed:
			if point.distance_to(stick_origin) < 108 and stick_finger < 0:
				stick_finger = event.index
				update_stick(point)
			else:
				for action in actions:
					if point.distance_to(actions[action]) < 40:
						fingers[event.index] = action
						if not edit_layout:
							action_pressed.emit(action)
						break
		else:
			if event.index == stick_finger:
				stick_finger = -1
				movement = Vector2.ZERO
			if fingers.has(event.index):
				if not edit_layout:
					action_released.emit(fingers[event.index])
				fingers.erase(event.index)
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == stick_finger:
			update_stick(event.position)
		elif edit_layout and fingers.has(event.index):
			actions[fingers[event.index]] = event.position.clamp(Vector2(35, 180), Vector2(1245, 685))
		queue_redraw()

func reset_input() -> void:
	for action in fingers.values():
		action_released.emit(action)
	fingers.clear()
	stick_finger = -1
	movement = Vector2.ZERO

func update_stick(point: Vector2) -> void:
	stick_point = (point - stick_origin).limit_length(66)
	movement = stick_point / 66
	if movement.length() < 0.12:
		movement = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	draw_circle(stick_origin, 90, Color(0.05, 0.1, 0.18, 0.4))
	draw_arc(stick_origin, 90, 0, TAU, 48, Color(0.6, 0.8, 1, 0.45), 2, true)
	draw_circle(stick_origin + stick_point if stick_finger >= 0 else stick_origin, 34, Color(0.65, 0.83, 1, 0.35))
	for action in actions:
		var center: Vector2 = actions[action]
		var pressed: bool = fingers.values().has(action)
		var tint := Color("ffd16b") if action in ["special", "ultimate", "transform"] else Color("a4d2ef")
		draw_circle(center, 33, Color(tint, 0.55) if pressed else Color(0.025, 0.06, 0.12, 0.72))
		draw_arc(center, 33, 0, TAU, 32, Color(tint, 0.7), 1.5, true)
		var text_size := ThemeDB.fallback_font.get_string_size(titles[action], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string(ThemeDB.fallback_font, center - Vector2(text_size.x / 2, -4), titles[action], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tint)
