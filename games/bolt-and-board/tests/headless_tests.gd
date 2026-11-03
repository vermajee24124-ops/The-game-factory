extends SceneTree

const Rules = preload("res://scripts/puzzle_rules.gd")

func _initialize() -> void:
	call_deferred("_run_tests")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("TEST FAILURE: " + message)
	quit(1)
	return false

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
	if not _expect(Rules.is_screw_accessible(Vector3(1.6, 0.17, 0.0), 1, states), "Outside upper-board footprint should be accessible"):
		return
	if not _expect(not Rules.is_screw_accessible(Vector3(0.0, 0.17, 0.0), 1, states), "Covered screw should be blocked"):
		return
	upper_board["removed"] = true
	if not _expect(Rules.is_screw_accessible(Vector3(0.0, 0.17, 0.0), 1, states), "Screw should unlock after upper board is removed"):
		return
	if not _expect(Rules.get_layer_count(1) == 2, "Level 1 should have two layers"):
		return
	if not _expect(Rules.get_layer_count(30) == 5, "High levels should cap at five layers"):
		return
	if not _expect(Rules.is_level_unlocked(1, 1), "The first level must always be unlocked"):
		return
	if not _expect(not Rules.is_level_unlocked(2, 1), "Future levels must remain locked"):
		return
	if not _expect(Rules.is_level_unlocked(3, 3), "Progress must unlock completed campaign levels"):
		return
	if not _expect(Rules.get_pattern_index(1, 0) != Rules.get_pattern_index(2, 0), "Consecutive levels should vary screw patterns"):
		return
	var screw_states := {"a": {"removed": true}, "b": {"removed": true}}
	if not _expect(Rules.is_board_cleared(["a", "b"], screw_states), "Board should clear when all screws are removed"):
		return
	screw_states["b"]["removed"] = false
	if not _expect(not Rules.is_board_cleared(["a", "b"], screw_states), "Board should remain until every screw is removed"):
		return

	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	if not _expect(scene != null, "Main scene must load"):
		return
	if not _expect(FileAccess.file_exists("res://assets/textures/wood_oak_normal.png"), "Wood normal map must be generated"):
		return
	if not _expect(FileAccess.file_exists("res://assets/textures/wood_oak_roughness.png"), "Wood roughness map must be generated"):
		return
	if not _expect(FileAccess.file_exists("res://assets/textures/brushed_steel_normal.png"), "Steel normal map must be generated"):
		return
	if not _expect(FileAccess.file_exists("res://assets/audio/match_clear.wav"), "Match-clear sound must be generated"):
		return
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.call("_on_play_pressed")
	await process_frame
	var boards: Array = game.get("boards")
	var screws: Dictionary = game.get("screws")
	if not _expect(boards.size() >= 2, "Playable level should contain multiple boards"):
		return
	if not _expect(screws.size() >= 8, "Playable level should contain screws"):
		return
	if not _expect(game.get("level_select_overlay") != null, "Level selection screen must be created"):
		return
	if not _expect(game.get("pause_overlay") != null, "Pause screen must be created"):
		return
	if not _expect(game.get("splash_overlay") != null, "Branded startup/loading screen must be created"):
		return
	if not _expect(game.get("tutorial_overlay") != null, "First-run tutorial must be created"):
		return
	if not _expect(game.get("timer_label") != null, "Gameplay must show an elapsed timer"):
		return
	var ui_root: Control = game.get("ui_root")
	if not _expect(ui_root.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Full-screen UI root must pass gameplay touches through"):
		return
	var touch_test_id := ""
	for screw_id in screws.keys():
		if game.call("_is_screw_accessible", screws[screw_id]):
			touch_test_id = str(screw_id)
			break
	if not _expect(not touch_test_id.is_empty(), "A starting-level screw must be accessible"):
		return
	var touch_screw: Dictionary = screws[touch_test_id]
	var touch_point: Vector2 = (game.get("camera") as Camera3D).unproject_position(touch_screw["position"] + Vector3(0.0, 0.12, 0.0))
	game.call("_handle_tap", touch_point)
	if not _expect(bool(screws[touch_test_id]["removed"]), "A simulated screen tap on an exposed screw must remove it"):
		return
	game.call("_load_level", 1)
	boards = game.get("boards")
	screws = game.get("screws")
	var toolbox_targets: Array = Rules.build_toolbox_targets([4, 2, 1, 0], 0, 4)
	if not _expect(toolbox_targets.size() == 3, "Toolbox targets should split color counts into batches of three"):
		return
	if not _expect(int(toolbox_targets[0]["goal"]) == 3 and int(toolbox_targets[1]["goal"]) == 1, "Final color batch may be smaller than three"):
		return
	var generated_targets: Array = game.get("toolbox_targets")
	var generated_capacity := 0
	for target in generated_targets:
		generated_capacity += int(target["goal"])
	if not _expect(generated_capacity == int(game.get("total_screws")), "Every level screw must belong to exactly one color toolbox"):
		return
	game.set("toolbox_targets", [{"color": 0, "goal": 1}, {"color": 1, "goal": 1}])
	game.set("toolbox_target_index", 0)
	game.set("toolbox_target_progress", 0)
	game.set("tray_colors", [])
	if not _expect(bool(game.call("_add_screw_to_tray", 1)), "A non-target color should enter temporary storage"):
		return
	if not _expect((game.get("tray_colors") as Array).size() == 1, "Temporary storage should retain a mismatched color"):
		return
	if not _expect(bool(game.call("_add_screw_to_tray", 0)), "A matching screw should fill the active toolbox"):
		return
	if not _expect(int(game.get("toolbox_target_index")) == 2, "A filled toolbox should advance and consume a buffered matching screw"):
		return
	if not _expect((game.get("tray_colors") as Array).is_empty(), "Buffered screws should auto-transfer when their toolbox becomes active"):
		return
	game.set("toolbox_targets", [{"color": 0, "goal": 9}])
	game.set("toolbox_target_index", 0)
	game.set("toolbox_target_progress", 0)
	game.set("tray_colors", [])
	for color_id in [1, 2, 3, 1, 2]:
		game.call("_add_screw_to_tray", color_id)
	if not _expect(bool(game.get("fail_overlay").visible), "Filling all five temporary slots must trigger the retry screen"):
		return
	game.call("_on_restart_pressed")
	if not _expect(not bool(game.get("fail_overlay").visible), "Retry should reset the full tray screen"):
		return
	boards = game.get("boards")
	screws = game.get("screws")
	game.call("_on_pause_pressed")
	if not _expect(bool(game.get("is_paused")), "Pause should stop gameplay input"):
		return
	game.call("_resume_game")
	if not _expect(bool(game.get("game_started")), "Resume should return to gameplay"):
		return
	var back_key := InputEventKey.new()
	back_key.pressed = true
	back_key.keycode = KEY_ESCAPE
	game.call("_unhandled_input", back_key)
	if not _expect(bool(game.get("is_paused")), "Android/escape back key should pause active gameplay"):
		return
	game.call("_unhandled_input", back_key)
	if not _expect(bool(game.get("game_started")), "Back key should resume from the pause overlay"):
		return
	var four_screw_pattern: Array = game.call("_build_screw_points", 4.0, 3.0, 0, 0)
	var six_screw_pattern: Array = game.call("_build_screw_points", 4.0, 3.0, 1, 0)
	if not _expect(four_screw_pattern.size() == 4, "Base pattern should have four corner screws"):
		return
	if not _expect(six_screw_pattern.size() == 6, "Pattern variation should add two side screws"):
		return
	var piece_specs: Array = game.call("_build_piece_specs", 4.0, 3.0, 1, 0)
	if not _expect(piece_specs.size() == 3, "The side-and-center layout should have three planks"):
		return
	var l_layout: Array = game.call("_build_piece_specs", 4.0, 3.0, 2, 0)
	var four_piece_layout: Array = game.call("_build_piece_specs", 4.0, 3.0, 1, 1)
	if not _expect(l_layout.size() == 3, "The L-shaped level layout should have three planks"):
		return
	if not _expect(four_piece_layout.size() == 4, "The four-corner layout should have four independent planks"):
		return
	game.set("tray_colors", [])
	for board_data in boards.duplicate():
		var board_screw_ids: Array = board_data["screws"].duplicate()
		for screw_id in board_screw_ids:
			var screw_state: Dictionary = screws[screw_id]
			screw_state["removed"] = true
			game.set("removed_screws", int(game.get("removed_screws")) + 1)
		game.call("_check_board_cleared", int(board_data["id"]))
		if not _expect(bool(board_data["clearing"]), "A cleared plate should enter its fall animation"):
			return
		game.call("_finish_board_clear", int(board_data["id"]))
		if not _expect(bool(board_data["removed"]), "A plate should unlock lower screws after its fall animation finishes"):
			return
	if not _expect(int(game.get("removed_screws")) == int(game.get("total_screws")), "Every screw should be removable in layer order"):
		return
	game.set("toolbox_target_index", (game.get("toolbox_targets") as Array).size())
	game.set("tray_colors", [])
	game.call("_check_level_complete")
	if not _expect(bool(game.get("finish_overlay").visible), "Level completion should show its result screen"):
		return
	if not _expect(str(game.get("next_level_button").text) == "NEXT LEVEL", "Normal levels should offer the next level"):
		return
	game.call("_on_next_pressed")
	if not _expect(int(game.get("level_index")) == 2, "Next should load the following level"):
		return
	if not _expect(int(game.get("highest_unlocked_level")) == 2, "Completing a level should unlock the next one"):
		return
	print("PASS: PBR assets, multi-piece layers, animated plate blocking, touch picking, color toolbox sorting, five-slot storage and campaign progression")
	quit(0)
