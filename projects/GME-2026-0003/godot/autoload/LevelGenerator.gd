extends Node

const SALT: String = "TURBO_RUSH_2026"
const TRACK_COUNT: int = 200
const TRACK_STYLE_NAMES := [
    "Grand Prix Circuit","Downtown Dash","Coastal Sprint","Canyon Run","Night Express",
    "Industrial Loop","Snowline Chase","Neon Drift","Volcanic Charge","Mountain Climb",
    "Tight Chicane","High-Speed Ring","Hairpin Challenge","Jump Rally","Boost Boulevard",
    "Traffic Gauntlet","Narrow Bridge","Scenic Tour","Endurance Route","Elite Grand Prix"
]
const TRACK_SURFACES := ["asphalt","wet","gravel","sand","snow","ice","mixed","circuit"]

func level_seed(level:int)->int:
    return abs(hash(str(level)+":"+SALT))

func track_profile(level:int)->Dictionary:
    # 200 stable, named blueprint profiles; each level builds its own seeded layout.
    var idx:int=posmod(maxi(1,level)-1,TRACK_COUNT)
    var style_index:int=idx%TRACK_STYLE_NAMES.size()
    var env_index:int=int(idx/25.0)%GameConfig.ENVIRONMENTS.size()
    var env_entry:Array=GameConfig.ENVIRONMENTS[env_index]
    var surface_index:int=posmod(env_index*3+style_index,TRACK_SURFACES.size())
    return {
        "index":idx+1,
        "id":"track_%03d" % (idx+1),
        "name":"%s %s #%03d" % [str(env_entry[1]),str(TRACK_STYLE_NAMES[style_index]),idx+1],
        "environment_id":str(env_entry[0]),
        "surface":str(TRACK_SURFACES[surface_index]),
        "curve_bias":float((style_index*3)%10)/9.0,
        "jump_bias":float((style_index*7)%10)/9.0,
        "boost_bias":float((style_index*5+2)%10)/9.0,
        "narrow_bias":float((style_index*9+3)%10)/9.0,
        "traffic_bias":float((style_index*4+1)%10)/9.0,
        "width_scale":0.90+float(style_index%8)*0.025
    }

func environment_id(level:int)->String:
    return str(track_profile(level)["environment_id"])

func generate(level:int)->Dictionary:
    var rng:=RandomNumberGenerator.new()
    rng.seed=level_seed(level)
    var profile:Dictionary=track_profile(level)
    var d:=DifficultyService.difficulty(level)
    var typ:=DifficultyService.race_type(level)
    var variance:=rng.randf_range(-8.0,8.0)
    if typ=="Standard": variance=rng.randf_range(-10.0,10.0)
    elif typ=="Endurance": variance=rng.randf_range(-12.0,12.0)
    var target:=DifficultyService.target_time(level,variance)
    var length:=DifficultyService.track_length(level,variance)
    var traffic_mult:=1.0 if typ=="Standard" else 0.8 if typ=="Sprint" else 1.25 if typ=="Endurance" else 1.15
    var traffic:=clampi(int(round((10.0+32.0*d*lerpf(0.90,1.10,float(profile["traffic_bias"]))) * traffic_mult)),4,GameConfig.MAX_TRAFFIC)
    var obstacles:=clampi(int(round(6.0+34.0*d)),6,GameConfig.MAX_OBSTACLES)
    var jumps:=clampi(floori(4.0*d+float(profile["jump_bias"])*2.0),0,12)
    var coins:=clampi(70+int(150.0*d)+rng.randi_range(-10,10),40,GameConfig.MAX_TRACK_COINS)
    var boosts:=clampi(rng.randi_range(2,8)+roundi(float(profile["boost_bias"])*2.0)-1,2,10)
    var diamond:=typ=="Elite" or rng.randf()<(0.08 if typ=="Endurance" else 0.05)
    var modules:Array=[{"type":"start_straight","length":60.0,"turn":0.0}]
    var remaining:=length-130.0
    var curve_bias:float=float(profile["curve_bias"])
    var jump_bias:float=float(profile["jump_bias"])
    var boost_bias:float=float(profile["boost_bias"])
    var narrow_bias:float=float(profile["narrow_bias"])
    var traffic_bias:float=float(profile["traffic_bias"])
    while remaining>75.0:
        var roll:=rng.randf()
        var t:String="straight"
        var hairpin_limit:=0.025+curve_bias*0.065
        var chicane_limit:=0.10+curve_bias*0.10
        var tight_limit:=0.20+curve_bias*0.10
        var medium_limit:=0.38+curve_bias*0.10
        var gentle_limit:=0.52+curve_bias*0.11
        var narrow_limit:=0.62+narrow_bias*0.12
        var jump_limit:=0.72+jump_bias*0.10
        var boost_limit:=0.82+boost_bias*0.10
        var traffic_limit:=0.92+traffic_bias*0.07
        if d>0.72 and roll<hairpin_limit:t="hairpin"
        elif d>0.45 and roll<chicane_limit:t="chicane"
        elif d>0.30 and roll<tight_limit:t="tight_curve"
        elif roll<medium_limit:t="medium_curve"
        elif roll<gentle_limit:t="gentle_curve"
        elif roll<narrow_limit:t="narrow_gate"
        elif roll<jump_limit:t="jump"
        elif roll<boost_limit:t="boost_lane"
        elif roll<traffic_limit:t="traffic_zone"
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
    return {
        "level_number":level,
        "seed":level_seed(level),
        "track_id":str(profile["id"]),
        "track_name":str(profile["name"]),
        "track_profile_index":int(profile["index"]),
        "track_surface":str(profile["surface"]),
        "track_width_scale":float(profile["width_scale"]),
        "track_profile":profile,
        "race_type":typ,
        "difficulty":d,
        "spawn_difficulty":d,
        "environment_id":environment_id(level),
        "condition_id":GameConfig.CONDITIONS[rng.randi_range(0,GameConfig.CONDITIONS.size()-1)],
        "modifiers":_modifiers(level,d,rng),
        "target_time_sec":target,
        "track_length_m":length,
        "traffic_count":traffic,
        "obstacle_count":obstacles,
        "jump_count":jumps,
        "coin_count":coins,
        "boost_pickup_count":boosts,
        "has_diamond_pickup":diamond,
        "track_modules":modules
    }

func _modifiers(level:int,d:float,rng:RandomNumberGenerator)->Array:
    var out:Array=[]
    if level<25:return out
    var wanted:=1 if d<0.65 else 2
    while out.size()<wanted:
        var m:String=GameConfig.MODIFIERS[rng.randi_range(0,GameConfig.MODIFIERS.size()-1)]
        if m=="Mirror Layout" and level<60:continue
        if not out.has(m):out.append(m)
    return out
