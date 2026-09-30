extends Node
const SALT: String = "TURBO_RUSH_2026"

func level_seed(level:int)->int:
    return abs(hash(str(level)+":"+SALT))

func environment_id(level:int)->String:
    if level<=19:return "sunrise_city"
    if level<=39:return "coastal_highway"
    if level<=59:return "desert_canyon"
    if level<=79:return "mountain_pass"
    if level<=99:return "industrial_night"
    if level<=119:return "snowline"
    if level<=139:return "neon_metro"
    if level<=159:return "volcanic_rim"
    return GameConfig.ENVIRONMENTS[int(level/20.0)%GameConfig.ENVIRONMENTS.size()][0]

func generate(level:int)->Dictionary:
    var rng:=RandomNumberGenerator.new()
    rng.seed=level_seed(level)
    var d:=DifficultyService.difficulty(level)
    var typ:=DifficultyService.race_type(level)
    var variance:=rng.randf_range(-8.0,8.0)
    if typ=="Standard": variance=rng.randf_range(-10.0,10.0)
    elif typ=="Endurance": variance=rng.randf_range(-12.0,12.0)
    var target:=DifficultyService.target_time(level,variance)
    var length:=DifficultyService.track_length(level,variance)
    var traffic_mult:=1.0 if typ=="Standard" else 0.8 if typ=="Sprint" else 1.25 if typ=="Endurance" else 1.15
    var traffic:=clampi(int(round((10.0+32.0*d)*traffic_mult)),4,GameConfig.MAX_TRAFFIC)
    var obstacles:=clampi(int(round(6.0+34.0*d)),6,GameConfig.MAX_OBSTACLES)
    var jumps:=clampi(floori(4.0*d),0,12)
    var coins:=clampi(70+int(150.0*d)+rng.randi_range(-10,10),40,GameConfig.MAX_TRACK_COINS)
    var boosts:=rng.randi_range(2,8)
    var diamond:=typ=="Elite" or rng.randf()<(0.08 if typ=="Endurance" else 0.05)
    var modules:Array=[{"type":"start_straight","length":60.0,"turn":0.0}]
    var remaining:=length-130.0
    while remaining>75.0:
        var roll:=rng.randf()
        var t: String = "straight"
        if d>0.72 and roll<0.10:t="hairpin"
        elif d>0.45 and roll<0.20:t="chicane"
        elif d>0.30 and roll<0.30:t="tight_curve"
        elif roll<0.48:t="medium_curve"
        elif roll<0.66:t="gentle_curve"
        elif roll<0.76:t="narrow_gate"
        elif roll<0.84:t="jump"
        elif roll<0.91:t="boost_lane"
        elif roll<0.96:t="traffic_zone"
        else:t="scenic_segment"
        var min_len:=35.0
        var max_len:=70.0
        if t=="hairpin":min_len=28.0;max_len=45.0
        elif t=="chicane":min_len=50.0;max_len=80.0
        elif t=="jump":min_len=24.0;max_len=36.0
        elif t=="traffic_zone":min_len=70.0;max_len=110.0
        var seg:=minf(remaining,rng.randf_range(min_len,max_len))
        modules.append({"type":t,"length":seg,"turn":(-1.0 if rng.randi_range(0,1)==0 else 1.0)})
        remaining-=seg
    modules.append({"type":"finish_straight","length":70.0,"turn":0.0})
    return {"level_number":level,"seed":level_seed(level),"race_type":typ,"difficulty":d,"spawn_difficulty":d,"environment_id":environment_id(level),"condition_id":GameConfig.CONDITIONS[rng.randi_range(0,GameConfig.CONDITIONS.size()-1)],"modifiers":_modifiers(level,d,rng),"target_time_sec":target,"track_length_m":length,"traffic_count":traffic,"obstacle_count":obstacles,"jump_count":jumps,"coin_count":coins,"boost_pickup_count":boosts,"has_diamond_pickup":diamond,"track_modules":modules}

func _modifiers(level:int,d:float,rng:RandomNumberGenerator)->Array:
    var out:Array=[]
    if level<25:return out
    var wanted:=1 if d<0.65 else 2
    while out.size()<wanted:
        var m:String=GameConfig.MODIFIERS[rng.randi_range(0,GameConfig.MODIFIERS.size()-1)]
        if m=="Mirror Layout" and level<60:continue
        if not out.has(m):out.append(m)
    return out
