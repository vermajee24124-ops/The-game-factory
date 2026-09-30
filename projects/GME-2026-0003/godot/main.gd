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
var position_label:Label
var progress_bar:ProgressBar
var boost_bar:ProgressBar
var damage_bar:ProgressBar
var coin_label:Label
var speed_label:Label
var countdown_label:Label
var coins_label:Label
var diamonds_label:Label
var pre_race_label:Label
var pre_car_label:Label
var results_label:Label
var results_detail:Label
var next_button:Button
var double_button:Button

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
    AdsManager.init()
    IAPManager.init()
    HapticsSystem.enabled=bool(SaveSystem.data["settings"]["haptics_enabled"])
    _setup_world()
    _setup_ui()
    _show_main_menu()

func _setup_world()->void:
    world_root=Node3D.new()
    world_root.name="RuntimeWorld"
    add_child(world_root)
    var env:=WorldEnvironment.new()
    var e:=Environment.new()
    e.background_mode=Environment.BG_COLOR
    e.background_color=palette.bg
    e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color=Color("#59709E")
    e.ambient_light_energy=0.8
    env.environment=e
    world_root.add_child(env)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-50.0,-30.0,0.0)
    sun.light_energy=1.2
    sun.shadow_enabled=true
    world_root.add_child(sun)

func _style(color:Color,radius:=16)->StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=color
    s.corner_radius_top_left=radius
    s.corner_radius_top_right=radius
    s.corner_radius_bottom_left=radius
    s.corner_radius_bottom_right=radius
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
    b.add_theme_stylebox_override("pressed",_style(palette.primary.darkened(0.20) if primary else palette.panel_light.darkened(0.10),12))
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
    _build_main_menu()
    _build_level_select()
    _build_pre_race()
    _build_race_hud()
    _build_pause()
    _build_wreck()
    _build_results()
    _build_garage()
    _build_shop()
    _build_settings()
    toast=_label(ui_root,"",22,palette.text)
    toast.position=Vector2(730,990)
    toast.visible=false

func _show_only(id:String)->void:
    for k in screens.keys():
        screens[k].visible=false
    screens[id].visible=true
    current_screen=id
    hud.visible=(id=="race") if hud else false
    _refresh_currency_header()

func _refresh_currency_header()->void:
    if coins_label:coins_label.text="COINS  %d" % EconomyService.coins()
    if diamonds_label:diamonds_label.text="DIAMONDS  %d" % EconomyService.diamonds()

func _show_main_menu()->void:
    _show_only("main_menu")

func _build_main_menu()->void:
    var c:=_new_screen("main_menu","TURBO RUSH")
    var p:Control=c.get_node("Panel")
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
    var shop:=_button(p,"SHOP",Vector2(240,72),false)
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
    var info:=Panel.new()
    info.position=Vector2(760,220)
    info.size=Vector2(1050,620)
    info.add_theme_stylebox_override("panel",_style(palette.panel,24))
    p.add_child(info)
    var h:=_label(info,"YOUR GARAGE",28,palette.muted)
    h.position=Vector2(45,35)
    var car:=_label(info,"ROOKIE GT",68,palette.text)
    car.position=Vector2(45,90)
    var d:=_label(info,"1 player + 5 AI\nDeterministic finite races\n2–3 minute target\nCoins • Diamonds • Boost • Chests • Stars",26,palette.muted)
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
    position_label=_label(hud,"1/6",38,palette.text)
    position_label.position=Vector2(54,42)
    coin_label=_label(hud,"Coins 0",24,palette.coin)
    coin_label.position=Vector2(1580,42)
    speed_label=_label(hud,"0 km/h",24,palette.text)
    speed_label.position=Vector2(1580,88)
    progress_bar=ProgressBar.new()
    progress_bar.position=Vector2(520,45)
    progress_bar.size=Vector2(860,25)
    progress_bar.max_value=1.0
    progress_bar.show_percentage=false
    progress_bar.add_theme_stylebox_override("background",_style(palette.panel,10))
    progress_bar.add_theme_stylebox_override("fill",_style(palette.secondary,10))
    hud.add_child(progress_bar)
    boost_bar=ProgressBar.new()
    boost_bar.position=Vector2(1460,910)
    boost_bar.size=Vector2(360,28)
    boost_bar.max_value=100
    boost_bar.show_percentage=false
    boost_bar.add_theme_stylebox_override("background",_style(palette.panel,10))
    boost_bar.add_theme_stylebox_override("fill",_style(palette.secondary,10))
    hud.add_child(boost_bar)
    damage_bar=ProgressBar.new()
    damage_bar.position=Vector2(50,200)
    damage_bar.size=Vector2(270,22)
    damage_bar.max_value=100
    damage_bar.show_percentage=false
    damage_bar.add_theme_stylebox_override("background",_style(palette.panel,10))
    damage_bar.add_theme_stylebox_override("fill",_style(palette.danger,10))
    hud.add_child(damage_bar)
    countdown_label=_label(hud,"",96,palette.text)
    countdown_label.position=Vector2(900,350)
    var left:=_button(hud,"◀",Vector2(140,90),false)
    left.position=Vector2(35,840)
    left.button_down.connect(func():left_held=true)
    left.button_up.connect(func():left_held=false)
    var brake:=_button(hud,"BRAKE",Vector2(150,90),false)
    brake.position=Vector2(185,840)
    brake.button_down.connect(func():brake_held=true)
    brake.button_up.connect(func():brake_held=false)
    var right:=_button(hud,"▶",Vector2(140,90),false)
    right.position=Vector2(325,840)
    right.button_down.connect(func():right_held=true)
    right.button_up.connect(func():right_held=false)
    var boost:=_button(hud,"BOOST",Vector2(180,115),true)
    boost.position=Vector2(1640,735)
    boost.pressed.connect(func():_try_boost())
    var pause:=_button(hud,"Ⅱ",Vector2(86,62),false)
    pause.position=Vector2(45,120)
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
    double_button=_button(p,"WATCH AD • DOUBLE RANK + CHEST",Vector2(560,70),false)
    double_button.position=Vector2(1060,765)
    double_button.disabled=true

