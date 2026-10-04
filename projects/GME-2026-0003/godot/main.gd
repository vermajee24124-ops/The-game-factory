extends Node3D

const ROAD_WIDTH := 16.0
const NARROW_WIDTH := 9.0
const ROAD_STEP := 10.0
const MAX_LEVEL_PREVIEW := 50

var state := "IDLE"
var current_screen := "main_menu"
var current_level := 1
var level_def:Dictionary = {}
var path_points:Array[Vector3] = []
var path_distances:Array[float] = []
var path_widths:Array[float] = []

var world_root:Node3D
var player_car:CharacterBody3D
var race_camera:Camera3D
var ai_racers:Array = []
var traffic:Array = []
var pickups:Array = []
var obstacles:Array = []

var player_progress := 0.0
var player_lane := 0.0
var player_speed := 0.0
var boost_energy := 40.0
var boosting := false
var damage := 0.0
var clean_score := 100.0
var race_clock := 0.0
var countdown_clock := 0.0
var collision_cooldown := 0.0
var invulnerable_time := 0.0
var left_held := false
var right_held := false
var brake_held := false

var ui_layer:CanvasLayer
var ui_root:Control
var screens:Dictionary = {}
var hud:Control
var toast:Label
var loading_screen:Control
var loading_logo:TextureRect
var loading_status:Label
var loading_progress:ProgressBar
var position_label:Label
var progress_bar:ProgressBar
var boost_bar:ProgressBar
var damage_bar:ProgressBar
var coin_label:Label
var speed_label:Label
var timer_label:Label
var target_label:Label
var environment_label:Label
var countdown_label:Label
var coins_label:Label
var diamonds_label:Label
var pre_race_label:Label
var pre_car_label:Label
var results_label:Label
var results_detail:Label
var next_button:Button
var double_button:Button
var menu_stage:Node3D
var menu_camera:Camera3D
var menu_car:CharacterBody3D
var menu_spin:=0.0
var impact_shake:=0.0
var race_theme_env:WorldEnvironment
var race_sun:DirectionalLight3D
var sky_material:ProceduralSkyMaterial
var last_rewards:Dictionary={}
var last_result:Dictionary={}
var double_reward_claimed:=false
var pickup_time:=0.0

var palette := {
    "bg":Color("#0B1020"),
    "panel":Color("#151B2E"),
    "panel_light":Color("#1E2740"),
    "primary":Color("#FF6B2C"),
    "secondary":Color("#23C4FF"),
    "success":Color("#3BD47A"),
    "warning":Color("#FFB020"),
    "danger":Color("#FF4D5E"),
    "coin":Color("#FFC93C"),
    "diamond":Color("#6BE1FF"),
    "text":Color("#F5F7FF"),
    "muted":Color("#A7B0CC")
}

func _ready()->void:
    SaveSystem.mark_launch()
    HapticsSystem.enabled=bool(SaveSystem.data["settings"]["haptics_enabled"])
    _setup_world()
    _build_menu_stage()
    StudioPolish.enhance_menu(menu_stage)
    _setup_ui()

    if OS.has_feature("web"):
        WebAdsManager.init()
        AdsManager.init()
        await _run_startup_sequence()
        return

    var consent_status := str(SaveSystem.data.get("privacy", {}).get("consent_status", "unknown"))
    if consent_status == "unknown":
        _show_privacy()
    else:
        AdsManager.init()
        await _run_startup_sequence()

func _setup_world()->void:
    world_root=Node3D.new()
    world_root.name="RuntimeWorld"
    add_child(world_root)
    var env:=WorldEnvironment.new()
    race_theme_env=env
    var e:=Environment.new()
    e.background_mode=Environment.BG_SKY
    e.background_color=Color("#10192B")
    var sky:=Sky.new()
    sky_material=ProceduralSkyMaterial.new()
    sky_material.sky_top_color=Color("#18314A")
    sky_material.sky_horizon_color=Color("#8AAED0")
    sky_material.ground_horizon_color=Color("#394B60")
    sky_material.ground_bottom_color=Color("#111A26")
    sky_material.sun_angle_max=18.0
    sky_material.sun_curve=0.12
    sky.sky_material=sky_material
    e.sky=sky
    e.background_energy_multiplier=0.92
    e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color=Color("#7896C8")
    e.ambient_light_energy=1.05
    e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    e.tonemap_exposure=1.10
    e.fog_enabled=true
    e.fog_light_color=Color("#56657F")
    e.fog_light_energy=0.20
    e.fog_density=0.0025
    e.fog_sky_affect=0.22
    env.environment=e
    world_root.add_child(env)
    var sun:=DirectionalLight3D.new()
    race_sun=sun
    sun.rotation_degrees=Vector3(-48.0,-28.0,0.0)
    sun.light_energy=1.45
    sun.light_color=Color("#D8E8FF")
    sun.shadow_enabled=true
    sun.directional_shadow_max_distance=140.0
    world_root.add_child(sun)

func _style(color:Color,radius:=16)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=color
    s.corner_radius_top_left=radius
    s.corner_radius_top_right=radius
    s.corner_radius_bottom_left=radius
    s.corner_radius_bottom_right=radius
    s.border_width_left=1
    s.border_width_top=1
    s.border_width_right=1
    s.border_width_bottom=1
    s.border_color=Color(1,1,1,0.08)
    s.shadow_color=Color(0,0,0,0.32)
    s.shadow_size=6
    return s

func _label(parent:Node,text_value:String,size:=22,color:=Color.WHITE)->Label:
    var l:=Label.new()
    l.text=text_value
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",color)
    parent.add_child(l)
    return l

func _button(parent:Node,text_value:String,size:=Vector2(300,70),primary:=true)->Button:
    var b:=Button.new()
    b.text=text_value
    b.custom_minimum_size=size
    b.add_theme_font_size_override("font_size",22)
    b.add_theme_stylebox_override("normal",_style(palette.primary if primary else palette.panel_light,12))
    b.add_theme_stylebox_override("hover",_style(palette.primary.lightened(0.08) if primary else palette.panel_light.lightened(0.08),12))
    b.add_theme_stylebox_override("pressed",_style(palette.primary.darkened(0.20) if primary else palette.panel_light.darkened(0.10),12))
    b.add_theme_stylebox_override("focus",_style(palette.primary.lightened(0.03) if primary else palette.panel_light,12))
    b.add_theme_stylebox_override("disabled",_style(Color(0.16,0.18,0.23,0.82),12))
    b.focus_mode=Control.FOCUS_ALL
    parent.add_child(b)
    return b

func _new_screen(id:String,title:String)->Control:
    var c:=Control.new()
    c.name=id
    c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    c.visible=false
    ui_root.add_child(c)
    screens[id]=c
    var panel:=Panel.new()
    panel.name="Panel"
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_theme_stylebox_override("panel",_style(palette.bg,0))
    c.add_child(panel)
    var t:=_label(panel,title,44,palette.text)
    t.position=Vector2(60,35)
    return c

func _setup_ui()->void:
    ui_layer=CanvasLayer.new()
    add_child(ui_layer)
    ui_root=Control.new()
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_layer.add_child(ui_root)
    _build_onboarding()
    _build_main_menu()
    _build_level_select()
    _build_pre_race()
    _build_race_hud()
    _build_pause()
    _build_wreck()
    _build_results()
    _build_garage()
    _build_shop()
    _build_collection()
    _build_daily_tasks()
    _build_settings()
    _build_privacy()
    _build_loading_screen()
    toast=_label(ui_root,"",22,palette.text)
    toast.position=Vector2(730,990)
    toast.visible=false

func _show_only(id:String)->void:
    for k in screens.keys():
        screens[k].visible=false
    screens[id].visible=true
    current_screen=id
    if menu_camera:
        menu_camera.current = id != "race" and id != "pause" and id != "wreck"
    if race_camera and id=="race":
        race_camera.current=true
    if hud:
        hud.visible = id == "race"
    _refresh_currency_header()

func _refresh_currency_header()->void:
    if coins_label:coins_label.text="COINS  %d" % EconomyService.coins()
    if diamonds_label:diamonds_label.text="DIAMONDS  %d" % EconomyService.diamonds()

func _build_menu_stage()->void:
    menu_stage=Node3D.new()
    menu_stage.name="MenuHeroStage"
    add_child(menu_stage)

    var floor:=MeshInstance3D.new()
    var fm:=PlaneMesh.new()
    fm.size=Vector2(30.0,22.0)
    floor.mesh=fm
    var floor_mat:=StandardMaterial3D.new()
    floor_mat.albedo_color=Color("#0B1324")
    floor_mat.metallic=0.12
    floor_mat.roughness=0.80
    floor.material_override=floor_mat
    menu_stage.add_child(floor)

    var platform:=MeshInstance3D.new()
    platform.name="HeroPlatform"
    var pm:=CylinderMesh.new()
    pm.top_radius=6.8
    pm.bottom_radius=7.3
    pm.height=0.34
    platform.mesh=pm
    platform.position=Vector3(0,0.12,0)
    var platform_mat:=StandardMaterial3D.new()
    platform_mat.albedo_color=Color("#111C31")
    platform_mat.metallic=0.42
    platform_mat.roughness=0.28
    platform.material_override=platform_mat
    menu_stage.add_child(platform)

    var accent_platform:=MeshInstance3D.new()
    accent_platform.name="HeroPlatformAccent"
    var apm:=CylinderMesh.new()
    apm.top_radius=5.9
    apm.bottom_radius=6.0
    apm.height=0.05
    accent_platform.mesh=apm
    accent_platform.position=Vector3(0,0.31,0)
    var accent_mat:=StandardMaterial3D.new()
    accent_mat.albedo_color=palette.secondary
    accent_mat.emission_enabled=true
    accent_mat.emission=palette.secondary
    accent_mat.emission_energy_multiplier=0.42
    accent_platform.material_override=accent_mat
    menu_stage.add_child(accent_platform)

    for x in [-7.0,-3.5,0.0,3.5,7.0]:
        var strip:=MeshInstance3D.new()
        var sm:=BoxMesh.new()
        sm.size=Vector3(0.08,0.03,18.0)
        strip.mesh=sm
        strip.position=Vector3(x,0.03,0)
        var gm:=StandardMaterial3D.new()
        gm.albedo_color=palette.secondary
        gm.emission_enabled=true
        gm.emission=palette.secondary
        gm.emission_energy_multiplier=0.50
        strip.material_override=gm
        menu_stage.add_child(strip)

    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-38,-145,0)
    key.light_energy=1.1
    key.light_color=Color("#D6E9FF")
    key.shadow_enabled=true
    menu_stage.add_child(key)

    var rim:=OmniLight3D.new()
    rim.position=Vector3(3.5,4.5,2.5)
    rim.light_energy=8.0
    rim.omni_range=14.0
    rim.light_color=Color("#23C4FF")
    menu_stage.add_child(rim)

    var warm:=OmniLight3D.new()
    warm.position=Vector3(-4.0,3.0,-2.0)
    warm.light_energy=5.0
    warm.omni_range=11.0
    warm.light_color=Color("#FF6B2C")
    menu_stage.add_child(warm)

    menu_car=_make_car("MENU_HERO",str(SaveSystem.data["progression"]["cars"]["selected"]),palette.primary)
    menu_car.position=Vector3(0,0.40,0)
    menu_car.rotation_degrees=Vector3(0,-28,0)
    menu_stage.add_child(menu_car)

    menu_camera=Camera3D.new()
    menu_camera.name="MenuCamera"
    menu_camera.position=Vector3(7.8,4.2,-10.0)
    menu_camera.fov=54.0
    menu_camera.near=0.1
    menu_camera.far=80.0
    menu_stage.add_child(menu_camera)
    menu_camera.look_at(Vector3(0,1.0,0),Vector3.UP)
    menu_camera.current=true

