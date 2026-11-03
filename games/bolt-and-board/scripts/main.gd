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
var screw_color_values: Array[Color] = [Color("#F05B48"), Color("#23A9B8"), Color("#F2B844")]
var screw_color_names: Array[String] = ["CORAL", "OCEAN", "GOLD"]
var screw_color_materials: Array[StandardMaterial3D] = []
var color_totals: Array[int] = [0, 0, 0]
var toolbox_filled: Array[int] = [0, 0, 0]
var toolbox_buttons: Array[Button] = []
var spare_screw_ids: Array[String] = []
var spare_slot_limit: int = 5
var spare_slot_labels: Array[Label] = []
var tray_label: Label
var sorted_screws: int = 0
var hammer_uses: int = 1
var extra_slot_used: bool = false
var hammer_button: Button
var extra_slot_button: Button
var tutorial_seen: bool = false
var splash_overlay: ColorRect
var tutorial_overlay: ColorRect
var splash_progress: ProgressBar
var splash_tween: Tween

var ui_root: Control
var level_label: Label
var progress_label: Label
var timer_label: Label
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
	_show_splash()


func _process(delta: float) -> void:
	if game_started and not is_paused:
		level_elapsed += delta
		if timer_label != null:
			timer_label.text = "TIME %s" % _format_time(level_elapsed)


func _create_materials() -> void:
	for color_value in [Color("#B77A43"), Color("#367FA2"), Color("#7B4934"), Color("#D6B985"), Color("#3D8A5C")]:
		var wood := StandardMaterial3D.new()
		wood.albedo_color = color_value
		wood.roughness = 0.88
		wood.metallic = 0.0
		var wood_texture := load("res://assets/textures/wood_oak.png") as Texture2D
		if wood_texture != null:
			wood.albedo_texture = wood_texture
			wood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wood_materials.append(wood)

	for screw_color in screw_color_values:
		var colored_metal := StandardMaterial3D.new()
		colored_metal.albedo_color = screw_color
		colored_metal.metallic = 0.62
		colored_metal.roughness = 0.23
		colored_metal.metallic_specular = 0.85
		screw_color_materials.append(colored_metal)

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
	floor_material.albedo_color = Color("#75634F")
	floor_material.roughness = 0.94
	var floor_texture := load("res://assets/textures/wood_oak.png") as Texture2D
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
	style.bg_color = Color("#6F4328")
	style.border_color = Color("#E7B66E")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _style_button(button: Button, primary: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#F6C66F") if primary else Color("#E8D0A0")
	normal.border_color = Color("#FFF0C2") if primary else Color("#A66B3C")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(13)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#FFDA8B") if primary else Color("#F6DDB0")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#D99A45") if primary else Color("#D2AE78")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#382114"))
	button.add_theme_color_override("font_hover_color", Color("#24150D"))
	button.add_theme_font_size_override("font_size", 18)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load("user://wood_metal_progress.cfg") == OK:
		highest_unlocked_level = clampi(int(config.get_value("progress", "highest_level", 1)), 1, MAX_LEVEL)
		is_muted = bool(config.get_value("settings", "muted", false))
		tutorial_seen = bool(config.get_value("settings", "tutorial_seen", false))


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_level", highest_unlocked_level)
	config.set_value("settings", "muted", is_muted)
	config.set_value("settings", "tutorial_seen", tutorial_seen)
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
	if splash_tween != null and splash_tween.is_valid():
		splash_tween.kill()
	splash_overlay.visible = false
	tutorial_overlay.visible = false
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
	environment.background_color = Color("#4D2E1D")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#FFE0B0")
	environment.ambient_light_energy = 1.02
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 0.96
	environment.adjustment_contrast = 1.06
	environment.adjustment_saturation = 0.90
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sunlight.light_energy = 1.28
	sunlight.shadow_enabled = true
	sunlight.shadow_bias = 0.08
	sunlight.directional_shadow_max_distance = 14.0
	add_child(sunlight)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-28.0, 145.0, 0.0)
	fill_light.light_color = Color("#FFE3B9")
	fill_light.light_energy = 0.48
	fill_light.shadow_enabled = false
	add_child(fill_light)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	floor_mesh.mesh = plane
	floor_mesh.material_override = floor_material
	floor_mesh.position = Vector3(0.0, -1.15, 0.0)
	add_child(floor_mesh)

	var platform := MeshInstance3D.new()
	var platform_box := BoxMesh.new()
	platform_box.size = Vector3(4.45, 0.42, 5.55)
	platform.mesh = platform_box
	var platform_mat := StandardMaterial3D.new()
	platform_mat.albedo_color = Color("#60412D")
	platform_mat.roughness = 0.72
	platform.material_override = platform_mat
	platform.position = Vector3(0.0, -0.18, 0.0)
	add_child(platform)

	var platform_top := MeshInstance3D.new()
	var platform_top_mesh := BoxMesh.new()
	platform_top_mesh.size = Vector3(4.28, 0.045, 5.38)
	platform_top.mesh = platform_top_mesh
	platform_top.material_override = wood_materials[0]
	platform_top.position = Vector3(0.0, 0.055, 0.0)
	add_child(platform_top)


