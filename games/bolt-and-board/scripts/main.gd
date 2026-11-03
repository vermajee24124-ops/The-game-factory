extends Node3D

const PuzzleRules = preload("res://scripts/puzzle_rules.gd")
const MAX_LEVEL := 30
const SCREW_LAYER := 1
const BOARD_LAYER := 2

var camera: Camera3D
var game_root: Node3D
var boards: Array = []
var screws: Dictionary = {}
var level_index: int = 1
var total_screws: int = 0
var removed_screws: int = 0
var game_started: bool = false
var next_board_id: int = 0
var next_screw_id: int = 0
var highest_unlocked_level: int = 1
var current_hint_id: String = ""
var sfx_player: AudioStreamPlayer
var progress_bar: ProgressBar
var is_muted: bool = false

var ui_root: Control
var level_label: Label
var progress_label: Label
var status_label: Label
var menu_overlay: ColorRect
var finish_overlay: ColorRect
var level_select_overlay: ColorRect
var pause_overlay: ColorRect
var finish_title: Label
var finish_summary: Label
var next_level_button: Button
var menu_sound_button: Button
var pause_sound_button: Button
var pause_button: Button
var level_buttons: Array[Button] = []
var hint_button: Button
var is_paused: bool = false
var hints_used: int = 0
var level_elapsed: float = 0.0

var wood_materials: Array = []
var metal_material: StandardMaterial3D
var dark_metal_material: StandardMaterial3D
var blocked_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var hole_material: StandardMaterial3D
var floor_material: StandardMaterial3D


func _ready() -> void:
	_load_progress()
	_create_materials()
	_create_audio()
	_create_world()
	_create_camera()
	_create_game_root()
	_create_ui()
	_show_menu()


func _process(delta: float) -> void:
	if game_started and not is_paused:
		level_elapsed += delta


func _create_materials() -> void:
	for color_value in [Color("#9B6237"), Color("#B77A43"), Color("#85502F"), Color("#C18A50"), Color("#A66D3E")]:
		var wood := StandardMaterial3D.new()
		wood.albedo_color = color_value
		wood.roughness = 0.88
		wood.metallic = 0.0
		var wood_texture := load("res://assets/textures/wood_oak.png") as Texture2D
		if wood_texture != null:
			wood.albedo_texture = wood_texture
			wood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wood_materials.append(wood)

	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color("#C9D4DD")
	metal_material.metallic = 0.82
	metal_material.roughness = 0.24
	var steel_texture := load("res://assets/textures/brushed_steel.png") as Texture2D
	if steel_texture != null:
		metal_material.albedo_texture = steel_texture

	dark_metal_material = StandardMaterial3D.new()
	dark_metal_material.albedo_color = Color("#596675")
	dark_metal_material.metallic = 0.72
	dark_metal_material.roughness = 0.36

	blocked_material = StandardMaterial3D.new()
	blocked_material.albedo_color = Color("#65717B")
	blocked_material.metallic = 0.55
	blocked_material.roughness = 0.5

	gold_material = StandardMaterial3D.new()
	gold_material.albedo_color = Color("#FFD36A")
	gold_material.metallic = 0.78
	gold_material.roughness = 0.22

	hole_material = StandardMaterial3D.new()
	hole_material.albedo_color = Color("#24170F")
	hole_material.roughness = 1.0

	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color("#172534")
	floor_material.roughness = 0.95
	var floor_texture := load("res://assets/textures/dark_surface.png") as Texture2D
	if floor_texture != null:
		floor_material.albedo_texture = floor_texture


func _create_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)