func _apply_race_theme()->void:
    if not race_theme_env or level_def.is_empty():
        return
    var env_id:=str(level_def.get("environment_id","sunrise_city"))
    var condition:=str(level_def.get("condition_id","Clear"))
    var bg:=Color("#0D1526")
    var ambient:=Color("#6F8DBA")
    var fog:=Color("#3B4A61")
    var sun_color:=Color("#D8E8FF")
    var sun_energy:=1.30

    match env_id:
        "sunrise_city":
            bg=Color("#18314A"); ambient=Color("#86A9CF"); fog=Color("#526984"); sun_color=Color("#FFE1B0"); sun_energy=1.50
        "coastal_highway":
            bg=Color("#0C2A3A"); ambient=Color("#6AB1C9"); fog=Color("#3D7182"); sun_color=Color("#D8F2FF"); sun_energy=1.45
        "desert_canyon":
            bg=Color("#3A2019"); ambient=Color("#B58B6A"); fog=Color("#76584A"); sun_color=Color("#FFD3A0"); sun_energy=1.55
        "mountain_pass":
            bg=Color("#182B32"); ambient=Color("#7FA8AD"); fog=Color("#4F6F73"); sun_color=Color("#D8FFFF"); sun_energy=1.40
        "industrial_night":
            bg=Color("#050812"); ambient=Color("#53698E"); fog=Color("#202A42"); sun_color=Color("#94B9FF"); sun_energy=0.72
        "snowline":
            bg=Color("#24405A"); ambient=Color("#AFC8D7"); fog=Color("#7790A1"); sun_color=Color("#F4FBFF"); sun_energy=1.35
        "neon_metro":
            bg=Color("#090B20"); ambient=Color("#6470C4"); fog=Color("#2C315F"); sun_color=Color("#AAB6FF"); sun_energy=0.80
        "volcanic_rim":
            bg=Color("#240B0B"); ambient=Color("#9E5F55"); fog=Color("#593431"); sun_color=Color("#FFB08A"); sun_energy=1.02

    if condition=="Night":
        bg=bg.darkened(0.28); ambient=ambient.darkened(0.20); fog=fog.darkened(0.12); sun_energy*=0.62
    elif condition=="Fog":
        fog=fog.lightened(0.18)
    elif condition=="Snow":
        ambient=ambient.lightened(0.10); fog=fog.lightened(0.10)
    elif condition=="Sandstorm":
        fog=Color("#8E6C52")
    elif condition=="Ash Haze":
        fog=Color("#554E4D")

    var e:=race_theme_env.environment
    e.background_color=bg
    e.ambient_light_color=ambient
    e.ambient_light_energy=1.0
    e.fog_light_color=fog
    e.fog_light_energy=0.34 if condition=="Fog" else 0.22
    e.fog_density=0.0038 if condition=="Fog" else 0.0025
    race_sun.light_color=sun_color
    race_sun.light_energy=sun_energy
    if sky_material:
        sky_material.sky_top_color=bg.darkened(0.10)
        sky_material.sky_horizon_color=ambient.lightened(0.12)
        sky_material.ground_horizon_color=fog.lightened(0.06)
        sky_material.ground_bottom_color=bg.darkened(0.35)

func _add_road_details()->void:
    if path_points.size()<2:
        return
    var step:=maxi(1,int(path_points.size()/85))
    var curb1:=StandardMaterial3D.new()
    curb1.albedo_color=Color("#D2D7E0")
    curb1.roughness=0.60
    curb1.metallic=0.18
    var curb2:=StandardMaterial3D.new()
    curb2.albedo_color=Color("#38475E")
    curb2.roughness=0.68
    for i in range(0,path_points.size()-1,step):
        var p:=path_points[i]
        var t:=_tangent_at_index(i)
        var side:=Vector3(-t.z,0,t.x).normalized()
        var half:=float(path_widths[i])*0.5
        for sgn in [-1.0,1.0]:
            var curb:=MeshInstance3D.new()
            var cm:=BoxMesh.new()
            cm.size=Vector3(0.42,0.12,5.8)
            curb.mesh=cm
            curb.position=p+side*sgn*(half+0.26)+Vector3.UP*0.08
            curb.rotation.y=atan2(t.x,t.z)
            curb.material_override=curb1 if ((i/step)%2==0) else curb2
            world_root.add_child(curb)

func _add_start_grid()->void:
    if path_points.size()<2:
        return
    var idx:=mini(3,path_points.size()-2)
    var p:=path_points[idx]
    var t:=_tangent_at_index(idx)
    var side:=Vector3(-t.z,0,t.x).normalized()
    for row in range(3):
        for col in range(6):
            var tile:=MeshInstance3D.new()
            var bm:=BoxMesh.new()
            bm.size=Vector3(1.55,0.035,1.8)
            tile.mesh=bm
            tile.position=p+t*float(row-1)*2.2+side*(float(col)-2.5)*2.5+Vector3.UP*0.10
            tile.rotation.y=atan2(t.x,t.z)
            var tm:=StandardMaterial3D.new()
            tm.albedo_color=Color("#F0F4FF") if ((row+col)%2==0) else Color("#101724")
            tile.material_override=tm
            world_root.add_child(tile)

func _spawn_landmarks(env_id:String,rng:RandomNumberGenerator)->void:
    var count:=mini(10,maxi(4,int(path_points.size()/24)))
    for n in range(count):
        var idx:=clampi(int(float(n+1)*float(path_points.size()-1)/float(count+1)),2,path_points.size()-2)
        var sample:=_sample_path(path_distances[idx])
        var sample_pos:Vector3=sample["pos"]
        var sample_tangent:Vector3=sample["tangent"]
        var sample_width:float=float(sample["width"])
        var side:Vector3=Vector3(-sample_tangent.z,0,sample_tangent.x).normalized()
        var sgn:float=1.0 if n%2==0 else -1.0
        var base:Vector3=sample_pos+side*sgn*(sample_width*0.5+6.0)

        var pole:=MeshInstance3D.new()
        var pm:=CylinderMesh.new()
        pm.top_radius=0.09
        pm.bottom_radius=0.12
        pm.height=5.0
        pole.mesh=pm
        pole.position=base+Vector3.UP*2.5
        var steel:=StandardMaterial3D.new()
        steel.albedo_color=Color("#56657C")
        steel.metallic=0.65
        steel.roughness=0.30
        pole.material_override=steel
        world_root.add_child(pole)

        var sign:=MeshInstance3D.new()
        var sm:=BoxMesh.new()
        sm.size=Vector3(2.8,1.0,0.12)
        sign.mesh=sm
        sign.position=base+Vector3.UP*4.8
        sign.rotation.y=atan2(sample_tangent.x,sample_tangent.z)
        var signmat:=StandardMaterial3D.new()
        signmat.albedo_color=palette.secondary if env_id=="neon_metro" else palette.primary
        signmat.emission_enabled=true
        signmat.emission=signmat.albedo_color
        signmat.emission_energy_multiplier=0.55
        sign.material_override=signmat
        world_root.add_child(sign)

func _impact_feedback()->void:
    impact_shake=minf(1.0,impact_shake+0.75)
    var flash:Node = hud.get_node_or_null("ImpactFlash") if hud else null
    if flash is ColorRect:
        flash.visible=true
        flash.modulate.a=0.42
        var tw:=create_tween()
        tw.tween_property(flash,"modulate:a",0.0,0.18)
        tw.finished.connect(func():if is_instance_valid(flash):flash.visible=false)

func _update_car_fx()->void:
    if not is_instance_valid(player_car):
        return
    var flame:Node=player_car.get_meta("boost_flame",null)
    if flame is Node3D:
        flame.visible=boosting
        if boosting:
            flame.scale=Vector3(0.85,0.72,0.35)+Vector3(0.12,0.08,0.16)*sin(race_clock*32.0)
    var glow:Node=player_car.get_meta("boost_glow",null)
    if glow is OmniLight3D:
        glow.visible=boosting
    var brake_fx:Node=player_car.get_meta("brake_glow",null)
    if brake_fx is MeshInstance3D:
        brake_fx.visible=brake_held

func _show_privacy()->void:
    _show_only("privacy")

func _build_privacy()->void:
    var c:=_new_screen("privacy","PRIVACY & AD CHOICE")
    var p:Control=c.get_node("Panel")

    var intro:=_label(p,"Turbo Rush works fully offline. Advertising is optional and uses the non-personalized mode.",30,palette.text)
    intro.position=Vector2(70,145)
    intro.size=Vector2(1200,90)
    intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

    var detail:=_label(p,"Choose whether Turbo Rush may load optional ads. You can keep playing normally without ads.",23,palette.muted)
    detail.position=Vector2(70,260)
    detail.size=Vector2(1250,80)
    detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

    var allow:=_button(p,"ALLOW OPTIONAL NON-PERSONALIZED ADS",Vector2(650,82),true)
    allow.position=Vector2(70,390)
    allow.pressed.connect(func():
        SaveSystem.data["privacy"]["consent_status"]="non_personalized"
        SaveSystem.data["privacy"]["personalized_ads"]=false
        SaveSystem.data["privacy"]["consent_timestamp_unix"]=Time.get_unix_time_from_system()
        SaveSystem.save_now()
        AdsManager.init()
        await _run_startup_sequence()
    )

    var deny:=_button(p,"CONTINUE WITHOUT ADS",Vector2(650,82),false)
    deny.position=Vector2(70,495)
    deny.pressed.connect(func():
        SaveSystem.data["privacy"]["consent_status"]="denied"
        SaveSystem.data["privacy"]["personalized_ads"]=false
        SaveSystem.data["privacy"]["consent_timestamp_unix"]=Time.get_unix_time_from_system()
        SaveSystem.save_now()
        AdsManager.set_online(false)
        await _run_startup_sequence()
    )

    var note:=_label(p,"Choice: non-personalized ads only. No purchases or external billing are used.",20,palette.secondary)
    note.position=Vector2(70,625)
    note.size=Vector2(1300,70)

func _build_loading_screen()->void:
    loading_screen=Control.new()
    loading_screen.name="StartupLoading"
    loading_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.add_child(loading_screen)
    var bg:=Panel.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.add_theme_stylebox_override("panel",_style(Color("#050812"),0))
    loading_screen.add_child(bg)

    loading_logo=TextureRect.new()
    loading_logo.name="Logo"
    loading_logo.position=Vector2(660,175)
    loading_logo.size=Vector2(600,600)
    loading_logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    loading_logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var logo=load("res://assets/turbo_rush_logo.svg")
    if logo:
        loading_logo.texture=logo
    loading_screen.add_child(loading_logo)

    var title:=_label(loading_screen,"TURBO RUSH",54,palette.text)
    title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    title.position=Vector2(460,735)
    title.size=Vector2(1000,80)

    loading_status=_label(loading_screen,"INITIALIZING GARAGE...",22,palette.muted)
    loading_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    loading_status.position=Vector2(520,815)
    loading_status.size=Vector2(880,50)

    var studio_mark:=_label(loading_screen,"VERMA GAME STUDIOS • OFFLINE-READY",16,palette.muted)
    studio_mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    studio_mark.position=Vector2(620,930)
    studio_mark.size=Vector2(680,34)

    loading_progress=ProgressBar.new()
    loading_progress.position=Vector2(620,875)
    loading_progress.size=Vector2(680,18)
    loading_progress.min_value=0
    loading_progress.max_value=100
    loading_progress.value=0
    loading_progress.show_percentage=false
    loading_screen.add_child(loading_progress)

func _run_startup_sequence()->void:
    _show_only("main_menu")
    for k in screens.keys():
        screens[k].visible=false
    if loading_screen:
        loading_screen.visible=true

    # Ads may appear only while this startup/loading screen is active.
    # The native adapter must itself confirm connectivity and consent.
    AdsManager.show_loading_banners()

    var steps=[
        ["LOADING TURBO RUSH...",10],
        ["PREPARING GARAGE...",35],
        ["PREPARING CAMPAIGN...",60],
        ["CHECKING LOCAL SAVE...",82],
        ["READY TO RACE",100]
    ]
    for step in steps:
        loading_status.text=str(step[0])
        loading_progress.value=float(step[1])
        await get_tree().create_timer(0.34).timeout

    # Never make the player wait for an ad response.
    AdsManager.hide_loading_banners()
    loading_screen.visible=false

    if not bool(SaveSystem.data["profile"].get("onboarding_completed", false)):
        _show_onboarding()
    else:
        _show_main_menu()

func _show_main_menu()->void:
    AdsManager.hide_loading_banners()
    var selected_id:=str(SaveSystem.data["progression"]["cars"]["selected"])
    var selected_car:Dictionary=GameConfig.car(selected_id)
    if menu_car and is_instance_valid(menu_car):
        var current_id:=str(menu_car.get_meta("car_id",""))
        if selected_id!=current_id and menu_stage:
            menu_car.queue_free()
            menu_car=_make_car("MENU_HERO",selected_id,palette.primary)
            menu_car.position=Vector3(0,0.40,0)
            menu_car.rotation_degrees=Vector3(0,-28,0)
            menu_stage.add_child(menu_car)
    var hero_name:Label=screens["main_menu"].get_node_or_null("Panel/HeroInfo/HeroCarName") as Label
    if hero_name:
        hero_name.text=str(selected_car.get("name","Rookie GT"))
    var hero_stats:Label=screens["main_menu"].get_node_or_null("Panel/HeroInfo/HeroCarStats") as Label
    if hero_stats:
        hero_stats.text="%d KM/H • %.1f ACCEL • +%d BOOST\nLevel-based finite racing • 1 player + 5 AI\nCoins • Diamonds • Boost • Chests • Stars" % [
            int(float(selected_car.get("top_speed",140.0))),
            float(selected_car.get("accel",8.0)),
            int(float(selected_car.get("boost_power",25.0)))
        ]
    _show_only("main_menu")

func _show_onboarding()->void:
    _show_only("onboarding")
    var p:Control=screens["onboarding"].get_node("Panel")
    var bonus:=_button(p,"START ROOKIE RACE",Vector2(480,90),true)
    bonus.position=Vector2(70,300)
    bonus.pressed.connect(func():
        if not bool(SaveSystem.data["profile"].get("onboarding_completed",false)):
            EconomyService.grant_coins(120,"onboarding_bonus")
            _start_race(1)
    )

