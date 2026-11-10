class_name Fighter
extends Node3D

signal struck(target, amount, perfect)
signal launched(actor, attack)
signal transformed(actor)
signal landed(actor, speed)

var warrior: int = 0
var form_index: int = 0
var health: float = 200.0
var ki: float = 100.0
var stamina: float = 100.0
var combo: int = 0
var combo_time: float = 0.0
var guarding: bool = false
var guard_age: float = 0.0
var charging: bool = false
var cooldown: float = 0.0
var action_duration: float = 0.7
var stunned: float = 0.0
var invincible: float = 0.0
var motion := Vector3.ZERO
var target: Fighter
var pending: AttackDefinition
var windup: float = 0.0
var transform_time: float = 0.0
var animation_time: float = 0.0
var attack_pose: float = 0.0
var kick_pose: float = 0.0
var attack_animation_time: float = 0.0
var attack_animation: String = "punch"
var fury: float = 0.0
var melee_pending: Dictionary = {}
var knocked_airborne: bool = false
var landing_time: float = 0.0
var charge_orb: MeshInstance3D
var lightning: MeshInstance3D
var lightning_step: int = -1
var active: bool = false
var aura_particles: CPUParticles3D
var aura: MeshInstance3D
var model: Node3D
var hair_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var animation_player: AnimationPlayer
var rigged_model: Node3D
var rig_animation: AnimationPlayer
var animation_tree: AnimationTree
var rig_playback: AnimationNodeStateMachinePlayback
var rig_state: String = ""
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	build_model()

func build_model() -> void:
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	model = Node3D.new()
	add_child(model)
	var skin := Color("e8af83")
	var suit := Color("ed682a") if warrior == 0 else Color("244b97")
	var navy := Color("152f66")
	Art.box(model, Vector3(0, 1.66, 0), Vector3(0.85, 0.88, 0.46), suit)
	Art.box(model, Vector3(0, 1.95, -0.24), Vector3(0.42, 0.45, 0.06), navy if warrior == 0 else Color("f0ecdc"))
	Art.box(model, Vector3(0, 1.26, 0), Vector3(0.88, 0.16, 0.49), navy if warrior == 0 else Color("c5a86d"))
	Art.ball(model, Vector3(0, 2.38, 0), 0.35, skin)
	Art.box(model, Vector3(0, 2.35, -0.30), Vector3(0.47, 0.16, 0.08), skin)
	for side in [-1.0, 1.0]:
		Art.box(model, Vector3(side * 0.14, 2.43, -0.335), Vector3(0.15, 0.065, 0.035), Color.WHITE)
		Art.box(model, Vector3(side * 0.14, 2.43, -0.36), Vector3(0.045, 0.058, 0.025), Color("102d36"))
		Art.box(model, Vector3(side * 0.14, 2.49, -0.35), Vector3(0.19, 0.045, 0.035), Color("191622"))
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.59, 1.98, 0)
		model.add_child(arm)
		Art.ball(arm, Vector3(0, -0.16, 0), 0.22, skin if warrior == 0 else suit)
		Art.box(arm, Vector3(0, -0.41, 0), Vector3(0.27, 0.5, 0.3), skin if warrior == 0 else suit)
		Art.box(arm, Vector3(0, -0.67, 0), Vector3(0.3, 0.18, 0.32), navy if warrior == 0 else Color.WHITE)
		Art.ball(arm, Vector3(0, -0.80, 0), 0.17, skin if warrior == 0 else Color.WHITE)
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.24, 1.18, 0)
		model.add_child(leg)
		Art.box(leg, Vector3(0, -0.38, 0), Vector3(0.36, 0.77, 0.41), suit)
		Art.box(leg, Vector3(0, -0.91, -0.06), Vector3(0.37, 0.35, 0.54), navy if warrior == 0 else Color("efead9"))
		if side < 0:
			left_arm = arm
			left_leg = leg
		else:
			right_arm = arm
			right_leg = leg
	if warrior == 1:
		Art.box(model, Vector3(0, 1.75, -0.27), Vector3(0.81, 0.65, 0.09), Color("eee9d8"))
		Art.box(model, Vector3(0, 1.60, -0.33), Vector3(0.56, 0.26, 0.035), Color("c7a56b"))
	else:
		Art.ball(model, Vector3(0.23, 1.83, -0.27), 0.13, Color("f9eed9"))
	hair_root = Node3D.new()
	model.add_child(hair_root)
	refresh_form()
	animation_player = AnimationPlayer.new()
	model.add_child(animation_player)
	var library := AnimationLibrary.new()
	var idle := Animation.new()
	idle.length = 1.2
	idle.loop_mode = Animation.LOOP_LINEAR
	var track := idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(track, NodePath(".:position:y"))
	idle.track_insert_key(track, 0.0, 0.0)
	idle.track_insert_key(track, 0.6, 0.035)
	idle.track_insert_key(track, 1.2, 0.0)
	library.add_animation("breathing", idle)
	animation_player.add_animation_library("", library)
	animation_player.play("breathing")
	install_rig()
	if is_instance_valid(charge_orb): charge_orb.queue_free()
	charge_orb = Art.ball(self, Vector3(0, 1.6, -1.2), 0.35, Color.CYAN, 1)
	charge_orb.material_override = EnergyFX.aura_material(Color.CYAN)
	charge_orb.visible = false
	if is_instance_valid(lightning): lightning.queue_free()
	lightning = MeshInstance3D.new()
	lightning.mesh = ImmediateMesh.new()
	lightning.material_override = Art.material(Color("c4deff"), 1.0)
	add_child(lightning)

