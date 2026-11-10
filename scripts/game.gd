extends Node3D

const GOLD := Color("ffd074")
const INK := Color("0c1528")
var player: Fighter
var enemy: Fighter
var arena: BattleArena
var camera: Camera3D
var world: Node3D
var sun: DirectionalLight3D
var layer: CanvasLayer
var menu: Control
var hud: Control
var overlay: Control
var touch: TouchControls
var sound: GameSound
var hp_player: ProgressBar
var hp_enemy: ProgressBar
var ki_player: ProgressBar
var ki_enemy: ProgressBar
var timer_label: Label
var message_label: Label
var combo_label: Label
var form_label: Label
var form_effect_label: Label
var rival_form_label: Label
var preview_stats: Label
var stamina_player: ProgressBar
var hp_trail_player: ProgressBar
var hp_trail_enemy: ProgressBar
var cost_form: int = -1
var warrior_select: OptionButton
var form_select: OptionButton
var arena_select: OptionButton
var mode_select: OptionButton
var difficulty_select: OptionButton
var battle_form: OptionButton
var battle_attack: OptionButton
var projectiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var held: Dictionary = {}
var running: bool = false
var paused: bool = false
var selector_open: bool = false
var story_line: int = 0
var story_lines: Array = []
var training_defense: bool = false
var story_finished: bool = false
var dialogue_active: bool = false
var mode: int = 0
var difficulty: int = 1
var wave: int = 1
var time_left: float = 180
var elapsed: float = 0
var ai_clock: float = 0
var message_time: float = 0
var shake: float = 0
var clash_time: float = 0
var clash_power: float = 0
var clash_attack: AttackDefinition
var clash_enemy_attack: AttackDefinition
var clash_visual: Node3D
var menu_orbit: float = 0
var input_buffer: Array[Dictionary] = []
var settings: Dictionary = {"volume": 0.65, "quality": 1, "touch": true}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	load_settings()
	get_viewport().scaling_3d_scale = [0.65, 0.85, 1.0][int(settings.quality)]
	sound = GameSound.new()
	add_child(sound)
	sound.volume = settings.volume
	world = Node3D.new()
	add_child(world)
	camera = Camera3D.new()
	camera.fov = 54
	camera.far = 220
	add_child(camera)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -30, 0)
	sun.light_color = Color("ffe3bd")
	sun.light_energy = 0.95
	sun.shadow_enabled = settings.quality > 0
	add_child(sun)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("101f3c")
	sky_material.sky_horizon_color = Color("7795b0")
	sky_material.ground_bottom_color = Color("16213a")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9d9f3")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	layer = CanvasLayer.new()
	add_child(layer)
	setup_theme()
	build_menu()
	build_hud()
	show_menu()

func setup_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 18
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("13233a") if state == "normal" else Color("29435b")
		style.border_color = GOLD if state != "normal" else Color("36516a")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		theme.set_stylebox(state, "Button", style)
		theme.set_stylebox(state, "OptionButton", style)
	var root := Control.new()
	root.theme = theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	menu = Control.new()
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(hud)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

