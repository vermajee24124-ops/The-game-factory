extends SceneTree

func _init() -> void:
    assert(ResourceLoader.exists("res://project.godot"), "project.godot missing")
    assert(ResourceLoader.exists("res://scenes/Main.tscn"), "Main.tscn missing")
    assert(ResourceLoader.exists("res://scripts/main.gd"), "main.gd missing")
    var scene := load("res://scenes/Main.tscn")
    assert(scene != null, "Main scene could not be loaded")
    print("Pocket Board 3D smoke test passed")
    quit()