func refresh_form() -> void:
	for child in hair_root.get_children():
		hair_root.remove_child(child)
		child.queue_free()
	var info := Roster.form(warrior, form_index)
	var color: Color = info.hair
	Art.ball(hair_root, Vector3(0, 2.64, 0.02), 0.37, color)
	var count := 7 if warrior == 0 else 9
	for i in count:
		var angle: float = float(i) / count * TAU
		var height := 0.94 if warrior == 1 else 0.76
		var loc := Vector3(cos(angle) * 0.26, 2.88 + 0.10 * sin(angle), sin(angle) * 0.24)
		Art.spike(hair_root, loc, height, color, Vector3(sin(angle) * 12, i * 27, cos(angle) * -14) if warrior == 1 else Vector3(sin(angle) * 42, i * 27, cos(angle) * -55))
	if Roster.forms(warrior)[form_index] == "Super Saiyan 3":
		for i in 6:
			Art.spike(hair_root, Vector3(0, 2.4 - i * 0.18, 0.35 + i * 0.07), 1.0, color, Vector3(35, i * 50, 20))
	if is_instance_valid(aura_particles):
		aura_particles.queue_free()
	if is_instance_valid(aura):
		aura.queue_free()
	var aura_color: Color = info.aura
	aura_color.a = 0.12
	aura = Art.ball(self, Vector3(0, 1.65, 0), 1.0, aura_color, 0.7)
	aura.scale = Vector3(0.95, 1.95, 0.85)
	aura.visible = form_index > 0
	aura.material_override = EnergyFX.aura_material(info.aura)
	aura_particles = EnergyFX.particles(self, info.aura, 0.65, 32)
	aura_particles.position.y = 0.6
	aura_particles.emitting = form_index > 0
	update_rig_hair()