func label(parent: Node, value: String, pos: Vector2, size: int = 18, tint: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = value
	node.position = pos
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", tint)
	parent.add_child(node)
	return node

func button(parent: Node, title: String, pos: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var node := Button.new()
	node.text = title
	node.position = pos
	node.size = dimensions
	node.pressed.connect(callback)
	node.mouse_entered.connect(func(): animate_button(node, Color(1.18, 1.18, 1.18)))
	node.mouse_exited.connect(func(): animate_button(node, Color.WHITE))
	node.button_down.connect(func(): animate_button(node, Color(0.7, 0.85, 1.0)))
	node.button_up.connect(func(): animate_button(node, Color.WHITE))
	parent.add_child(node)
	return node

func animate_button(node: Control, tint: Color) -> void:
	if node.has_meta("feedback") and node.get_meta("feedback").is_valid():
		node.get_meta("feedback").kill()
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", tint, 0.12)
	node.set_meta("feedback", tween)

func reveal(node: Control) -> void:
	node.modulate.a = 0
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)

func panel(parent: Node, pos: Vector2, dimensions: Vector2, color: Color) -> ColorRect:
	if parent == overlay:
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var node := ColorRect.new()
	node.color = color
	node.position = pos
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func option(parent: Node, values: Array, pos: Vector2, width: float = 245) -> OptionButton:
	var node := OptionButton.new()
	node.position = pos
	node.size = Vector2(width, 42)
	for value in values:
		node.add_item(str(value))
	parent.add_child(node)
	node.get_popup().about_to_popup.connect(func(): set_selector_open(true))
	node.get_popup().popup_hide.connect(func(): set_selector_open(false))
	node.get_popup().add_theme_constant_override("v_separation", 14)
	return node

func set_selector_open(value: bool) -> void:
	selector_open = value
	if not running:
		return
	touch.reset_input()
	held.clear()
	input_buffer.clear()
	for fighter in [player, enemy]:
		fighter.set_combat_paused(paused or value)
	touch.input_enabled = not paused and not value

func build_menu() -> void:
	panel(menu, Vector2.ZERO, Vector2(630, 720), Color(0.025, 0.045, 0.085, 0.94))
	panel(menu, Vector2(42, 54), Vector2(48, 3), GOLD)
	label(menu, "FAN-MADE  /  EARLY ACCESS 0.3", Vector2(103, 40), 15, GOLD)
	label(menu, "DRAGON BALL", Vector2(40, 75), 51)
	label(menu, "ULTIMATE\nWARRIORS", Vector2(39, 129), 58, GOLD)
	label(menu, "BREAK YOUR LIMITS", Vector2(44, 278), 19, Color("a6c5dc"))
	label(menu, "FIGHTER", Vector2(44, 324), 13, GOLD)
	label(menu, "STARTING FORM", Vector2(322, 324), 13, GOLD)
	warrior_select = option(menu, ["SON GOKU", "VEGETA"], Vector2(44, 350))
	form_select = option(menu, Roster.forms(0), Vector2(322, 350), 265)
	warrior_select.item_selected.connect(func(index: int):
		form_select.clear()
		for form in Roster.forms(index):
			form_select.add_item(form)
		player.warrior = index
		player.form_index = 0
		player.build_model()
		update_preview())
	label(menu, "BATTLE MODE", Vector2(44, 408), 13, GOLD)
	label(menu, "ARENA", Vector2(322, 408), 13, GOLD)
	mode_select = option(menu, Roster.MODES, Vector2(44, 433))
	arena_select = option(menu, Roster.ARENAS, Vector2(322, 433), 265)
	difficulty_select = option(menu, Roster.DIFFICULTIES, Vector2(44, 495), 245)
	difficulty_select.select(1)
	button(menu, "SETTINGS / CONTROLS", Vector2(322, 495), Vector2(265, 44), show_settings)
	var start := button(menu, "ENTER THE ARENA     →", Vector2(44, 558), Vector2(543, 58), start_match)
	start.add_theme_color_override("font_color", GOLD)
	label(menu, "Original skinned characters · development art", Vector2(44, 635), 13, Color("9bb0c4"))
	label(menu, "Offline play  •  Touch + keyboard  •  No account required", Vector2(44, 660), 13, Color("9bb0c4"))
	panel(menu, Vector2(670, 515), Vector2(565, 178), Color(0.025, 0.045, 0.085, 0.88))
	preview_stats = label(menu, "", Vector2(694, 535), 18, GOLD)
	form_select.item_selected.connect(func(_index: int): update_preview())

func update_preview() -> void:
	if not is_instance_valid(player): return
	player.form_index = form_select.selected
	player.refresh_form()
	var form := Roster.form(player.warrior, player.form_index)
	preview_stats.text = "%s · %s\n%s\nPOWER ×%.2f   SPEED ×%.2f   KI DRAIN %.1f/s\n%s" % ["GOKU" if player.warrior == 0 else "VEGETA", form.name, form.description, form.power, form.speed, form.drain, form.continuity]
	preview_stats.add_theme_color_override("font_color", form.aura)
	reveal(preview_stats)

func bar(parent: Node, pos: Vector2, width: float, tint: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.position = pos
	node.size = Vector2(width, 16)
	node.show_percentage = false
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04,0.07,0.12,0.35)
	node.add_theme_stylebox_override("fill", fill)
	node.add_theme_stylebox_override("background", bg)
	parent.add_child(node)
	return node

func build_hud() -> void:
	panel(hud, Vector2.ZERO, Vector2(1280, 155), Color(0.025, 0.04, 0.075, 0.78))
	label(hud, "PLAYER 01", Vector2(30, 14), 16, GOLD)
	label(hud, "RIVAL", Vector2(926, 14), 16, GOLD)
	hp_trail_player = bar(hud, Vector2(30, 45), 390, Color("ffd074"))
	hp_trail_enemy = bar(hud, Vector2(860, 45), 390, Color("ffd074"))
	hp_player = bar(hud, Vector2(30, 45), 390, Color("62d7ab"))
	hp_enemy = bar(hud, Vector2(860, 45), 390, Color("f28b75"))
	ki_player = bar(hud, Vector2(30, 70), 330, Color("69bfff"))
	ki_enemy = bar(hud, Vector2(920, 70), 330, Color("69bfff"))
	stamina_player = bar(hud, Vector2(30, 91), 230, Color("dfca7e"))
	stamina_player.size.y = 4
	form_effect_label = label(hud, "", Vector2(30, 159), 14, Color("b7d8ec"))
	rival_form_label = label(hud, "", Vector2(860, 159), 14, Color("f28b75"))
	timer_label = label(hud, "180", Vector2(599, 18), 37)
	form_label = label(hud, "", Vector2(30, 107), 13, GOLD)
	combo_label = label(hud, "", Vector2(30, 185), 28, GOLD)
	message_label = label(hud, "", Vector2(345, 205), 26, GOLD)
	button(hud, "RESET", Vector2(990, 102), Vector2(100, 42), training_reset)
	button(hud, "DUMMY", Vector2(1100, 102), Vector2(110, 42), func():
		if mode in [1, 9]:
			training_defense = not training_defense
			notify("Dummy: guard" if training_defense else "Dummy: idle", 1.5))
	button(hud, "Ⅱ", Vector2(1228, 101), Vector2(44, 42), toggle_pause)
	battle_form = option(hud, [], Vector2(390, 102), 225)
	battle_attack = option(hud, [], Vector2(635, 102), 325)
	panel(hud, Vector2(305, 678), Vector2(645, 42), Color(0.02, 0.04, 0.08, 0.8))
	label(hud, "WASD move · J punch · K kick · L blast · B guard · C charge · Space vanish", Vector2(315, 680), 12, Color("bdcede"))
	label(hud, "E special · R ultimate · T form · Q/F fly · G grapple · Enter clash · Esc pause", Vector2(315, 698), 12, Color("bdcede"))
	touch = TouchControls.new()
	hud.add_child(touch)
	var layout := ConfigFile.new()
	if layout.load("user://settings.cfg") == OK:
		for action in touch.actions:
			touch.actions[action] = layout.get_value("layout", action, touch.actions[action])
	touch.action_pressed.connect(press_action)
	touch.action_released.connect(release_action)

func clear_world() -> void:
	dialogue_active = false
	selector_open = false
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	projectiles.clear()
	effects.clear()
	clash_time = 0
	clash_visual = null

func spawn_fighters(character: int, form: int) -> void:
	player = Fighter.new()
	player.warrior = character
	player.form_index = form
	world.add_child(player)
	enemy = Fighter.new()
	enemy.warrior = 1 - character
	world.add_child(enemy)
	player.position = Vector3(-3, 0, 4)
	enemy.position = Vector3(3, 0, -4)
	player.target = enemy
	enemy.target = player
	for fighter in [player, enemy]:
		fighter.struck.connect(on_strike)
		fighter.launched.connect(launch_attack)
		fighter.landed.connect(on_landing)
		fighter.transformed.connect(on_transform)

func show_menu() -> void:
	running = false
	paused = false
	held.clear()
	input_buffer.clear()
	clear_overlay()
	clear_world()
	arena = BattleArena.new()
	world.add_child(arena)
	arena.generate(0)
	spawn_fighters(warrior_select.selected, 0)
	player.position = Vector3(2, 0, 0)
	enemy.position = Vector3(5.5, 0, -1)
	player.rotation.y = PI
	enemy.rotation.y = PI
	menu.visible = true
	hud.visible = false
	update_preview()
	reveal(menu)

func start_match() -> void:
	sound.play("menu")
	mode = mode_select.selected
	difficulty = difficulty_select.selected
	wave = 1
	cost_form = -1
	clear_overlay()
	clear_world()
	arena = BattleArena.new()
	world.add_child(arena)
	arena.generate(arena_select.selected)
	spawn_fighters(warrior_select.selected, form_select.selected)
	player.active = true
	enemy.active = true
	running = true
	paused = false
	menu.visible = false
	hud.visible = true
	hp_trail_player.value = 100
	hp_trail_enemy.value = 100
	reveal(hud)
	touch.visible = settings.touch
	battle_form.clear()
	battle_attack.clear()
	for form in Roster.forms(player.warrior):
		battle_form.add_item(form)
	battle_form.select(player.form_index)
	for attack in Roster.attacks(player.warrior):
		battle_attack.add_item(attack.title + "  [" + str(int(ceil(player.special_cost(attack)))) + " ki]")
	time_left = 90 if mode == 4 else 180
	elapsed = 0
	ai_clock = 1.5
	if mode == 8:
		enemy.form_index = Roster.forms(enemy.warrior).size() - 1
		enemy.refresh_form()
		difficulty = 3
	notify("FIGHT!", 2.5)
	if mode == 2:
		begin_story_chapter()

func _process(delta: float) -> void:
	touch.input_enabled = running and not paused and not selector_open and overlay.get_child_count() == 0
	if not is_instance_valid(player):
		return
	if not running:
		menu_orbit += delta * 0.12
		camera.position = Vector3(0.6 + sin(menu_orbit) * 0.7, 3.0, 10)
		camera.look_at(Vector3(1.0, 1.8, -1), Vector3.UP)
		return
	if paused or selector_open:
		return
	elapsed += delta
	time_left -= delta
	message_time -= delta
	if message_time <= 0:
		message_label.text = ""
	update_effects(delta)
	update_projectiles(delta)
	if clash_time > 0:
		update_clash(delta)
	else:
		process_controls(delta)
		if mode != 5:
			process_ai(delta)
	update_camera(delta)
	update_hud(delta)
	if mode in [1, 9]:
		if mode == 9 and player.combo >= 3:
			end_match("TRIAL COMPLETE", "Three-hit chain connected. Try a launch into a beam next.")
		if enemy.health <= 0:
			enemy.health = 200
			for fighter in [player, enemy]:
				fighter.model.rotation.z = 0
		player.health = maxf(player.health, 50)
		time_left = 180
	else:
		if player.health <= 0:
			end_match("DEFEAT", "Train, adapt, and return stronger.")
		elif enemy.health <= 0:
			if mode in [2, 3, 6, 7] and (mode == 3 or wave < (5 if mode == 7 else 3)):
				next_wave()
			else:
				if mode == 2:
					begin_story_ending()
				else:
					end_match("VICTORY", "You broke through your limits.")
		elif time_left <= 0:
			end_match("TIME UP", "Player wins on health." if player.health > enemy.health else "Rival wins on health.")

func process_controls(delta: float) -> void:
	var stick := touch.movement if touch.visible else Vector2.ZERO
	stick += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	var forward := -camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0
	var direction := right.normalized() * stick.x - forward * stick.y
	direction.y = float(held.get("up", false) or Input.is_physical_key_pressed(KEY_Q)) - float(held.get("down", false) or Input.is_physical_key_pressed(KEY_F))
	player.move_input(direction, delta)
	player.guarding = held.get("guard", false) or Input.is_physical_key_pressed(KEY_B)
	player.charging = held.get("charge", false) or Input.is_physical_key_pressed(KEY_C)
	for entry in input_buffer.duplicate():
		entry.ttl -= delta
		if entry.ttl <= 0:
			input_buffer.erase(entry)
		elif player.can_act() or (entry.action == "special" and player.can_cancel_special()):
			execute_action(entry.action)
			input_buffer.erase(entry)
			break
	if mode == 5:
		var direction2 := Vector3(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), 0, float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP)))
		enemy.move_input(direction2, delta)
		enemy.guarding = Input.is_physical_key_pressed(KEY_KP_0)
		enemy.charging = Input.is_physical_key_pressed(KEY_KP_5)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or event.echo:
		return
	if event.pressed and event.physical_keycode == KEY_ESCAPE and running:
		toggle_pause()
		return
	if not running or paused or selector_open:
		return
	var mapping := {KEY_H:"medium", KEY_J:"light", KEY_K:"heavy", KEY_L:"blast", KEY_SPACE:"dash", KEY_E:"special", KEY_R:"ultimate", KEY_T:"transform", KEY_G:"grapple", KEY_ENTER:"clash"}
	if mapping.has(event.physical_keycode) and event.pressed:
		press_action(mapping[event.physical_keycode])
	if mode == 5 and event.pressed:
		match event.physical_keycode:
			KEY_KP_1: enemy.melee()
			KEY_KP_2: enemy.melee(true)
			KEY_KP_3: enemy.special(Roster.attacks(enemy.warrior)[0])
			KEY_KP_4: enemy.vanish()