func _play_sfx(sound_name: String) -> void:
	if is_muted or sfx_player == null:
		return
	var sound_path := "res://assets/audio/%s.wav" % sound_name
	if ResourceLoader.exists(sound_path):
		sfx_player.stop()
		sfx_player.stream = load(sound_path) as AudioStream
		sfx_player.play()


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#223346")
	style.border_color = Color("#52677A")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _style_button(button: Button, primary: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#D99B4A") if primary else Color("#344A5E")
	normal.border_color = Color("#F0C47A") if primary else Color("#647B8E")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(13)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#E9AD5C") if primary else Color("#405B72")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#B77A34") if primary else Color("#283D50")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#172333"))
	button.add_theme_color_override("font_hover_color", Color("#101B25"))
	button.add_theme_font_size_override("font_size", 18)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load("user://wood_metal_progress.cfg") == OK:
		highest_unlocked_level = clampi(int(config.get_value("progress", "highest_level", 1)), 1, MAX_LEVEL)
		is_muted = bool(config.get_value("settings", "muted", false))


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_level", highest_unlocked_level)
	config.set_value("settings", "muted", is_muted)
	config.save("user://wood_metal_progress.cfg")


func _toggle_sound() -> void:
	is_muted = not is_muted
	_save_progress()
	_update_sound_button_labels()
	if not is_muted:
		_play_sfx("ui_click")


func _update_sound_button_labels() -> void:
	var label_text := "SOUND: OFF" if is_muted else "SOUND: ON"
	if menu_sound_button != null:
		menu_sound_button.text = label_text
	if pause_sound_button != null:
		pause_sound_button.text = label_text


func start_preview() -> void:
	menu_overlay.visible = false
	finish_overlay.visible = false
	level_select_overlay.visible = false
	pause_overlay.visible = false
	is_paused = false
	game_started = true
	level_index = min(3, MAX_LEVEL)
	_load_level(level_index)


func _create_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#172333")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#B6C7D8")
	environment.ambient_light_energy = 0.65
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sunlight.light_energy = 1.35
	sunlight.shadow_enabled = true
	add_child(sunlight)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	floor_mesh.mesh = plane
	floor_mesh.material_override = floor_material
	floor_mesh.position = Vector3(0.0, -1.15, 0.0)
	add_child(floor_mesh)

	var platform := MeshInstance3D.new()
	var platform_box := BoxMesh.new()
	platform_box.size = Vector3(8.4, 0.32, 7.0)
	platform.mesh = platform_box
	var platform_mat := StandardMaterial3D.new()
	platform_mat.albedo_color = Color("#314253")
	platform_mat.roughness = 0.72
	platform.material_override = platform_mat
	platform.position = Vector3(0.0, -0.91, 0.0)
	add_child(platform)


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 9.5, 13.0)
	camera.fov = 43.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.35, 0.0), Vector3.UP)