func _build_onboarding()->void:
    var c:=_new_screen("onboarding","WELCOME TO TURBO RUSH")
    var p:Control=c.get_node("Panel")
    var intro:=_label(p,"Learn the basics in one guided Level 1 race.",28,palette.muted)
    intro.position=Vector2(70,160)
    var steps:=_label(p,"STEER  •  AVOID TRAFFIC  •  COLLECT COINS  •  TAP BOOST\nFinish the race to unlock Level 2 and unlock your first upgrade.",24,palette.text)
    steps.position=Vector2(70,225)

func _build_main_menu()->void:
    var c:=_new_screen("main_menu","TURBO RUSH")
    var p:Control=c.get_node("Panel")

    var logo:=TextureRect.new()
    logo.name="MenuLogo"
    logo.position=Vector2(1410,18)
    logo.size=Vector2(430,150)
    logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.texture=load("res://assets/turbo_rush_logo.svg")
    p.add_child(logo)

    var version_badge:=_label(p,"v%s • OFFLINE-FIRST • 6 RACERS" % GameConfig.GAME_VERSION,18,palette.muted)
    version_badge.position=Vector2(1415,160)
    coins_label=_label(p,"COINS  0",24,palette.coin)
    coins_label.position=Vector2(70,110)
    diamonds_label=_label(p,"DIAMONDS  0",24,palette.diamond)
    diamonds_label.position=Vector2(280,110)
    var sub:=_label(p,"FAST • FINITE • SKILL-BASED RACING",22,palette.muted)
    sub.position=Vector2(70,155)
    var play:=_button(p,"PLAY",Vector2(500,100),true)
    play.position=Vector2(70,250)
    play.pressed.connect(func():
        current_level=int(SaveSystem.data["profile"]["highest_unlocked_level"])
        _prepare_pre_race()
        _show_only("pre_race")
    )
    var garage:=_button(p,"GARAGE",Vector2(240,72),false)
    garage.position=Vector2(70,380)
    garage.pressed.connect(func():
        _refresh_garage()
        _show_only("garage")
    )
    var shop:=_button(p,"REWARDS",Vector2(240,72),false)
    shop.position=Vector2(330,380)
    shop.pressed.connect(func():_show_only("shop"))
    var campaign:=_button(p,"CAMPAIGN",Vector2(500,78),true)
    campaign.position=Vector2(70,490)
    campaign.pressed.connect(func():
        _refresh_level_select()
        _show_only("level_select")
    )
    var settings:=_button(p,"SETTINGS",Vector2(240,72),false)
    settings.position=Vector2(70,585)
    settings.pressed.connect(func():_show_only("settings"))
    var daily:=_button(p,"DAILY REWARDS",Vector2(240,72),false)
    daily.position=Vector2(330,585)
    daily.pressed.connect(func():_show_only("daily_tasks"))
    var info:=Panel.new()
    info.name="HeroInfo"
    info.position=Vector2(760,220)
    info.size=Vector2(1050,620)
    info.add_theme_stylebox_override("panel",_style(palette.panel,24))
    p.add_child(info)
    var h:=_label(info,"YOUR GARAGE",28,palette.muted)
    h.position=Vector2(45,35)
    var selected_menu_id:=str(SaveSystem.data["progression"]["cars"]["selected"])
    var selected_menu_car:Dictionary=GameConfig.car(selected_menu_id)
    var car:=_label(info,str(selected_menu_car.get("name","Rookie GT")),68,palette.text)
    car.name="HeroCarName"
    car.position=Vector2(45,90)
    var d:=_label(info,"%d KM/H • %.1f ACCEL • +%d BOOST\nLevel-based finite racing • 1 player + 5 AI\nCoins • Diamonds • Boost • Chests • Stars" % [
        int(float(selected_menu_car.get("top_speed",140.0))),
        float(selected_menu_car.get("accel",8.0)),
        int(float(selected_menu_car.get("boost_power",25.0)))
    ],26,palette.muted)
    d.name="HeroCarStats"
    d.position=Vector2(45,195)

func _build_level_select()->void:
    var c:=_new_screen("level_select","CAMPAIGN")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var grid:=GridContainer.new()
    grid.name="LevelGrid"
    grid.columns=10
    grid.position=Vector2(65,135)
    grid.size=Vector2(1800,820)
    grid.add_theme_constant_override("h_separation",10)
    grid.add_theme_constant_override("v_separation",10)
    p.add_child(grid)

func _refresh_level_select()->void:
    var grid:GridContainer=screens["level_select"].get_node("Panel/LevelGrid")
    for n in grid.get_children():n.queue_free()
    var unlocked:=int(SaveSystem.data["profile"]["highest_unlocked_level"])
    for level in range(1,MAX_LEVEL_PREVIEW+1):
        var b:=_button(grid,"LEVEL %d" % level,Vector2(165,75),level<=unlocked)
        b.disabled=level>unlocked
        b.pressed.connect(func(l=level):
            current_level=l
            _prepare_pre_race()
            _show_only("pre_race")
        )

func _build_pre_race()->void:
    var c:=_new_screen("pre_race","PRE-RACE")
    var p:Control=c.get_node("Panel")
    pre_race_label=_label(p,"",34,palette.secondary)
    pre_race_label.position=Vector2(65,120)
    pre_car_label=_label(p,"",28,palette.text)
    pre_car_label.position=Vector2(65,270)
    var back:=_button(p,"BACK",Vector2(170,60),false)
    back.position=Vector2(65,885)
    back.pressed.connect(func():_show_main_menu())
    var race:=_button(p,"RACE",Vector2(430,90),true)
    race.position=Vector2(930,805)
    race.pressed.connect(func():_start_race(current_level))
    var hint:=Panel.new()
    hint.position=Vector2(650,150)
    hint.size=Vector2(700,560)
    hint.add_theme_stylebox_override("panel",_style(palette.panel,24))
    p.add_child(hint)
    var hh:=_label(hint,"RACE BRIEF",28,palette.muted)
    hh.position=Vector2(35,30)
    var body:=_label(hint,"Track is generated from the deterministic level seed.\nTraffic and obstacles scale with difficulty.\nEvery 10th level is Elite.\nFinish positions 1–5 unlock the next level.",24,palette.text)
    body.position=Vector2(35,100)
    var left:=_button(p,"< CAR",Vector2(170,70),false)
    left.position=Vector2(1480,250)
    left.pressed.connect(func():_cycle_car(-1))
    var right:=_button(p,"CAR >",Vector2(170,70),false)
    right.position=Vector2(1665,250)
    right.pressed.connect(func():_cycle_car(1))

func _environment_name(id:String)->String:
    for e in GameConfig.ENVIRONMENTS:
        if str(e[0])==id:
            return str(e[1])
    return id

func _prepare_pre_race()->void:
    var unlocked:=int(SaveSystem.data["profile"]["highest_unlocked_level"])
    current_level=clampi(current_level,1,unlocked)
    level_def=LevelGenerator.generate(current_level)
    pre_race_label.text="LEVEL %d • %s\n%s • %s\nTarget %.0fs • Difficulty %.2f" % [current_level,str(level_def.race_type),_environment_name(str(level_def.environment_id)),str(level_def.condition_id),float(level_def.target_time_sec),float(level_def.difficulty)]
    var id:=str(SaveSystem.data["progression"]["cars"]["selected"])
    var c:=GameConfig.car(id)
    var up:Dictionary=SaveSystem.data["progression"]["upgrades"]
    pre_car_label.text="%s\nTop Speed %d km/h • Accel %.1f • Boost +%d km/h\nUpgrades: Speed %d • Handling %d • Stability %d" % [str(c.get("name","Rookie GT")),int(float(c.get("top_speed",140.0))+2.5*int(up.get("top_speed",0))),float(c.get("accel",8.0))+0.35*int(up.get("acceleration",0)),int(float(c.get("boost_power",25.0))+2.0*int(up.get("boost_power",0))),int(up.get("top_speed",0)),int(up.get("handling",0)),int(up.get("stability",0))]

func _cycle_car(direction:int)->void:
    var ids:Array=GameConfig.CARS.keys()
    var idx:=ids.find(SaveSystem.data["progression"]["cars"]["selected"])
    if idx<0:idx=0
    for _i in range(ids.size()):
        idx=(idx+direction+ids.size())%ids.size()
        var id:=str(ids[idx])
        if ProgressionService.owns_car(id):
            ProgressionService.select_car(id)
            break
    _prepare_pre_race()

func _build_race_hud()->void:
    hud=Control.new()
    hud.name="RaceHUD"
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.visible=false
    ui_layer.add_child(hud)

    var pos_panel:=Panel.new()
    pos_panel.position=Vector2(28,28)
    pos_panel.size=Vector2(160,78)
    pos_panel.add_theme_stylebox_override("panel",_style(Color(0.05,0.07,0.12,0.88),16))
    hud.add_child(pos_panel)
    position_label=_label(pos_panel,"1/6",40,palette.text)
    position_label.position=Vector2(24,13)

    progress_bar=ProgressBar.new()
    progress_bar.position=Vector2(225,38)
    progress_bar.size=Vector2(1010,24)
    progress_bar.max_value=1.0
    progress_bar.show_percentage=false
    progress_bar.add_theme_stylebox_override("background",_style(Color(0.05,0.07,0.12,0.86),12))
    progress_bar.add_theme_stylebox_override("fill",_style(palette.secondary,12))
    hud.add_child(progress_bar)

    environment_label=_label(hud,"",20,palette.text)
    environment_label.position=Vector2(225,70)
    environment_label.size=Vector2(650,35)

    target_label=_label(hud,"TARGET 02:15",18,palette.muted)
    target_label.position=Vector2(910,70)
    target_label.size=Vector2(320,32)
    target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

    timer_label=_label(hud,"00:00",28,palette.text)
    timer_label.position=Vector2(1245,36)
    timer_label.size=Vector2(220,42)
    timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

    coin_label=_label(hud,"COINS 0",22,palette.coin)
    coin_label.position=Vector2(1515,38)
    coin_label.size=Vector2(260,35)
    coin_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
    speed_label=_label(hud,"0 km/h",23,palette.text)
    speed_label.position=Vector2(1515,72)
    speed_label.size=Vector2(260,35)
    speed_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

    var damage_label:=_label(hud,"DAMAGE",18,palette.muted)
    damage_label.position=Vector2(38,187)
    damage_label.size=Vector2(170,28)

    damage_bar=ProgressBar.new()
    damage_bar.position=Vector2(38,215)
    damage_bar.size=Vector2(280,18)
    damage_bar.max_value=100
    damage_bar.show_percentage=false
    damage_bar.add_theme_stylebox_override("background",_style(Color(0.05,0.07,0.12,0.86),9))
    damage_bar.add_theme_stylebox_override("fill",_style(palette.danger,9))
    hud.add_child(damage_bar)

    boost_bar=ProgressBar.new()
    boost_bar.position=Vector2(1450,910)
    boost_bar.size=Vector2(370,28)
    boost_bar.max_value=100
    boost_bar.show_percentage=false
    boost_bar.add_theme_stylebox_override("background",_style(Color(0.05,0.07,0.12,0.88),10))
    boost_bar.add_theme_stylebox_override("fill",_style(palette.secondary,10))
    hud.add_child(boost_bar)

    var impact_flash:=ColorRect.new()
    impact_flash.name="ImpactFlash"
    impact_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    impact_flash.color=Color("#FF5368")
    impact_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    impact_flash.visible=false
    hud.add_child(impact_flash)

    countdown_label=_label(hud,"",98,palette.text)
    countdown_label.position=Vector2(860,330)
    countdown_label.size=Vector2(220,120)
    countdown_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

    var left:=_button(hud,"◀",Vector2(150,96),false)
    left.position=Vector2(34,845)
    left.button_down.connect(func():left_held=true)
    left.button_up.connect(func():left_held=false)

    var brake:=_button(hud,"BRAKE",Vector2(170,96),false)
    brake.position=Vector2(195,845)
    brake.button_down.connect(func():brake_held=true)
    brake.button_up.connect(func():brake_held=false)

    var right:=_button(hud,"▶",Vector2(150,96),false)
    right.position=Vector2(386,845)
    right.button_down.connect(func():right_held=true)
    right.button_up.connect(func():right_held=false)

    var nitro_label:=_label(hud,"NITRO",18,palette.muted)
    nitro_label.position=Vector2(1450,875)
    nitro_label.size=Vector2(370,30)
    nitro_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
    var boost:=_button(hud,"BOOST",Vector2(200,118),true)
    boost.position=Vector2(1600,735)
    boost.pressed.connect(func():_try_boost())

    var pause:=_button(hud,"Ⅱ",Vector2(88,64),false)
    pause.position=Vector2(38,122)
    pause.pressed.connect(func():_pause_race())