func press_action(action: String) -> void:
	if not running or paused or selector_open:
		return
	held[action] = true
	if clash_time > 0:
		if action in ["light", "heavy", "clash"]:
			clash_power += 0.11
		return
	if action in ["guard", "charge", "up", "down"]:
		return
	if player.can_act() or action == "dash" or (action == "special" and player.can_cancel_special()):
		execute_action(action)
	else:
		if input_buffer.size() < 2:
			input_buffer.append({"action": action, "ttl": 0.25})

func release_action(action: String) -> void:
	held.erase(action)

func execute_action(action: String) -> void:
	match action:
		"medium": player.medium_attack()
		"light", "heavy", "grapple":
			if player.melee(action == "heavy", action == "grapple"):
				sound.play("dash")
		"blast": player.special(AttackDefinition.make("Ki blast", 5, 5, "blast", Color("ffd977"), 0.08))
		"special":
			var attack: AttackDefinition = Roster.attacks(player.warrior)[battle_attack.selected]
			if not player.special(attack, true):
				notify("Needs " + str(int(ceil(player.special_cost(attack)))) + " ki / form " + str(attack.minimum_form), 1.2)
		"ultimate":
			var attack: AttackDefinition = Roster.attacks(player.warrior)[4 if player.warrior == 0 else 3]
			if not player.special(attack):
				notify("Ultimate: charge ki or select its required form", 1.3)
		"transform":
			var selected: int = battle_form.selected
			if selected == player.form_index:
				selected = (selected + 1) % Roster.forms(player.warrior).size()
				battle_form.select(selected)
			if not player.transform(selected):
				notify("Transformation needs %d Ki and a clear recovery" % int(player.transformation_cost(selected)), 1.5)
		"dash":
			if player.vanish():
				sound.play("dash")