func _create_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.2
	camera.position = Vector3(0.0, 13.5, 4.4)
	camera.current = true
	camera.near = 0.05
	camera.far = 60.0
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.55, 0.0), Vector3.UP)


func _create_game_root() -> void:
	game_root = Node3D.new()
	game_root.name = "GeneratedPuzzle"
	add_child(game_root)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The full-screen root is only a layout container. It must not swallow taps intended for the 3D puzzle.
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui_root)

	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _make_panel_style())
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 18.0
	top_panel.offset_top = 18.0
	top_panel.offset_right = -18.0
	top_panel.offset_bottom = 86.0
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

	timer_label = Label.new()
	timer_label.text = "TIME 00:00"
	timer_label.custom_minimum_size = Vector2(92.0, 0.0)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 16)
	top_row.add_child(timer_label)

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

	var toolbox_panel := PanelContainer.new()
	toolbox_panel.add_theme_stylebox_override("panel", _make_panel_style())
	toolbox_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolbox_panel.offset_left = 18.0
	toolbox_panel.offset_top = 98.0
	toolbox_panel.offset_right = -18.0
	toolbox_panel.offset_bottom = 188.0
	ui_root.add_child(toolbox_panel)

	var toolbox_row := HBoxContainer.new()
	toolbox_row.add_theme_constant_override("separation", 8)
	toolbox_panel.add_child(toolbox_row)
	toolbox_buttons.clear()
	for color_id in range(screw_color_values.size()):
		var toolbox_button := Button.new()
		toolbox_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toolbox_button.custom_minimum_size = Vector2(0.0, 68.0)
		toolbox_button.text = "%s\n0/0" % screw_color_names[color_id]
		toolbox_button.pressed.connect(_on_toolbox_pressed.bind(color_id))
		_style_toolbox_button(toolbox_button, screw_color_values[color_id])
		toolbox_buttons.append(toolbox_button)
		toolbox_row.add_child(toolbox_button)

	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style())
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 14.0
	bottom_panel.offset_top = -250.0
	bottom_panel.offset_right = -14.0
	bottom_panel.offset_bottom = -12.0
	ui_root.add_child(bottom_panel)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 4)
	bottom_panel.add_child(bottom_box)

	status_label = Label.new()
	status_label.text = "Tap an exposed screw, then sort it by colour."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0.0, 32.0)
	status_label.add_theme_font_size_override("font_size", 15)
	bottom_box.add_child(status_label)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 10.0)
	bottom_box.add_child(progress_bar)

	tray_label = Label.new()
	tray_label.text = "SPARE TRAY 0/5"
	tray_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_label.add_theme_font_size_override("font_size", 14)
	bottom_box.add_child(tray_label)

	var tray_row := HBoxContainer.new()
	tray_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(tray_row)
	spare_slot_labels.clear()
	for slot_index in range(6):
		var slot_label := Label.new()
		slot_label.text = "○"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.custom_minimum_size = Vector2(48.0, 30.0)
		slot_label.add_theme_font_size_override("font_size", 23)
		slot_label.add_theme_color_override("font_color", Color("#F6DCA8"))
		slot_label.visible = slot_index < spare_slot_limit
		spare_slot_labels.append(slot_label)
		tray_row.add_child(slot_label)

	var tool_row := HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(tool_row)

	hint_button = Button.new()
	hint_button.text = "HINT"
	hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_button.custom_minimum_size = Vector2(0.0, 46.0)
	hint_button.pressed.connect(_on_hint_pressed)
	_style_button(hint_button, true)
	tool_row.add_child(hint_button)

	hammer_button = Button.new()
	hammer_button.text = "HAMMER x1"
	hammer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hammer_button.custom_minimum_size = Vector2(0.0, 46.0)
	hammer_button.pressed.connect(_on_hammer_pressed)
	_style_button(hammer_button, false)
	tool_row.add_child(hammer_button)

	extra_slot_button = Button.new()
	extra_slot_button.text = "+1 SLOT"
	extra_slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extra_slot_button.custom_minimum_size = Vector2(0.0, 46.0)
	extra_slot_button.pressed.connect(_on_extra_slot_pressed)
	_style_button(extra_slot_button, false)
	tool_row.add_child(extra_slot_button)

	menu_overlay = _make_overlay()
	ui_root.add_child(menu_overlay)
	var menu_center := CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(menu_center)
	var menu_panel := PanelContainer.new()
	menu_panel.add_theme_stylebox_override("panel", _make_panel_style())
	menu_panel.custom_minimum_size = Vector2(560.0, 520.0)
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

	var tutorial_button := Button.new()
	tutorial_button.text = "HOW TO PLAY"
	tutorial_button.custom_minimum_size = Vector2(0.0, 50.0)
	tutorial_button.pressed.connect(_show_tutorial)
	_style_button(tutorial_button, false)
	menu_box.add_child(tutorial_button)

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
	_create_tutorial_overlay()
	_create_splash_overlay()
	_update_sound_button_labels()