func _build_pause()->void:
    var c:=_new_screen("pause","PAUSED")
    var p:Control=c.get_node("Panel")
    var resume:=_button(p,"RESUME",Vector2(350,80),true)
    resume.position=Vector2(70,220)
    resume.pressed.connect(func():_resume_race())
    var restart:=_button(p,"RESTART",Vector2(350,80),false)
    restart.position=Vector2(70,325)
    restart.pressed.connect(func():
        _resume_race()
        _start_race(current_level)
    )
    var quit:=_button(p,"QUIT",Vector2(350,80),false)
    quit.position=Vector2(70,430)
    quit.pressed.connect(func():_quit_race())

func _build_wreck()->void:
    var c:=_new_screen("wreck","WRECKED")
    var p:Control=c.get_node("Panel")
    var info:=_label(p,"Damage reached 100. Choose a continuation.",28,palette.muted)
    info.position=Vector2(70,150)
    var ad:=_button(p,"WATCH AD TO REVIVE",Vector2(430,78),true)
    ad.name="ReviveAd"
    ad.position=Vector2(70,250)
    ad.pressed.connect(func():_revive_with_ad())
    var dia:=_button(p,"REVIVE • 5 DIAMONDS",Vector2(430,78),false)
    dia.position=Vector2(70,350)
    dia.pressed.connect(func():_revive_with_diamonds())
    var quit:=_button(p,"QUIT RACE",Vector2(430,78),false)
    quit.position=Vector2(70,450)
    quit.pressed.connect(func():_finish_race(false))

func _build_results()->void:
    var c:=_new_screen("results","RESULTS")
    var p:Control=c.get_node("Panel")
    results_label=_label(p,"1st PLACE",72,palette.coin)
    results_label.position=Vector2(70,140)
    results_detail=_label(p,"",24,palette.text)
    results_detail.position=Vector2(70,250)
    next_button=_button(p,"NEXT LEVEL",Vector2(430,85),true)
    next_button.name="NextLevel"
    next_button.position=Vector2(70,760)
    next_button.pressed.connect(func():
        current_level+=1
        _prepare_pre_race()
        _show_only("pre_race")
    )
    var retry:=_button(p,"RETRY",Vector2(260,75),false)
    retry.position=Vector2(530,765)
    retry.pressed.connect(func():_start_race(current_level))
    var menu:=_button(p,"MENU",Vector2(200,75),false)
    menu.position=Vector2(820,765)
    menu.pressed.connect(func():_show_main_menu())
    double_button=_button(p,"WATCH AD • DOUBLE REWARDS",Vector2(560,70),false)
    double_button.position=Vector2(1060,765)
    double_button.disabled=true
    double_button.pressed.connect(func():
        if double_reward_claimed or last_rewards.is_empty():
            return
        AdsManager.show_rewarded("double_coins",func(ok:bool):
            if not ok:
                _show_toast("Rewarded ad unavailable")
                return
            if double_reward_claimed:
                return
            double_reward_claimed=true
            EconomyService.grant_coins(int(last_rewards.get("total_coins",0)),"rewarded_double")
            EconomyService.grant_diamonds(int(last_rewards.get("total_diamonds",0)),"rewarded_double")
            double_button.disabled=true
            double_button.text="REWARDS DOUBLED"
            _refresh_currency_header()
            _show_toast("Rewards doubled")
        ) )

func _build_garage()->void:
    var c:=_new_screen("garage","GARAGE")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var cars_scroll:=ScrollContainer.new()
    cars_scroll.name="CarsScroll"
    cars_scroll.position=Vector2(55,130)
    cars_scroll.size=Vector2(520,730)
    p.add_child(cars_scroll)
    var cars:=VBoxContainer.new()
    cars.name="Cars"
    cars.custom_minimum_size=Vector2(500,900)
    cars.add_theme_constant_override("separation",8)
    cars_scroll.add_child(cars)

    var upgrades_scroll:=ScrollContainer.new()
    upgrades_scroll.name="UpgradesScroll"
    upgrades_scroll.position=Vector2(610,130)
    upgrades_scroll.size=Vector2(570,730)
    p.add_child(upgrades_scroll)
    var upgrades:=VBoxContainer.new()
    upgrades.name="Upgrades"
    upgrades.custom_minimum_size=Vector2(550,800)
    upgrades.add_theme_constant_override("separation",8)
    upgrades_scroll.add_child(upgrades)

    var cosmetics_scroll:=ScrollContainer.new()
    cosmetics_scroll.name="CosmeticsScroll"
    cosmetics_scroll.position=Vector2(1210,130)
    cosmetics_scroll.size=Vector2(610,630)
    p.add_child(cosmetics_scroll)
    var cosmetics:=VBoxContainer.new()
    cosmetics.name="Cosmetics"
    cosmetics.custom_minimum_size=Vector2(590,900)
    cosmetics.add_theme_constant_override("separation",8)
    cosmetics_scroll.add_child(cosmetics)
    var collection:=_button(p,"COLLECTION • 54 SKINS / 48 CARDS",Vector2(610,76),true)
    collection.position=Vector2(1210,780)
    collection.pressed.connect(func():_refresh_collection("skins");_show_only("collection"))

func _refresh_garage()->void:
    var cars:VBoxContainer=screens["garage"].get_node("Panel/CarsScroll/Cars")
    var upgrades:VBoxContainer=screens["garage"].get_node("Panel/UpgradesScroll/Upgrades")
    var cosmetics:VBoxContainer=screens["garage"].get_node("Panel/CosmeticsScroll/Cosmetics")
    for n in cars.get_children():n.queue_free()
    for n in upgrades.get_children():n.queue_free()
    for n in cosmetics.get_children():n.queue_free()
    var owned:Array=SaveSystem.data["progression"]["cars"]["owned"]
    _label(cars,"CARS • %d TOTAL" % GameConfig.CARS.size(),28,palette.muted)
    for id in GameConfig.CARS.keys():
        var cd:Dictionary=GameConfig.car(str(id))
        var owned_now:=owned.has(id)
        var can_buy:=ProgressionService.can_buy_car(str(id))
        var title:=str(cd.get("name",""))+" • L"+str(cd.get("level",1))
        title+=" • "+str(cd.get("ability","Balanced"))
        if not owned_now:
            title+=" • "+str(cd.get("cost_coins",cd.get("cost",0)))+" Coins + "+str(cd.get("cost_diamonds",0))+" Diamonds"
        var b:=_button(cars,title,Vector2(500,60),owned_now or can_buy)
        b.disabled=not (owned_now or can_buy)
        b.pressed.connect(func(car_id=str(id)):
            if ProgressionService.owns_car(car_id):
                ProgressionService.select_car(car_id)
                _show_toast("Equipped")
            elif ProgressionService.buy_car(car_id):
                _show_toast("Car unlocked")
            else:
                _show_toast("Level or Coins required")
            _refresh_garage()
            _refresh_currency_header()
        )

    _label(upgrades,"PERFORMANCE",28,palette.muted)
    for stat in ProgressionService.STAT_KEYS:
        var row:=HBoxContainer.new()
        row.custom_minimum_size=Vector2(560,58)
        upgrades.add_child(row)
        var cur:=ProgressionService.upgrade_level(stat)
        var label:=_label(row,str(stat).replace("_"," ").capitalize()+" • "+str(cur),19,palette.text)
        label.custom_minimum_size=Vector2(330,55)
        var b:=_button(row,"MAX" if cur>=10 else "UP "+str(GameConfig.UPGRADE_COSTS[cur+1]),Vector2(200,52),true)
        b.disabled=cur>=10 or not ProgressionService.can_upgrade(stat)
        b.pressed.connect(func(s=stat):
            if ProgressionService.upgrade(s):_show_toast("Upgrade applied")
            else:_show_toast("Check level and Coins")
            _refresh_garage()
            _refresh_currency_header()
        )

    _label(cosmetics,"PAINTS + WHEELS",28,palette.muted)
    for id in GameConfig.PAINTS.keys():
        var item:Dictionary=GameConfig.paint(str(id))
        var owned_p:=ProgressionService.has_cosmetic(str(id))
        var cur_p:=str(SaveSystem.data["cosmetics"]["equipped"].get("paint","paint_red"))==str(id)
        var ptxt:=str(item.get("name",""))+" • L"+str(item.get("level",1))
        if not owned_p:ptxt+=" • "+str(item.get("cost",0))+" "+str(item.get("currency","coins")).capitalize()
        var b:=_button(cosmetics,("✓ " if cur_p else "")+ptxt,Vector2(590,54),owned_p or ProgressionService.player_level()>=int(item.get("level",1)))
        b.disabled=not (owned_p or ProgressionService.player_level()>=int(item.get("level",1)))
        b.pressed.connect(func(paint_id=str(id)):
            if ProgressionService.buy_paint(paint_id):_show_toast("Paint equipped")
            else:_show_toast("Level or currency required")
            _refresh_garage()
            _refresh_currency_header()
        )
    for id in GameConfig.WHEELS.keys():
        var item:Dictionary=GameConfig.wheel(str(id))
        var owned_w:=ProgressionService.has_cosmetic(str(id))
        var cur_w:=str(SaveSystem.data["cosmetics"]["equipped"].get("wheel","wheel_stock"))==str(id)
        var wtxt:=str(item.get("name",""))+" • L"+str(item.get("level",1))+" • "+str(item.get("ability","Balanced Wheels"))
        if not owned_w:wtxt+=" • "+str(item.get("cost_coins",item.get("cost",0)))+" Coins + "+str(item.get("cost_diamonds",0))+" Diamonds"
        var b:=_button(cosmetics,("✓ " if cur_w else "")+wtxt,Vector2(590,54),owned_w or ProgressionService.player_level()>=int(item.get("level",1)))
        b.disabled=not (owned_w or ProgressionService.player_level()>=int(item.get("level",1)))
        b.pressed.connect(func(wheel_id=str(id)):
            if ProgressionService.buy_wheel(wheel_id):_show_toast("Wheels equipped")
            else:_show_toast("Level or currency required")
            _refresh_garage()
            _refresh_currency_header()
        )

func _build_collection()->void:
    var c:=_new_screen("collection","COLLECTION")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_only("garage"))
    var skins_tab:=_button(p,"SKINS 54",Vector2(220,65),true)
    skins_tab.position=Vector2(70,105)
    skins_tab.pressed.connect(func():_refresh_collection("skins"))
    var cards_tab:=_button(p,"CARDS 48",Vector2(220,65),false)
    cards_tab.position=Vector2(310,105)
    cards_tab.pressed.connect(func():_refresh_collection("cards"))
    var hint:=_label(p,"Equip one skin. Equip up to three cards for small passive bonuses.",20,palette.muted)
    hint.position=Vector2(560,120)
    var scroll:=ScrollContainer.new()
    scroll.name="Scroll"
    scroll.position=Vector2(70,195)
    scroll.size=Vector2(1740,760)
    p.add_child(scroll)
    var list:=VBoxContainer.new()
    list.name="List"
    list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation",8)
    scroll.add_child(list)

func _refresh_collection(category:String)->void:
    var list:VBoxContainer=screens["collection"].get_node("Panel/Scroll/List")
    for n in list.get_children(): n.queue_free()
    if category=="skins":
        _label(list,"SKINS • %d/54 OWNED" % _count_owned_skins(),28,palette.muted)
        for id in ContentCatalog.SKINS.keys():
            var item:Dictionary=ContentCatalog.skin(str(id))
            var owned:=ProgressionService.owns_skin(str(id))
            var equipped:=str(SaveSystem.data["cosmetics"]["equipped"].get("skin","skin_01"))==str(id)
            var text_value:=("%s • %s" % [str(item.get("name","")),str(item.get("rarity","common")).capitalize()])
            if equipped: text_value="✓ "+text_value+" • EQUIPPED"
            elif not owned: text_value+= " • LOCKED"
            var b:=_button(list,text_value,Vector2(1620,58),owned)
            b.disabled=not owned
            b.pressed.connect(func(skin_id=str(id)):
                if ProgressionService.equip_skin(skin_id): _show_toast("Skin equipped")
                _refresh_collection("skins")
            )
    else:
        _label(list,"CARDS • %d/48 OWNED • EQUIPPED %d/3" % [_count_owned_cards(),ProgressionService.equipped_cards().size()],28,palette.muted)
        for id in ContentCatalog.CARDS.keys():
            var item:Dictionary=ContentCatalog.card(str(id))
            var owned:=ProgressionService.owns_card(str(id))
            var equipped:=ProgressionService.equipped_cards().has(str(id))
            var text_value:=("%s • %s • %s" % [str(item.get("name","")),str(item.get("rarity","common")).capitalize(),str(item.get("type","")).replace("_"," ").capitalize()])
            if owned:
                text_value+=" • "+("EQUIPPED" if equipped else "OWNED")
            else:
                text_value+=" • LOCKED"
            var b:=_button(list,text_value,Vector2(1620,58),owned)
            b.disabled=not owned
            b.pressed.connect(func(card_id=str(id)):
                if not ProgressionService.toggle_card_equip(card_id): _show_toast("Keep 1–3 cards equipped")
                _refresh_collection("cards")
            )

func _count_owned_skins()->int:
    var count:=0
    for id in ContentCatalog.SKINS.keys():
        if ProgressionService.owns_skin(str(id)): count+=1
    return count