func process_ai(delta: float) -> void:
	if mode in [1, 9]:
		enemy.guarding = training_defense
		return
	var dist: float = player.position.distance_to(enemy.position)
	var skill: float = [0.55, 1.0, 1.4, 1.9][difficulty]
	var direction := (player.position - enemy.position).normalized()
	if enemy.ki < 22 and dist > 7:
		enemy.charging = true
	else:
		enemy.charging = false
		if dist > 2.7:
			enemy.move_input(direction * skill * 0.7, delta)
	ai_clock -= delta
	if ai_clock > 0 or not enemy.can_act():
		return
	ai_clock = rng.randf_range(0.25, 0.8) / skill
	enemy.guarding = false
	if mode == 1:
		return
	if player.pending != null and rng.randf() < 0.25 * skill:
		enemy.guarding = true
		if difficulty >= 2 and dist < 8:
			enemy.vanish()
	elif enemy.form_index < mini(wave + difficulty, Roster.forms(enemy.warrior).size() - 1) and enemy.ki > 70 and rng.randf() < 0.16:
		enemy.transform(enemy.form_index + 1)
	elif dist < 3.3:
		enemy.melee(rng.randf() < 0.3, rng.randf() < 0.08)
	elif enemy.ki > 28 and rng.randf() < 0.60:
		var attacks := Roster.attacks(enemy.warrior)
		var attack: AttackDefinition = attacks[rng.randi_range(0, attacks.size() - 1)]
		if attack.minimum_form <= enemy.form_index:
			enemy.special(attack)
	else:
		enemy.guarding = rng.randf() < 0.3

