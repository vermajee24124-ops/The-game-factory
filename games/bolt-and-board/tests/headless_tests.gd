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
	var top_screws: Array = boards[0]["screws"].duplicate()
	for screw_id in top_screws:
		game.call("_try_remove_screw", str(screw_id))
	assert(bool(boards[0]["removed"]), "Top board should clear after all its screws are removed")
	var lower_screws: Array = boards[1]["screws"].duplicate()
	for screw_id in lower_screws:
		game.call("_try_remove_screw", str(screw_id))
	assert(bool(boards[1]["removed"]), "Lower board should clear after upper board is removed")
	assert(int(game.get("removed_screws")) == int(game.get("total_screws")), "Every screw should be removable in sequence")
	assert(bool(game.get("finish_overlay").visible), "Level completion should show its result screen")
	assert(str(game.get("next_level_button").text) == "NEXT LEVEL", "Normal levels should offer the next level")
	game.call("_on_next_pressed")
	assert(int(game.get("level_index")) == 2, "Next should load the following level")
	assert(int(game.get("highest_unlocked_level")) == 2, "Completing a level should unlock the next one")
	print("PASS: puzzle rules, level locks, pattern variation, menus, pause/resume, level completion and progression")
	quit(0)