func _count_owned_cards()->int:
    var count:=0
    for id in ContentCatalog.CARDS.keys():
        if ProgressionService.owns_card(str(id)): count+=1
    return count

func _build_daily_tasks()->void:
    var c:=_new_screen("daily_tasks","DAILY REWARDS")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var intro:=_label(p,"Three optional rewarded-ad claims per day. Rewards are mostly Coins; Diamonds are uncommon.",24,palette.muted)
    intro.position=Vector2(70,130)
    for i in range(3):
        var id:="bonus_coins"
        var b:=_button(p,"WATCH AD • DAILY BONUS %d" % (i+1),Vector2(620,82),true)
        b.position=Vector2(70,220+i*120)
        b.pressed.connect(func():_claim_daily_reward())
    var info:=_label(p,"Reward pool: 80 / 120 / 180 / 250 / 400 Coins\nRare reward: 1 / 2 / 3 Diamonds\nMaximum: 3 rewarded claims each day.",26,palette.text)
    info.position=Vector2(760,235)

func _claim_daily_reward()->void:
    AdsManager.show_rewarded("bonus_coins",func(ok:bool):
        if not ok:
            _show_toast("Rewarded ad unavailable")
            return
        var roll:=RandomNumberGenerator.new()
        roll.randomize()
        if roll.randf()<0.10:
            var diamonds:=roll.randi_range(1,3)
            EconomyService.grant_diamonds(diamonds,"daily_reward_ad")
            _show_toast("Daily reward • %d Diamonds" % diamonds)
        else:
            var pool:Array=[80,120,180,250,400]
            var coins:=int(pool[roll.randi_range(0,pool.size()-1)])
            EconomyService.grant_coins(coins,"daily_reward_ad")
            _show_toast("Daily reward • %d Coins" % coins)
        _refresh_currency_header()
    )

func _build_shop()->void:
    var c:=_new_screen("shop","REWARDS")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var note:=_label(p,"Free-to-play rewards only • Earn Coins, Diamonds, cars, wheels and cards through gameplay.",22,palette.muted)
    note.position=Vector2(60,105)
    var daily:=_button(p,"OPEN DAILY TASKS",Vector2(420,70),true)
    daily.position=Vector2(60,165)
    daily.pressed.connect(func():_show_only("daily_tasks"))
    var campaign:=_button(p,"PLAY CAMPAIGN",Vector2(420,70),false)
    campaign.position=Vector2(500,165)
    campaign.pressed.connect(func():_show_only("level_select"))
    var info:=_label(p,"Turbo Rush 1.7 has no in-app purchase or external billing system.\nAll progression and unlocks are available through normal gameplay.",30,palette.text)
    info.position=Vector2(60,300)
    var details:=_label(p,"Complete races • collect track pickups • open earned chests • claim daily rewards • upgrade your garage.",24,palette.muted)
    details.position=Vector2(60,410)
    var ad_info:=_label(p,"Optional rewarded ads may appear only when you explicitly choose an ad reward.",22,palette.secondary)
    ad_info.position=Vector2(60,520)

func _build_settings()->void:
    var c:=_new_screen("settings","SETTINGS")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var h:=CheckButton.new()
    h.text="Haptics"
    h.position=Vector2(70,170)
    h.button_pressed=bool(SaveSystem.data["settings"]["haptics_enabled"])
    h.add_theme_font_size_override("font_size",24)
    p.add_child(h)
    h.toggled.connect(func(v):
        SaveSystem.data["settings"]["haptics_enabled"]=v
        HapticsSystem.enabled=v
        SaveSystem.save_now()
    )
    var a:=CheckButton.new()
    a.text="Auto Acceleration"
    a.position=Vector2(70,250)
    a.button_pressed=bool(SaveSystem.data["settings"]["controls"]["auto_acceleration"])
    a.add_theme_font_size_override("font_size",24)
    p.add_child(a)
    a.toggled.connect(func(v):
        SaveSystem.data["settings"]["controls"]["auto_acceleration"]=v
        SaveSystem.save_now()
    )
    var txt:=_label(p,"54 cars • 60 wheels • 54 skins • 48 cards\nCars and wheels use Coins + Diamonds. Abilities are gameplay-affecting but balanced.\nLandscape locked • Safe area • Offline-first",24,palette.muted)
    txt.position=Vector2(70,350)
    var support:=_label(p,"Support: %s\nPackage: %s" % [ReleaseConfig.SUPPORT_EMAIL,ReleaseConfig.PACKAGE_NAME],20,palette.muted)
    support.position=Vector2(70,465)
    support.size=Vector2(900,80)

func _start_race(level:int)->void:
    current_level=maxi(1,level)
    level_def=LevelGenerator.generate(current_level)
    RaceSession.reset(current_level,level_def)
    _clear_race_world()
    _build_race_world()
    state="COUNTDOWN"
    RaceSession.state="COUNTDOWN"
    countdown_clock=0.0
    race_clock=0.0
    player_progress=0.0
    player_lane=0.0
    player_speed=0.0
    boost_energy=40.0
    boosting=false
    damage=0.0
    clean_score=100.0
    collision_cooldown=0.0
    invulnerable_time=0.0
    SaveSystem.data["stats"]["races_started"]+=1
    SaveSystem.save_now()
    _show_only("race")
    EventBus.race_started.emit(current_level)

func _clear_race_world()->void:
    for child in world_root.get_children():
        if child is WorldEnvironment or child is DirectionalLight3D:continue
        child.queue_free()
    path_points.clear()
    path_distances.clear()
    path_widths.clear()
    ai_racers.clear()
    traffic.clear()
    pickups.clear()
    obstacles.clear()

func _build_race_world()->void:
    _generate_path()
    _build_track_surface()
    _apply_race_theme()
    _spawn_scenery()
    StudioPolish.enhance_race(world_root, path_points, path_widths, str(level_def.environment_id))
    _spawn_items()
    _spawn_racers()
    player_car=_make_car("PLAYER",str(SaveSystem.data["progression"]["cars"]["selected"]),palette.primary)
    world_root.add_child(player_car)
    _place_racer(player_car,0.0,0.0)
    race_camera=Camera3D.new()
    race_camera.name="RaceCamera"
    race_camera.current=true
    race_camera.position=Vector3(0,4.1,-11.5)
    race_camera.fov=70
    race_camera.near=0.1
    race_camera.far=420.0
    player_car.add_child(race_camera)

func _generate_path()->void:
    var pos:=Vector3.ZERO
    var heading:=0.0
    var distance:=0.0
    path_points.append(pos)
    path_distances.append(distance)
    path_widths.append(ROAD_WIDTH)
    for module in level_def.track_modules:
        var length:=float(module.get("length",50.0))
        var steps:=maxi(2,ceili(length/ROAD_STEP))
        var start_heading:=heading
        var base_y:=pos.y
        var final_turn:=0.0
        for j in range(1,steps+1):
            var t:=float(j)/float(steps)
            var typ:=str(module.get("type","straight"))
            var sign:=float(module.get("turn",1.0))
            var turn:=0.0
            if typ=="gentle_curve":turn=sign*0.65
            elif typ=="medium_curve":turn=sign*(0.85+0.45*float(level_def.difficulty))
            elif typ=="tight_curve":turn=sign*(1.25+0.7*float(level_def.difficulty))
            elif typ=="hairpin":turn=sign*(2.65+0.3*float(level_def.difficulty))
            elif typ=="chicane":turn=sin(t*TAU)*0.9
            final_turn=turn
            var h:=start_heading+turn*t
            var step_len:=length/float(steps)
            pos+=Vector3(sin(h),0,cos(h))*step_len
            pos.y=base_y+(sin(t*PI)*2.4 if typ=="jump" else 0.0)
            path_points.append(pos)
            distance+=step_len
            path_distances.append(distance)
            path_widths.append(NARROW_WIDTH if typ=="narrow_gate" else ROAD_WIDTH)
        heading=start_heading+final_turn

func _build_track_surface()->void:
    if path_points.size()<2:return
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color("#1A2030")
    mat.roughness=0.92
    st.set_material(mat)
    for i in range(path_points.size()-1):
        var p0:=path_points[i]
        var p1:=path_points[i+1]
        var tangent:Vector3=(p1-p0).normalized()
        var side:=Vector3(-tangent.z,0,tangent.x).normalized()
        if side.length_squared()<0.1:side=Vector3.RIGHT
        var w0:=path_widths[i]*0.5
        var w1:=path_widths[i+1]*0.5
        var a:=p0+side*w0+Vector3.UP*0.02
        var b:=p0-side*w0+Vector3.UP*0.02
        var c:=p1-side*w1+Vector3.UP*0.02
        var d:=p1+side*w1+Vector3.UP*0.02
        st.add_vertex(a);st.add_vertex(b);st.add_vertex(c)
        st.add_vertex(a);st.add_vertex(c);st.add_vertex(d)
    st.generate_normals()
    var track:=MeshInstance3D.new()
    track.mesh=st.commit()
    world_root.add_child(track)

    var line_mat:=StandardMaterial3D.new()
    line_mat.albedo_color=Color("#E7EBF5")
    for i in range(0,path_points.size(),4):
        var marker:=MeshInstance3D.new()
        var bm:=BoxMesh.new()
        bm.size=Vector3(0.20,0.05,4.0)
        marker.mesh=bm
        marker.position=path_points[i]+Vector3.UP*0.12
        marker.rotation.y=atan2(_tangent_at_index(i).x,_tangent_at_index(i).z)
        marker.material_override=line_mat
        world_root.add_child(marker)

    var lane_mat:=StandardMaterial3D.new()
    lane_mat.albedo_color=Color("#AEB8C8")
    lane_mat.roughness=0.70
    var edge_mat:=StandardMaterial3D.new()
    edge_mat.albedo_color=Color("#D5DFEA")
    edge_mat.metallic=0.18
    edge_mat.roughness=0.45
    for i in range(0,path_points.size()-1,5):
        var sample:Dictionary=_sample_path(path_distances[i])
        var tangent:Vector3=sample["tangent"]
        var side:Vector3=Vector3(-tangent.z,0,tangent.x).normalized()
        var width:float=float(sample["width"])
        var yaw:=atan2(tangent.x,tangent.z)
        for lane_offset in [-2.65,2.65]:
            var dash:=MeshInstance3D.new()
            var db:=BoxMesh.new()
            db.size=Vector3(0.12,0.045,3.2)
            dash.mesh=db
            dash.position=sample["pos"]+side*lane_offset+Vector3.UP*0.115
            dash.rotation.y=yaw
            dash.material_override=lane_mat
            world_root.add_child(dash)
        for side_sign in [-1.0,1.0]:
            var edge:=MeshInstance3D.new()
            var eb:=BoxMesh.new()
            eb.size=Vector3(0.16,0.05,5.0)
            edge.mesh=eb
            edge.position=sample["pos"]+side*side_sign*(width*0.5-0.18)+Vector3.UP*0.13
            edge.rotation.y=yaw
            edge.material_override=edge_mat
            world_root.add_child(edge)

    _add_finish_gate()
    _add_road_details()
    _add_start_grid()

func _add_finish_gate()->void:
    var p:=path_points[path_points.size()-1]
    var tangent:=_tangent_at_index(path_points.size()-2)
    var side:=Vector3(-tangent.z,0,tangent.x).normalized()
    for s in [-1.0,1.0]:
        var post:=MeshInstance3D.new()
        var bm:=BoxMesh.new()
        bm.size=Vector3(0.5,5.0,0.5)
        post.mesh=bm
        post.position=p+side*s*7.0+Vector3.UP*2.5
        var m:=StandardMaterial3D.new()
        m.albedo_color=palette.primary
        post.material_override=m
        world_root.add_child(post)

    var top:=MeshInstance3D.new()
    var tb:=BoxMesh.new()
    tb.size=Vector3(14.0,0.55,0.55)
    top.mesh=tb
    top.position=p+Vector3.UP*4.95
    top.rotation.y=atan2(tangent.x,tangent.z)
    var top_mat:=StandardMaterial3D.new()
    top_mat.albedo_color=Color("#20283A")
    top_mat.metallic=0.45
    top.material_override=top_mat
    world_root.add_child(top)

    for j in range(-6,6):
        var tile:=MeshInstance3D.new()
        var cb:=BoxMesh.new()
        cb.size=Vector3(1.15,0.05,4.5)
        tile.mesh=cb
        tile.position=p+side*(float(j)*1.15+0.575)+Vector3.UP*0.11
        tile.rotation.y=atan2(tangent.x,tangent.z)
        var cm:=StandardMaterial3D.new()
        cm.albedo_color=Color("#F4F6FF") if (j%2==0) else Color("#1A1E29")
        tile.material_override=cm
        world_root.add_child(tile)