func _physics_process(delta: float) -> void:
	animation_time += delta
	cooldown = maxf(0, cooldown - delta)
	stunned = maxf(0, stunned - delta)
	invincible = maxf(0, invincible - delta)
	combo_time -= delta
	if combo_time <= 0:
		combo = 0
	if not active:
		return
	if health <= 0:
		play_rig("defeat")
		model.rotation.z = lerpf(model.rotation.z, PI / 2, delta * 5)
		return
	guard_age = guard_age + delta if guarding else 0.0
	var info := Roster.form(warrior, form_index)
	ki = clampf(ki + (19.0 if charging else 1.5 - info.drain) * delta, 0, 100)
	stamina = minf(100, stamina + delta * info.stamina_regen)
	health = maxf(1.0, health - info.strain * delta) if info.strain > 0 else health
	fury = maxf(0, fury - delta * 0.025)
	attack_animation_time = maxf(0, attack_animation_time - delta)
	landing_time = maxf(0, landing_time - delta)
	if not melee_pending.is_empty():
		if stunned > 0 or guarding:
			melee_pending.clear()
		else:
			melee_pending.remaining -= delta
			if melee_pending.remaining <= 0:
				resolve_melee()
	if ki <= 0 and form_index > 0:
		form_index = 0
		fury = 0
		refresh_form()
	if transform_time > 0:
		transform_time -= delta
		aura.visible = true
		aura.scale.x = 1.2 + sin(animation_time * 35) * 0.2
	if pending != null:
		windup -= delta
		if windup <= 0:
			var attack := pending
			pending = null
			attack_animation = "sphere_release" if attack.kind == "sphere" else "ki_blast" if attack.kind == "blast" else "rush" if attack.kind == "rush" else "vanish" if attack.kind == "teleport" else "beam_release"
			attack_animation_time = attack.recovery
			play_rig(attack_animation, true)
			launched.emit(self, attack)
	if knocked_airborne:
		motion.y -= 22.0 * delta
	var falling_speed := motion.y
	var previous_height := position.y
	position += motion * delta
	if knocked_airborne and position.y <= 0 and previous_height > 0:
		knocked_airborne = false
		landing_time = 0.3
		cooldown = maxf(cooldown, 0.18)
		motion.y = 0
		landed.emit(self, absf(falling_speed))
	var vertical_speed := motion.y
	motion = motion.move_toward(Vector3.ZERO, delta * 19)
	if knocked_airborne: motion.y = vertical_speed
	position.x = clampf(position.x, -36, 36)
	position.z = clampf(position.z, -36, 36)
	position.y = clampf(position.y, 0, 17)
	if is_instance_valid(target) and stunned <= 0:
		var aim := Vector3(target.position.x, position.y, target.position.z)
		if position.distance_squared_to(aim) > 0.01:
			look_at(aim, Vector3.UP)
	animate(delta)

func animate(delta: float) -> void:
	update_rig_animation()
	update_energy_details()
	var moving := Vector2(motion.x, motion.z).length() > 0.3
	var stride: float = sin(animation_time * 13) * 0.65 if moving and position.y < 0.2 else 0.0
	left_leg.rotation.x = lerpf(left_leg.rotation.x, stride, delta * 15)
	right_leg.rotation.x = lerpf(right_leg.rotation.x, -stride, delta * 15)
	kick_pose = maxf(0, kick_pose - delta * 4)
	right_leg.rotation.x -= kick_pose * 1.4
	attack_pose = maxf(0, attack_pose - delta * 5)
	var pose: float = -1.6 * attack_pose
	if pending != null or charging or transform_time > 0:
		pose = -1.1 if pending == null or pending.kind != "sphere" else -2.9
	if guarding:
		pose = -1.5
	left_arm.rotation.x = lerpf(left_arm.rotation.x, pose - stride * 0.4, delta * 18)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, pose + stride * 0.4, delta * 18)
	model.rotation.x = lerpf(model.rotation.x, -0.18 if moving else 0.0, delta * 5)
	aura.visible = form_index > 0 or charging or pending != null or transform_time > 0
	aura_particles.emitting = aura.visible
	aura.material_override.set_shader_parameter("intensity", 1.8 if charging or transform_time > 0 else 1.0)
	aura.rotation.y += delta * 2
	aura.scale.z = 0.8 + sin(animation_time * 11) * 0.08

func can_act() -> bool:
	return active and health > 0 and cooldown <= 0 and stunned <= 0 and pending == null and transform_time <= 0 and melee_pending.is_empty()

func move_input(direction: Vector3, delta: float) -> void:
	if stunned > 0 or pending != null or transform_time > 0 or health <= 0:
		return
	var speed: float = 9.0 * Roster.form(warrior, form_index).speed
	if guarding or charging:
		speed *= 0.25
	motion += direction.limit_length() * speed * delta * 16
	motion = motion.limit_length(speed)

func melee(heavy: bool = false, grapple: bool = false, strength: float = 1.0) -> bool:
	if not can_act() or not is_instance_valid(target):
		return false
	cooldown = 0.52 if heavy else 0.28
	action_duration = cooldown
	if heavy:
		kick_pose = 1.0
	attack_pose = 1.0
	charging = false
	attack_animation = "grapple" if grapple else "kick" if heavy else ["punch", "hook", "uppercut"][combo % 3]
	attack_animation_time = cooldown
	play_rig(attack_animation, true)
	melee_pending = {"remaining": cooldown * 0.42, "heavy": heavy, "grapple": grapple, "strength": strength, "power": attack_power()}
	return true

