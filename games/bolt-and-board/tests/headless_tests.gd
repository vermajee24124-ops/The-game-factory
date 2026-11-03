extends SceneTree

const Rules = preload("res://scripts/puzzle_rules.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var lower_board := {
		"id": 1, "center": Vector2.ZERO, "width": 4.0, "depth": 3.0,
		"y": 0.0, "removed": false
	}
	var upper_board := {
		"id": 2, "center": Vector2.ZERO, "width": 2.0, "depth": 2.0,
		"y": 0.46, "removed": false
	}
	var states: Array = [lower_board, upper_board]
	assert(Rules.is_screw_accessible(Vector3(1.6, 0.17, 0.0), 1, states), "Outside upper-board footprint should be accessible")
	assert(not Rules.is_screw_accessible(Vector3(0.0, 0.17, 0.0), 1, states), "Covered screw should be blocked")
	upper_board["removed"] = true
	assert(Rules.is_screw_accessible(Vector3(0.0, 0.17, 0.0), 1, states), "Screw should unlock after upper board is removed")
	assert(Rules.get_layer_count(1) == 2, "Level 1 should have two layers")
	assert(Rules.get_layer_count(30) == 5, "High levels should cap at five layers")
	assert(Rules.is_level_unlocked(1, 1), "The first level must always be unlocked")
	assert(not Rules.is_level_unlocked(2, 1), "Future levels must remain locked")
	assert(Rules.is_level_unlocked(3, 3), "Progress must unlock completed campaign levels")
	assert(Rules.get_pattern_index(1, 0) != Rules.get_pattern_index(2, 0), "Consecutive levels should vary screw patterns")
	var screw_states := {"a": {"removed": true}, "b": {"removed": true}}
	assert(Rules.is_board_cleared(["a", "b"], screw_states), "Board should clear when all screws are removed")
	screw_states["b"]["removed"] = false
	assert(not Rules.is_board_cleared(["a", "b"], screw_states), "Board should remain until every screw is removed")

	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	assert(scene != null, "Main scene must load")
	assert(FileAccess.file_exists("res://assets/textures/wood_oak_normal.png"), "Wood normal map must be generated")
	assert(FileAccess.file_exists("res://assets/textures/wood_oak_roughness.png"), "Wood roughness map must be generated")
	assert(FileAccess.file_exists("res://assets/textures/brushed_steel_normal.png"), "Steel normal map must be generated")
	assert(FileAccess.file_exists("res://assets/audio/match_clear.wav"), "Match-clear sound must be generated")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.call("_on_play_pressed")
	await process_frame
	var boards: Array = game.get("boards")
	var screws: Dictionary = game.get("screws")
	assert(boards.size() >= 2, "Playable level should contain multiple boards")
	assert(screws.size() >= 8, "Playable level should contain screws")
	assert(game.get("level_select_overlay") != null, "Level selection screen must be created")
	assert(game.get("pause_overlay") != null, "Pause screen must be created")
	assert(game.get("splash_overlay") != null, "Branded startup/loading screen must be created")
	assert(game.get("tutorial_overlay") != null, "First-run tutorial must be created")
	assert(game.get("timer_label") != null, "Gameplay must show an elapsed timer")
	var ui_root: Control = game.get("ui_root")
	assert(ui_root.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Full-screen UI root must pass gameplay touches through")
	var touch_test_id := ""
	for screw_id in screws.keys():
		if game.call("_is_screw_accessible", screws[screw_id]):
			touch_test_id = str(screw_id)
			break
	assert(not touch_test_id.is_empty(), "A starting-level screw must be accessible")
	var touch_screw: Dictionary = screws[touch_test_id]
	var touch_point: Vector2 = (game.get("camera") as Camera3D).unproject_position(touch_screw["position"] + Vector3(0.0, 0.12, 0.0))
	game.call("_handle_tap", touch_point)
	assert(bool(screws[touch_test_id]["removed"]), "A simulated screen tap on an exposed screw must remove it")
	game.call("_load_level", 1)
	boards = game.get("boards")
	screws = game.get("screws")
	var toolbox_targets: Array = Rules.build_toolbox_targets([4, 2, 1, 0], 0, 4)
	assert(toolbox_targets.size() == 3, "Toolbox targets should split color counts into batches of three")
	assert(int(toolbox_targets[0]["goal"]) == 3 and int(toolbox_targets[1]["goal"]) == 1, "Final color batch may be smaller than three")
	var generated_targets: Array = game.get("toolbox_targets")
	var generated_capacity := 0
	for target in generated_targets:
		generated_capacity += int(target["goal"])
	assert(generated_capacity == int(game.get("total_screws")), "Every level screw must belong to exactly one color toolbox")
	game.set("toolbox_targets", [{"color": 0, "goal": 1}, {"color": 1, "goal": 1}])
	game.set("toolbox_target_index", 0)
	game.set("toolbox_target_progress", 0)
	game.set("tray_colors", [])
	assert(bool(game.call("_add_screw_to_tray", 1)), "A non-target color should enter temporary storage")
	assert((game.get("tray_colors") as Array).size() == 1, "Temporary storage should retain a mismatched color")
	assert(bool(game.call("_add_screw_to_tray", 0)), "A matching screw should fill the active toolbox")
	assert(int(game.get("toolbox_target_index")) == 2, "A filled toolbox should advance and consume a buffered matching screw")
	assert((game.get("tray_colors") as Array).is_empty(), "Buffered screws should auto-transfer when their toolbox becomes active")
	game.set("toolbox_targets", [{"color": 0, "goal": 9}])
	game.set("toolbox_target_index", 0)
	game.set("toolbox_target_progress", 0)
	game.set("tray_colors", [])
	for color_id in [1, 2, 3, 1, 2]:
		game.call("_add_screw_to_tray", color_id)
	assert(bool(game.get("fail_overlay").visible), "Filling all five temporary slots must trigger the retry screen")
	game.call("_on_restart_pressed")
	assert(not bool(game.get("fail_overlay").visible), "Retry should reset the full tray screen")
	boards = game.get("boards")
	screws = game.get("screws")
	game.call("_on_pause_pressed")
	assert(bool(game.get("is_paused")), "Pause should stop gameplay input")
	game.call("_resume_game")
	assert(bool(game.get("game_started")), "Resume should return to gameplay")
	var back_key := InputEventKey.new()
	back_key.pressed = true
	back_key.keycode = KEY_ESCAPE
	game.call("_unhandled_input", back_key)
	assert(bool(game.get("is_paused")), "Android/escape back key should pause active gameplay")
	game.call("_unhandled_input", back_key)
	assert(bool(game.get("game_started")), "Back key should resume from the pause overlay")
	var four_screw_pattern: Array = game.call("_build_screw_points", 4.0, 3.0, 0, 0)
	var six_screw_pattern: Array = game.call("_build_screw_points", 4.0, 3.0, 1, 0)
	assert(four_screw_pattern.size() == 4, "Base pattern should have four corner screws")
	assert(six_screw_pattern.size() == 6, "Pattern variation should add two side screws")
	var piece_specs: Array = game.call("_build_piece_specs", 4.0, 3.0, 1, 0)
	assert(piece_specs.size() == 3, "The side-and-center layout should have three planks")
	var l_layout: Array = game.call("_build_piece_specs", 4.0, 3.0, 2, 0)
	var four_piece_layout: Array = game.call("_build_piece_specs", 4.0, 3.0, 1, 1)
	assert(l_layout.size() == 3, "The L-shaped level layout should have three planks")
	assert(four_piece_layout.size() == 4, "The four-corner layout should have four independent planks")
	game.set("tray_colors", [])
	for board_data in boards.duplicate():
		var board_screw_ids: Array = board_data["screws"].duplicate()
		for screw_id in board_screw_ids:
			var screw_state: Dictionary = screws[screw_id]
			screw_state["removed"] = true
			game.set("removed_screws", int(game.get("removed_screws")) + 1)
		game.call("_check_board_cleared", int(board_data["id"]))
		assert(bool(board_data["clearing"]), "A cleared plate should enter its fall animation")
		game.call("_finish_board_clear", int(board_data["id"]))
		assert(bool(board_data["removed"]), "A plate should unlock lower screws after its fall animation finishes")
	assert(int(game.get("removed_screws")) == int(game.get("total_screws")), "Every screw should be removable in layer order")
	game.set("toolbox_target_index", (game.get("toolbox_targets") as Array).size())
	game.set("tray_colors", [])
	game.call("_check_level_complete")
	assert(bool(game.get("finish_overlay").visible), "Level completion should show its result screen")
	assert(str(game.get("next_level_button").text) == "NEXT LEVEL", "Normal levels should offer the next level")
	game.call("_on_next_pressed")
	assert(int(game.get("level_index")) == 2, "Next should load the following level")
	assert(int(game.get("highest_unlocked_level")) == 2, "Completing a level should unlock the next one")
	print("PASS: PBR assets, multi-piece layers, animated plate blocking, touch picking, color toolbox sorting, five-slot storage and campaign progression")
	quit(0)
