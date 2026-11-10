extends SceneTree
var checks := 0
var failures := 0
var game
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + title)
	if not ok: failures += 1
func reset() -> void:
	for actor in [game.player,game.enemy]:
		actor.health = 200; actor.ki = 100; actor.cooldown = 0; actor.stunned = 0
		actor.form_index = 0; actor.invincible = 0; actor.guarding = false
		actor.pending = null; actor.melee_pending.clear(); actor.combo = 0; actor.fury = 0
		actor.transform_time = 0; actor.motion = Vector3.ZERO; actor.knocked_airborne = false
	game.player.position = Vector3.ZERO; game.enemy.position = Vector3(0,0,-2)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.sound.volume = 0; game.mode_select.select(1);game.start_match();game.set_process(false)
	game.player.set_physics_process(false);game.enemy.set_physics_process(false)
	reset()
	game.player.melee();game.player._physics_process(.05)
	check(game.enemy.health == 200,"strike anticipation cannot deal damage")
	game.player._physics_process(.08)
	check(game.enemy.health == 195,"strike connects once on its impact frame")
	game.player._physics_process(.5)
	check(game.enemy.health == 195,"recovery cannot repeat the hit")
	reset();game.player.melee();game.enemy.position.z = -8;game.player._physics_process(.13)
	check(game.enemy.health == 200,"moving outside range during startup evades the hit")
	reset();game.player.melee();game.player.take_hit(1,Vector3.ZERO);game.player._physics_process(.13)
	check(game.enemy.health == 200,"hit-stun interrupts an unlanded strike")
	reset();game.player.melee();game.player._physics_process(.05)
	game.enemy.guarding = true;game.enemy.guard_age = .05;game.player._physics_process(.08)
	check(game.enemy.health == 200 and game.enemy.rig_state == "parry","late perfect guard parries at contact")
	reset();game.player.melee();game.player.guarding = true;game.player._physics_process(.13)
	check(game.enemy.health == 200,"guard cancels startup instead of attacking while blocking")
	reset();game.player.melee();game.player._physics_process(.2)
	check(game.player.special(Roster.attacks(0)[0],true),"confirmed hit can cancel late recovery into special")
	reset();game.player.melee();game.player._physics_process(.2);game.player.ki = 0
	var remaining: float = game.player.cooldown
	check(not game.player.special(Roster.attacks(0)[0],true) and game.player.cooldown == remaining,"unaffordable cancel cannot erase recovery")
	reset();game.enemy.position.z = -8;game.player.melee();game.player._physics_process(.2)
	check(not game.player.can_cancel_special(),"whiff cannot unlock hit-confirm cancel")
	reset();game.player.melee(true);game.player._physics_process(.23)
	var peak := 0.0
	for i in 120:
		game.enemy._physics_process(1.0/60.0);peak = maxf(peak,game.enemy.position.y)
	check(peak > .4 and game.enemy.position.y == 0 and not game.enemy.knocked_airborne,"launch arcs return to ground and recover")
	reset();game.player.form_index = 6;game.player.ki = 0
	check(game.player.transform(0) and game.player.ki == 0,"base reversion is free even when Ki is depleted")
	check(Roster.form(0,5).power > Roster.form(0,4).power and Roster.form(0,6).power > Roster.form(0,5).power,"normalized god and blue power progress beyond SSJ3")
	reset();game.launch_attack(game.player,Roster.attacks(0)[5])
	check(game.enemy.health == 200,"standalone Instant Transmission moves without inflicting invented damage")
	print("RESULT: %d checks / %d failures" % [checks,failures])
	game.queue_free();await create_timer(.1).timeout;quit(1 if failures else 0)
