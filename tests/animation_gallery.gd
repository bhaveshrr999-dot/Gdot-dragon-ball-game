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
	for warrior in 2:
		actor = Fighter.new()
		actor.warrior = warrior
		scene.add_child(actor)
		actor.rotation.y = PI
		actor.animation_tree.active = false
		actor.aura_particles.emitting = false
		actor.aura_particles.visible = false
		var clips := actor.rig_animation.get_animation_list()
		var rows := ceili((clips.size() - 1) / 6.0)
		var atlas := Image.create(480 * 6, 480 * rows, false, Image.FORMAT_RGB8)
		var index := 0
		for clip in clips:
			if clip == "RESET": continue
			title.text = ("GOKU / " if warrior == 0 else "VEGETA / ") + clip
			actor.rig_animation.play(clip)
			actor.rig_animation.seek(actor.rig_animation.get_animation(clip).length * 0.42, true)
			actor.rig_animation.pause()
			await process_frame
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			frame.convert(Image.FORMAT_RGB8)
			frame.resize(480,480)
			atlas.blit_rect(frame, Rect2i(0,0,480,480), Vector2i((index % 6)*480,(index / 6)*480))
			index += 1
		atlas.save_png("/tmp/animation-atlas-%d.png" % warrior)
		print("Rendered ",index," distinct clips for warrior ",warrior)
		actor.queue_free()
		await process_frame
	scene.queue_free()
	await process_frame
	quit()
