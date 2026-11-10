extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, title: String) -> void:
	checks += 1
	print(("PASS: " if value else "FAIL: ") + title)
	if not value: failures += 1
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.sound.volume = 0
	game.mode_select.select(1)
	game.start_match()
	var actor: Fighter = game.player
	actor.set_physics_process(false)
	game.enemy.set_physics_process(false)
	game.set_process(false)
	actor.form_index = 1
	actor.refresh_form()
	actor._physics_process(1.0)
	check(actor.health < 200 and actor.ki < 100, "Kaioken strains health and Ki over time")
	actor.health = 1
	actor._physics_process(1.0)
	check(actor.health == 1, "strain alone never kills")
	actor.form_index = 4
	actor.ki = 100
	actor.refresh_form()
	actor._physics_process(1.0)
	check(actor.ki < 96, "SSJ3 has severe upkeep")
	var visible_hair := []
	for mesh in actor.rigged_model.find_children("HairStyle_*", "MeshInstance3D", true, false):
		if mesh.visible: visible_hair.append(str(mesh.name))
	check(visible_hair == ["HairStyle_long"], "SSJ3 exclusively enables skinned long hair")
	actor.form_index = 0
	actor.refresh_form()
	visible_hair.clear()
	for mesh in actor.rigged_model.find_children("HairStyle_*", "MeshInstance3D", true, false):
		if mesh.visible: visible_hair.append(str(mesh.name))
	check(visible_hair == ["HairStyle_base"], "reversion restores only base silhouette")
	actor.form_index = 6
	check(is_equal_approx(actor.special_cost(Roster.attacks(0)[0]), 20.4), "Blue reduces a 24-Ki beam to 20.4")
	actor.form_index = 4
	actor.ki = 0.01
	actor._physics_process(1.0)
	check(actor.form_index == 0, "energy exhaustion reverts form")
	check(Roster.form(1,2).speed < Roster.form(1,1).speed and Roster.form(1,2).power > Roster.form(1,1).power, "Super Vegeta trades speed for strength")
	actor.warrior = 1
	actor.form_index = 8
	actor.health = 200
	actor.ki = 100
	actor.invincible = 0
	actor.guarding = false
	actor.take_hit(20, Vector3.ZERO)
	check(actor.health < 180 and actor.fury > 0, "Ultra Ego takes real damage and builds fury")
	var boosted := actor.attack_power()
	actor._physics_process(1.0)
	check(actor.attack_power() < boosted, "fury decays instead of permanent snowball")
	for i in 8:
		actor.health = 200
		actor.take_hit(100, Vector3.ZERO)
	check(actor.fury <= 0.5, "fury damage bonus capped at 50 percent")
	actor.stunned = 0
	actor.cooldown = 0
	actor.transform_time = 0
	actor.ki = 100
	actor.transform(0)
	check(actor.fury == 0, "changing forms clears fury")
	actor.warrior = 0
	actor.form_index = 0
	actor.health = 200
	actor.cooldown = 0
	actor.stunned = 0
	actor.transform_time = 0
	actor.pending = null
	actor.position = Vector3.ZERO
	game.enemy.position = Vector3(0,0,-2)
	game.enemy.form_index = 0
	game.enemy.invincible = 0
	game.enemy.guarding = false
	actor.combo = 0
	var routes := []
	for i in 3:
		actor.cooldown = 0
		actor.melee()
		actor._physics_process(0.13)
		routes.append(actor.attack_animation)
	check(routes == ["punch", "hook", "uppercut"], "three-hit chain chooses distinct clips")
	actor.cooldown = 0
	actor.medium_attack()
	check(actor.attack_animation == "medium" and is_equal_approx(actor.rig_animation.get_animation("medium").length / actor.animation_tree.get("parameters/medium/speed/scale"), 0.38), "medium motion spans its recovery")
	actor.cooldown = 0
	actor.ki = 100
	actor.melee_pending.clear()
	actor.special(Roster.attacks(0)[0])
	actor.update_rig_animation()
	check(actor.rig_state == "beam", "beam uses cupped charge pose")
	actor._physics_process(0.51)
	check(actor.rig_state == "beam_release", "release plays after startup completes")
	var power: float = game.projectiles.back().power
	actor.form_index = 7
	check(is_equal_approx(game.projectiles.back().power, power), "launched projectile retains launch power through transformation")
	actor.play_rig("idle", true)
	await create_timer(0.3).timeout
	var skeleton: Skeleton3D = actor.rigged_model.find_children("*", "Skeleton3D", true, false)[0]
	var bone := skeleton.find_bone("forearmR")
	var idle_height := skeleton.get_bone_global_pose(bone).origin.y
	actor.play_rig("sphere", true)
	await create_timer(0.3).timeout
	check(skeleton.get_bone_global_pose(bone).origin.y > idle_height + 0.4, "imported sphere clip actually raises the skeletal elbow")
	game.end_match("VICTORY", "test")
	check(actor.rig_state == "victory", "winner plays authored victory clip")
	print("RESULT: %d checks / %d failures" % [checks,failures])
	game.queue_free()
	await create_timer(0.1).timeout
	quit(1 if failures else 0)
