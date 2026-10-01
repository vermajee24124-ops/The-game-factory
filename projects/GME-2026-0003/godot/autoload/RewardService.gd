extends Node
const RANK_MULT:Dictionary={1:2.20,2:1.80,3:1.50,4:1.25,5:1.10,6:1.00}
var rng:=RandomNumberGenerator.new()
func _ready()->void:rng.randomize()
func _tier(level:int)->int:return floori(float(level-1)/10.0)+1
func _base(level:int)->float:return minf(500.0,60.0+18.0*float(_tier(level)-1))
func rank_reward(level:int,pos:int,elite:bool)->int:
    if pos<1 or pos>6:return 0
    var em:=1.5 if elite else 1.0
    return int(round(_base(level)*RANK_MULT[pos]*em/5.0)*5.0)
func chest_reward(pos:int,elite:bool)->Dictionary:
    var tier:="Gold" if (elite and pos<=3) or (not elite and pos==1) else "Silver" if (elite or pos<=3) else "Bronze"
    var table:Array=[[150,0.30],[220,0.25],[300,0.20],[380,0.15],[450,0.08],[500,0.02]]
    if tier=="Silver":table=[[80,0.30],[120,0.30],[180,0.20],[250,0.12],[350,0.06],[500,0.02]]
    elif tier=="Bronze":table=[[50,0.35],[80,0.30],[120,0.20],[180,0.10],[250,0.04],[500,0.01]]
    var roll:=rng.randf()
    var acc:=0.0
    var coins:=50
    for e in table:
        acc+=float(e[1])
        if roll<=acc:coins=int(e[0]);break
    var chance:=0.03 if tier=="Gold" else 0.02 if tier=="Silver" else 0.01
    var diamonds:=1 if rng.randf()<=chance else 0
    if diamonds>0 and rng.randf()<0.01:diamonds=2
    if elite and pos==1:coins+=50
    return {"tier":tier,"coins":coins,"diamonds":diamonds}
func random_bonus()->Dictionary:
    var roll:=rng.randf()
    var t:Array=[[0.397,20,0],[0.300,40,0],[0.150,80,0],[0.090,150,0],[0.050,250,0],[0.0025,0,1],[0.0005,0,2]]
    var acc:=0.0
    for e in t:
        acc+=float(e[0])
        if roll<=acc:return {"coins":int(e[1]),"diamonds":int(e[2])}
    return {"coins":20,"diamonds":0}
func stars_for(pos:int,clean:float)->int:
    if pos==1 and clean>=80:return 3
    if pos>0 and pos<=3:return 2
    if pos>0:return 1
    return 0
func first_clear(level:int)->Dictionary:
    if level%50==0:return {"coins":0,"diamonds":8}
    if level%10==0:return {"coins":0,"diamonds":3}
    return {"coins":0,"diamonds":0}
func resolve_result(r:Dictionary)->Dictionary:
    if not bool(r.completed):return {"rank_coins":0,"chest_coins":0,"chest_diamonds":0,"bonus_coins":0,"bonus_diamonds":0,"first_clear_diamonds":0,"track_coins":0,"diamond_pickup":0,"total_coins":0,"total_diamonds":0,"chest":"None"}
    var elite:=str(r.race_type)=="Elite"
    var ch:=chest_reward(int(r.finish_position),elite)
    var bonus:=random_bonus()
    var rec:=SaveSystem.level_record(int(r.level_number))
    var first:=first_clear(int(r.level_number)) if not bool(rec.first_clear_completed) else {"coins":0,"diamonds":0}
    var rank:=rank_reward(int(r.level_number),int(r.finish_position),elite)
    var track:=int(r.track_coins_collected)
    var pickup:=1 if bool(r.diamond_pickup_collected) else 0
    var raw_coins:=rank+int(ch.coins)+int(bonus.coins)+int(first.coins)+track
    var tc:=int(round(float(raw_coins)*ProgressionService.coin_multiplier()))
    var td:=int(ch.diamonds)+int(bonus.diamonds)+int(first.diamonds)+pickup
    EconomyService.grant_coins(tc,"race_reward")
    if td>0:EconomyService.grant_diamonds(td,"race_reward")
    SaveSystem.data["stats"]["chests_opened"]+=1
    SaveSystem.save_now()
    return {"rank_coins":rank,"chest_coins":int(ch.coins),"chest_diamonds":int(ch.diamonds),"bonus_coins":int(bonus.coins),"bonus_diamonds":int(bonus.diamonds),"first_clear_diamonds":int(first.diamonds),"track_coins":track,"diamond_pickup":pickup,"total_coins":tc,"total_diamonds":td,"chest":str(ch.tier)}