func launch_attack(actor: Fighter, attack: AttackDefinition) -> void:
	if not running:
		return
	var target: Fighter = actor.target
	var direction: Vector3 = (target.position + Vector3.UP * 1.4 - actor.position - Vector3.UP * 1.4).normalized()
	if attack.kind in ["teleport", "warp", "rush"]:
		actor.position = target.position + target.basis.z * 2.6
		burst(actor.position + Vector3.UP, attack.color, 2)
		if attack.kind == "teleport":
			return
		if attack.kind == "rush":
			var perfect := target.take_hit(attack.damage * actor.attack_power(), Vector3.UP * 6 + direction * 18)
			on_strike(target, attack.damage, perfect)
			arena.damage_environment(target.position, 5)
			return
		direction = (target.position - actor.position).normalized()
	if attack.kind == "explosion":
		burst(actor.position, attack.color, 11)
		if actor.position.distance_to(target.position) < 16:
			target.take_hit(attack.damage, direction * 28)
		actor.health = maxf(1, actor.health - 35)
		arena.damage_environment(actor.position, 14)
		sound.play("explosion")
		return
	var visual := Node3D.new()
	world.add_child(visual)
	visual.position = actor.position + Vector3.UP * 1.45 + direction * 1.2
	var radius: float = 1.2 if attack.kind == "sphere" else 0.25 if attack.kind == "blast" else 0.48
	if attack.kind in ["beam", "warp"]:
		var core := Art.ball(visual, Vector3.ZERO, radius, attack.color, 2)
		core.scale = Vector3(1, 1, 8)
		visual.look_at(visual.position + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)
	else:
		Art.ball(visual, Vector3.ZERO, radius, attack.color, 2)
	var trail := EnergyFX.particles(visual, attack.color, radius * 0.5, 16 if attack.kind == "blast" else 32)
	trail.direction = -direction
	trail.gravity = Vector3.ZERO
	projectiles.append({"node": visual, "actor": actor, "target": target, "attack": attack, "direction": direction, "ttl": 4.0, "radius": radius, "power": actor.attack_power()})
	sound.play_at("blast" if attack.kind == "blast" else "beam", actor.global_position)
	if attack.damage > 30:
		notify(attack.title.to_upper(), 1.3)
		shake = 0.15

func update_projectiles(delta: float) -> void:
	for shot in projectiles.duplicate():
		if not projectiles.has(shot):
			continue
		shot.ttl -= delta
		var node: Node3D = shot.node
		var previous := node.position
		var speed: float = 15 if shot.attack.kind == "sphere" else 36
		node.position += shot.direction * speed * delta
		var hit_point: Vector3 = shot.target.position + Vector3.UP * 1.5
		var segment := node.position - previous
		var fraction := clampf((hit_point - previous).dot(segment) / maxf(segment.length_squared(), 0.0001), 0, 1)
		if (previous + segment * fraction).distance_to(hit_point) < shot.radius + 1.0:
			var damage: float = shot.attack.damage * shot.power
			var before: float = shot.target.health
			var perfect: bool = shot.target.take_hit(damage, shot.direction * 15)
			on_strike(shot.target, before - shot.target.health, perfect)
			arena.damage_environment(node.position, 2 + shot.radius * 3)
			remove_shot(shot)
			continue
		var clashed := false
		if shot.attack.kind in ["beam", "warp"]:
			for other in projectiles.duplicate():
				if other.actor != shot.actor and other.attack.kind in ["beam", "warp"] and node.position.distance_to(other.node.position) < 5:
					start_clash(shot, other)
					clashed = true
					break
		if clashed:
			break
		if shot.ttl <= 0 or node.position.length() > 100:
			remove_shot(shot)

func remove_shot(shot: Dictionary) -> void:
	projectiles.erase(shot)
	if is_instance_valid(shot.node):
		shot.node.queue_free()

func start_clash(first: Dictionary, second: Dictionary) -> void:
	if clash_time > 0:
		return
	clash_attack = first.attack if first.actor == player else second.attack
	clash_enemy_attack = first.attack if first.actor == enemy else second.attack
	var point: Vector3 = (first.node.position + second.node.position) / 2
	for shot in projectiles.duplicate():
		remove_shot(shot)
	clash_time = 3.0
	clash_power = 0
	player.stunned = 3.2
	enemy.stunned = 3.2
	clash_visual = Node3D.new()
	world.add_child(clash_visual)
	clash_visual.position = point
	Art.ball(clash_visual, Vector3.ZERO, 1.3, GOLD, 3)
	for fighter in [player, enemy]:
		var beam := Art.ball(clash_visual, (fighter.position + Vector3.UP * 1.4 - point) / 2, 0.5, Color("89cfff") if fighter == player else Color("c183ff"), 2)
		var relative: Vector3 = fighter.position + Vector3.UP * 1.4 - point
		beam.scale.z = relative.length()
		beam.look_at(fighter.position + Vector3.UP * 1.4, Vector3.UP)
	notify("BEAM CLASH!  TAP PUNCH / ENTER", 3.2)
	sound.play("beam")

func update_clash(delta: float) -> void:
	clash_time -= delta
	clash_power -= delta * [0.16, 0.32, 0.5, 0.8][difficulty]
	clash_visual.scale = Vector3.ONE * (1 + sin(elapsed * 25) * 0.08)
	if clash_time <= 0:
		var winner: Fighter = player if clash_power > 0 else enemy
		var loser: Fighter = enemy if winner == player else player
		var attack: AttackDefinition = clash_attack if winner == player else clash_enemy_attack
		loser.take_hit(attack.damage * 1.5, (loser.position - winner.position).normalized() * 30)
		burst(clash_visual.position, GOLD, 8)
		arena.damage_environment(clash_visual.position, 10)
		clash_visual.queue_free()
		clash_visual = null
		notify("CLASH WON!" if winner == player else "CLASH LOST!", 1.4)
		sound.play("explosion")
		shake = 0.7