func _create_game_root() -> void:
	game_root = Node3D.new()
	game_root.name = "GeneratedPuzzle"
	add_child(game_root)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_root)

	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _make_panel_style())
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 18.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = -18.0
	top_panel.offset_bottom = 100.0
	ui_root.add_child(top_panel)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_panel.add_child(top_row)

	level_label = Label.new()
	level_label.text = "LEVEL 1"
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 26)
	top_row.add_child(level_label)

	progress_label = Label.new()
	progress_label.text = "SCREWS 0/0"
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 18)
	top_row.add_child(progress_label)

	var restart_button := Button.new()
	restart_button.text = "RESTART"
	restart_button.custom_minimum_size = Vector2(112.0, 54.0)
	restart_button.pressed.connect(_on_restart_pressed)
	_style_button(restart_button, false)
	top_row.add_child(restart_button)

	pause_button = Button.new()
	pause_button.text = "PAUSE"
	pause_button.custom_minimum_size = Vector2(92.0, 54.0)
	pause_button.pressed.connect(_on_pause_pressed)
	_style_button(pause_button, false)
	top_row.add_child(pause_button)

	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style())
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 18.0
	bottom_panel.offset_top = -176.0
	bottom_panel.offset_right = -18.0
	bottom_panel.offset_bottom = -18.0
	ui_root.add_child(bottom_panel)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_box)

	status_label = Label.new()
	status_label.text = "Tap an exposed screw to remove it."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0.0, 48.0)
	status_label.add_theme_font_size_override("font_size", 17)
	bottom_box.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 14.0)
	bottom_box.add_child(progress_bar)

	hint_button = Button.new()
	hint_button.text = "HINT: SHOW AN EXPOSED SCREW"
	hint_button.custom_minimum_size = Vector2(0.0, 52.0)
	hint_button.pressed.connect(_on_hint_pressed)
	_style_button(hint_button, true)
	bottom_box.add_child(hint_button)

	menu_overlay = _make_overlay()
	ui_root.add_child(menu_overlay)
	var menu_center := CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(menu_center)
	var menu_panel := PanelContainer.new()
	menu_panel.add_theme_stylebox_override("panel", _make_panel_style())
	menu_panel.custom_minimum_size = Vector2(560.0, 470.0)
	menu_center.add_child(menu_panel)
	var menu_box := VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 18)
	menu_panel.add_child(menu_box)
	var title := Label.new()
	title.text = "WOOD & METAL\nPUZZLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	menu_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Remove the screws. Clear the boards."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	menu_box.add_child(subtitle)
	var play_button := Button.new()
	play_button.text = "CONTINUE"
	play_button.custom_minimum_size = Vector2(0.0, 64.0)
	play_button.add_theme_font_size_override("font_size", 25)
	play_button.pressed.connect(_on_play_pressed)
	_style_button(play_button, true)
	menu_box.add_child(play_button)

	var level_select_button := Button.new()
	level_select_button.text = "SELECT LEVEL"
	level_select_button.custom_minimum_size = Vector2(0.0, 54.0)
	level_select_button.pressed.connect(_show_level_select)
	_style_button(level_select_button, false)
	menu_box.add_child(level_select_button)

	menu_sound_button = Button.new()
	menu_sound_button.custom_minimum_size = Vector2(0.0, 48.0)
	menu_sound_button.pressed.connect(_toggle_sound)
	_style_button(menu_sound_button, false)
	menu_box.add_child(menu_sound_button)

	finish_overlay = _make_overlay()
	ui_root.add_child(finish_overlay)
	var finish_center := CenterContainer.new()
	finish_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish_overlay.add_child(finish_center)
	var finish_panel := PanelContainer.new()
	finish_panel.add_theme_stylebox_override("panel", _make_panel_style())
	finish_panel.custom_minimum_size = Vector2(540.0, 300.0)
	finish_center.add_child(finish_panel)
	var finish_box := VBoxContainer.new()
	finish_box.add_theme_constant_override("separation", 20)
	finish_panel.add_child(finish_box)
	finish_title = Label.new()
	finish_title.text = "LEVEL COMPLETE!"
	finish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_title.add_theme_font_size_override("font_size", 30)
	finish_box.add_child(finish_title)
	finish_summary = Label.new()
	finish_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finish_summary.add_theme_font_size_override("font_size", 18)
	finish_box.add_child(finish_summary)
	next_level_button = Button.new()
	next_level_button.text = "NEXT LEVEL"
	next_level_button.custom_minimum_size = Vector2(0.0, 68.0)
	next_level_button.add_theme_font_size_override("font_size", 24)
	next_level_button.pressed.connect(_on_next_pressed)
	_style_button(next_level_button, true)
	finish_box.add_child(next_level_button)
	finish_overlay.visible = false

	_create_level_select_overlay()
	_create_pause_overlay()
	_update_sound_button_labels()