func _build_garage()->void:
    var c:=_new_screen("garage","GARAGE")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var cars:=VBoxContainer.new()
    cars.name="Cars"
    cars.position=Vector2(55,130)
    cars.size=Vector2(500,800)
    cars.add_theme_constant_override("separation",10)
    p.add_child(cars)
    var up:=VBoxContainer.new()
    up.name="Upgrades"
    up.position=Vector2(620,130)
    up.size=Vector2(1120,800)
    up.add_theme_constant_override("separation",10)
    p.add_child(up)

func _refresh_garage()->void:
    var cars:VBoxContainer=screens["garage"].get_node("Panel/Cars")
    var up:VBoxContainer=screens["garage"].get_node("Panel/Upgrades")
    for n in cars.get_children():n.queue_free()
    for n in up.get_children():n.queue_free()
    var owned:Array=SaveSystem.data["progression"]["cars"]["owned"]
    for id in GameConfig.CARS.keys():
        var cd:Dictionary=GameConfig.car(str(id))
        var can_level:=ProgressionService.player_level()>=int(cd.get("level",1))
        var can_buy:=can_level and EconomyService.coins()>=int(cd.get("cost",0))
        var b:=_button(cars,"%s • L%d • %d Coins" % [str(cd.get("name","")),int(cd.get("level",1)),int(cd.get("cost",0))],owned.has(id) or can_buy)
        b.disabled=not (owned.has(id) or can_buy)
        b.pressed.connect(func(car_id=str(id)):
            if owned.has(car_id):
                ProgressionService.select_car(car_id)
                _show_toast("Equipped")
            elif ProgressionService.buy_car(car_id):
                _show_toast("Car unlocked")
            else:
                _show_toast("Level or Coins required")
            _refresh_garage()
            _refresh_currency_header()
        )
    _label(up,"GLOBAL UPGRADES",28,palette.muted)
    for stat in ProgressionService.STAT_KEYS:
        var row:=HBoxContainer.new()
        row.custom_minimum_size=Vector2(900,62)
        up.add_child(row)
        var cur:=int(SaveSystem.data["progression"]["upgrades"].get(stat,0))
        var lab:=_label(row,"%s • Level %d" % [str(stat).replace("_"," ").capitalize(),cur],21,palette.text)
        lab.custom_minimum_size=Vector2(560,60)
        var can:=ProgressionService.can_upgrade(stat)
        var b:=_button(row,"MAX" if cur>=10 else "UPGRADE • %d" % GameConfig.UPGRADE_COSTS[cur+1],Vector2(300,60),true)
        b.disabled=cur>=10 or not can
        b.pressed.connect(func(s=stat):
            if ProgressionService.upgrade(s):_show_toast("Upgrade applied")
            else:_show_toast("Check player level and Coins")
            _refresh_garage()
            _refresh_currency_header()
        )