func on_strike(target: Fighter, amount: float, perfect: bool) -> void:
	burst(target.position + Vector3.UP * 1.6, Color("9beaff") if perfect else GOLD, 1.1)
	sound.play_at("dash" if perfect else "hit", target.global_position + Vector3.UP, 1.1 if perfect else 1.0)
	shake = 0.07 if perfect else 0.18
	var text := Label3D.new()
	text.text = "EVADE / PERFECT" if perfect else str(int(amount))
	text.font_size = 60
	text.pixel_size = 0.009
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.position = target.position + Vector3.UP * 3.8
	text.modulate = Color("a6e7ff") if perfect else GOLD
	world.add_child(text)
	effects.append({"node": text, "ttl": 0.7, "life": 0.7, "float": true})

func on_landing(actor: Fighter, speed: float) -> void:
	if speed < 4: return
	burst(actor.position + Vector3.UP * 0.15, Color("b7a185"), minf(2.5, speed * 0.18))
	arena.damage_environment(actor.position, minf(3, speed * 0.2))
	shake = maxf(shake, 0.1)
	sound.play_at("hit", actor.global_position, 0.8)

func on_transform(actor: Fighter) -> void:
	var form := Roster.form(actor.warrior, actor.form_index)
	if actor == player:
		battle_form.select(player.form_index)
	burst(actor.position + Vector3.UP, form.aura, 4)
	shake = 0.4
	sound.play_at("transform", actor.global_position, 0.9 + actor.form_index * 0.025)
	notify(form.name.to_upper() + "  ·  " + form.continuity, 2.0)

func burst(point: Vector3, tint: Color, radius: float) -> void:
	var visual := Node3D.new()
	world.add_child(visual)
	visual.position = point
	Art.ring(visual, Vector3.ZERO, radius, Color(tint, 0.8))
	for i in (8 if settings.quality == 0 else 16):
		var spark := Art.spike(visual, Vector3.ZERO, radius * 0.8, tint, Vector3(i * 71, i * 37, i * 131))
		spark.position = Vector3(sin(i * 2.3), cos(i * 1.7), sin(i * 3.1)) * radius * 0.3
	effects.append({"node": visual, "ttl": 0.45, "life": 0.45, "float": false})
	if effects.size() > 48:
		var oldest: Dictionary = effects.pop_front()
		oldest.node.queue_free()

func update_effects(delta: float) -> void:
	for effect in effects.duplicate():
		effect.ttl -= delta
		if effect.ttl <= 0:
			effect.node.queue_free()
			effects.erase(effect)
		elif effect.float:
			effect.node.position.y += delta * 2
		else:
			effect.node.scale = Vector3.ONE * (1.0 + (1.0 - effect.ttl / effect.life) * 1.5)

func update_camera(delta: float) -> void:
	var focus := player.position.lerp(enemy.position, 0.3) + Vector3.UP * 1.8
	var back := (player.position - enemy.position)
	back.y = 0
	back = back.normalized()
	if back.length() < 0.1:
		back = Vector3.BACK
	var distance: float = clampf(player.position.distance_to(enemy.position) * 0.5 + 8, 10, 25)
	var desired := player.position + back * distance + Vector3.UP * (4 + distance * 0.12) + Vector3(back.z, 0, -back.x) * 3
	if clash_time > 0:
		focus = clash_visual.position
		desired = focus + Vector3(10, 4, 10)
	shake = maxf(0, shake - delta)
	camera.position = camera.position.lerp(desired, 1.0 - exp(-delta * 5)) + Vector3(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake), 0)
	camera.position.y = maxf(2, camera.position.y)
	camera.look_at(focus, Vector3.UP)

func update_hud(delta: float = 0.016) -> void:
	hp_player.value = player.health / 2
	hp_enemy.value = enemy.health / 2
	ki_player.value = player.ki
	ki_enemy.value = enemy.ki
	stamina_player.value = player.stamina
	hp_trail_player.value = move_toward(hp_trail_player.value, hp_player.value, delta * 22)
	hp_trail_enemy.value = move_toward(hp_trail_enemy.value, hp_enemy.value, delta * 22)
	if cost_form != player.form_index:
		cost_form = player.form_index
		var attacks := Roster.attacks(player.warrior)
		for index in battle_attack.item_count:
			var attack: AttackDefinition = attacks[index]
			battle_attack.set_item_text(index, "%s [%d ki]" % [attack.title, int(ceil(player.special_cost(attack)))])
	var form := Roster.form(player.warrior, player.form_index)
	form_effect_label.text = form.description + (" · FURY +%d%%" % int(player.fury * 100) if form.name == "Ultra Ego" else "")
	form_effect_label.add_theme_color_override("font_color", form.aura)
	rival_form_label.text = Roster.forms(enemy.warrior)[enemy.form_index]
	touch.cooldown_fraction = clampf(player.cooldown / maxf(player.action_duration, 0.01), 0, 1)
	touch.available_ki = player.ki
	touch.form_tint = form.aura
	touch.queue_redraw()
	timer_label.text = "%03d" % maxi(0, int(time_left))
	form_label.text = ("GOKU" if player.warrior == 0 else "VEGETA") + "  /  " + Roster.forms(player.warrior)[player.form_index] + "\nHP %d  KI %d  ST %d" % [int(player.health), int(player.ki), int(player.stamina)]
	combo_label.text = "%d HIT COMBO" % player.combo if player.combo > 1 else ""