func _spawn_scenery()->void:
    var rng:=RandomNumberGenerator.new()
    rng.seed=int(level_def.seed)^991
    var env_id:=str(level_def.environment_id)
    var building_palette:Array=[
        Color("#26344A"),Color("#34445C"),Color("#3A3F54"),
        Color("#202A3D"),Color("#48536A"),Color("#2B3548")
    ]
    var ground_mat:=StandardMaterial3D.new()
    ground_mat.albedo_color=Color("#111A22")
    ground_mat.roughness=1.0

    # One pooled-style ground strip keeps the procedural road from floating in an empty void.
    if path_points.size()>2:
        var gst:=SurfaceTool.new()
        gst.begin(Mesh.PRIMITIVE_TRIANGLES)
        gst.set_material(ground_mat)
        for i in range(path_points.size()-1):
            var p0:=path_points[i]
            var p1:=path_points[i+1]
            var tangent:Vector3=(p1-p0).normalized()
            var side:=Vector3(-tangent.z,0,tangent.x).normalized()
            var a:=p0+side*70.0-Vector3.UP*0.03
            var b:=p0-side*70.0-Vector3.UP*0.03
            var cc:=p1-side*70.0-Vector3.UP*0.03
            var d:=p1+side*70.0-Vector3.UP*0.03
            gst.add_vertex(a);gst.add_vertex(b);gst.add_vertex(cc)
            gst.add_vertex(a);gst.add_vertex(cc);gst.add_vertex(d)
        gst.generate_normals()
        var ground:=MeshInstance3D.new()
        ground.name="EnvironmentGround"
        ground.mesh=gst.commit()
        world_root.add_child(ground)

    for i in range(0,path_points.size(),6):
        var sample:Dictionary=_sample_path(path_distances[i])
        var sample_pos:Vector3=sample["pos"]
        var sample_tangent:Vector3=sample["tangent"]
        var sample_width:float=float(sample["width"])
        var side:Vector3=Vector3(-sample_tangent.z,0,sample_tangent.x).normalized()
        for n in range(2):
            var sign:float=-1.0 if n==0 else 1.0
            var offset:float=sample_width*0.5+7.0+rng.randf_range(0.0,14.0)
            var p:Vector3=sample_pos+side*sign*offset

            # Environment silhouette varies by biome without expensive runtime assets.
            var is_city:=env_id.find("city")>=0 or env_id.find("metro")>=0
            var is_industrial:=env_id.find("industrial")>=0
            var is_nature:=env_id.find("mountain")>=0 or env_id.find("snow")>=0 or env_id.find("desert")>=0
            if is_nature and rng.randf()<0.55:
                var tree:=MeshInstance3D.new()
                var cone:=CylinderMesh.new()
                cone.top_radius=0.0
                cone.bottom_radius=rng.randf_range(1.4,2.2)
                cone.height=rng.randf_range(5.0,9.0)
                tree.mesh=cone
                tree.position=p+Vector3.UP*float(cone.height)*0.5
                var tm:=StandardMaterial3D.new()
                tm.albedo_color=Color("#2F6B4F") if env_id.find("snow")<0 else Color("#D7E6EF")
                tm.roughness=0.9
                tree.material_override=tm
                world_root.add_child(tree)
            else:
                var building:=MeshInstance3D.new()
                var bm:=BoxMesh.new()
                var h:=rng.randf_range(4.0,12.0)
                if is_city:h=rng.randf_range(8.0,22.0)
                if is_industrial:h=rng.randf_range(5.0,15.0)
                bm.size=Vector3(rng.randf_range(3.0,7.0),h,rng.randf_range(3.0,7.0))
                building.mesh=bm
                building.position=p+Vector3.UP*h*0.5
                var mat:=StandardMaterial3D.new()
                mat.albedo_color=building_palette[rng.randi_range(0,building_palette.size()-1)]
                mat.roughness=0.8
                building.material_override=mat
                world_root.add_child(building)

                if is_city and rng.randf()<0.45:
                    var beacon:=MeshInstance3D.new()
                    var lm:=BoxMesh.new()
                    lm.size=Vector3(0.12,0.8,0.12)
                    beacon.mesh=lm
                    beacon.position=p+Vector3(0,h+0.5,0)
                    var glow:=StandardMaterial3D.new()
                    glow.albedo_color=palette.secondary
                    glow.emission_enabled=true
                    glow.emission=palette.secondary
                    glow.emission_energy_multiplier=2.0
                    beacon.material_override=glow
                    world_root.add_child(beacon)

                    if rng.randf()<0.65:
                        var window_strip:=MeshInstance3D.new()
                        var wsm:=BoxMesh.new()
                        wsm.size=Vector3(0.18,0.70,1.10)
                        window_strip.mesh=wsm
                        window_strip.position=p+Vector3(rng.randf_range(-1.8,1.8),h*rng.randf_range(0.35,0.75),rng.randf_range(-2.5,2.5))
                        var window_mat:=StandardMaterial3D.new()
                        window_mat.albedo_color=Color("#B9D8FF")
                        window_mat.emission_enabled=true
                        window_mat.emission=Color("#4EB8FF")
                        window_mat.emission_energy_multiplier=0.85
                        window_strip.material_override=window_mat
                        world_root.add_child(window_strip)

            if (is_city or is_industrial) and i%3==0:
                var pole:=MeshInstance3D.new()
                var pb:=CylinderMesh.new()
                pb.top_radius=0.06
                pb.bottom_radius=0.08
                pb.height=4.2
                pole.mesh=pb
                pole.position=sample_pos+side*sign*(sample_width*0.5+2.4)+Vector3.UP*2.1
                var pole_mat:=StandardMaterial3D.new()
                pole_mat.albedo_color=Color("#394657")
                pole_mat.metallic=0.55
                pole.material_override=pole_mat
                world_root.add_child(pole)

                var lamp:=MeshInstance3D.new()
                var lb:=SphereMesh.new()
                lb.radius=0.18
                lb.height=0.36
                lamp.mesh=lb
                lamp.position=pole.position+Vector3(0,2.1,0)
                var lm:=StandardMaterial3D.new()
                lm.albedo_color=Color("#FFF1B5")
                lm.emission_enabled=true
                lm.emission=Color("#FFD978")
                lm.emission_energy_multiplier=2.0
                lamp.material_override=lm
                world_root.add_child(lamp)

            # Low-cost roadside safety rail gives the track a finished silhouette.
            if i%2==0:
                var rail:=MeshInstance3D.new()
                var rb:=BoxMesh.new()
                rb.size=Vector3(0.18,0.7,5.5)
                rail.mesh=rb
                rail.position=sample_pos+side*sign*(sample_width*0.5+1.5)+Vector3.UP*0.35
                rail.rotation.y=atan2(sample_tangent.x,sample_tangent.z)
                var rm:=StandardMaterial3D.new()
                rm.albedo_color=Color("#7C8799")
                rm.metallic=0.65
                rm.roughness=0.35
                rail.material_override=rm
                world_root.add_child(rail)

    _spawn_landmarks(env_id,rng)

func _spawn_items()->void:
    var rng:=RandomNumberGenerator.new()
    rng.seed=int(level_def.seed)^76543
    for i in range(int(level_def.coin_count)):
        var d:=rng.randf_range(60.0,float(level_def.track_length_m)-80.0)
        var lane:=rng.randf_range(-5.0,5.0)
        var n:=_pickup_mesh("coin",palette.coin)
        world_root.add_child(n)
        _place_node(n,d,lane,0.55)
        pickups.append({"kind":"coin","distance":d,"lane":lane,"node":n,"base_y":float(n.position.y),"collected":false})
    for i in range(int(level_def.boost_pickup_count)):
        var d:=rng.randf_range(100.0,float(level_def.track_length_m)-100.0)
        var lane:=rng.randf_range(-4.0,4.0)
        var n:=_pickup_mesh("boost",palette.secondary)
        world_root.add_child(n)
        _place_node(n,d,lane,0.8)
        pickups.append({"kind":"boost","distance":d,"lane":lane,"node":n,"base_y":float(n.position.y),"collected":false})
    if bool(level_def.has_diamond_pickup):
        var d:=rng.randf_range(180.0,float(level_def.track_length_m)-180.0)
        var lane:=rng.randf_range(-4.0,4.0)
        var n:=_pickup_mesh("diamond",palette.diamond)
        world_root.add_child(n)
        _place_node(n,d,lane,1.0)
        pickups.append({"kind":"diamond","distance":d,"lane":lane,"node":n,"base_y":float(n.position.y),"collected":false})
    for i in range(int(level_def.obstacle_count)):
        var d:=rng.randf_range(90.0,float(level_def.track_length_m)-100.0)
        var lane:=rng.randf_range(-5.0,5.0)
        var kinds:Array=["cone","barrier","oil","crate"]
        var kind:=str(kinds[rng.randi_range(0,kinds.size()-1)])
        var n:=_obstacle_mesh(kind)
        world_root.add_child(n)
        _place_node(n,d,lane,0.0)
        obstacles.append({"kind":kind,"distance":d,"lane":lane,"node":n,"hit":false})
    for i in range(mini(GameConfig.MAX_TRAFFIC,int(level_def.traffic_count))):
        var d:=40.0+float(i)*maxf(8.0,(float(level_def.track_length_m)-120.0)/float(maxi(1,int(level_def.traffic_count))))
        var lane:=rng.randf_range(-5.0,5.0)
        var n:=_make_car("TRAFFIC_%d"%i,"rookie_gt",Color("#7D889B"))
        world_root.add_child(n)
        _place_racer(n,d,lane)
        traffic.append({"progress":d,"lane":lane,"speed_factor":rng.randf_range(0.35,0.65),"node":n})

func _spawn_racers()->void:
    var rng:=RandomNumberGenerator.new()
    rng.seed=int(level_def.seed)^4421
    var roles:Array=["front","aggressive","aggressive","balanced","mistake"]
    var ids:Array=GameConfig.CARS.keys()
    for i in range(GameConfig.AI_CAR_COUNT):
        var id:=str(ids[mini(i,ids.size()-1)])
        var n:=_make_car("AI_%d"%i,id,Color.from_hsv(float(i)/7.0,0.65,0.95))
        world_root.add_child(n)
        var d:float=-float(i+1)*3.0
        var lane:float=float(i-2)*2.0
        _place_racer(n,d,lane)
        ai_racers.append({"progress":d,"lane":lane,"speed_factor":0.93+0.12*float(level_def.difficulty)+rng.randf_range(-0.02,0.02),"role":str(roles[i]),"node":n,"target_lane":lane})