func resolve_melee() -> void:
	var strike := melee_pending.duplicate()
	melee_pending.clear()
	if not is_instance_valid(target) or target.health <= 0 or health <= 0:
		return
	if position.distance_to(target.position) >= 3.4:
		return
	combo += 1
	combo_time = 1.5
	var damage: float = (12.0 if strike.heavy else 5.0) * strike.strength * strike.power
	var knock := (target.position - position).normalized() * (18 if strike.heavy else 4)
	if strike.heavy: knock.y = 7
	elif combo % 3 == 0: knock.y = 4
	if strike.grapple:
		damage = 14 * strike.power
		target.guarding = false
		knock *= 1.6
	var before: float = target.health
	var perfect := target.take_hit(damage, knock)
	struck.emit(target, before - target.health, perfect)

func take_hit(amount: float, force: Vector3) -> bool:
	if invincible > 0 or health <= 0:
		return true
	var info := Roster.form(warrior, form_index)
	var evade_chance: float = info.evasion * (0.5 if ki < 20 else 1.0)
	if ki >= 8 and rng.randf() < evade_chance:
		ki -= 8
		invincible = 0.28
		attack_animation = "dodge"
		attack_animation_time = 0.28
		play_rig("dodge", true)
		position.x += rng.randf_range(-2.0, 2.0)
		if is_instance_valid(target) and position.distance_to(target.position) < 4:
			target.health = maxf(0, target.health - amount * 0.2)
			target.stunned = 0.15
		return true
	if guarding and stamina > 8:
		stamina -= 8
		if guard_age < 0.17:
			ki = minf(100, ki + 7)
			attack_animation = "parry"
			attack_animation_time = 0.24
			play_rig("parry", true)
			return true
		amount *= 0.18
		force *= 0.2
	amount *= info.defense
	health = maxf(0, health - amount)
	if info.name == "Ultra Ego":
		fury = minf(0.5, fury + amount / 200.0)
	attack_animation_time = 0
	melee_pending.clear()
	if force.y > 2: knocked_airborne = true
	stunned = 0.12 if guarding else 0.25
	pending = null
	motion += force
	return false

func can_cancel_special() -> bool:
	return active and health > 0 and stunned <= 0 and transform_time <= 0 and pending == null and melee_pending.is_empty() and combo > 0 and cooldown > 0 and cooldown <= 0.15

func special(attack: AttackDefinition, allow_cancel: bool = false) -> bool:
	if (not can_act() and not (allow_cancel and can_cancel_special())) or ki < special_cost(attack) or form_index < attack.minimum_form:
		return false
	ki -= special_cost(attack)
	pending = attack
	windup = attack.startup
	cooldown = attack.startup + attack.recovery
	action_duration = cooldown
	charging = false
	guarding = false
	return true

func transform(index: int) -> bool:
	if not can_act() or index == form_index or index < 0 or index >= Roster.forms(warrior).size():
		return false
	var cost := transformation_cost(index)
	if ki < cost: return false
	ki -= cost
	form_index = index
	fury = 0
	transform_time = 0.4 if index == 0 else 1.0 if "Instinct" in Roster.forms(warrior)[index] else 1.35
	cooldown = transform_time
	action_duration = cooldown
	refresh_form()
	transformed.emit(self)
	return true

func transformation_cost(index: int) -> float:
	return 0.0 if index == 0 else ceilf(10.0 + Roster.form(warrior, index).power * 5.0)

func vanish() -> bool:
	if not active or health <= 0 or ki < 15 or invincible > 0 or not is_instance_valid(target):
		return false
	ki -= 15
	stunned = 0
	pending = null
	melee_pending.clear()
	knocked_airborne = false
	position = target.position + target.basis.z * 2.5
	position.y = maxf(0, position.y)
	invincible = 0.45
	cooldown = 0.2
	action_duration = cooldown
	attack_animation = "vanish"
	attack_animation_time = 0.2
	play_rig("vanish", true)
	return true

