extends SceneTree

var game_root: Node

func _init() -> void:
    assert(ResourceLoader.exists("res://project.godot"), "project.godot missing")
    assert(ResourceLoader.exists("res://scenes/Main.tscn"), "Main.tscn missing")
    assert(ResourceLoader.exists("res://scripts/main.gd"), "main.gd missing")
    assert(ResourceLoader.exists("res://scripts/pocket_board_game.gd"), "pocket_board_game.gd missing")

    var scene := load("res://scenes/Main.tscn")
    assert(scene != null, "Main scene could not be loaded")

    game_root = scene.instantiate()
    root.add_child(game_root)
    await process_frame
    await process_frame

    var pieces = game_root.get("pieces")
    assert(pieces is Array, "Piece collection missing")
    assert(pieces.size() == 19, "Expected exactly 19 playable pieces, got %d" % pieces.size())
    assert(is_instance_valid(game_root.get("striker")), "Striker was not created")

    print("Pocket Board 3D smoke test passed: scene, striker, and 19-piece rack initialized")
    game_root.queue_free()
    quit()