func _make_car(car_name:String,_car_id:String,color:Color)->CharacterBody3D:
    var car:=CharacterBody3D.new()
    car.name=car_name
    car.collision_layer=2
    car.collision_mask=0

    var shape:=CollisionShape3D.new()
    var bs:=BoxShape3D.new()
    bs.size=Vector3(2.25,1.0,4.2)
    shape.shape=bs
    shape.position.y=0.58
    car.add_child(shape)

    car.set_meta("car_id",_car_id)
    var body_color:=color
    if car_name=="PLAYER":
        var skin_id:=str(SaveSystem.data["cosmetics"]["equipped"].get("skin","skin_01"))
        var skin:=ContentCatalog.skin(skin_id)
        if not skin.is_empty():
            body_color=Color(str(skin.get("color","#FF6B2C")))

    var lower:=MeshInstance3D.new()
    var lower_mesh:=BoxMesh.new()
    lower_mesh.size=Vector3(2.24,0.46,4.12)
    lower.mesh=lower_mesh
    lower.position.y=0.52
    var lower_mat:=StandardMaterial3D.new()
    lower_mat.albedo_color=body_color.darkened(0.16)
    lower_mat.metallic=0.28
    lower_mat.roughness=0.28
    lower.material_override=lower_mat
    car.add_child(lower)

    var body:=MeshInstance3D.new()
    var bm:=BoxMesh.new()
    bm.size=Vector3(2.08,0.52,3.42)
    body.mesh=bm
    body.position=Vector3(0,0.82,-0.15)
    body.rotation_degrees.x=-2.5
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=body_color
    mat.metallic=0.22
    mat.roughness=0.24
    body.material_override=mat
    car.add_child(body)

    var hood:=MeshInstance3D.new()
    var hm:=BoxMesh.new()
    hm.size=Vector3(1.88,0.20,1.18)
    hood.mesh=hm
    hood.position=Vector3(0,1.03,-1.38)
    hood.rotation_degrees.x=-4.0
    hood.material_override=mat
    car.add_child(hood)

    var cabin:=MeshInstance3D.new()
    var cb:=BoxMesh.new()
    cb.size=Vector3(1.34,0.52,1.70)
    cabin.mesh=cb
    cabin.position=Vector3(0,1.25,0.05)
    cabin.rotation_degrees.x=7.0
    var glass:=StandardMaterial3D.new()
    glass.albedo_color=Color("#12243B")
    glass.metallic=0.75
    glass.roughness=0.12
    cabin.material_override=glass
    car.add_child(cabin)

    var roof:=MeshInstance3D.new()
    var rb:=BoxMesh.new()
    rb.size=Vector3(1.08,0.08,1.15)
    roof.mesh=rb
    roof.position=Vector3(0,1.57,0.05)
    var roof_mat:=StandardMaterial3D.new()
    roof_mat.albedo_color=Color("#0E1420")
    roof_mat.metallic=0.55
    roof_mat.roughness=0.2
    roof.material_override=roof_mat
    car.add_child(roof)

    var splitter:=MeshInstance3D.new()
    var spb:=BoxMesh.new()
    spb.size=Vector3(1.86,0.10,0.32)
    splitter.mesh=spb
    splitter.position=Vector3(0,0.50,-2.02)
    var split_mat:=StandardMaterial3D.new()
    split_mat.albedo_color=Color("#0B0E15")
    split_mat.metallic=0.45
    splitter.material_override=split_mat
    car.add_child(splitter)

    var spoiler:=MeshInstance3D.new()
    var sb:=BoxMesh.new()
    sb.size=Vector3(1.76,0.12,0.36)
    spoiler.mesh=sb
    spoiler.position=Vector3(0,1.23,1.72)
    spoiler.material_override=roof_mat
    car.add_child(spoiler)

    for sx in [-0.82,0.82]:
        for sz in [-1.35,1.35]:
            var wheel:=MeshInstance3D.new()
            var cm:=CylinderMesh.new()
            cm.height=0.34
            cm.top_radius=0.44
            cm.bottom_radius=0.44
            wheel.mesh=cm
            wheel.name="Wheel%s%s" % ["L" if sx<0 else "R","F" if sz<0 else "R"]
            wheel.position=Vector3(sx,0.38,sz)
            wheel.rotation.z=PI/2
            var wm:=StandardMaterial3D.new()
            wm.albedo_color=Color("#0B0E13")
            wm.metallic=0.32
            wm.roughness=0.48
            wheel.material_override=wm
            car.add_child(wheel)
            var hub:=MeshInstance3D.new()
            var hubm:=CylinderMesh.new()
            hubm.height=0.10
            hubm.top_radius=0.18
            hubm.bottom_radius=0.18
            hub.mesh=hubm
            hub.position=Vector3(sx + (0.18 if sx<0 else -0.18),0.38,sz)
            hub.rotation.z=PI/2
            var hub_mat:=StandardMaterial3D.new()
            hub_mat.albedo_color=Color("#C5CEDF")
            hub_mat.metallic=0.75
            hub.material_override=hub_mat
            car.add_child(hub)

    for sx in [-0.62,0.62]:
        var lamp:=MeshInstance3D.new()
        var lm:=BoxMesh.new()
        lm.size=Vector3(0.26,0.14,0.10)
        lamp.mesh=lm
        lamp.position=Vector3(sx,0.88,-2.05)
        var led:=StandardMaterial3D.new()
        led.albedo_color=Color("#E9FCFF")
        led.emission_enabled=true
        led.emission=Color("#83E6FF")
        led.emission_energy_multiplier=3.0
        lamp.material_override=led
        car.add_child(lamp)

        var tail:=MeshInstance3D.new()
        var tm:=BoxMesh.new()
        tm.size=Vector3(0.26,0.12,0.08)
        tail.mesh=tm
        tail.position=Vector3(sx,0.82,2.07)
        var tail_mat:=StandardMaterial3D.new()
        tail_mat.albedo_color=Color("#FF3D52")
        tail_mat.emission_enabled=true
        tail_mat.emission=Color("#FF3147")
        tail_mat.emission_energy_multiplier=1.7
        tail.material_override=tail_mat
        car.add_child(tail)

    var underglow:=MeshInstance3D.new()
    underglow.name="Underglow"
    var ugm:=BoxMesh.new()
    ugm.size=Vector3(1.55,0.03,3.10)
    underglow.mesh=ugm
    underglow.position=Vector3(0,0.26,0)
    var ugmat:=StandardMaterial3D.new()
    ugmat.albedo_color=body_color
    ugmat.emission_enabled=true
    ugmat.emission=body_color
    ugmat.emission_energy_multiplier=0.72
    underglow.material_override=ugmat
    car.add_child(underglow)

    for sx in [-1.0,1.0]:
        var mirror:=MeshInstance3D.new()
        var mm:=BoxMesh.new()
        mm.size=Vector3(0.22,0.16,0.42)
        mirror.mesh=mm
        mirror.position=Vector3(sx*1.10,1.05,-0.05)
        mirror.rotation_degrees.y=12.0*float(sx)
        mirror.material_override=roof_mat
        car.add_child(mirror)

    var flame:=MeshInstance3D.new()
    flame.name="BoostFlame"
    var fm:=BoxMesh.new()
    fm.size=Vector3(0.44,0.22,0.75)
    flame.mesh=fm
    flame.position=Vector3(0,0.72,2.42)
    flame.scale=Vector3(0.85,0.72,0.35)
    var fmat:=StandardMaterial3D.new()
    fmat.albedo_color=Color("#FF9B4A")
    fmat.emission_enabled=true
    fmat.emission=Color("#5DE9FF")
    fmat.emission_energy_multiplier=3.2
    flame.material_override=fmat
    flame.visible=false
    car.add_child(flame)
    car.set_meta("boost_flame",flame)

    var boost_light:=OmniLight3D.new()
    boost_light.name="BoostGlow"
    boost_light.position=Vector3(0,0.75,2.55)
    boost_light.light_energy=6.0
    boost_light.omni_range=5.0
    boost_light.light_color=Color("#32D8FF")
    boost_light.visible=false
    car.add_child(boost_light)
    car.set_meta("boost_glow",boost_light)

    var brake_glow:=MeshInstance3D.new()
    brake_glow.name="BrakeGlow"
    var bgm:=BoxMesh.new()
    bgm.size=Vector3(1.38,0.08,0.12)
    brake_glow.mesh=bgm
    brake_glow.position=Vector3(0,0.88,2.12)
    var bgmat:=StandardMaterial3D.new()
    bgmat.albedo_color=Color("#FF3147")
    bgmat.emission_enabled=true
    bgmat.emission=Color("#FF3147")
    bgmat.emission_energy_multiplier=2.6
    brake_glow.material_override=bgmat
    brake_glow.visible=false
    car.add_child(brake_glow)
    car.set_meta("brake_glow",brake_glow)

    return car

func _animate_vehicle_wheels(vehicle:Node3D,speed:float,delta:float)->void:
    if not is_instance_valid(vehicle):return
    var spin:=speed*delta*0.95
    for wheel_name in ["WheelLF","WheelRF","WheelLR","WheelRR"]:
        var wheel:=vehicle.get_node_or_null(wheel_name)
        if wheel is Node3D:
            wheel.rotate_x(spin)

func _pickup_mesh(kind:String,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.emission_enabled=true
    mat.emission=color
    mat.emission_energy_multiplier=1.5
    if kind=="coin":
        var cm:=CylinderMesh.new()
        cm.height=0.20
        cm.top_radius=0.5
        cm.bottom_radius=0.5
        n.mesh=cm
    elif kind=="diamond":
        var sm:=SphereMesh.new()
        sm.radius=0.55
        sm.height=1.0
        n.mesh=sm
        n.scale=Vector3(0.8,1.4,0.8)
    else:
        var bm:=BoxMesh.new()
        bm.size=Vector3(0.8,0.8,0.8)
        n.mesh=bm
    n.material_override=mat
    return n

func _obstacle_mesh(kind:String)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var bm:=BoxMesh.new()
    if kind=="barrier":bm.size=Vector3(3.0,1.2,0.9)
    elif kind=="crate":bm.size=Vector3(1.2,1.2,1.2)
    elif kind=="cone":bm.size=Vector3(0.8,1.0,0.8)
    else:bm.size=Vector3(3.6,0.12,2.2)
    n.mesh=bm
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=Color("#343A49") if kind=="oil" else palette.warning
    n.material_override=mat
    return n

func _place_node(node:Node3D,distance:float,lane:float,lift:float)->void:
    var s:=_sample_path(distance)
    var side:=Vector3(-s.tangent.z,0,s.tangent.x).normalized()
    node.position=s.pos+side*lane+Vector3.UP*lift
    node.rotation.y=atan2(s.tangent.x,s.tangent.z)

func _place_racer(node:Node3D,distance:float,lane:float)->void:
    var s:=_sample_path(distance)
    var side:=Vector3(-s.tangent.z,0,s.tangent.x).normalized()
    node.global_position=s.pos+side*lane+Vector3.UP*0.45
    node.rotation.y=atan2(s.tangent.x,s.tangent.z)

func _sample_path(distance:float)->Dictionary:
    if path_points.size()<2:return {"pos":Vector3.ZERO,"tangent":Vector3.FORWARD,"width":ROAD_WIDTH}
    var d:=clampf(distance,0.0,float(level_def.track_length_m))
    var idx:=0
    while idx<path_distances.size()-1 and path_distances[idx+1]<d:idx+=1
    var d0:=path_distances[idx]
    var d1:=path_distances[mini(idx+1,path_distances.size()-1)]
    var t:=0.0 if is_equal_approx(d0,d1) else (d-d0)/(d1-d0)
    var p0:=path_points[idx]
    var p1:=path_points[mini(idx+1,path_points.size()-1)]
    return {"pos":p0.lerp(p1,t),"tangent":(p1-p0).normalized(),"width":lerpf(path_widths[idx],path_widths[mini(idx+1,path_widths.size()-1)],t)}

func _tangent_at_index(i:int)->Vector3:
    var a:=path_points[clampi(i,0,path_points.size()-1)]
    var b:=path_points[mini(i+1,path_points.size()-1)]
    return (b-a).normalized()

func _process(delta:float)->void:
    pickup_time+=delta
    if menu_car and is_instance_valid(menu_car) and current_screen!="race":
        menu_spin+=delta
        menu_car.rotation.y=deg_to_rad(-28.0)+sin(menu_spin*0.32)*0.12
    if impact_shake>0.0:
        impact_shake=maxf(0.0,impact_shake-delta*4.0)
    for i in range(pickups.size()):
        var pickup:Dictionary=pickups[i]
        if bool(pickup.get("collected",false)):
            continue
        var pickup_node:=pickup.get("node") as Node3D
        if not is_instance_valid(pickup_node):
            continue
        var kind:=str(pickup.get("kind","coin"))
        pickup_node.rotation.y+=delta*(2.6 if kind=="coin" else 1.8)
        pickup_node.position.y=float(pickup.get("base_y",pickup_node.position.y))+sin(pickup_time*3.2+float(i))*0.12
        if kind=="boost":
            var pulse:=0.92+sin(pickup_time*5.0+float(i))*0.08
            pickup_node.scale=Vector3.ONE*pulse
    if state=="COUNTDOWN":
        _update_countdown(delta)
    elif state=="RACING":
        _update_race(delta)

func _update_countdown(delta:float)->void:
    countdown_clock+=delta
    if countdown_clock<1.0:countdown_label.text="3"
    elif countdown_clock<2.0:countdown_label.text="2"
    elif countdown_clock<3.0:countdown_label.text="1"
    else:
        countdown_label.text="GO!"
        state="RACING"
        RaceSession.state="RACING"
        get_tree().create_timer(0.35).timeout.connect(func():if is_instance_valid(countdown_label):countdown_label.text="")
    var tick:=int(ceil(3.0-countdown_clock))
    if tick>=1 and tick<=3:EventBus.countdown_tick.emit(tick)

func _update_race(delta:float)->void:
    race_clock+=delta
    collision_cooldown=maxf(0.0,collision_cooldown-delta)
    invulnerable_time=maxf(0.0,invulnerable_time-delta)
    var car_id:=str(SaveSystem.data["progression"]["cars"]["selected"])
    var cd:=GameConfig.car(car_id)
    var up:Dictionary=SaveSystem.data["progression"]["upgrades"]
    var top_speed:=float(cd.get("top_speed",140.0))+2.5*int(up.get("top_speed",0))+ProgressionService.top_speed_bonus()
    var accel:=float(cd.get("accel",8.0))+0.35*int(up.get("acceleration",0))+ProgressionService.acceleration_bonus()
    var braking:=float(cd.get("brake",12.0))+0.7*int(up.get("braking",0))+ProgressionService.braking_bonus()
    var boost_power:=float(cd.get("boost_power",25.0))+2.0*int(up.get("boost_power",0))+ProgressionService.boost_power_bonus()
    var handling:=float(cd.get("grip",1.0))*(1.0+0.025*int(up.get("handling",0))+ProgressionService.handling_bonus())
    var stability:=float(cd.get("stability",1.0))*(1.0+0.02*int(up.get("stability",0))+ProgressionService.stability_bonus())
    var launch_bonus:=ProgressionService.launch_bonus()
    if race_clock<5.0:
        accel*=1.0+launch_bonus
    var target_speed:=top_speed/3.6*GameConfig.EXPECTED_SPEED_FACTOR
    if boosting:
        target_speed+=boost_power/3.6
        var drain_factor:=1.0-ProgressionService.boost_efficiency_bonus()
        boost_energy=maxf(0.0,boost_energy-(50.0-2.78*int(up.get("boost_duration",0))-ProgressionService.boost_duration_bonus()*10.0)*drain_factor*delta)
        if boost_energy<=0.0:boosting=false
    else:
        boost_energy=minf(100.0,boost_energy+4.0*delta)
    var steer:=0.0
    if left_held or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):steer-=1.0
    if right_held or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):steer+=1.0
    var sensitivity:=float(SaveSystem.data["settings"]["controls"].get("steering_sensitivity",0.5))
    player_lane+=steer*6.0*(0.55+0.9*sensitivity)*handling*stability*delta
    var width:=float(_sample_path(player_progress).width)
    player_lane=clampf(player_lane,-width*0.45,width*0.45)
    if brake_held or Input.is_key_pressed(KEY_S):
        target_speed*=clampf(0.72+(braking-12.0)*0.01,0.55,0.72)
    player_speed=move_toward(player_speed,target_speed,accel*delta)
    player_progress=minf(player_progress+player_speed*delta,float(level_def.track_length_m))
    _place_racer(player_car,player_progress,player_lane)
    player_car.rotation.z=lerpf(player_car.rotation.z,-steer*0.035*clampf(player_speed/45.0,0.0,1.0),minf(1.0,delta*8.0))
    _animate_vehicle_wheels(player_car,player_speed,delta)
    _update_car_fx()
    if is_instance_valid(race_camera):
        var speed_ratio:=clampf(player_speed/(GameConfig.car(car_id).get("top_speed",140.0)/3.6),0.0,1.25)
        race_camera.fov=lerpf(68.0,78.0,speed_ratio)+(3.0 if boosting else 0.0)
        race_camera.position.z=lerpf(-13.0,-9.5,speed_ratio)
        race_camera.position.x=sin(race_clock*18.0)*0.035*(1.0 if boosting else 0.35)
        race_camera.position.y=4.1+sin(race_clock*10.0)*0.04*(1.0 if boosting else 0.25)+impact_shake*0.08
        StudioPolish.camera_feedback(race_camera, player_speed, boosting, impact_shake, delta)
    _update_ai(delta)
    _update_traffic(delta)
    _check_pickups()
    _check_collisions()
    var live_position:=_player_position()
    position_label.text="%d/6" % live_position
    position_label.add_theme_color_override("font_color",palette.success if live_position==1 else (palette.warning if live_position>=5 else palette.text))
    progress_bar.value=player_progress/float(level_def.track_length_m)
    boost_bar.value=boost_energy
    damage_bar.value=damage
    coin_label.text="COINS %d" % RaceSession.track_coins_collected
    speed_label.text="%d km/h" % int(player_speed*3.6)
    var total_seconds:=int(race_clock)
    timer_label.text="%02d:%02d" % [int(total_seconds/60),total_seconds%60]
    var target_seconds:=int(float(level_def.target_time_sec))
    target_label.text="TARGET %02d:%02d" % [int(target_seconds/60),target_seconds%60]
    environment_label.text="%s  •  %s" % [_environment_name(str(level_def.environment_id)),str(level_def.race_type).to_upper()]
    if player_progress>=float(level_def.track_length_m)-1.0:
        _finish_race(true)
    elif damage>=100.0:
        state="WRECKED"
        RaceSession.state="WRECKED"
        _show_only("wreck")
        var ad:Button=screens["wreck"].get_node("Panel/ReviveAd")
        ad.disabled=not AdsManager.is_online()