func _create_splash_overlay() -> void:
	splash_overlay = ColorRect.new()
	splash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_overlay.color = Color("#160F0B")
	ui_root.add_child(splash_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.custom_minimum_size = Vector2(540.0, 390.0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var studio := Label.new()
	studio.text = "WOODWORKS STUDIO"
	studio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	studio.add_theme_font_size_override("font_size", 20)
	studio.add_theme_color_override("font_color", Color("#E6B76E"))
	box.add_child(studio)
	var title := Label.new()
	title.text = "BOLT & BOARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "3D SCREW PUZZLE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	box.add_child(subtitle)
	splash_progress = ProgressBar.new()
	splash_progress.min_value = 0.0
	splash_progress.max_value = 100.0
	splash_progress.value = 0.0
	splash_progress.show_percentage = false
	splash_progress.custom_minimum_size = Vector2(0.0, 18.0)
	box.add_child(splash_progress)
	var loading := Label.new()
	loading.text = "Preparing local game assets..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_font_size_override("font_size", 15)
	box.add_child(loading)


func _create_tutorial_overlay() -> void:
	tutorial_overlay = _make_overlay()
	tutorial_overlay.visible = false
	ui_root.add_child(tutorial_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.custom_minimum_size = Vector2(560.0, 520.0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "HOW TO PLAY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	box.add_child(heading)
	var instructions := Label.new()
	instructions.text = "1. Tap a bright, exposed screw to collect it.\n\n2. Collected screws wait in the five-space spare tray.\n\n3. Tap the matching colour box above the board to sort all screws of that colour.\n\n4. Clear every wooden beam and sort every screw to win."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 19)
	box.add_child(instructions)
	var continue_button := Button.new()
	continue_button.text = "LET'S PLAY"
	continue_button.custom_minimum_size = Vector2(0.0, 60.0)
	continue_button.pressed.connect(_close_tutorial)
	_style_button(continue_button, true)
	box.add_child(continue_button)


func _show_splash() -> void:
	menu_overlay.visible = false
	finish_overlay.visible = false
	level_select_overlay.visible = false
	pause_overlay.visible = false
	tutorial_overlay.visible = false
	splash_overlay.visible = true
	game_started = false
	is_paused = false
	if splash_tween != null and splash_tween.is_valid():
		splash_tween.kill()
	splash_progress.value = 0.0
	splash_tween = create_tween()
	splash_tween.tween_property(splash_progress, "value", 100.0, 1.15)
	splash_tween.tween_interval(0.18)
	splash_tween.tween_callback(_finish_splash)


func _finish_splash() -> void:
	if game_started or not splash_overlay.visible:
		return
	splash_overlay.visible = false
	if tutorial_seen:
		_show_menu()
	else:
		_show_tutorial()


func _show_tutorial() -> void:
	menu_overlay.visible = false
	finish_overlay.visible = false
	level_select_overlay.visible = false
	pause_overlay.visible = false
	splash_overlay.visible = false
	tutorial_overlay.visible = true
	game_started = false
	is_paused = false


func _close_tutorial() -> void:
	tutorial_seen = true
	_save_progress()
	tutorial_overlay.visible = false
	_show_menu()


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


func _style_toolbox_button(button: Button, color_value: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color_value
	normal.border_color = color_value.lightened(0.28)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.content_margin_left = 8.0
	normal.content_margin_right = 8.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color_value.lightened(0.16)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color_value.darkened(0.15)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#332015"))
	button.add_theme_color_override("font_hover_color", Color("#24150D"))
	button.add_theme_font_size_override("font_size", 17)


func _make_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.025, 0.04, 0.82)
	return overlay



func _show_menu() -> void:
	if splash_tween != null and splash_tween.is_valid():
		splash_tween.kill()
	splash_overlay.visible = false
	tutorial_overlay.visible = false
	menu_overlay.visible = true
	finish_overlay.visible = false
	level_select_overlay.visible = false
	pause_overlay.visible = false
	game_started = false
	is_paused = false
	status_label.text = "Remove exposed screws, clear the top board, then work downward."



func _show_level_select() -> void:
	splash_overlay.visible = false
	tutorial_overlay.visible = false
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
	if splash_tween != null and splash_tween.is_valid():
		splash_tween.kill()
	splash_overlay.visible = false
	tutorial_overlay.visible = false
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
	sorted_screws = 0
	hints_used = 0
	level_elapsed = 0.0
	next_board_id = 0
	next_screw_id = 0
	color_totals = [0, 0, 0]
	toolbox_filled = [0, 0, 0]
	spare_screw_ids.clear()
	spare_slot_limit = 5
	hammer_uses = 1
	extra_slot_used = false
	finish_overlay.visible = false
	current_hint_id = ""

	var layer_count: int = PuzzleRules.get_layer_count(number)
	# Orthographic framing keeps the interlocked board large and readable in portrait mode.
	camera.size = 8.1 + float(layer_count - 2) * 0.22
	camera.position = Vector3(0.0, 14.0 + float(layer_count - 2) * 0.35, 3.8)
	camera.look_at(Vector3(0.0, 0.55, 0.0), Vector3.UP)
	for layer in range(layer_count):
		var width: float = 3.35 + float(layer) * 0.10
		var depth: float = 4.45 + float(layer) * 0.10
		var y: float = 0.20 + float(layer_count - 1 - layer) * 0.43
		var center_x: float = sin(float(number * 3 + layer) * 0.47) * 0.12
		var center_z: float = cos(float(number * 2 + layer) * 0.39) * 0.12
		var piece_specs: Array = _build_piece_specs(width, depth, number, layer)
		for piece_index in range(piece_specs.size()):
			var piece: Dictionary = piece_specs[piece_index]
			_create_board(
				float(piece["width"]),
				float(piece["depth"]),
				y + float(piece_index % 3) * 0.055,
				center_x + float(piece["x"]),
				center_z + float(piece["z"]),
				layer,
				number + piece_index,
				float(piece.get("angle", 0.0))
			)

	_initialize_toolboxes()
	_update_hud()
	status_label.text = "Tap exposed screws, then sort them into the matching colour boxes."
	_refresh_screw_visuals()
	_update_sorting_ui()


func _build_piece_specs(width: float, depth: float, level: int, layer: int) -> Array:
	var specs: Array = []
	match posmod(level + layer, 4):
		0:
			# Interlocked H: two long rails with three cross braces.
			for x_offset in [-0.92, 0.92]:
				specs.append({"x": x_offset, "z": 0.0, "width": depth * 0.78, "depth": 0.58, "angle": PI * 0.5})
			for z_offset in [-1.23, 0.0, 1.23]:
				specs.append({"x": 0.0, "z": z_offset, "width": width * 0.82, "depth": 0.54, "angle": 0.0})
		1:
			# Crossing diagonals with two short locking braces.
			specs.append({"x": 0.0, "z": 0.0, "width": depth * 0.92, "depth": 0.62, "angle": PI * 0.25})
			specs.append({"x": 0.0, "z": 0.0, "width": width * 0.84, "depth": 0.62, "angle": -PI * 0.25})
			for z_offset in [-1.15, 1.15]:
				specs.append({"x": 0.0, "z": z_offset, "width": width * 0.62, "depth": 0.48, "angle": 0.0})
		2:
			# Crossed frame with a central diagonal lock.
			for z_offset in [-0.95, 0.95]:
				specs.append({"x": 0.0, "z": z_offset, "width": width * 0.95, "depth": 0.58, "angle": 0.0})
			for x_offset in [-0.82, 0.82]:
				specs.append({"x": x_offset, "z": 0.0, "width": depth * 0.78, "depth": 0.54, "angle": PI * 0.5})
			specs.append({"x": 0.0, "z": 0.0, "width": depth * 0.80, "depth": 0.42, "angle": PI * 0.20})
		3:
			# Zig-zag rails and a short horizontal bridge.
			specs.append({"x": -0.60, "z": -0.72, "width": depth * 0.72, "depth": 0.56, "angle": PI * 0.30})
			specs.append({"x": 0.60, "z": 0.72, "width": depth * 0.72, "depth": 0.56, "angle": PI * 0.30})
			specs.append({"x": 0.60, "z": -0.72, "width": depth * 0.72, "depth": 0.56, "angle": -PI * 0.30})
			specs.append({"x": -0.60, "z": 0.72, "width": depth * 0.72, "depth": 0.56, "angle": -PI * 0.30})
			specs.append({"x": 0.0, "z": 0.0, "width": width * 0.72, "depth": 0.48, "angle": 0.0})
	return specs


func _create_board(width: float, depth: float, y: float, center_x: float, center_z: float, layer: int, number: int, angle: float = 0.0) -> void:
	var board_id: int = next_board_id
	next_board_id += 1

	var board_node := Node3D.new()
	board_node.name = "WoodBoard_%02d" % board_id
	board_node.position = Vector3(center_x, y, center_z)
	board_node.rotation.y = angle
	game_root.add_child(board_node)

	var board_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.30, depth)
	board_mesh.mesh = box
	board_mesh.material_override = wood_materials[(layer + number) % wood_materials.size()]
	board_node.add_child(board_mesh)

	# Raised inset top and warm edge band create a finished toy-wood look.
	var top_face := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(maxf(0.1, width - 0.12), 0.035, maxf(0.1, depth - 0.12))
	top_face.mesh = top_box
	top_face.material_override = wood_materials[(layer + number + 1) % wood_materials.size()]
	top_face.position.y = 0.162
	board_node.add_child(top_face)

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
	edge_mat.albedo_color = Color("#704224")
	edge_mat.roughness = 0.84
	_add_box(board_node, Vector3(width - 0.10, 0.045, 0.045), edge_mat, Vector3(0.0, 0.186, depth * 0.5 - 0.03))
	_add_box(board_node, Vector3(width - 0.10, 0.045, 0.045), edge_mat, Vector3(0.0, 0.186, -depth * 0.5 + 0.03))
	_add_box(board_node, Vector3(0.045, 0.045, depth - 0.10), edge_mat, Vector3(width * 0.5 - 0.03, 0.186, 0.0))
	_add_box(board_node, Vector3(0.045, 0.045, depth - 0.10), edge_mat, Vector3(-width * 0.5 + 0.03, 0.186, 0.0))

	var board_data: Dictionary = {
		"id": board_id,
		"node": board_node,
		"center": Vector2(center_x, center_z),
		"width": width,
		"depth": depth,
		"y": y,
		"layer": layer,
		"rotation_y": angle,
		"removed": false,
		"body": board_body,
		"screws": []
	}
	boards.append(board_data)

	var local_points := _build_screw_points(width, depth, number, layer)
	for point in local_points:
		var world_position: Vector3 = board_node.to_global(Vector3(point.x, 0.17, point.y))
		_create_screw(board_id, world_position)


func _build_screw_points(width: float, depth: float, level: int, layer: int) -> Array[Vector2]:
	var sx: float = width * 0.40
	var sz: float = depth * 0.34
	# Two end fasteners form the base pattern; occasional centre/side fasteners add variety.
	var points: Array[Vector2] = [Vector2(-sx, 0.0), Vector2(sx, 0.0)]
	var pattern: int = posmod(level + layer * 2, 4)
	match pattern:
		1:
			points.append(Vector2.ZERO)
		2:
			points.append(Vector2(0.0, -sz))
			points.append(Vector2(0.0, sz))
		3:
			points.append(Vector2(0.0, -sz))
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
		var owning_node: Node3D = owning_board["node"]
		var hole := MeshInstance3D.new()
		var hole_mesh := CylinderMesh.new()
		hole_mesh.top_radius = 0.145
		hole_mesh.bottom_radius = 0.145
		hole_mesh.height = 0.018
		hole.mesh = hole_mesh
		hole.material_override = hole_material
		hole.position = owning_node.to_local(world_position) + Vector3(0.0, 0.015, 0.0)
		owning_node.add_child(hole)

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
	washer_mesh.top_radius = 0.155
	washer_mesh.bottom_radius = 0.155
	washer_mesh.height = 0.045
	washer.mesh = washer_mesh
	washer.material_override = dark_metal_material
	washer.position = Vector3(0.0, 0.015, 0.0)
	screw_root.add_child(washer)

	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.12
	head_mesh.bottom_radius = 0.12
	head_mesh.height = 0.085
	head_mesh.radial_segments = 24
	head.mesh = head_mesh
	var screw_color_id: int = posmod(board_id + level_index, screw_color_values.size())
	head.material_override = screw_color_materials[screw_color_id]
	head.position = Vector3(0.0, 0.09, 0.0)
	screw_root.add_child(head)

	var slot_mat := StandardMaterial3D.new()
	slot_mat.albedo_color = Color("#39434D")
	slot_mat.metallic = 0.65
	slot_mat.roughness = 0.5
	_add_box(screw_root, Vector3(0.12, 0.012, 0.022), slot_mat, Vector3(0.0, 0.132, 0.0))
	_add_box(screw_root, Vector3(0.022, 0.012, 0.12), slot_mat, Vector3(0.0, 0.133, 0.0))

	var area := Area3D.new()
	area.name = "TapArea"
	area.collision_layer = SCREW_LAYER
	area.collision_mask = 0
	area.set_meta("screw_id", screw_id)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
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
		"color_id": screw_color_id,
		"removed": false
	}
	color_totals[screw_color_id] += 1
	total_screws += 1


func _find_board_index(board_id: int) -> int:
	for index in range(boards.size()):
		if int(boards[index]["id"]) == board_id:
			return index
	return -1


func _is_screw_accessible(screw: Dictionary) -> bool:
	return PuzzleRules.is_screw_accessible(screw["position"], int(screw["board_id"]), boards)


func _initialize_toolboxes() -> void:
	toolbox_filled = [0, 0, 0]
	_update_sorting_ui()


func _update_sorting_ui() -> void:
	for color_id in range(toolbox_buttons.size()):
		var button: Button = toolbox_buttons[color_id]
		var required: int = color_totals[color_id]
		var filled: int = toolbox_filled[color_id]
		button.text = "%s\n%d / %d" % [screw_color_names[color_id], filled, required]
		button.disabled = required <= 0 or filled >= required
	for slot_index in range(spare_slot_labels.size()):
		var slot_label: Label = spare_slot_labels[slot_index]
		slot_label.visible = slot_index < spare_slot_limit
		if slot_index < spare_screw_ids.size():
			var stored_screw: Dictionary = screws[spare_screw_ids[slot_index]]
			slot_label.text = "●"
			slot_label.add_theme_color_override("font_color", screw_color_values[int(stored_screw["color_id"])])
		else:
			slot_label.text = "○"
			slot_label.add_theme_color_override("font_color", Color("#F6DCA8"))
	if tray_label != null:
		tray_label.text = "SPARE TRAY  %d / %d" % [spare_screw_ids.size(), spare_slot_limit]
	if hammer_button != null:
		hammer_button.text = "HAMMER x%d" % hammer_uses
		hammer_button.disabled = hammer_uses <= 0
	if extra_slot_button != null:
		extra_slot_button.text = "SLOT ✓" if extra_slot_used else "+1 SLOT"
		extra_slot_button.disabled = extra_slot_used


func _on_toolbox_pressed(color_id: int) -> void:
	if color_id < 0 or color_id >= screw_color_values.size():
		return
	var moved_count: int = 0
	var remaining: Array[String] = []
	for screw_id in spare_screw_ids:
		var stored_screw: Dictionary = screws[screw_id]
		if int(stored_screw["color_id"]) == color_id:
			moved_count += 1
		else:
			remaining.append(screw_id)
	if moved_count <= 0:
		status_label.text = "No %s screws in the spare tray." % screw_color_names[color_id].to_lower()
		_play_sfx("ui_click")
		return
	spare_screw_ids = remaining
	toolbox_filled[color_id] += moved_count
	sorted_screws += moved_count
	status_label.text = "%s box filled with %d screw(s)!" % [screw_color_names[color_id], moved_count]
	_play_sfx("board_clear")
	_update_sorting_ui()
	_update_hud()
	_check_level_complete()


func _on_hammer_pressed() -> void:
	if hammer_uses <= 0:
		status_label.text = "No hammer charge left in this level."
		return
	if spare_screw_ids.size() >= spare_slot_limit:
		status_label.text = "Spare tray is full. Sort a colour box first."
		return
	for screw_id in screws.keys():
		var screw: Dictionary = screws[screw_id]
		if not bool(screw["removed"]) and _is_screw_accessible(screw):
			var before_count: int = removed_screws
			_try_remove_screw(str(screw_id))
			if removed_screws > before_count:
				hammer_uses -= 1
				status_label.text = "Hammer collected one exposed screw."
				_update_sorting_ui()
			return
	status_label.text = "No exposed screw for the hammer."


func _on_extra_slot_pressed() -> void:
	if extra_slot_used:
		return
	extra_slot_used = true
	spare_slot_limit = 6
	status_label.text = "Extra spare slot unlocked for this level."
	_play_sfx("ui_click")
	_update_sorting_ui()


func _refresh_screw_visuals() -> void:
	for screw_id in screws.keys():
		var screw: Dictionary = screws[screw_id]
		if bool(screw["removed"]):
			continue
		var head: MeshInstance3D = screw["head"]
		if str(screw_id) == current_hint_id:
			head.material_override = gold_material
		elif _is_screw_accessible(screw):
			head.material_override = screw_color_materials[int(screw["color_id"])]
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



func _find_screw_near_screen_position(screen_position: Vector2) -> String:
	if camera == null:
		return ""
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var hit_radius: float = clampf(viewport_size.x * 0.075, 42.0, 68.0)
	var best_distance_squared: float = hit_radius * hit_radius
	var best_screw_id: String = ""
	for screw_id in screws.keys():
		var screw: Dictionary = screws[screw_id]
		if bool(screw.get("removed", false)) or not _is_screw_accessible(screw):
			continue
		var target_position: Vector3 = screw["position"] + Vector3(0.0, 0.12, 0.0)
		if camera.is_position_behind(target_position):
			continue
		var target_screen: Vector2 = camera.unproject_position(target_position)
		var distance_squared: float = target_screen.distance_squared_to(screen_position)
		if distance_squared <= best_distance_squared:
			best_distance_squared = distance_squared
			best_screw_id = str(screw_id)
	return best_screw_id


func _handle_tap(screen_position: Vector2) -> void:
	# Screen-space picking is reliable for touchscreens and remains constrained to exposed screws.
	var screen_pick_id: String = _find_screw_near_screen_position(screen_position)
	if not screen_pick_id.is_empty():
		_try_remove_screw(screen_pick_id)
		return
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
		status_label.text = "This screw is covered by another wooden beam."
		return
	if spare_screw_ids.size() >= spare_slot_limit:
		status_label.text = "SPARE TRAY FULL! Tap a matching colour box to sort screws."
		_play_sfx("ui_click")
		return

	screw["removed"] = true
	removed_screws += 1
	spare_screw_ids.append(screw_id)
	if current_hint_id == screw_id:
		current_hint_id = ""
	_play_sfx("screw_remove")
	_update_sorting_ui()
	var screw_node: Node3D = screw["node"]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(screw_node, "position", screw_node.position + Vector3(0.0, 0.85, 0.0), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(screw_node, "rotation:y", screw_node.rotation.y + TAU * 1.5, 0.32)
	tween.tween_property(screw_node, "scale", Vector3(0.22, 0.22, 0.22), 0.32)
	tween.chain().tween_callback(Callable(screw_node, "queue_free"))

	status_label.text = "Screw collected! Tap its matching colour box to sort it."
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
	if sorted_screws < total_screws or not spare_screw_ids.is_empty():
		return
	game_started = false
	is_paused = false
	highest_unlocked_level = maxi(highest_unlocked_level, mini(level_index + 1, MAX_LEVEL))
	_save_progress()
	_play_sfx("level_complete")
	var stars: int = 3 if hints_used == 0 else (2 if hints_used <= 2 else 1)
	var star_text := "★".repeat(stars) + "☆".repeat(3 - stars)
	finish_title.text = "LEVEL %d COMPLETE!" % level_index
	finish_summary.text = "%s\nSorted: %d/%d   Hints: %d\nTime: %s" % [star_text, sorted_screws, total_screws, hints_used, _format_time(level_elapsed)]
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
	progress_label.text = "SORTED %d/%d" % [sorted_screws, total_screws]
	if timer_label != null:
		timer_label.text = "TIME %s" % _format_time(level_elapsed)
	if progress_bar != null:
		progress_bar.value = 100.0 if total_screws <= 0 else (float(sorted_screws) / float(total_screws)) * 100.0
