extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1.0).timeout
	root.get_texture().get_image().save_png("/tmp/warriors-menu.png")
	game.mode_select.select(1)
	game.start_match()
	await create_timer(2.0).timeout
	root.get_texture().get_image().save_png("/tmp/warriors-battle.png")
	print("Rendered menu and gameplay. Desktop FPS: ", Engine.get_frames_per_second())
	game.queue_free()
	await create_timer(0.2).timeout
	quit()
