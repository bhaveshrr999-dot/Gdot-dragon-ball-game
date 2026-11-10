extends SceneTree
var failures := 0
var game
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, title: String) -> void:
	print(("PASS: " if value else "FAIL: ") + title)
	if not value:
		failures += 1
func tap(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
		await process_frame
func run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.sound.volume = 0
	check(Input.emulate_mouse_from_touch, "touch-to-GUI emulation enabled")
	await tap(Vector2(300, 585))
	check(game.running, "real touch activates main-menu start")
	await tap(Vector2(500, 122))
	check(game.battle_form.get_popup().visible, "real touch opens form selector")
	check(game.selector_open and not game.player.is_physics_processing(), "selector freezes combat")
	var popup: PopupMenu = game.battle_form.get_popup()
	var row_height: float = popup.get_theme_font("font").get_height(popup.get_theme_font_size("font_size")) + popup.get_theme_constant("v_separation")
	await tap(Vector2(popup.position) + Vector2(60, row_height * 1.5 + 4))
	check(game.battle_form.selected == 1, "real touch selects Kaioken")
	game.battle_form.get_popup().hide()
	await process_frame
	check(not game.selector_open and game.player.is_physics_processing(), "selector close resumes combat")
	await tap(Vector2(1249, 122))
	check(game.paused, "real touch activates pause")
	await tap(Vector2(600, 310))
	check(not game.paused, "real touch activates resume")
	game.show_menu()
	var press := InputEventScreenTouch.new()
	press.position = game.touch.actions.light
	press.pressed = true
	game.touch._input(press)
	check(game.touch.fingers.is_empty(), "hidden HUD cannot capture touches")
	game.mode_select.select(2)
	game.start_match()
	check(game.paused and game.story_lines.size() > 1, "story opens with dialogue")
	for i in 4:
		game.advance_story()
	check(not game.paused, "opening dialogue hands control to battle")
	game.begin_story_ending()
	for i in 5:
		game.advance_story()
	check(not game.running, "ending reaches campaign completion screen")
	for mode_index in [6, 7]:
		game.mode_select.select(mode_index)
		game.start_match()
		var rounds: int = 5 if mode_index == 7 else 3
		for round_index in rounds:
			game.enemy.health = 0
			game._process(0.01)
		check(not game.running and game.wave == rounds, "mode %d completes all rounds" % mode_index)
	game.mode_select.select(1)
	game.start_match()
	game.player.health = 40
	game.training_reset()
	check(game.player.health == 200 and game.player.ki == 100, "training reset restores resources")
	game.player.cooldown = 0
	game.enemy.position = game.player.position + Vector3(0, 0, -2)
	game.player.medium_attack()
	check(game.enemy.health == 192, "medium attack deals intermediate damage")
	game.mode_select.select(9)
	game.start_match()
	game.player.combo = 3
	game._process(0.01)
	check(not game.running, "combo trial recognizes three-hit chain")
	game.queue_free()
	await create_timer(0.1).timeout
	quit(1 if failures else 0)
