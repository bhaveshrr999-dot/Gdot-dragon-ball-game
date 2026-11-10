extends SceneTree

var failures: int = 0
var checks: int = 0
var game

func check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + title)
	else:
		print("PASS: " + title)

func _initialize() -> void:
	call_deferred("run")

func reset_actor(actor: Fighter) -> void:
	actor.cooldown = 0
	actor.stunned = 0
	actor.transform_time = 0
	actor.pending = null
	actor.melee_pending.clear()
	actor.ki = 100
	actor.invincible = 0
	actor.guarding = false
	actor.health = 200
	actor.motion = Vector3.ZERO

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.sound.volume = 0
	check(game.menu.visible, "main menu starts")
	game.mode_select.select(1)
	game.start_match()
	check(game.running and game.player.active and game.enemy.active, "training launches both fighters")
	for warrior in 2:
		game.warrior_select.select(warrior)
		game.form_select.clear()
		for form in Roster.forms(warrior):
			game.form_select.add_item(form)
		game.form_select.select(0)
		game.start_match()
		var fighter: Fighter = game.player
		check(fighter.rig_animation != null and fighter.rig_animation.has_animation("run"), "imported skeletal run animation")
		check(fighter.animation_tree.active, "animation blend state machine active")
		for index in Roster.forms(warrior).size():
			reset_actor(fighter)
			if index > 0:
				check(fighter.transform(index), "transform %d:%d" % [warrior, index])
			check(fighter.form_index == index and fighter.hair_root.get_child_count() > 0, "form changes live model %d:%d" % [warrior, index])
		for attack in Roster.attacks(warrior):
			reset_actor(fighter)
			fighter.form_index = maxi(attack.minimum_form, 0)
			check(fighter.special(attack), "attack accepted: " + attack.title)
			fighter.pending = null
			game.launch_attack(fighter, attack)
			check(game.projectiles.size() > 0 or attack.kind in ["rush", "teleport", "explosion"], "attack executes: " + attack.title)
			for shot in game.projectiles.duplicate():
				game.remove_shot(shot)
	var player: Fighter = game.player
	var enemy: Fighter = game.enemy
	reset_actor(player)
	reset_actor(enemy)
	player.form_index = 0
	enemy.form_index = 0
	player.position = Vector3.ZERO
	enemy.position = Vector3(0, 0, -2)
	check(player.melee(), "melee input accepted")
	check(enemy.health == 200, "melee does not damage before impact frame")
	player._physics_process(0.13)
	check(enemy.health < 200, "melee damages target at impact frame")
	reset_actor(player)
	reset_actor(enemy)
	enemy.position = Vector3(0, 0, -15)
	player.melee()
	player._physics_process(0.13)
	check(enemy.health == 200, "melee cannot hit out of range")
	reset_actor(enemy)
	enemy.guarding = true
	enemy.guard_age = 0.05
	enemy.take_hit(50, Vector3.ONE)
	check(enemy.health == 200, "perfect block prevents damage")
	enemy.guard_age = 0.3
	enemy.take_hit(50, Vector3.ONE)
	check(enemy.health == 191, "normal block reduces damage")
	reset_actor(player)
	player.ki = 0
	check(not player.special(Roster.attacks(player.warrior)[0]), "insufficient ki rejects attack")
	player.ki = 100
	check(player.vanish() and player.invincible > 0 and player.ki == 85, "vanish costs ki and grants invulnerability")
	check((player.position - enemy.position).dot(enemy.basis.z) > 0, "vanish moves behind the rival")
	reset_actor(player)
	reset_actor(enemy)
	player.position = Vector3(0, 0, 5)
	enemy.position = Vector3(0, 0, -5)
	game.launch_attack(player, Roster.attacks(player.warrior)[0])
	game.launch_attack(enemy, Roster.attacks(enemy.warrior)[0])
	for i in 30:
		game.update_projectiles(1.0 / 60)
		if game.clash_time > 0:
			break
	check(game.clash_time > 0, "opposing beams trigger interactive clash")
	game.press_action("clash")
	check(game.clash_power > 0, "player input contributes to clash")
	game.clash_power = 4
	game.update_clash(3.1)
	check(enemy.health < 200 and game.clash_time <= 0, "clash resolves and damages loser")
	reset_actor(player)
	reset_actor(enemy)
	player.position = Vector3.ZERO
	enemy.position = Vector3(0, 0, -5)
	game.launch_attack(player, AttackDefinition.make("test", 20, 0, "blast", Color.CYAN, 0))
	game.update_projectiles(0.2)
	check(enemy.health < 200, "swept projectile collision prevents tunneling")
	for index in 7:
		var arena := BattleArena.new()
		game.world.add_child(arena)
		arena.generate(index)
		check(arena.get_child_count() > 20, "arena generates %d" % index)
		arena.damage_environment(Vector3(15, 0, 15), 12)
		check(arena.craters.size() == 1, "arena destruction creates crater %d" % index)
		arena.queue_free()
	game.toggle_pause()
	var health: float = player.health
	check(game.paused and not player.is_physics_processing(), "pause freezes fighter simulation")
	game.toggle_pause()
	check(not game.paused and player.is_physics_processing() and player.health == health, "resume restores simulation")
	game.touch.visible = true
	var press := InputEventScreenTouch.new()
	press.index = 1
	press.position = Vector2(200, 556)
	press.pressed = true
	game.touch._input(press)
	check(game.touch.movement.x > 0.1, "touch joystick responds")
	var guard := InputEventScreenTouch.new()
	guard.index = 2
	guard.position = game.touch.actions.guard
	guard.pressed = true
	game.touch._input(guard)
	check(game.held.get("guard", false) and game.touch.movement.x > 0.1, "multitouch supports move and guard")
	game.touch.reset_input()
	check(game.touch.movement == Vector2.ZERO and not game.held.has("guard"), "touch reset releases held controls")
	for index in Roster.MODES.size():
		game.mode_select.select(index)
		game.start_match()
		check(game.mode == index and game.running, "mode launches %d" % index)
	game.mode = 3
	game.enemy.health = 0
	game._process(0.01)
	check(game.wave == 2 and game.enemy.health > 0, "survival advances wave")
	game.player.health = 0
	game._process(0.01)
	check(not game.running and game.overlay.get_child_count() > 0, "defeat presents rematch/menu")
	game.settings.volume = 0.35
	game.save_settings()
	game.settings.volume = 0.8
	game.load_settings()
	check(is_equal_approx(game.settings.volume, 0.35), "settings persist")
	game.settings.volume = 0.65
	game.save_settings()
	print("RESULT: %d checks / %d failures" % [checks, failures])
	game.queue_free()
	await create_timer(0.1).timeout
	quit(1 if failures > 0 else 0)
