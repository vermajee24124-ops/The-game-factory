extends Node

func difficulty(level:int)->float:
    return minf(1.0,1.0-exp(-float(maxi(level,1)-1)/70.0))

func recommended_upgrade_level(level:int)->int:
    if level<=4:return 0
    if level<=12:return 1
    if level<=22:return 2
    if level<=34:return 3
    if level<=48:return 4
    if level<=64:return 5
    if level<=84:return 6
    if level<=109:return 7
    if level<=144:return 8
    if level<=199:return 9
    return 10

func race_type(level:int)->String:
    if level%10==0:return "Elite"
    if level>=15 and level%10==5:return "Sprint"
    if level>=27 and level%10==7:return "Endurance"
    return "Standard"

func expected_top_speed_kmh(level:int)->float:
    return minf(190.0,140.0+2.5*recommended_upgrade_level(level)+minf(30.0,floori(float(level)/10.0)*2.0))

func target_time(level:int,variance:float=0.0)->float:
    var d:=difficulty(level)
    var t:=race_type(level)
    var base:=135.0+15.0*d
    var lo:=120.0
    var hi:=170.0
    if t=="Sprint": base=95.0+10.0*d; lo=85.0; hi=115.0
    elif t=="Endurance": base=185.0+15.0*d; lo=175.0; hi=215.0
    elif t=="Elite": base+=10.0; lo=130.0; hi=180.0
    return clampf(base+variance,lo,hi)

func expected_speed_mps(level:int)->float:
    return expected_top_speed_kmh(level)/3.6*GameConfig.EXPECTED_SPEED_FACTOR

func track_length(level:int,variance:float=0.0)->float:
    return target_time(level,variance)*expected_speed_mps(level)

func ai_top_speed_multiplier(level:int,elite:bool)->float:
    var v:=0.88+0.18*difficulty(level)+(0.02 if elite else 0.0)
    return minf(v,1.08 if elite else 1.06)
