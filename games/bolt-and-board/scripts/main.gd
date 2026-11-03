extends Node3D

const PuzzleRules = preload("res://scripts/puzzle_rules.gd")
const MAX_LEVEL := 30
const SCREW_LAYER := 1
const BOARD_LAYER := 2
const TRAY_CAPACITY := 5
const TOOLBOX_BATCH_SIZE := 3

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
var camera_focus := Vector3(0.0, 0.3, 0.0)
var camera_yaw: float = 0.0
var camera_pitch: float = 0.62
var camera_distance: float = 14.0
var camera_dragging: bool = false
var camera_drag_moved: bool = false
var camera_drag_start := Vector2.ZERO

var wood_materials: Array = []
var screw_color_materials: Array = []
var tray_colors: Array[int] = []
var tray_slot_labels: Array[Label] = []
var tray_status_label: Label
var toolbox_title_label: Label
var toolbox_target_label: Label
var toolbox_next_label: Label
var toolbox_slot_labels: Array[Label] = []
var toolbox_targets: Array[Dictionary] = []
var toolbox_target_index: int = 0
var toolbox_target_progress: int = 0
var fail_overlay: ColorRect
var metal_material: StandardMaterial3D
var screw_hole_mesh: CylinderMesh
var screw_shaft_mesh: CylinderMesh
var screw_washer_mesh: CylinderMesh
var screw_washer_lip_mesh: CylinderMesh
var screw_head_mesh: CylinderMesh
var screw_rim_mesh: TorusMesh
var screw_thread_mesh: ArrayMesh
var screw_hit_shape: SphereShape3D
var screw_slot_horizontal_mesh: BoxMesh
var screw_slot_vertical_mesh: BoxMesh
var screw_slot_material: StandardMaterial3D
var dark_metal_material: StandardMaterial3D
var blocked_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var hole_material: StandardMaterial3D
var floor_material: StandardMaterial3D


func _ready() -> void:
	_load_progress()
	_create_materials()
	_create_screw_mesh_cache()
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
		wood.roughness = 0.82
		wood.metallic = 0.0
		wood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var wood_texture := load("res://assets/textures/wood_oak.png") as Texture2D
		var wood_normal := load("res://assets/textures/wood_oak_normal.png") as Texture2D
		var wood_roughness := load("res://assets/textures/wood_oak_roughness.png") as Texture2D
		if wood_texture != null:
			wood.albedo_texture = wood_texture
		if wood_normal != null:
			wood.normal_enabled = true
			wood.normal_texture = wood_normal
			wood.normal_scale = 0.38
		if wood_roughness != null:
			wood.roughness_texture = wood_roughness
		wood.uv1_scale = Vector3(1.8, 1.8, 1.0)
		wood.uv1_triplanar = true
		wood_materials.append(wood)

	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color("#C9D4DD")
	metal_material.metallic = 0.82
	metal_material.roughness = 0.28
	metal_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var steel_texture := load("res://assets/textures/brushed_steel.png") as Texture2D
	var steel_normal := load("res://assets/textures/brushed_steel_normal.png") as Texture2D
	var steel_roughness := load("res://assets/textures/brushed_steel_roughness.png") as Texture2D
	if steel_texture != null:
		metal_material.albedo_texture = steel_texture
	if steel_normal != null:
		metal_material.normal_enabled = true
		metal_material.normal_texture = steel_normal
		metal_material.normal_scale = 0.22
	if steel_roughness != null:
		metal_material.roughness_texture = steel_roughness

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

	screw_color_materials.clear()
	for color_value in [Color("#E45A43"), Color("#39A9C8"), Color("#E6B84F"), Color("#9A73D6")]:
		var colored_steel := StandardMaterial3D.new()
		colored_steel.albedo_color = color_value
		colored_steel.metallic = 0.72
		colored_steel.roughness = 0.24
		screw_color_materials.append(colored_steel)

	hole_material = StandardMaterial3D.new()
	hole_material.albedo_color = Color("#24170F")
	hole_material.roughness = 1.0

	floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color("#172534")
	floor_material.roughness = 0.95
	var floor_texture := load("res://assets/textures/dark_surface.png") as Texture2D
	if floor_texture != null:
		floor_material.albedo_texture = floor_texture


