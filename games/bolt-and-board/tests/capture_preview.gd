extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed: PackedScene = load("res://Main.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Main.tscn")
		quit(1)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game.call("start_preview")
	await process_frame
	await create_timer(1.2).timeout
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_viewport().get_texture().get_image()
	var result := image.save_png(output_dir.path_join("godot_preview.png"))
	if result != OK:
		push_error("Screenshot capture failed: %s" % result)
		quit(1)
		return
	print("Saved rendered preview to res://artifacts/godot_preview.png")
	quit(0)
