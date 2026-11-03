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
	assert(four_screw_pattern.size() == 2, "Base beam pattern should use two end screws")
	assert(six_screw_pattern.size() == 3, "Pattern variation should add one centre screw")
	var piece_specs: Array = game.call("_build_piece_specs", 4.0, 4.5, 1, 0)
	assert(piece_specs.size() == 4, "Interlocked campaign layouts must contain several beams")
	assert(game.get("toolbox_buttons").size() == 3, "Three colour sorting boxes must be available")
	assert(game.get("spare_slot_limit") == 5, "Spare tray must start with five slots")
	var angled_cover := {
		"id": 9, "center": Vector2.ZERO, "width": 4.0, "depth": 1.0,
		"y": 0.46, "rotation_y": PI * 0.25, "removed": false
	}
	var angled_states: Array = [lower_board, angled_cover]
	assert(not Rules.is_screw_accessible(Vector3(0.707, 0.17, -0.707), 1, angled_states), "Rotated upper beams must block covered screws")
	var safety_steps := 0
	while int(game.get("removed_screws")) < int(game.get("total_screws")) and safety_steps < 300:
		var selected_id := ""
		var current_screws: Dictionary = game.get("screws")
		for screw_id in current_screws.keys():
			var screw_state: Dictionary = current_screws[screw_id]
			if not bool(screw_state["removed"]) and bool(game.call("_is_screw_accessible", screw_state)):
				selected_id = str(screw_id)
				break
		assert(not selected_id.is_empty(), "There must always be a reachable screw until the puzzle is cleared")
		game.call("_try_remove_screw", selected_id)
		var tray_contents: Array = game.get("spare_screw_ids")
		if tray_contents.size() >= 4:
			for color_id in range(3):
				game.call("_on_toolbox_pressed", color_id)
		safety_steps += 1
	for color_id in range(3):
		game.call("_on_toolbox_pressed", color_id)
	boards = game.get("boards")
	assert(int(game.get("removed_screws")) == int(game.get("total_screws")), "Every screw must be collectable")
	assert(int(game.get("sorted_screws")) == int(game.get("total_screws")), "Every collected screw must be sortable into its matching colour box")
	assert((game.get("spare_screw_ids") as Array).is_empty(), "The spare tray must be empty at level completion")
	for board_data in boards:
		assert(bool(board_data["removed"]), "Every beam must fall after all of its screws are removed")
	assert(bool(game.get("finish_overlay").visible), "Level completion should show its result screen")
	assert(str(game.get("next_level_button").text) == "NEXT LEVEL", "Normal levels should offer the next level")
	game.call("_on_next_pressed")
	assert(int(game.get("level_index")) == 2, "Next should load the following level")
	assert(int(game.get("highest_unlocked_level")) == 2, "Completing a level should unlock the next one")
	print("PASS: puzzle rules, multi-piece layers, touch picking, startup flow, level locks, menus, pause/resume, completion and progression")
	quit(0)