func _create_screw_mesh_cache() -> void:
	screw_hole_mesh = CylinderMesh.new()
	screw_hole_mesh.top_radius = 0.145
	screw_hole_mesh.bottom_radius = 0.145
	screw_hole_mesh.height = 0.018
	screw_hole_mesh.radial_segments = 24

	screw_shaft_mesh = CylinderMesh.new()
	screw_shaft_mesh.top_radius = 0.052
	screw_shaft_mesh.bottom_radius = 0.052
	screw_shaft_mesh.height = 0.31
	screw_shaft_mesh.radial_segments = 24

	screw_washer_mesh = CylinderMesh.new()
	screw_washer_mesh.top_radius = 0.185
	screw_washer_mesh.bottom_radius = 0.185
	screw_washer_mesh.height = 0.035
	screw_washer_mesh.radial_segments = 32

	screw_washer_lip_mesh = CylinderMesh.new()
	screw_washer_lip_mesh.top_radius = 0.17
	screw_washer_lip_mesh.bottom_radius = 0.17
	screw_washer_lip_mesh.height = 0.012
	screw_washer_lip_mesh.radial_segments = 32

	screw_head_mesh = CylinderMesh.new()
	screw_head_mesh.top_radius = 0.118
	screw_head_mesh.bottom_radius = 0.145
	screw_head_mesh.height = 0.105
	screw_head_mesh.radial_segments = 32

	screw_rim_mesh = TorusMesh.new()
	screw_rim_mesh.inner_radius = 0.137
	screw_rim_mesh.outer_radius = 0.151
	screw_rim_mesh.rings = 24
	screw_rim_mesh.ring_segments = 8

	screw_thread_mesh = _build_thread_mesh(0.055, 0.25, 0.058, 0.012)
	screw_hit_shape = SphereShape3D.new()
	screw_hit_shape.radius = 0.34

	screw_slot_horizontal_mesh = BoxMesh.new()
	screw_slot_horizontal_mesh.size = Vector3(0.145, 0.014, 0.022)
	screw_slot_vertical_mesh = BoxMesh.new()
	screw_slot_vertical_mesh.size = Vector3(0.022, 0.014, 0.145)
	screw_slot_material = StandardMaterial3D.new()
	screw_slot_material.albedo_color = Color("#26313C")
	screw_slot_material.metallic = 0.82
	screw_slot_material.roughness = 0.28


func _add_shared_mesh(parent: Node3D, mesh: Mesh, material: Material, local_position: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = local_position
	parent.add_child(instance)
	return instance


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
	style.bg_color = Color("#101D2B")
	style.border_color = Color("#B98A4F")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0.0, 6.0)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style


