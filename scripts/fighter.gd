class_name Fighter
extends Node3D

signal struck(target, amount, perfect)
signal launched(actor, attack)
signal transformed(actor)

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
	stamina = minf(100, stamina + delta * 10)
	if ki <= 0 and form_index > 0:
		form_index = 0
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
			launched.emit(self, attack)
	position += motion * delta
	motion = motion.move_toward(Vector3.ZERO, delta * 19)
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
	return active and health > 0 and cooldown <= 0 and stunned <= 0 and pending == null and transform_time <= 0

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
	if heavy:
		kick_pose = 1.0
	attack_pose = 1.0
	charging = false
	if position.distance_to(target.position) < 3.4:
		combo += 1
		combo_time = 1.5
		var damage: float = (12.0 if heavy else 5.0) * strength * Roster.form(warrior, form_index).power
		var knock := (target.position - position).normalized() * (18 if heavy else 4)
		if heavy:
			knock.y = 7
		if grapple:
			damage = 14
			target.guarding = false
			knock *= 1.6
		var before: float = target.health
		var perfect := target.take_hit(damage, knock)
		struck.emit(target, before - target.health, perfect)
	return true

func take_hit(amount: float, force: Vector3) -> bool:
	if invincible > 0 or health <= 0:
		return true
	var info := Roster.form(warrior, form_index)
	if ki >= 8 and rng.randf() < info.evasion:
		ki -= 8
		invincible = 0.28
		position.x += rng.randf_range(-2.0, 2.0)
		if is_instance_valid(target) and position.distance_to(target.position) < 4:
			target.health = maxf(0, target.health - amount * 0.2)
			target.stunned = 0.15
		return true
	if guarding and stamina > 8:
		stamina -= 8
		if guard_age < 0.17:
			ki = minf(100, ki + 7)
			return true
		amount *= 0.18
		force *= 0.2
	health = maxf(0, health - amount)
	stunned = 0.12 if guarding else 0.25
	pending = null
	motion += force
	return false

func special(attack: AttackDefinition) -> bool:
	if not can_act() or ki < attack.cost or form_index < attack.minimum_form:
		return false
	ki -= attack.cost
	pending = attack
	windup = attack.startup
	cooldown = attack.startup + attack.recovery
	charging = false
	guarding = false
	return true

func transform(index: int) -> bool:
	if not can_act() or index == form_index or ki < 18 or index < 0 or index >= Roster.forms(warrior).size():
		return false
	ki -= 18
	form_index = index
	transform_time = 1.1 + index * 0.035
	cooldown = transform_time
	refresh_form()
	transformed.emit(self)
	return true

func vanish() -> bool:
	if not active or health <= 0 or ki < 15 or invincible > 0 or not is_instance_valid(target):
		return false
	ki -= 15
	stunned = 0
	pending = null
	position = target.position + target.basis.z * 2.5
	position.y = maxf(0, position.y)
	invincible = 0.45
	cooldown = 0.2
	return true

func medium_attack() -> bool:
	if not can_act():
		return false
	var accepted := melee(false, false, 1.6)
	if accepted:
		cooldown = 0.38
		kick_pose = 0.6
	return accepted

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
	for clip in rig_animation.get_animation_list():
		if clip == "RESET":
			continue
		var state: String = clip.get_file()
		if state in ["idle", "run", "flight", "guard", "charge"]:
			rig_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		var node := AnimationNodeAnimation.new()
		node.animation = clip
		machine.add_node(state, node)
		states.append(state)
	for source in states:
		for target_state in states:
			if source != target_state:
				var transition := AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.12
				machine.add_transition(source, target_state, transition)
	animation_tree.tree_root = machine
	animation_tree.active = true
	rig_playback = animation_tree.get("parameters/playback")
	if machine.has_node("idle"):
		rig_playback.start("idle")
	rig_state = "idle"
	update_rig_hair()

func update_rig_hair() -> void:
	if not is_instance_valid(rigged_model):
		return
	for mesh in rigged_model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var mat: Material = mesh.mesh.surface_get_material(surface)
			if mat is StandardMaterial3D and mat.resource_name.begins_with("Hair"):
				var changed: StandardMaterial3D = mat.duplicate()
				changed.albedo_color = Roster.form(warrior, form_index).hair
				mesh.set_surface_override_material(surface, changed)

func play_rig(state: String) -> void:
	if rig_playback != null and state != rig_state and animation_tree.tree_root.has_node(state):
		rig_playback.travel(state)
		rig_state = state

func update_rig_animation() -> void:
	var state := "idle"
	if motion.length() > 0.5:
		state = "run" if position.y < 0.2 else "flight"
	if charging: state = "charge"
	if guarding: state = "guard"
	if attack_pose > 0: state = "kick" if kick_pose > 0 else "punch"
	if pending != null: state = "beam"
	if stunned > 0: state = "hit"
	if transform_time > 0: state = "transform"
	play_rig(state)
