extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await process_frame
	game.sound.volume = 0
	game.start_match()
	var start := Time.get_ticks_msec()
	var next_action := 0
	var next_report := 0
	var next_form := 0
	var action_index := 0
	var matches := 1
	var peak_nodes := 0
	var actions := ["light","medium","heavy","blast","special","dash","charge","transform","ultimate"]
	while Time.get_ticks_msec() - start < 180000:
		await process_frame
		var elapsed := Time.get_ticks_msec() - start
		if not game.running:
			game.start_match();matches += 1
		game.player.move_input((game.enemy.position-game.player.position).normalized(), minf(process_frame_delta(),0.1))
		if elapsed >= next_action:
			game.held.erase("charge")
			game.press_action(actions[action_index % actions.size()])
			action_index += 1;next_action = elapsed + 400
		if elapsed >= next_form:
			game.player.ki = 100
			game.battle_form.select((game.battle_form.selected+1)%Roster.forms(game.player.warrior).size())
			next_form = elapsed + 10000
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		if elapsed >= next_report:
			print("SOAK seconds=",elapsed/1000," matches=",matches," actions=",action_index," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," objects=",Performance.get_monitor(Performance.OBJECT_COUNT)," memory=",Performance.get_monitor(Performance.MEMORY_STATIC)," fps=",Engine.get_frames_per_second())
			next_report = elapsed + 15000
	print("SOAK COMPLETE peak_nodes=",peak_nodes," matches=",matches," actions=",action_index)
	game.queue_free();await create_timer(.3).timeout;quit()
func process_frame_delta() -> float:
	return root.get_process_delta_time()