func _style_button(button: Button, primary: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#D59A4C") if primary else Color("#263D52")
	normal.border_color = Color("#F4D39B") if primary else Color("#627F98")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0.0, 3.0)
	normal.content_margin_left = 18.0
	normal.content_margin_right = 18.0
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
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#132A45")
	sky_material.sky_horizon_color = Color("#D6A878")
	sky_material.ground_bottom_color = Color("#0C1724")
	sky_material.ground_horizon_color = Color("#5C4B40")
	sky_material.sun_angle_max = 18.0
	sky_material.use_debanding = true
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.78
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_exposure = 1.06
	environment.tonemap_white = 1.12
	environment.glow_enabled = true
	environment.glow_intensity = 0.22
	environment.glow_strength = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.02
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 1.12
	environment.fog_enabled = true
	environment.fog_light_color = Color("#A9B9C9")
	environment.fog_density = 0.004
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sunlight.light_color = Color("#FFE0B8")
	sunlight.light_energy = 1.72
	sunlight.shadow_enabled = true
	sunlight.shadow_blur = 2.8
	sunlight.directional_shadow_max_distance = 24.0
	sunlight.shadow_bias = 0.035
	sunlight.shadow_normal_bias = 1.4
	add_child(sunlight)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-4.0, 5.0, 2.5)
	fill_light.light_color = Color("#6BA8D6")
	fill_light.light_energy = 0.42
	fill_light.omni_range = 13.0
	fill_light.shadow_enabled = false
	add_child(fill_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(3.8, 3.2, -4.0)
	rim_light.light_color = Color("#F0B56C")
	rim_light.light_energy = 0.62
	rim_light.omni_range = 10.0
	rim_light.shadow_enabled = false
	add_child(rim_light)

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
	platform_mat.albedo_color = Color("#25394A")
	platform_mat.metallic = 0.34
	platform_mat.roughness = 0.38
	platform.material_override = platform_mat
	platform.position = Vector3(0.0, -0.91, 0.0)
	add_child(platform)

	var platform_trim := MeshInstance3D.new()
	var trim_box := BoxMesh.new()
	trim_box.size = Vector3(8.52, 0.07, 7.12)
	platform_trim.mesh = trim_box
	var trim_material := StandardMaterial3D.new()
	trim_material.albedo_color = Color("#C28A4C")
	trim_material.metallic = 0.72
	trim_material.roughness = 0.28
	platform_trim.material_override = trim_material
	platform_trim.position = Vector3(0.0, -0.78, 0.0)
	add_child(platform_trim)


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
	# The full-screen root is only a layout container. It must not swallow taps intended for the 3D puzzle.
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	toolbox_panel.offset_top = 112.0
	toolbox_panel.offset_right = -18.0
	toolbox_panel.offset_bottom = 232.0
	ui_root.add_child(toolbox_panel)
	var toolbox_box := VBoxContainer.new()
	toolbox_box.add_theme_constant_override("separation", 4)
	toolbox_panel.add_child(toolbox_box)
	toolbox_title_label = Label.new()
	toolbox_title_label.text = "ACTIVE TOOLBOX"
	toolbox_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toolbox_title_label.add_theme_font_size_override("font_size", 14)
	toolbox_title_label.add_theme_color_override("font_color", Color("#E6BD79"))
	toolbox_box.add_child(toolbox_title_label)
	toolbox_target_label = Label.new()
	toolbox_target_label.text = "CORAL  0/3"
	toolbox_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toolbox_target_label.add_theme_font_size_override("font_size", 20)
	toolbox_box.add_child(toolbox_target_label)
	var toolbox_slots_row := HBoxContainer.new()
	toolbox_slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbox_slots_row.add_theme_constant_override("separation", 12)
	toolbox_box.add_child(toolbox_slots_row)
	toolbox_slot_labels.clear()
	for slot_index in range(TOOLBOX_BATCH_SIZE):
		var target_slot := Label.new()
		target_slot.text = "○"
		target_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target_slot.add_theme_font_size_override("font_size", 24)
		toolbox_slots_row.add_child(target_slot)
		toolbox_slot_labels.append(target_slot)
	toolbox_next_label = Label.new()
	toolbox_next_label.text = "UP NEXT"
	toolbox_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toolbox_next_label.add_theme_font_size_override("font_size", 13)
	toolbox_next_label.add_theme_color_override("font_color", Color("#AAB9C9"))
	toolbox_box.add_child(toolbox_next_label)

	var bottom_panel := PanelContainer.new()
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style())
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 18.0
	bottom_panel.offset_top = -252.0
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
	progress_bar.custom_minimum_size = Vector2(0.0, 12.0)
	bottom_box.add_child(progress_bar)

	tray_status_label = Label.new()
	tray_status_label.text = "TEMP STORAGE  |  KEEP FIVE SLOTS FROM FILLING"
	tray_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_status_label.add_theme_font_size_override("font_size", 15)
	tray_status_label.add_theme_color_override("font_color", Color("#E6BD79"))
	bottom_box.add_child(tray_status_label)

	var tray_row := HBoxContainer.new()
	tray_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_row.add_theme_constant_override("separation", 9)
	bottom_box.add_child(tray_row)
	tray_slot_labels.clear()
	for slot_index in range(TRAY_CAPACITY):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48.0, 48.0)
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color("#182838")
		slot_style.border_color = Color("#718397")
		slot_style.set_border_width_all(2)
		slot_style.set_corner_radius_all(12)
		slot.add_theme_stylebox_override("panel", slot_style)
		tray_row.add_child(slot)
		var slot_label := Label.new()
		slot_label.text = "·"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 28)
		slot.add_child(slot_label)
		tray_slot_labels.append(slot_label)

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
	_create_fail_overlay()
	_update_sound_button_labels()