func medium_attack() -> bool:
	if not can_act():
		return false
	var accepted := melee(false, false, 1.6)
	if accepted:
		cooldown = 0.38
		action_duration = cooldown
		melee_pending.remaining = cooldown * 0.42
		kick_pose = 0.6
		attack_animation = "medium"
		attack_animation_time = cooldown
		play_rig("medium", true)
	return accepted

func attack_power() -> float:
	return Roster.form(warrior, form_index).power * (1.0 + fury if Roster.forms(warrior)[form_index] == "Ultra Ego" else 1.0)

func special_cost(attack: AttackDefinition) -> float:
	return attack.cost * Roster.form(warrior, form_index).ki_cost

func install_rig() -> void:
	var scene: PackedScene = load("res://assets/models/goku.glb" if warrior == 0 else "res://assets/models/vegeta.glb")
	for child in model.get_children():
		if child is Node3D:
			child.visible = false
	rigged_model = scene.instantiate()
	model.add_child(rigged_model)
	var players := rigged_model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	rig_animation = players[0]
	animation_tree = AnimationTree.new()
	rigged_model.add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(rig_animation)
	var machine := AnimationNodeStateMachine.new()
	var states: Array[String] = []
	var playback_rates: Dictionary = {}
	for clip in rig_animation.get_animation_list():
		if clip == "RESET":
			continue
		var state: String = clip.get_file()
		if state in ["idle", "walk", "run", "sprint", "flight", "hover", "ascend", "descend", "guard", "charge", "beam", "final_flash", "sphere", "fall"]:
			rig_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		# Retiming retains Blender anticipation, impact and follow-through within recovery.
		var durations := {"punch": 0.28, "hook": 0.28, "uppercut": 0.28, "medium": 0.38, "kick": 0.52, "grapple": 0.28, "vanish": 0.2, "beam_release": 0.7, "sphere_release": 0.7, "ki_blast": 0.7, "parry": 0.24, "dodge": 0.28, "land": 0.3}
		var node := AnimationNodeAnimation.new()
		node.animation = clip
		if durations.has(state):
			# Scale playback without rewriting imported keys; in-place retiming can
			# collide with later keys when a clip is slowed down.
			var blend := AnimationNodeBlendTree.new()
			blend.add_node("clip", node)
			blend.add_node("speed", AnimationNodeTimeScale.new())
			blend.connect_node("speed", 0, "clip")
			blend.connect_node("output", 0, "speed")
			machine.add_node(state, blend)
			playback_rates[state] = rig_animation.get_animation(clip).length / durations[state]
		else:
			machine.add_node(state, node)
		states.append(state)
	for source in states:
		for target_state in states:
			if source != target_state:
				var transition := AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.045 if target_state in ["punch", "hook", "uppercut", "medium", "kick", "hit"] else 0.12
				machine.add_transition(source, target_state, transition)
	animation_tree.tree_root = machine
	for state in playback_rates:
		animation_tree.set("parameters/%s/speed/scale" % state, playback_rates[state])
	animation_tree.active = true
	rig_playback = animation_tree.get("parameters/playback")
	if machine.has_node("idle"):
		rig_playback.start("idle")
	rig_state = "idle"
	update_rig_hair()

func update_rig_hair() -> void:
	if not is_instance_valid(rigged_model):
		return
	var form_title: String = Roster.forms(warrior)[form_index]
	var width := 1.12 if form_title == "Super Vegeta" else 1.07 if form_title == "Blue Evolution" else 0.96 if form_title == "Super Saiyan God" else 1.0
	rigged_model.scale = Vector3(width, 1, width)
	for mesh in rigged_model.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name) == "MajinMark": mesh.visible = form_title == "Majin Vegeta"
		if str(mesh.name).begins_with("HairStyle_"):
			mesh.visible = str(mesh.name) == "HairStyle_" + Roster.hair_style(warrior, form_index)
		for surface in mesh.mesh.get_surface_count():
			var mat: Material = mesh.mesh.surface_get_material(surface)
			if mat is StandardMaterial3D and (mat.resource_name.begins_with("Hair") or mat.resource_name.begins_with("Brows") or mat.resource_name.begins_with("Iris")):
				var changed: StandardMaterial3D = mat.duplicate()
				changed.albedo_color = Roster.form(warrior, form_index).hair
				if mat.resource_name.begins_with("Iris"):
					changed.albedo_color = Color("173028") if form_index == 0 or form_title == "Kaioken" else Color("28b594")
					if "Instinct" in form_title: changed.albedo_color = Color("a6b3ca")
					elif "God" in form_title: changed.albedo_color = Color("cb2a35")
					elif "Blue" in form_title: changed.albedo_color = Color("1687c8")
					elif "Ego" in form_title: changed.albedo_color = Color("9b31c9")
				if mat.resource_name.begins_with("Brows") and Roster.forms(warrior)[form_index] in ["Super Saiyan 3", "Ultra Ego"]:
					changed.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					changed.albedo_color.a = 0
				mesh.set_surface_override_material(surface, changed)