func _build_shop()->void:
    var c:=_new_screen("shop","SHOP")
    var p:Control=c.get_node("Panel")
    var back:=_button(p,"BACK",Vector2(160,60),false)
    back.position=Vector2(1650,35)
    back.pressed.connect(func():_show_main_menu())
    var note:=_label(p,"IAP is network-dependent. Offline mode keeps the store safe and non-blocking.",24,palette.muted)
    note.position=Vector2(60,115)
    var y:=205
    for id in IAPManager.products.keys():
        var item:Dictionary=IAPManager.products[id]
        var b:=_button(p,"%s • %s" % [str(id).replace("_"," ").capitalize(),str(item.get("price",""))],Vector2(520,70),true)
        b.position=Vector2(70,y)
        b.disabled=not IAPManager.online
        b.pressed.connect(func(pid=str(id)):IAPManager.purchase(pid))
        y+=95

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
    var txt:=_label(p,"Landscape locked • Safe area • Offline-first\nUpgrade, car and cosmetic progress is stored locally.",24,palette.muted)
    txt.position=Vector2(70,350)

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
    _spawn_scenery()
    _spawn_items()
    _spawn_racers()
    player_car=_make_car("PLAYER",str(SaveSystem.data["progression"]["cars"]["selected"]),palette.primary)
    world_root.add_child(player_car)
    _place_racer(player_car,0.0,0.0)
    var cam:=Camera3D.new()
    cam.current=true
    cam.position=Vector3(0,4,-11)
    cam.fov=70
    player_car.add_child(cam)

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
    _add_finish_gate()

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

func _spawn_scenery()->void:
    var rng:=RandomNumberGenerator.new()
    rng.seed=int(level_def.seed)^991
    for i in range(0,path_points.size(),6):
        var s:=_sample_path(path_distances[i])
        var side:=Vector3(-s.tangent.z,0,s.tangent.x).normalized()
        for n in range(2):
            var sign:float=-1.0 if n==0 else 1.0
            var node:=MeshInstance3D.new()
            var bm:=BoxMesh.new()
            var h:=rng.randf_range(3.0,10.0)
            bm.size=Vector3(rng.randf_range(2.0,6.0),h,rng.randf_range(2.0,6.0))
            node.mesh=bm
            node.position=s.pos+side*sign*(s.width*0.5+7.0+rng.randf_range(0.0,10.0))+Vector3.UP*h*0.5
            var mat:=StandardMaterial3D.new()
            mat.albedo_color=Color("#27324B")
            node.material_override=mat
            world_root.add_child(node)

func _spawn_items()->void:
    var rng:=RandomNumberGenerator.new()
    rng.seed=int(level_def.seed)^76543
    for i in range(int(level_def.coin_count)):
        var d:=rng.randf_range(60.0,float(level_def.track_length_m)-80.0)
        var lane:=rng.randf_range(-5.0,5.0)
        var n:=_pickup_mesh("coin",palette.coin)
        world_root.add_child(n)
        _place_node(n,d,lane,0.55)
        pickups.append({"kind":"coin","distance":d,"lane":lane,"node":n,"collected":false})
    for i in range(int(level_def.boost_pickup_count)):
        var d:=rng.randf_range(100.0,float(level_def.track_length_m)-100.0)
        var lane:=rng.randf_range(-4.0,4.0)
        var n:=_pickup_mesh("boost",palette.secondary)
        world_root.add_child(n)
        _place_node(n,d,lane,0.8)
        pickups.append({"kind":"boost","distance":d,"lane":lane,"node":n,"collected":false})
    if bool(level_def.has_diamond_pickup):
        var d:=rng.randf_range(180.0,float(level_def.track_length_m)-180.0)
        var lane:=rng.randf_range(-4.0,4.0)
        var n:=_pickup_mesh("diamond",palette.diamond)
        world_root.add_child(n)
        _place_node(n,d,lane,1.0)
        pickups.append({"kind":"diamond","distance":d,"lane":lane,"node":n,"collected":false})
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
        ai_racers.append({"progress":d,"lane":lane,"speed_factor":0.93+0.12*float(level_def.difficulty)+rng.randf_range(-0.02,0.02),"role":str(roles[i]),"node":n})