func _create_fail_overlay() -> void:
	fail_overlay = _make_overlay()
	fail_overlay.visible = false
	ui_root.add_child(fail_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fail_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.custom_minimum_size = Vector2(520.0, 330.0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "TRAY IS FULL!"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	box.add_child(heading)
	var message := Label.new()
	message.text = "Plan your moves and match three screws of the same color."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message)
	var retry := Button.new()
	retry.text = "TRY AGAIN"
	retry.custom_minimum_size = Vector2(0.0, 60.0)
	retry.pressed.connect(_on_restart_pressed)
	_style_button(retry, true)
	box.add_child(retry)
	var levels := Button.new()
	levels.text = "LEVEL SELECT"
	levels.custom_minimum_size = Vector2(0.0, 52.0)
	levels.pressed.connect(_show_level_select)
	_style_button(levels, false)
	box.add_child(levels)


func _refresh_tray_ui() -> void:
	for index in range(tray_slot_labels.size()):
		var slot_label: Label = tray_slot_labels[index]
		if index < tray_colors.size():
			var color_id: int = tray_colors[index]
			slot_label.text = "●"
			slot_label.add_theme_color_override("font_color", screw_color_materials[color_id].albedo_color)
		else:
			slot_label.text = "·"
			slot_label.add_theme_color_override("font_color", Color("#718397"))
	if tray_status_label != null:
		tray_status_label.text = "TEMP STORAGE  %d/%d" % [tray_colors.size(), TRAY_CAPACITY]


func _color_name(color_id: int) -> String:
	var names: Array[String] = ["CORAL", "CYAN", "GOLD", "VIOLET"]
	return names[posmod(color_id, names.size())]


func _get_active_toolbox_color() -> int:
	if toolbox_target_index >= toolbox_targets.size():
		return -1
	return int(toolbox_targets[toolbox_target_index].get("color", 0))


func _refresh_toolbox_ui() -> void:
	var active_color: int = _get_active_toolbox_color()
	var active_goal: int = 0
	if active_color >= 0:
		active_goal = int(toolbox_targets[toolbox_target_index].get("goal", 0))
		toolbox_title_label.text = "ACTIVE COLOR TOOLBOX"
		toolbox_target_label.text = "%s  %d / %d" % [_color_name(active_color), toolbox_target_progress, active_goal]
		var target_color: Color = screw_color_materials[active_color].albedo_color
		toolbox_target_label.add_theme_color_override("font_color", target_color)
		for index in range(toolbox_slot_labels.size()):
			var marker: Label = toolbox_slot_labels[index]
			marker.visible = index < active_goal
			marker.text = "●" if index < toolbox_target_progress else "○"
			marker.add_theme_color_override("font_color", target_color)
	else:
		toolbox_title_label.text = "ALL TOOLBOXES COMPLETE"
		toolbox_target_label.text = "SORTING COMPLETE"
		toolbox_target_label.add_theme_color_override("font_color", Color("#8CE0A6"))
		for marker in toolbox_slot_labels:
			marker.visible = false
	if toolbox_target_index + 1 < toolbox_targets.size():
		var upcoming: Dictionary = toolbox_targets[toolbox_target_index + 1]
		toolbox_next_label.text = "UP NEXT  %s  %d" % [_color_name(int(upcoming["color"])), int(upcoming["goal"])]
	elif active_color >= 0:
		toolbox_next_label.text = "LAST TOOLBOX"
	else:
		toolbox_next_label.text = "EVERY SCREW SORTED"


func _build_toolbox_targets() -> void:
	var color_counts: Array[int] = [0, 0, 0, 0]
	var exposed_counts: Array[int] = [0, 0, 0, 0]
	for screw_id in screws.keys():
		var screw: Dictionary = screws[screw_id]
		var color_id: int = int(screw.get("color_id", 0))
		color_counts[color_id] += 1
		if _is_screw_accessible(screw):
			exposed_counts[color_id] += 1
	var first_color: int = 0
	var most_exposed: int = -1
	for color_id in range(exposed_counts.size()):
		if exposed_counts[color_id] > most_exposed:
			most_exposed = exposed_counts[color_id]
			first_color = color_id
	toolbox_targets = PuzzleRules.build_toolbox_targets(color_counts, first_color, screw_color_materials.size())
	toolbox_target_index = 0
	toolbox_target_progress = 0
	_refresh_toolbox_ui()


func _advance_toolbox_if_filled() -> void:
	if toolbox_target_index >= toolbox_targets.size():
		return
	var goal: int = int(toolbox_targets[toolbox_target_index].get("goal", 0))
	if toolbox_target_progress < goal:
		return
	_play_sfx("match_clear")
	toolbox_target_index += 1
	toolbox_target_progress = 0
	_refresh_toolbox_ui()


func _consume_buffer_for_active_toolbox() -> void:
	var safety: int = 0
	while toolbox_target_index < toolbox_targets.size() and safety < 64:
		var target_color: int = _get_active_toolbox_color()
		var matching_index: int = tray_colors.find(target_color)
		if matching_index < 0:
			break
		tray_colors.remove_at(matching_index)
		toolbox_target_progress += 1
		_advance_toolbox_if_filled()
		safety += 1
	_refresh_tray_ui()
	_refresh_toolbox_ui()


func _add_screw_to_tray(color_id: int) -> bool:
	if toolbox_target_index >= toolbox_targets.size():
		return true
	if color_id == _get_active_toolbox_color():
		toolbox_target_progress += 1
		_advance_toolbox_if_filled()
		_consume_buffer_for_active_toolbox()
		status_label.text = "Correct color! The active toolbox is filling."
		return true
	tray_colors.append(color_id)
	_refresh_tray_ui()
	if tray_colors.size() >= TRAY_CAPACITY:
		game_started = false
		is_paused = false
		fail_overlay.visible = true
		_play_sfx("tray_full")
		status_label.text = "Temporary storage is full. Plan a different screw order."
		return false
	status_label.text = "%s screw stored. Find a %s screw for the active toolbox." % [_color_name(color_id), _color_name(_get_active_toolbox_color())]
	return true


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
	instructions.text = "1. Tap a bright, exposed screw.\n\n2. Fill the active toolbox with screws of its color.\n\n3. Other colors wait in the five-slot temporary tray. If all five fill, retry the level.\n\n4. Clear all plates and fill every toolbox to win. Drag to orbit and pinch to zoom."
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
	fail_overlay.visible = false
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
	fail_overlay.visible = false
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
	fail_overlay.visible = false
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
	if game_started or is_paused or fail_overlay.visible:
		pause_overlay.visible = false
		fail_overlay.visible = false
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
	tray_colors.clear()
	toolbox_targets.clear()
	toolbox_target_index = 0
	toolbox_target_progress = 0
	fail_overlay.visible = false
	_refresh_tray_ui()
	_refresh_toolbox_ui()

	var layer_count: int = PuzzleRules.get_layer_count(number)
	# Keep the full stack visible, but let players rotate and zoom to inspect the puzzle.
	var zoom_step: float = float(layer_count - 2)
	camera_focus = Vector3(0.0, 0.30 + zoom_step * 0.06, 0.0)
	camera_yaw = 0.0
	camera_pitch = 0.62
	camera_distance = 14.0 + zoom_step * 1.0
	_update_camera_pose()
	for layer in range(layer_count):
		var width: float = 3.55 + float(layer) * 0.72 + float(number % 3) * 0.10
		var depth: float = 2.45 + float(layer) * 0.52 + float(number % 2) * 0.12
		var y: float = 0.22 + float(layer_count - 1 - layer) * 0.46
		var center_x: float = sin(float(number * 3 + layer) * 0.47) * 0.24
		var center_z: float = cos(float(number * 2 + layer) * 0.39) * 0.20
		var piece_specs: Array = _build_piece_specs(width, depth, number, layer)
		for piece_index in range(piece_specs.size()):
			var piece: Dictionary = piece_specs[piece_index]
			_create_board(
				float(piece["width"]),
				float(piece["depth"]),
				y,
				center_x + float(piece["x"]),
				center_z + float(piece["z"]),
				layer,
				number + piece_index
			)

	_build_toolbox_targets()
	_update_hud()
	status_label.text = "Fill the active color toolbox. Store other colors carefully in the five-slot tray."
	_refresh_screw_visuals()


func _build_piece_specs(width: float, depth: float, level: int, layer: int) -> Array:
	var specs: Array = []
	match posmod(level * 2 + layer * 3, 4):
		0:
			for z_sign in [-1.0, 1.0]:
				specs.append({"x": 0.0, "z": z_sign * depth * 0.26, "width": width * 0.94, "depth": depth * 0.42})
		1:
			for x_offset in [-0.32, 0.0, 0.32]:
				specs.append({"x": x_offset * width, "z": 0.0, "width": width * 0.28, "depth": depth * 0.92})
		2:
			specs.append({"x": -width * 0.34, "z": 0.0, "width": width * 0.27, "depth": depth * 0.92})
			specs.append({"x": width * 0.34, "z": 0.0, "width": width * 0.27, "depth": depth * 0.92})
			specs.append({"x": 0.0, "z": 0.0, "width": width * 0.38, "depth": depth * 0.27})
		3:
			for z_offset in [-0.33, 0.0, 0.33]:
				specs.append({"x": 0.0, "z": z_offset * depth, "width": width * 0.94, "depth": depth * 0.27})
	return specs


func _create_board(width: float, depth: float, y: float, center_x: float, center_z: float, layer: int, number: int) -> void:
	var board_id: int = next_board_id
	next_board_id += 1

	var board_node := Node3D.new()
	board_node.name = "WoodBoard_%02d" % board_id
	board_node.position = Vector3(center_x, y, center_z)
	game_root.add_child(board_node)

	var board_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.34, depth)
	board_mesh.mesh = box
	var board_base_material := StandardMaterial3D.new()
	board_base_material.albedo_color = Color("#4A2B1D")
	board_base_material.roughness = 0.72
	board_mesh.material_override = board_base_material
	board_node.add_child(board_mesh)

	# Raised top plank, thin edge band and corner caps give each plate a finished furniture-like silhouette.
	var top_mesh := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(width - 0.055, 0.085, depth - 0.055)
	top_mesh.mesh = top_box
	top_mesh.material_override = wood_materials[(layer + number) % wood_materials.size()]
	top_mesh.position.y = 0.205
	board_node.add_child(top_mesh)

	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = Color("#D2A16A")
	edge_material.metallic = 0.12
	edge_material.roughness = 0.52
	_add_box(board_node, Vector3(width - 0.10, 0.025, 0.035), edge_material, Vector3(0.0, 0.225, depth * 0.5 - 0.025))
	_add_box(board_node, Vector3(width - 0.10, 0.025, 0.035), edge_material, Vector3(0.0, 0.225, -depth * 0.5 + 0.025))
	_add_box(board_node, Vector3(0.035, 0.025, depth - 0.10), edge_material, Vector3(width * 0.5 - 0.025, 0.225, 0.0))
	_add_box(board_node, Vector3(0.035, 0.025, depth - 0.10), edge_material, Vector3(-width * 0.5 + 0.025, 0.225, 0.0))

	# A real collider prevents taps passing through a visible upper board.
	var board_body := StaticBody3D.new()
	board_body.name = "BoardOcclusionCollider"
	board_body.collision_layer = BOARD_LAYER
	board_body.collision_mask = 0
	var board_collision := CollisionShape3D.new()
	var board_shape := BoxShape3D.new()
	board_shape.size = Vector3(width, 0.48, depth)
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
		"layer": layer,
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
		hole.mesh = screw_hole_mesh
		hole.material_override = hole_material
		hole.position = Vector3(world_position.x - owning_center.x, 0.245, world_position.z - owning_center.y)
		(owning_board["node"] as Node3D).add_child(hole)

	var shaft := MeshInstance3D.new()
	shaft.mesh = screw_shaft_mesh
	shaft.material_override = dark_metal_material
	shaft.position = Vector3(0.0, -0.08, 0.0)
	screw_root.add_child(shaft)

	var thread := MeshInstance3D.new()
	thread.name = "HelicalThread"
	thread.mesh = screw_thread_mesh
	thread.material_override = metal_material
	thread.position.y = -0.075
	screw_root.add_child(thread)

	var washer := MeshInstance3D.new()
	washer.mesh = screw_washer_mesh
	washer.material_override = dark_metal_material
	washer.position = Vector3(0.0, 0.075, 0.0)
	screw_root.add_child(washer)

	var washer_lip := MeshInstance3D.new()
	washer_lip.mesh = screw_washer_lip_mesh
	washer_lip.material_override = metal_material
	washer_lip.position = Vector3(0.0, 0.098, 0.0)
	screw_root.add_child(washer_lip)

	var head := MeshInstance3D.new()
	head.mesh = screw_head_mesh
	head.material_override = screw_color_materials[posmod(next_screw_id * 3 + board_id, screw_color_materials.size())]
	head.position = Vector3(0.0, 0.09, 0.0)
	screw_root.add_child(head)

	_add_shared_mesh(screw_root, screw_slot_horizontal_mesh, screw_slot_material, Vector3(0.0, 0.147, 0.0))
	_add_shared_mesh(screw_root, screw_slot_vertical_mesh, screw_slot_material, Vector3(0.0, 0.148, 0.0))
	var head_rim := MeshInstance3D.new()
	head_rim.mesh = screw_rim_mesh
	head_rim.material_override = metal_material
	head_rim.position.y = 0.143
	screw_root.add_child(head_rim)

	var area := Area3D.new()
	area.name = "TapArea"
	area.collision_layer = SCREW_LAYER
	area.collision_mask = 0
	area.set_meta("screw_id", screw_id)
	var collision := CollisionShape3D.new()
	collision.shape = screw_hit_shape
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
		"color_id": posmod(next_screw_id * 3 + board_id, screw_color_materials.size()),
		"removed": false
	}
	total_screws += 1
	_refresh_tray_ui()