func play_rig(state: String, restart: bool = false) -> void:
	if rig_playback != null and (state != rig_state or restart) and animation_tree.tree_root.has_node(state):
		if state == rig_state and restart:
			rig_playback.start(state, true)
		else:
			rig_playback.travel(state)
		rig_state = state

func update_rig_animation() -> void:
	var state := "hover" if position.y > 0.2 else "idle"
	var horizontal_speed := Vector2(motion.x, motion.z).length()
	if horizontal_speed > 0.5:
		state = "flight" if position.y > 0.2 else "walk" if horizontal_speed < 3 else "sprint" if horizontal_speed > 10 else "run"
	if position.y > 0.2 and absf(motion.y) > 1:
		state = "ascend" if motion.y > 0 else "descend"
	if knocked_airborne: state = "fall"
	if charging: state = "charge"
	if guarding: state = "guard"
	if attack_animation_time > 0: state = attack_animation
	if pending != null:
		state = "sphere" if pending.kind == "sphere" else "rush" if pending.kind == "rush" else "vanish" if pending.kind == "teleport" else "ki_blast" if pending.kind == "blast" else "final_flash" if pending.title == "Final Flash" else "beam"
	if stunned > 0: state = "hit"
	if landing_time > 0: state = "land"
	if transform_time > 0:
		var form_title: String = Roster.forms(warrior)[form_index]
		state = "transform_calm" if "Instinct" in form_title or "God" in form_title else "transform_power" if form_title in ["Super Saiyan 3", "Ultra Ego", "Blue Evolution"] else "transform"
	play_rig(state)

func update_energy_details() -> void:
	if not is_instance_valid(charge_orb): return
	charge_orb.visible = pending != null and pending.kind not in ["rush", "teleport"]
	if charge_orb.visible:
		var gathering := clampf(1.0 - windup / maxf(pending.startup, 0.01), 0, 1)
		var overhead := pending.kind == "sphere" and warrior == 0
		charge_orb.position = Vector3(0, 3.9, 0) if overhead else Vector3(0, 1.65, -1.1)
		charge_orb.scale = Vector3.ONE * lerpf(0.35, 3.2 if overhead else 1.5, gathering)
		charge_orb.material_override.set_shader_parameter("energy_color", pending.color)
	var title: String = Roster.forms(warrior)[form_index]
	lightning.visible = title in ["Super Saiyan 2", "Blue Kaioken", "Blue Evolution", "Ultra Ego"] or transform_time > 0
	var step := int(animation_time * 12)
	if not lightning.visible or step == lightning_step: return
	lightning_step = step
	var mesh: ImmediateMesh = lightning.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for arc in 5:
		var angle: float = arc * TAU / 5 + step * 0.6
		var previous := Vector3(cos(angle) * 0.7, 0.1, sin(angle) * 0.7)
		for segment in range(1, 8):
			var radius: float = 0.7 + sin(segment * 17.0 + step * 3.0 + arc) * 0.18
			var point := Vector3(cos(angle + segment * 0.12) * radius, segment * 0.45, sin(angle + segment * 0.12) * radius)
			mesh.surface_add_vertex(previous)
			mesh.surface_add_vertex(point)
			previous = point
	mesh.surface_end()

func set_combat_paused(value: bool) -> void:
	set_physics_process(not value)
	process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
