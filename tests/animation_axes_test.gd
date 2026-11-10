extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, title: String) -> void:
	checks += 1; print(("PASS: " if ok else "FAIL: ") + title)
	if not ok: failures += 1
func pose(actor: Fighter, clip: String, phase: float) -> void:
	actor.rig_animation.play(clip)
	actor.rig_animation.seek(actor.rig_animation.get_animation(clip).length * phase, true)
	actor.rig_animation.pause()
	await process_frame
func run() -> void:
	for warrior in 2:
		var actor := Fighter.new();actor.warrior = warrior;root.add_child(actor)
		actor.animation_tree.active = false
		var rig: Skeleton3D = actor.rigged_model.find_children("*","Skeleton3D",true,false)[0]
		var hand := rig.find_bone("handR" if warrior == 0 else "handL")
		var foot := rig.find_bone("footR")
		await pose(actor,"idle",0)
		var resting_hand := rig.get_bone_global_pose(hand).origin
		var resting_foot := rig.get_bone_global_pose(foot).origin
		await pose(actor,"punch",.42)
		var striking_hand := rig.get_bone_global_pose(hand).origin
		print("AXIS warrior=",warrior," idle hand=",resting_hand," strike=",striking_hand)
		check(striking_hand.z < resting_hand.z - .15,"warrior %d punches forward along local -Z" % warrior)
		await pose(actor,"kick",.42)
		check(rig.get_bone_global_pose(foot).origin.z < resting_foot.z - .35,"warrior %d kicks toward the target" % warrior)
		await pose(actor,"idle",0)
		check(rig.get_bone_global_pose(hand).origin.distance_to(resting_hand) < .01,"recovery restores resting hand without drift")
		var eye := rig.find_bone("eyeR")
		await pose(actor,"idle",73.0/90.0)
		print("BLINK scale=",rig.get_bone_pose_scale(eye)," length=",actor.rig_animation.get_animation("idle").length)
		check(rig.get_bone_pose_scale(eye).y < .2,"idle blink closes eyelid scale briefly")
		await pose(actor,"idle",.95)
		check(rig.get_bone_pose_scale(eye).y > .9,"blink reopens without sticking closed")
		actor.queue_free();await process_frame
	print("RESULT: %d checks / %d failures" % [checks,failures])
	quit(1 if failures else 0)