func notify(text: String, duration: float) -> void:
	message_label.text = text
	message_time = duration
	reveal(message_label)

func next_wave() -> void:
	wave += 1
	enemy.health = 200
	enemy.melee_pending.clear()
	enemy.pending = null
	enemy.cooldown = 0
	enemy.stunned = 0
	enemy.invincible = 0
	enemy.transform_time = 0
	enemy.attack_animation_time = 0
	enemy.landing_time = 0
	enemy.combo = 0
	enemy.stamina = 100
	enemy.guarding = false
	enemy.charging = false
	enemy.motion = Vector3.ZERO
	for shot in projectiles.duplicate(): remove_shot(shot)
	enemy.knocked_airborne = false
	enemy.fury = 0
	enemy.ki = 100
	enemy.form_index = mini(wave + difficulty, Roster.forms(enemy.warrior).size() - 1)
	enemy.refresh_form()
	enemy.model.rotation.z = 0
	enemy.position = Vector3(3, 0, -6)
	player.health = minf(200, player.health + 55)
	player.ki = minf(100, player.ki + 30)
	time_left = 180
	for shot in projectiles.duplicate():
		remove_shot(shot)
	notify("WAVE %d" % wave, 2.5)
	if mode == 2:
		begin_story_chapter()

func clear_overlay() -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()

func end_match(title: String, subtitle: String) -> void:
	running = false
	player.active = false
	enemy.active = false
	player.play_rig("victory" if player.health > enemy.health else "defeat", true)
	enemy.play_rig("victory" if enemy.health > player.health else "defeat", true)
	touch.reset_input()
	held.clear()
	input_buffer.clear()
	clear_overlay()
	panel(overlay, Vector2(320, 195), Vector2(640, 335), Color(0.03, 0.05, 0.09, 0.96))
	label(overlay, title, Vector2(420, 227), 50, GOLD)
	label(overlay, subtitle, Vector2(370, 302), 20)
	label(overlay, "Time %.1fs  ·  Wave %d" % [elapsed, wave], Vector2(370, 346), 18)
	button(overlay, "REMATCH", Vector2(370, 417), Vector2(235, 54), start_match)
	button(overlay, "MAIN MENU", Vector2(625, 417), Vector2(235, 54), show_menu)

func toggle_pause() -> void:
	if not running or dialogue_active:
		return
	paused = not paused
	for fighter in [player, enemy]:
		fighter.set_combat_paused(paused)
	clear_overlay()
	touch.reset_input()
	held.clear()
	input_buffer.clear()
	if paused:
		panel(overlay, Vector2(380, 170), Vector2(520, 380), Color(0.025, 0.04, 0.08, 0.97))
		label(overlay, "PAUSED", Vector2(460, 203), 42, GOLD)
		button(overlay, "RESUME", Vector2(440, 285), Vector2(400, 52), toggle_pause)
		button(overlay, "SETTINGS", Vector2(440, 354), Vector2(400, 52), show_settings)
		button(overlay, "MAIN MENU", Vector2(440, 423), Vector2(400, 52), show_menu)

func show_settings() -> void:
	if running and not paused:
		toggle_pause()
	clear_overlay()
	panel(overlay, Vector2(300, 100), Vector2(680, 535), Color(0.025, 0.04, 0.08, 0.99))
	label(overlay, "SETTINGS", Vector2(345, 120), 37, GOLD)
	label(overlay, "SOUND VOLUME", Vector2(345, 191), 16)
	var volume := HSlider.new()
	volume.position = Vector2(345, 228)
	volume.size = Vector2(580, 30)
	volume.max_value = 1
	volume.step = 0.05
	volume.value = settings.volume
	overlay.add_child(volume)
	volume.value_changed.connect(func(value: float): settings.volume = value; sound.volume = value; save_settings())
	label(overlay, "GRAPHICS", Vector2(345, 275), 16)
	var graphics := option(overlay, ["Low · no shadows", "Balanced · shadows", "High · full resolution"], Vector2(345, 310), 580)
	graphics.select(settings.quality)
	graphics.item_selected.connect(func(index: int):
		settings.quality = index
		sun.shadow_enabled = index > 0
		get_viewport().scaling_3d_scale = [0.65, 0.85, 1.0][index]
		save_settings())
	var touch_button := button(overlay, "TOUCH CONTROLS: ON" if settings.touch else "TOUCH CONTROLS: OFF", Vector2(345, 374), Vector2(280, 44), func():
		settings.touch = not settings.touch
		touch.visible = settings.touch and running
		save_settings()
		show_settings())
	touch_button.add_theme_font_size_override("font_size", 14)
	button(overlay, "MOVE TOUCH BUTTONS", Vector2(645, 374), Vector2(280, 44), customize_controls)
	label(overlay, "Local P2: arrows · numpad 1/2 strikes · 3 beam · 4 vanish · 0 guard · 5 ki", Vector2(345, 445), 13, Color("b5cadd"))
	label(overlay, "Forms span different continuities; attack labels identify game / film variants.", Vector2(345, 478), 13, Color("b5cadd"))
	button(overlay, "SAVE & CLOSE", Vector2(345, 541), Vector2(580, 50), func():
		save_settings()
		clear_overlay()
		if paused:
			toggle_pause())