func _build_thread_mesh(radius: float, length: float, pitch: float, tube_radius: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var turns: float = length / pitch
	var steps: int = maxi(24, int(turns * 32.0))
	var sides: int = 6
	for step in range(steps):
		var t0: float = float(step) / float(steps)
		var t1: float = float(step + 1) / float(steps)
		var a0: float = t0 * turns * TAU
		var a1: float = t1 * turns * TAU
		var c0 := Vector3(radius * cos(a0), -length * 0.5 + t0 * length, radius * sin(a0))
		var c1 := Vector3(radius * cos(a1), -length * 0.5 + t1 * length, radius * sin(a1))
		var tangent0 := Vector3(-radius * sin(a0), pitch / TAU, radius * cos(a0)).normalized()
		var tangent1 := Vector3(-radius * sin(a1), pitch / TAU, radius * cos(a1)).normalized()
		var radial0 := Vector3(cos(a0), 0.0, sin(a0))
		var radial1 := Vector3(cos(a1), 0.0, sin(a1))
		var bitangent0 := tangent0.cross(radial0).normalized()
		var bitangent1 := tangent1.cross(radial1).normalized()
		for side in range(sides):
			var q0: float = float(side) / float(sides) * TAU
			var q1: float = float(side + 1) / float(sides) * TAU
			var p00 := c0 + (radial0 * cos(q0) + bitangent0 * sin(q0)) * tube_radius
			var p01 := c0 + (radial0 * cos(q1) + bitangent0 * sin(q1)) * tube_radius
			var p10 := c1 + (radial1 * cos(q0) + bitangent1 * sin(q0)) * tube_radius
			var p11 := c1 + (radial1 * cos(q1) + bitangent1 * sin(q1)) * tube_radius
			surface.add_vertex(p00)
			surface.add_vertex(p10)
			surface.add_vertex(p11)
			surface.add_vertex(p00)
			surface.add_vertex(p11)
			surface.add_vertex(p01)
	surface.generate_normals()
	return surface.commit()


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
			head.material_override = screw_color_materials[int(screw.get("color_id", 0))]
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
			elif finish_overlay.visible or fail_overlay.visible:
				_show_level_select()
			return
	if not game_started or is_paused or finish_overlay.visible or fail_overlay.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			camera_dragging = true
			camera_drag_moved = false
			camera_drag_start = event.position
		else:
			if camera_dragging and not camera_drag_moved:
				_handle_tap(camera_drag_start)
			camera_dragging = false
	elif event is InputEventScreenDrag and camera_dragging:
		if event.relative.length() > 3.0:
			camera_drag_moved = true
			_rotate_camera_by_drag(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				camera_dragging = true
				camera_drag_moved = false
				camera_drag_start = event.position
			else:
				if camera_dragging and not camera_drag_moved:
					_handle_tap(camera_drag_start)
				camera_dragging = false
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = clampf(camera_distance - 0.8, 8.5, 25.0)
			_update_camera_pose()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = clampf(camera_distance + 0.8, 8.5, 25.0)
			_update_camera_pose()
	elif event is InputEventMouseMotion and camera_dragging:
		if event.relative.length() > 3.0:
			camera_drag_moved = true
			_rotate_camera_by_drag(event.relative)
	elif event is InputEventMagnifyGesture:
		camera_distance = clampf(camera_distance / event.factor, 8.5, 25.0)
		_update_camera_pose()


func _rotate_camera_by_drag(relative: Vector2) -> void:
	camera_yaw -= relative.x * 0.008
	camera_pitch = clampf(camera_pitch + relative.y * 0.006, 0.28, 1.18)
	_update_camera_pose()


func _update_camera_pose() -> void:
	if camera == null:
		return
	var horizontal: float = cos(camera_pitch) * camera_distance
	camera.position = camera_focus + Vector3(sin(camera_yaw) * horizontal, sin(camera_pitch) * camera_distance, cos(camera_yaw) * horizontal)
	camera.look_at(camera_focus, Vector3.UP)


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
		status_label.text = "This screw is covered. Clear the upper board first."
		return
	if not _add_screw_to_tray(int(screw.get("color_id", 0))):
		return

	screw["removed"] = true
	removed_screws += 1
	if current_hint_id == screw_id:
		current_hint_id = ""
	_play_sfx("screw_remove")
	var screw_node: Node3D = screw["node"]
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(screw_node, "position", screw_node.position + Vector3(0.0, 1.35, 0.0), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(screw_node, "rotation:y", screw_node.rotation.y + TAU * 3.0, 0.42)
	tween.tween_property(screw_node, "scale", Vector3(0.82, 0.82, 0.82), 0.42)
	_spawn_screw_pop(screw["position"], int(screw.get("color_id", 0)))
	tween.chain().tween_callback(Callable(screw_node, "queue_free"))

	status_label.text = "Nice! Screw removed. Find the other exposed screws."
	_update_hud()
	_check_board_cleared(int(screw["board_id"]))
	_refresh_screw_visuals()
	_check_level_complete()


func _spawn_screw_pop(world_position: Vector3, color_id: int) -> void:
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.055
	ring_mesh.outer_radius = 0.075
	ring_mesh.rings = 20
	ring_mesh.ring_segments = 8
	ring.mesh = ring_mesh
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = screw_color_materials[posmod(color_id, screw_color_materials.size())].albedo_color
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.emission_enabled = true
	ring_material.emission = ring_material.albedo_color
	ring_material.emission_energy_multiplier = 1.5
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_material
	ring.position = world_position + Vector3(0.0, 0.12, 0.0)
	ring.scale = Vector3.ONE * 0.15
	game_root.add_child(ring)
	var pop_tween := create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(ring, "scale", Vector3.ONE * 1.55, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(ring_material, "albedo_color:a", 0.0, 0.32)
	pop_tween.chain().tween_callback(Callable(ring, "queue_free"))


func _check_board_cleared(board_id: int) -> void:
	var index: int = _find_board_index(board_id)
	if index < 0:
		return
	var board: Dictionary = boards[index]
	if bool(board["removed"]):
		return
	if not PuzzleRules.is_board_cleared(board["screws"], screws):
		return

	if bool(board.get("clearing", false)):
		return
	# Keep the plate blocking lower screws until its fall animation has finished.
	board["clearing"] = true
	var board_node: Node3D = board["node"]
	_play_sfx("board_clear")
	var fall_tween := create_tween()
	fall_tween.set_parallel(true)
	fall_tween.tween_property(board_node, "position:y", board_node.position.y - 3.2, 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(board_node, "rotation", Vector3(0.72, randf_range(-0.22, 0.22), 0.46), 0.82).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	fall_tween.chain().tween_callback(_finish_board_clear.bind(board_id))
	status_label.text = "Plate released! Wait for it to clear before reaching the screws below."


func _finish_board_clear(board_id: int) -> void:
	var index: int = _find_board_index(board_id)
	if index < 0:
		return
	var board: Dictionary = boards[index]
	if bool(board.get("removed", false)):
		return
	board["removed"] = true
	board["clearing"] = false
	var board_node: Node3D = board["node"]
	if is_instance_valid(board_node):
		board_node.queue_free()
	_refresh_screw_visuals()
	_check_level_complete()


func _check_level_complete() -> void:
	for board in boards:
		if not bool(board["removed"]):
			return
	if toolbox_target_index < toolbox_targets.size() or not tray_colors.is_empty():
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
	if timer_label != null:
		timer_label.text = "TIME %s" % _format_time(level_elapsed)
	if progress_bar != null:
		progress_bar.value = 100.0 if total_screws <= 0 else (float(removed_screws) / float(total_screws)) * 100.0
	_refresh_tray_ui()
	_refresh_toolbox_ui()