func _update_ai(delta:float)->void:
    var elite:=str(level_def.race_type)=="Elite"
    var base:=DifficultyService.ai_top_speed_multiplier(current_level,elite)
    if RaceSession.assist_used:base*=0.95
    for i in range(ai_racers.size()):
        var ai:Dictionary=ai_racers[i]
        var factor:=float(ai.speed_factor)*base
        if str(ai.role)=="mistake" and sin(race_clock*0.35)>0.92:factor*=0.82

        var target_lane:=float(ai.target_lane)
        var gap:=player_progress-float(ai.progress)
        if gap>0.0 and gap<28.0:
            var side:=1.0 if fmod(float(i),2.0)==0.0 else -1.0
            target_lane=clampf(player_lane+side*2.2,-5.5,5.5)
        elif gap< -8.0:
            target_lane=clampf(float(ai.lane)*0.75+sin(race_clock*(0.7+0.08*i)+i)*1.1,-5.5,5.5)
        for obstacle in obstacles:
            if bool(obstacle.get("hit",false)):
                continue
            var obstacle_gap:=float(obstacle.get("distance",99999.0))-float(ai.progress)
            if obstacle_gap>0.0 and obstacle_gap<14.0 and absf(float(obstacle.get("lane",0.0))-float(ai.lane))<2.6:
                var avoid_dir:=1.0 if float(ai.lane)<=float(obstacle.get("lane",0.0)) else -1.0
                target_lane=clampf(float(ai.lane)+avoid_dir*3.0,-5.5,5.5)
                break
        if str(ai.role)=="aggressive":
            target_lane=clampf(target_lane+sin(race_clock*0.55+i)*0.6,-5.5,5.5)
        elif str(ai.role)=="front":
            target_lane=clampf(target_lane*0.85,-5.5,5.5)
        ai.target_lane=target_lane
        ai.lane=move_toward(float(ai.lane),target_lane,3.4*delta)

        var player_pressure:=clampf((player_progress-float(ai.progress))/55.0,0.0,0.06)
        factor+=player_pressure
        ai.progress=minf(float(ai.progress)+maxf(5.0,player_speed)*factor*delta,float(level_def.track_length_m)+50.0)

        ai_racers[i]=ai
        _place_racer(ai.node,float(ai.progress),float(ai.lane))
        _animate_vehicle_wheels(ai.node,player_speed*float(ai.speed_factor),delta)


func _update_traffic(delta:float)->void:
    for i in range(traffic.size()):
        var t:Dictionary=traffic[i]
        t.progress+=player_speed*float(t.speed_factor)*delta
        if t.progress>float(level_def.track_length_m)+35.0:t.progress=35.0+float(i)*8.0
        var desired_lane:=float(t.lane)+sin(race_clock*0.35+i)*0.45*delta
        if absf(player_progress-float(t.progress))<20.0:
            desired_lane=clampf(player_lane + (2.8 if player_lane<=0.0 else -2.8),-5.0,5.0)
        t.lane=move_toward(float(t.lane),clampf(desired_lane,-5.0,5.0),1.8*delta)
        traffic[i]=t
        _place_racer(t.node,float(t.progress),float(t.lane))
        _animate_vehicle_wheels(t.node,player_speed*float(t.speed_factor),delta)

func _check_pickups()->void:
    for i in range(pickups.size()):
        var p:Dictionary=pickups[i]
        if bool(p.collected):continue
        if absf(player_progress-float(p.distance))<4.0 and absf(player_lane-float(p.lane))<2.7:
            p.collected=true
            p.node.visible=false
            pickups[i]=p
            if str(p.kind)=="coin":
                RaceSession.track_coins_collected+=1
            elif str(p.kind)=="boost":
                boost_energy=minf(100.0,boost_energy+35.0)
            elif str(p.kind)=="diamond":
                RaceSession.diamond_pickup_collected=true
            HapticsSystem.pulse(0.15)

func _check_collisions()->void:
    if collision_cooldown>0.0 or invulnerable_time>0.0:return
    for i in range(obstacles.size()):
        var o:Dictionary=obstacles[i]
        if bool(o.hit):continue
        if absf(player_progress-float(o.distance))<3.0 and absf(player_lane-float(o.lane))<2.0:
            o.hit=true
            o.node.visible=false
            obstacles[i]=o
            var kind:=str(o.kind)
            if kind=="oil":
                player_lane+=2.5 if player_lane<0 else -2.5
            else:
                var dmg:=25.0 if kind=="barrier" else 10.0
                if RaceSession.assist_used:dmg*=0.8
                dmg*=ProgressionService.damage_multiplier()
                damage=minf(100.0,damage+dmg)
                clean_score=maxf(0.0,clean_score-(15.0 if dmg>20.0 else 5.0))
            collision_cooldown=0.8
            _impact_feedback()
            HapticsSystem.pulse(0.7)
    for t in traffic:
        if absf(player_progress-float(t.progress))<3.5 and absf(player_lane-float(t.lane))<1.8:
            var traffic_damage:=12.0*(0.8 if RaceSession.assist_used else 1.0)*ProgressionService.damage_multiplier()
            damage=minf(100.0,damage+traffic_damage)
            clean_score=maxf(0.0,clean_score-5.0)
            collision_cooldown=1.0
            _impact_feedback()
            HapticsSystem.pulse(0.5)

func _player_position()->int:
    var p:=1
    for ai in ai_racers:
        if float(ai.progress)>player_progress:p+=1
    return clampi(p,1,6)

func _try_boost()->void:
    if state=="RACING" and boost_energy>=20.0:
        boosting=true
        HapticsSystem.pulse(0.4)

func _pause_race()->void:
    if state!="RACING":return
    state="PAUSED"
    RaceSession.state="PAUSED"
    get_tree().paused=true
    screens["pause"].process_mode=Node.PROCESS_MODE_WHEN_PAUSED
    _show_only("pause")

func _resume_race()->void:
    get_tree().paused=false
    screens["pause"].visible=false
    state="RACING"
    RaceSession.state="RACING"
    current_screen="race"
    hud.visible=true

func _revive_with_ad()->void:
    AdsManager.show_rewarded("revive",func(ok:bool):
        if ok:_apply_revive()
        else:_show_toast("Ad unavailable right now")
    )

func _revive_with_diamonds()->void:
    if EconomyService.spend_diamonds(GameConfig.REVIVE_DIAMOND_COST,"diamond_continue"):
        _apply_revive()
    else:_show_toast("Not enough Diamonds")

func _apply_revive()->void:
    get_tree().paused=false
    screens["wreck"].visible=false
    state="RACING"
    RaceSession.state="RACING"
    current_screen="race"
    hud.visible=true
    damage=40.0
    boost_energy=minf(100.0,boost_energy+30.0)
    invulnerable_time=2.0
    RaceSession.revive_used=true
    SaveSystem.data["stats"]["revives_used"]+=1
    SaveSystem.save_now()
    _show_toast("Revived • 2 seconds protection")

func _quit_race()->void:
    if get_tree().paused:get_tree().paused=false
    _finish_race(false)

func _finish_race(completed:bool)->void:
    if state=="RESULTS":return
    if get_tree().paused:get_tree().paused=false
    state="RESULTS"
    RaceSession.state="RESULTS"
    var pos:=_player_position() if completed else 6
    var stars:=RewardService.stars_for(pos,clean_score) if completed else 0
    var result:Dictionary={"level_number":current_level,"completed":completed,"finish_position":pos,"race_time_sec":race_clock,"clean_score":clean_score,"stars_earned":stars,"track_coins_collected":RaceSession.track_coins_collected if completed else 0,"diamond_pickup_collected":RaceSession.diamond_pickup_collected if completed else false,"wrecked":damage>=100.0,"revive_used":RaceSession.revive_used,"assist_used":RaceSession.assist_used,"race_type":str(level_def.race_type)}
    var rewards:Dictionary=RewardService.resolve_result(result)
    rewards["stars"]=stars
    ProgressionService.handle_race_result(result)
    if bool(result.completed) and not bool(SaveSystem.data["profile"].get("onboarding_completed",false)):
        SaveSystem.data["profile"]["onboarding_completed"]=true
        SaveSystem.save_now()
    _show_results(result,rewards)

func _show_results(result:Dictionary,rewards:Dictionary)->void:
    last_result=result.duplicate(true)
    last_rewards=rewards.duplicate(true)
    double_reward_claimed=false
    _show_only("results")
    AdsManager.maybe_show_midgame()
    results_label.text=_ordinal(int(result.finish_position))+" PLACE" if bool(result.completed) else "DNF"
    results_detail.text="Rank Coins: %d\nChest: %s • %d Coins • %d Diamonds\nRandom Bonus: %d Coins • %d Diamonds\nTrack Coins: %d\nFirst Clear Diamonds: %d\nStars: %d\nTOTAL: %d Coins • %d Diamonds" % [int(rewards.rank_coins),str(rewards.chest),int(rewards.chest_coins),int(rewards.chest_diamonds),int(rewards.bonus_coins),int(rewards.bonus_diamonds),int(rewards.track_coins),int(rewards.first_clear_diamonds),int(rewards.stars),int(rewards.total_coins),int(rewards.total_diamonds)]
    next_button.disabled=not bool(result.completed) or int(result.finish_position)>5
    double_button.disabled=not bool(result.completed) or not AdsManager.can_show_rewarded("double_coins")
    double_button.text="WATCH AD • DOUBLE REWARDS" if not double_button.disabled else "DOUBLE REWARDS • UNAVAILABLE"
    _refresh_currency_header()

func _ordinal(pos:int)->String:
    if pos==1:return "1st"
    if pos==2:return "2nd"
    if pos==3:return "3rd"
    return "%dth" % pos

func _show_toast(message:String)->void:
    toast.text=message
    toast.visible=true
    get_tree().create_timer(2.5).timeout.connect(func():if is_instance_valid(toast):toast.visible=false)