func customize_controls() -> void:
	clear_overlay()
	touch.visible = true
	hud.visible = true
	hp_trail_player.value = 100
	hp_trail_enemy.value = 100
	reveal(hud)
	touch.edit_layout = true
	label(overlay, "Drag buttons with touch, then save. Joystick stays on the left.", Vector2(330, 200), 19, GOLD)
	button(overlay, "SAVE LAYOUT", Vector2(500, 250), Vector2(260, 52), func():
		touch.edit_layout = false
		touch.reset_input()
		save_settings()
		hud.visible = running
		show_settings())

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings:
			settings[key] = config.get_value("settings", key, settings[key])

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	if is_instance_valid(touch):
		for action in touch.actions:
			config.set_value("layout", action, touch.actions[action])
	config.save("user://settings.cfg")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and running and not paused:
		toggle_pause()

func begin_story_chapter() -> void:
	dialogue_active = true
	story_finished = false
	var chapters := [
		["RIVALRY AT DAWN", "Bulma: The simulator is ready. Keep your power down until calibration ends.", "Goku: A quick warm-up? Come on, Vegeta!", "Vegeta: Try paying attention. We are measuring control, not noise."],
		["THE RESONANCE", "Bulma: Your last exchange fed energy back into the system. It is repeating your attacks!", "Vegeta: Then stop giving it the same answer, Kakarot.", "Goku: Right. We change our timing and make an opening together."],
		["BEYOND THE LIMITS", "Bulma: One concentrated burst will break the feedback loop. The echo will resist.", "Goku: I'll draw it out. Vegeta, match my timing!", "Vegeta: Keep up with me. We finish this in one exchange."]
	]
	story_lines = chapters[wave - 1].duplicate()
	story_line = 0
	paused = true
	for fighter in [player, enemy]:
		fighter.set_physics_process(false)
	touch.reset_input()
	held.clear()
	show_story_line()

func begin_story_ending() -> void:
	dialogue_active = true
	story_finished = true
	story_lines = ["A RIVALRY CONTINUES", "Bulma: Feedback is gone. Next time, wait for the calibration light!", "Goku: That was great! Same time tomorrow?", "Vegeta: Tomorrow, we train without your machine.", "Campaign complete. Your training record has been saved."]
	story_line = 0
	paused = true
	for fighter in [player, enemy]:
		fighter.set_physics_process(false)
	var progress := ConfigFile.new()
	progress.load("user://campaign.cfg")
	progress.set_value("campaign", "completed", true)
	progress.set_value("campaign", "chapters", 3)
	progress.save("user://campaign.cfg")
	show_story_line()

func show_story_line() -> void:
	clear_overlay()
	var speaker: Fighter = player if story_line % 2 == 0 else enemy
	camera.position = speaker.position - speaker.basis.z * 5 + Vector3.UP * 2.7
	camera.look_at(speaker.position + Vector3.UP * 1.8)
	panel(overlay, Vector2.ZERO, Vector2(1280, 720), Color(0.01, 0.025, 0.05, 0.6))
	label(overlay, "ORIGINAL FAN STORY  /  CHAPTER %d" % wave, Vector2(100, 130), 18, GOLD)
	label(overlay, story_lines[0], Vector2(100, 190), 40, GOLD)
	var dialogue := label(overlay, story_lines[story_line] if story_line > 0 else "A training rivalry. A dangerous feedback loop. One chance to work together.", Vector2(100, 310), 26)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.size = Vector2(1060, 180)
	button(overlay, "CONTINUE →", Vector2(900, 570), Vector2(280, 65), advance_story)

func advance_story() -> void:
	story_line += 1
	if story_line < story_lines.size():
		show_story_line()
		return
	dialogue_active = false
	clear_overlay()
	paused = false
	for fighter in [player, enemy]:
		fighter.set_physics_process(true)
	if story_finished:
		end_match("CAMPAIGN COMPLETE", "The simulator is safe. The rivalry continues.")
	else:
		var progress := ConfigFile.new()
		progress.load("user://campaign.cfg")
		progress.set_value("campaign", "chapters", maxi(wave - 1, int(progress.get_value("campaign", "chapters", 0))))
		progress.save("user://campaign.cfg")
		notify("CHAPTER %d: FIGHT!" % wave, 2)

func training_reset() -> void:
	if not running or mode not in [1, 9] or paused or selector_open:
		return
	for fighter in [player, enemy]:
		fighter.health = 200
		fighter.ki = 100
		fighter.stamina = 100
		fighter.pending = null
		fighter.melee_pending.clear()
		fighter.knocked_airborne = false
		fighter.landing_time = 0
		fighter.attack_animation_time = 0
		fighter.fury = 0
		fighter.transform_time = 0
		fighter.combo = 0
		fighter.stunned = 0
		fighter.cooldown = 0
		fighter.motion = Vector3.ZERO
	player.position = Vector3(0, 0, 3)
	enemy.position = Vector3(0, 0, -1)
	for shot in projectiles.duplicate():
		remove_shot(shot)
	touch.reset_input()
	held.clear()
	input_buffer.clear()
	notify("Training reset · chain punch, medium, kick", 2)
