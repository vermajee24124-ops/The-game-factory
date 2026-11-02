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
	var top_screws: Array = boards[0]["screws"].duplicate()
	for screw_id in top_screws:
		game.call("_try_remove_screw", str(screw_id))
	assert(bool(boards[0]["removed"]), "Top board should clear after all its screws are removed")
	var lower_screws: Array = boards[1]["screws"].duplicate()
	for screw_id in lower_screws:
		game.call("_try_remove_screw", str(screw_id))
	assert(bool(boards[1]["removed"]), "Lower board should clear after upper board is removed")
	assert(int(game.get("removed_screws")) == int(game.get("total_screws")), "Every screw should be removable in sequence")
	print("PASS: puzzle rules, level bounds, scene load, gameplay initialization and full level clear")
	quit(0)