func _make_car(car_name:String,_car_id:String,color:Color)->CharacterBody3D:
    var car:=CharacterBody3D.new()
    car.name=car_name
    car.collision_layer=2
    car.collision_mask=0
    var shape:=CollisionShape3D.new()
    var bs:=BoxShape3D.new()
    bs.size=Vector3(2.2,1.0,4.1)
    shape.shape=bs
    shape.position.y=0.6
    car.add_child(shape)
    var body:=MeshInstance3D.new()
    var bm:=BoxMesh.new()
    bm.size=Vector3(2.2,0.9,4.0)
    body.mesh=bm
    body.position.y=0.6
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.roughness=0.45
    body.material_override=mat
    car.add_child(body)
    for sx in [-0.9,0.9]:
        for sz in [-1.35,1.35]:
            var wheel:=MeshInstance3D.new()
            var cm:=CylinderMesh.new()
            cm.height=0.35
            cm.top_radius=0.45
            cm.bottom_radius=0.45
            wheel.mesh=cm
            wheel.position=Vector3(sx,0.35,sz)
            wheel.rotation.z=PI/2
            var wm:=StandardMaterial3D.new()
            wm.albedo_color=Color("#14171E")
            wheel.material_override=wm
            car.add_child(wheel)
    return car

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
    var top_speed:=float(cd.get("top_speed",140.0))+2.5*int(up.get("top_speed",0))
    var accel:=float(cd.get("accel",8.0))+0.35*int(up.get("acceleration",0))
    var boost_power:=float(cd.get("boost_power",25.0))+2.0*int(up.get("boost_power",0))
    var target_speed:=top_speed/3.6*GameConfig.EXPECTED_SPEED_FACTOR
    if boosting:
        target_speed+=boost_power/3.6
        boost_energy=maxf(0.0,boost_energy-(50.0-2.78*int(up.get("boost_duration",0)))*delta)
        if boost_energy<=0.0:boosting=false
    else:
        boost_energy=minf(100.0,boost_energy+4.0*delta)
    var steer:=0.0
    if left_held or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):steer-=1.0
    if right_held or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):steer+=1.0
    var sensitivity:=float(SaveSystem.data["settings"]["controls"].get("steering_sensitivity",0.5))
    player_lane+=steer*6.0*(0.55+0.9*sensitivity)*delta
    var width:=float(_sample_path(player_progress).width)
    player_lane=clampf(player_lane,-width*0.45,width*0.45)
    if brake_held or Input.is_key_pressed(KEY_S):target_speed*=0.72
    player_speed=move_toward(player_speed,target_speed,accel*delta)
    player_progress=minf(player_progress+player_speed*delta,float(level_def.track_length_m))
    _place_racer(player_car,player_progress,player_lane)
    _update_ai(delta)
    _update_traffic(delta)
    _check_pickups()
    _check_collisions()
    position_label.text="%d/6" % _player_position()
    progress_bar.value=player_progress/float(level_def.track_length_m)
    boost_bar.value=boost_energy
    damage_bar.value=damage
    coin_label.text="Coins %d" % RaceSession.track_coins_collected
    speed_label.text="%d km/h" % int(player_speed*3.6)
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
        ai.progress=minf(float(ai.progress)+maxf(5.0,player_speed)*factor*delta,float(level_def.track_length_m)+50.0)
        ai.lane=clampf(float(ai.lane)+sin(race_clock*(0.5+0.1*i)+i)*0.25*delta,-5.6,5.6)
        ai_racers[i]=ai
        _place_racer(ai.node,float(ai.progress),float(ai.lane))

func _update_traffic(delta:float)->void:
    for i in range(traffic.size()):
        var t:Dictionary=traffic[i]
        t.progress+=player_speed*float(t.speed_factor)*delta
        if t.progress>float(level_def.track_length_m)+35.0:t.progress=35.0+float(i)*8.0
        t.lane=clampf(float(t.lane)+sin(race_clock*0.35+i)*0.12*delta,-5.0,5.0)
        traffic[i]=t
        _place_racer(t.node,float(t.progress),float(t.lane))

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
                damage=minf(100.0,damage+dmg)
                clean_score=maxf(0.0,clean_score-(15.0 if dmg>20.0 else 5.0))
            collision_cooldown=0.8
            HapticsSystem.pulse(0.7)
    for t in traffic:
        if absf(player_progress-float(t.progress))<3.5 and absf(player_lane-float(t.lane))<1.8:
            damage=minf(100.0,damage+12.0*(0.8 if RaceSession.assist_used else 1.0))
            clean_score=maxf(0.0,clean_score-5.0)
            collision_cooldown=1.0
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
    _show_results(result,rewards)

func _show_results(result:Dictionary,rewards:Dictionary)->void:
    _show_only("results")
    results_label.text=_ordinal(int(result.finish_position))+" PLACE" if bool(result.completed) else "DNF"
    results_detail.text="Rank Coins: %d\nChest: %s • %d Coins • %d Diamonds\nRandom Bonus: %d Coins • %d Diamonds\nTrack Coins: %d\nFirst Clear Diamonds: %d\nStars: %d\nTOTAL: %d Coins • %d Diamonds" % [int(rewards.rank_coins),str(rewards.chest),int(rewards.chest_coins),int(rewards.chest_diamonds),int(rewards.bonus_coins),int(rewards.bonus_diamonds),int(rewards.track_coins),int(rewards.first_clear_diamonds),int(rewards.stars),int(rewards.total_coins),int(rewards.total_diamonds)]
    next_button.disabled=not bool(result.completed) or int(result.finish_position)>5
    double_button.disabled=true
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
