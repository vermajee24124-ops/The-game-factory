extends Node
var capacities:Dictionary={
    "traffic":50,"obstacles":60,"coins":300,"boost_pickups":12,"diamond_pickup":1,
    "spark":30,"impact":20,"floating_reward":10
}
func capacity(id:String)->int:return int(capacities.get(id,0))