func _create_level_select_overlay() -> void:
	level_select_overlay = _make_overlay()
	level_select_overlay.visible = false
	ui_root.add_child(level_select_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_select_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.custom_minimum_size = Vector2(620.0, 900.0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "CHOOSE A LEVEL"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	box.add_child(heading)
	var note := Label.new()
	note.text = "Complete a level to unlock the next one."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	box.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	level_buttons.clear()
	for level in range(1, MAX_LEVEL + 1):
		var level_button := Button.new()
		level_button.custom_minimum_size = Vector2(170.0, 72.0)
		level_button.text = "LEVEL %02d\n%s" % [level, "UNLOCKED" if PuzzleRules.is_level_unlocked(level, highest_unlocked_level) else "LOCKED"]
		level_button.disabled = not PuzzleRules.is_level_unlocked(level, highest_unlocked_level)
		level_button.pressed.connect(_on_level_selected.bind(level))
		_style_button(level_button, level == highest_unlocked_level)
		level_buttons.append(level_button)
		grid.add_child(level_button)
	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(0.0, 54.0)
	back_button.pressed.connect(_show_menu)
	_style_button(back_button, false)
	box.add_child(back_button)


func _create_pause_overlay() -> void:
	pause_overlay = _make_overlay()
	pause_overlay.visible = false
	ui_root.add_child(pause_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.custom_minimum_size = Vector2(540.0, 600.0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	box.add_child(heading)
	var resume_button := Button.new()
	resume_button.text = "RESUME"
	resume_button.custom_minimum_size = Vector2(0.0, 58.0)
	resume_button.pressed.connect(_resume_game)
	_style_button(resume_button, true)
	box.add_child(resume_button)
	var restart_button := Button.new()
	restart_button.text = "RESTART LEVEL"
	restart_button.custom_minimum_size = Vector2(0.0, 54.0)
	restart_button.pressed.connect(_on_restart_pressed)
	_style_button(restart_button, false)
	box.add_child(restart_button)
	pause_sound_button = Button.new()
	pause_sound_button.custom_minimum_size = Vector2(0.0, 54.0)
	pause_sound_button.pressed.connect(_toggle_sound)
	_style_button(pause_sound_button, false)
	box.add_child(pause_sound_button)
	var levels_button := Button.new()
	levels_button.text = "LEVEL SELECT"
	levels_button.custom_minimum_size = Vector2(0.0, 54.0)
	levels_button.pressed.connect(_show_level_select)
	_style_button(levels_button, false)
	box.add_child(levels_button)
	var menu_button := Button.new()
	menu_button.text = "MAIN MENU"
	menu_button.custom_minimum_size = Vector2(0.0, 54.0)
	menu_button.pressed.connect(_show_menu)
	_style_button(menu_button, false)
	box.add_child(menu_button)


func _make_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.025, 0.04, 0.82)
	return overlay


func _show_menu() -> void:
	menu_overlay.visible = true
	finish_overlay.visible = false
	level_select_overlay.visible = false
	pause_overlay.visible = false
	game_started = false
	is_paused = false
	status_label.text = "Remove exposed screws, clear the top board, then work downward."


func _show_level_select() -> void:
	for level in range(level_buttons.size()):
		var level_button: Button = level_buttons[level]
		var level_number: int = level + 1
		level_button.disabled = not PuzzleRules.is_level_unlocked(level_number, highest_unlocked_level)
		level_button.text = "LEVEL %02d\n%s" % [level_number, "UNLOCKED" if not level_button.disabled else "LOCKED"]
	menu_overlay.visible = false
	finish_overlay.visible = false
	pause_overlay.visible = false
	level_select_overlay.visible = true
	game_started = false
	is_paused = false


func _on_level_selected(selected_level: int) -> void:
	if not PuzzleRules.is_level_unlocked(selected_level, highest_unlocked_level):
		return
	_start_level(selected_level)


func _start_level(selected_level: int) -> void:
	level_index = clampi(selected_level, 1, MAX_LEVEL)
	menu_overlay.visible = false
	finish_overlay.visible = false
	level_select_overlay.visible = false
	pause_overlay.visible = false
	is_paused = false
	game_started = true
	_load_level(level_index)
	_play_sfx("ui_click")


func _resume_game() -> void:
	pause_overlay.visible = false
	is_paused = false
	game_started = true


func _on_pause_pressed() -> void:
	if not game_started:
		return
	game_started = false
	is_paused = true
	pause_overlay.visible = true
	_update_sound_button_labels()


func _on_play_pressed() -> void:
	_start_level(highest_unlocked_level)


func _on_restart_pressed() -> void:
	if game_started or is_paused:
		pause_overlay.visible = false
		is_paused = false
		game_started = true
		_load_level(level_index)
		_play_sfx("ui_click")


func _on_next_pressed() -> void:
	finish_overlay.visible = false
	if level_index >= MAX_LEVEL:
		_show_level_select()
		return
	level_index += 1
	highest_unlocked_level = maxi(highest_unlocked_level, level_index)
	_save_progress()
	_start_level(level_index)


func _load_level(number: int) -> void:
	for child in game_root.get_children():
		child.queue_free()
	boards.clear()
	screws.clear()
	total_screws = 0
	removed_screws = 0
	hints_used = 0
	level_elapsed = 0.0
	next_board_id = 0
	next_screw_id = 0
	finish_overlay.visible = false
	current_hint_id = ""

	var layer_count: int = PuzzleRules.get_layer_count(number)
	# Keep the full stack comfortably visible on small portrait screens.
	var zoom_step: float = float(layer_count - 2)
	camera.position = Vector3(0.0, 8.4 + zoom_step * 0.65, 11.6 + zoom_step * 0.85)
	camera.look_at(Vector3(0.0, 0.30 + zoom_step * 0.06, 0.0), Vector3.UP)
	for layer in range(layer_count):
		var width: float = 3.55 + float(layer) * 0.72 + float(number % 3) * 0.10
		var depth: float = 2.45 + float(layer) * 0.52 + float(number % 2) * 0.12
		var y: float = 0.22 + float(layer_count - 1 - layer) * 0.46
		var center_x: float = sin(float(number * 3 + layer) * 0.47) * 0.24
		var center_z: float = cos(float(number * 2 + layer) * 0.39) * 0.20
		_create_board(width, depth, y, center_x, center_z, layer, number)

	_update_hud()
	status_label.text = "Tap the bright exposed screws. Remove every screw from a board to clear it."
	_refresh_screw_visuals()


func _create_board(width: float, depth: float, y: float, center_x: float, center_z: float, layer: int, number: int) -> void:
	var board_id: int = next_board_id
	next_board_id += 1

	var board_node := Node3D.new()
	board_node.name = "WoodBoard_%02d" % board_id
	board_node.position = Vector3(center_x, y, center_z)
	game_root.add_child(board_node)

	var board_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.30, depth)
	board_mesh.mesh = box
	board_mesh.material_override = wood_materials[(layer + number) % wood_materials.size()]
	board_node.add_child(board_mesh)

	# A real collider prevents taps passing through a visible upper board.
	var board_body := StaticBody3D.new()
	board_body.name = "BoardOcclusionCollider"
	board_body.collision_layer = BOARD_LAYER
	board_body.collision_mask = 0
	var board_collision := CollisionShape3D.new()
	var board_shape := BoxShape3D.new()
	board_shape.size = Vector3(width, 0.30, depth)
	board_collision.shape = board_shape
	board_body.add_child(board_collision)
	board_node.add_child(board_body)

	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color("#5A3826")
	edge_mat.roughness = 0.9
	_add_box(board_node, Vector3(width, 0.055, 0.055), edge_mat, Vector3(0.0, 0.155, depth * 0.5 - 0.03))
	_add_box(board_node, Vector3(width, 0.055, 0.055), edge_mat, Vector3(0.0, 0.155, -depth * 0.5 + 0.03))
	_add_box(board_node, Vector3(0.055, 0.055, depth), edge_mat, Vector3(width * 0.5 - 0.03, 0.155, 0.0))
	_add_box(board_node, Vector3(0.055, 0.055, depth), edge_mat, Vector3(-width * 0.5 + 0.03, 0.155, 0.0))

	var board_data: Dictionary = {
		"id": board_id,
		"node": board_node,
		"center": Vector2(center_x, center_z),
		"width": width,
		"depth": depth,
		"y": y,
		"removed": false,
		"body": board_body,
		"screws": []
	}
	boards.append(board_data)

	var local_points := _build_screw_points(width, depth, number, layer)
	for point in local_points:
		var world_position := Vector3(center_x + point.x, y + 0.17, center_z + point.y)
		_create_screw(board_id, world_position)


func _build_screw_points(width: float, depth: float, level: int, layer: int) -> Array[Vector2]:
	var sx: float = width * 0.42
	var sz: float = depth * 0.40
	var points: Array[Vector2] = [
		Vector2(-sx, -sz), Vector2(sx, -sz),
		Vector2(-sx, sz), Vector2(sx, sz)
	]
	var pattern: int = posmod(level + layer * 2, 6)
	match pattern:
		1:
			points.append(Vector2(0.0, -sz))
			points.append(Vector2(0.0, sz))
		2:
			points.append(Vector2(-sx, 0.0))
			points.append(Vector2(sx, 0.0))
		3, 5:
			points.append(Vector2(0.0, -sz))
			points.append(Vector2(0.0, sz))
			points.append(Vector2(-sx, 0.0))
			points.append(Vector2(sx, 0.0))
			if pattern == 5:
				points.append(Vector2.ZERO)
		4:
			points.append(Vector2.ZERO)
	return points


func _add_box(parent: Node3D, size: Vector3, material: Material, local_position: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = local_position
	parent.add_child(mesh_instance)


func _create_screw(board_id: int, world_position: Vector3) -> void:
	var screw_id: String = "screw_%03d" % next_screw_id
	next_screw_id += 1

	var screw_root := Node3D.new()
	screw_root.name = screw_id
	screw_root.position = world_position
	game_root.add_child(screw_root)

	# A dark socket stays visible when the screw has been removed.
	var board_index_for_hole: int = _find_board_index(board_id)
	if board_index_for_hole >= 0:
		var owning_board: Dictionary = boards[board_index_for_hole]
		var owning_center: Vector2 = owning_board["center"]
		var hole := MeshInstance3D.new()
		var hole_mesh := CylinderMesh.new()
		hole_mesh.top_radius = 0.145
		hole_mesh.bottom_radius = 0.145
		hole_mesh.height = 0.018
		hole.mesh = hole_mesh
		hole.material_override = hole_material
		hole.position = Vector3(world_position.x - owning_center.x, 0.153, world_position.z - owning_center.y)
		(owning_board["node"] as Node3D).add_child(hole)

	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.055
	shaft_mesh.bottom_radius = 0.055
	shaft_mesh.height = 0.30
	shaft.mesh = shaft_mesh
	shaft.material_override = dark_metal_material
	shaft.position = Vector3(0.0, -0.08, 0.0)
	screw_root.add_child(shaft)
	for thread_index in range(4):
		var thread_ring := MeshInstance3D.new()
		var thread_mesh := CylinderMesh.new()
		thread_mesh.top_radius = 0.067
		thread_mesh.bottom_radius = 0.067
		thread_mesh.height = 0.018
		thread_mesh.radial_segments = 16
		thread_ring.mesh = thread_mesh
		thread_ring.material_override = metal_material
		thread_ring.position = Vector3(0.0, -0.205 + float(thread_index) * 0.065, 0.0)
		screw_root.add_child(thread_ring)

	var washer := MeshInstance3D.new()
	var washer_mesh := CylinderMesh.new()
	washer_mesh.top_radius = 0.19
	washer_mesh.bottom_radius = 0.19
	washer_mesh.height = 0.045
	washer.mesh = washer_mesh
	washer.material_override = dark_metal_material
	washer.position = Vector3(0.0, 0.015, 0.0)
	screw_root.add_child(washer)

	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.135
	head_mesh.bottom_radius = 0.135
	head_mesh.height = 0.105
	head_mesh.radial_segments = 12
	head.mesh = head_mesh
	head.material_override = metal_material
	head.position = Vector3(0.0, 0.09, 0.0)
	screw_root.add_child(head)

	var slot_mat := StandardMaterial3D.new()
	slot_mat.albedo_color = Color("#39434D")
	slot_mat.metallic = 0.65
	slot_mat.roughness = 0.5
	_add_box(screw_root, Vector3(0.15, 0.012, 0.027), slot_mat, Vector3(0.0, 0.147, 0.0))
	_add_box(screw_root, Vector3(0.027, 0.012, 0.15), slot_mat, Vector3(0.0, 0.148, 0.0))

	var area := Area3D.new()
	area.name = "TapArea"
	area.collision_layer = SCREW_LAYER
	area.collision_mask = 0
	area.set_meta("screw_id", screw_id)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.34
	collision.shape = sphere
	collision.position = Vector3(0.0, 0.04, 0.0)
	area.add_child(collision)
	screw_root.add_child(area)

	var board_index: int = _find_board_index(board_id)
	if board_index >= 0:
		boards[board_index]["screws"].append(screw_id)

	screws[screw_id] = {
		"id": screw_id,
		"node": screw_root,
		"head": head,
		"board_id": board_id,
		"position": world_position,
		"removed": false
	}
	total_screws += 1


func _find_board_index(board_id: int) -> int:
	for index in range(boards.size()):
		if int(boards[index]["id"]) == board_id:
			return index
	return -1


func _is_screw_accessible(screw: Dictionary) -> bool:
	return PuzzleRules.is_screw_accessible(screw["position"], int(screw["board_id"]), boards)


func _refresh_screw_visuals() -> void:
	for screw_id in screws.keys():
		var screw: Dictionary = screws[screw_id]
		if bool(screw["removed"]):
			continue
		var head: MeshInstance3D = screw["head"]
		if str(screw_id) == current_hint_id:
			head.material_override = gold_material
		elif _is_screw_accessible(screw):
			head.material_override = metal_material
		else:
			head.material_override = blocked_material


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK:
			if pause_overlay.visible:
				_resume_game()
			elif game_started:
				_on_pause_pressed()
			elif level_select_overlay.visible:
				_show_menu()
			elif finish_overlay.visible:
				_show_level_select()
			return
	if not game_started or is_paused or finish_overlay.visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)


func _handle_tap(screen_position: Vector2) -> void:
	var ray_origin: Vector3 = camera.project_ray_origin(screen_position)
	var ray_end: Vector3 = ray_origin + camera.project_ray_normal(screen_position) * 100.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = SCREW_LAYER | BOARD_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Object = result.get("collider")
	# The visible board collider blocks a touch before a hidden screw can be hit.
	if collider is Area3D:
		var hit_area: Area3D = collider as Area3D
		if hit_area.has_meta("screw_id"):
			_try_remove_screw(str(hit_area.get_meta("screw_id")))


func _try_remove_screw(screw_id: String) -> void:
	if not screws.has(screw_id):
		return
	var screw: Dictionary = screws[screw_id]
	if bool(screw["removed"]):
		return
	if not _is_screw_accessible(screw):
		status_label.text = "This screw is covered. Clear the upper board first."
		return

	screw["removed"] = true
	removed_screws += 1
	if current_hint_id == screw_id:
		current_hint_id = ""
	_play_sfx("screw_remove")
	var screw_node: Node3D = screw["node"]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(screw_node, "position", screw_node.position + Vector3(0.0, 1.1, 0.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(screw_node, "rotation:y", screw_node.rotation.y + TAU * 1.25, 0.30)
	tween.chain().tween_callback(Callable(screw_node, "queue_free"))

	status_label.text = "Nice! Screw removed. Find the other exposed screws."
	_update_hud()
	_check_board_cleared(int(screw["board_id"]))
	_refresh_screw_visuals()
	_check_level_complete()


func _check_board_cleared(board_id: int) -> void:
	var index: int = _find_board_index(board_id)
	if index < 0:
		return
	var board: Dictionary = boards[index]
	if bool(board["removed"]):
		return
	if not PuzzleRules.is_board_cleared(board["screws"], screws):
		return

	board["removed"] = true
	var board_body: StaticBody3D = board["body"]
	board_body.collision_layer = 0
	board_body.collision_mask = 0
	var board_node: Node3D = board["node"]
	_play_sfx("board_clear")
	var fall_tween := create_tween()
	fall_tween.set_parallel(true)
	fall_tween.tween_property(board_node, "position:y", board_node.position.y - 2.8, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(board_node, "rotation", Vector3(0.55, 0.0, 0.28), 0.75)
	fall_tween.chain().tween_callback(Callable(board_node, "queue_free"))
	status_label.text = "Board cleared! Hidden screws are now exposed."


func _check_level_complete() -> void:
	for board in boards:
		if not bool(board["removed"]):
			return
	game_started = false
	is_paused = false
	highest_unlocked_level = maxi(highest_unlocked_level, mini(level_index + 1, MAX_LEVEL))
	_save_progress()
	_play_sfx("level_complete")
	var stars: int = 3 if hints_used == 0 else (2 if hints_used <= 2 else 1)
	var star_text := "★".repeat(stars) + "☆".repeat(3 - stars)
	finish_title.text = "LEVEL %d COMPLETE!" % level_index
	finish_summary.text = "%s\nHints used: %d   Time: %s" % [star_text, hints_used, _format_time(level_elapsed)]
	next_level_button.text = "LEVEL SELECT" if level_index >= MAX_LEVEL else "NEXT LEVEL"
	finish_overlay.visible = true
	status_label.text = "Great work!"


func _on_hint_pressed() -> void:
	current_hint_id = ""
	for screw_id in screws.keys():
		var screw: Dictionary = screws[screw_id]
		if not bool(screw["removed"]) and _is_screw_accessible(screw):
			current_hint_id = str(screw_id)
			hints_used += 1
			var head: MeshInstance3D = screw["head"]
			head.material_override = gold_material
			status_label.text = "Hint: tap the glowing gold screw."
			_play_sfx("ui_click")
			return
	status_label.text = "No available screw found."


func _format_time(seconds: float) -> String:
	var whole_seconds: int = maxi(0, int(seconds))
	return "%02d:%02d" % [int(whole_seconds / 60), whole_seconds % 60]


func _update_hud() -> void:
	level_label.text = "LEVEL %d" % level_index
	progress_label.text = "SCREWS %d/%d" % [removed_screws, total_screws]
	if progress_bar != null:
		progress_bar.value = 100.0 if total_screws <= 0 else (float(removed_screws) / float(total_screws)) * 100.0
