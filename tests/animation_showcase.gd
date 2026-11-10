extends SceneTree
var scene: Node3D
var actor: Fighter
var camera: Camera3D
var title: Label
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(480, 480)
	scene = Node3D.new()
	root.add_child(scene)
	camera = Camera3D.new()
	camera.position = Vector3(3.8, 2.6, 5.5)
	scene.add_child(camera)
	camera.look_at(Vector3(0, 1.65, 0))
	camera.fov = 38
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -25, 0)
	key.light_energy = 0.8
	scene.add_child(key)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("263647")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.6
	scene.add_child(world)
	var layer := CanvasLayer.new()
	scene.add_child(layer)
	title = Label.new()
	title.position = Vector2(15, 15)
	title.add_theme_font_size_override("font_size", 24)
	layer.add_child(title)
	var sequence := [["idle",.6],["punch",.28],["idle",.2],["hook",.28],["idle",.2],["uppercut",.28],["idle",.2],["kick",.52],["guard",.6],["parry",.24],["charge",.8],["beam",.8],["beam_release",.7],["hover",.6],["flight",.6],["land",.3],["transform_power",1.3],["transform_calm",1.3],["sphere",.8],["sphere_release",.7],["victory",1.3]]
	for warrior in 2:
		actor = Fighter.new();actor.warrior = warrior;scene.add_child(actor)
		actor.rotation.y = PI
		actor.aura_particles.visible = false
		for entry in sequence:
			title.text = ("GOKU / " if warrior == 0 else "VEGETA / ") + entry[0]
			actor.play_rig(entry[0], true)
			await create_timer(entry[1]).timeout
		actor.queue_free();await process_frame
	scene.queue_free();await process_frame;quit()
