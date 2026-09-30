extends Node
var state: String = "LOADING"
var level: int = 1
var definition: Dictionary = {}
var race_time: float = 0.0
var track_coins_collected: int = 0
var diamond_pickup_collected: bool = false
var damage: float = 0.0
var clean_score: float = 100.0
var revive_used: bool = false
var assist_used: bool = false

func reset(level_number:int, data:Dictionary)->void:
    level=level_number
    definition=data
    race_time=0.0
    track_coins_collected=0
    diamond_pickup_collected=false
    damage=0.0
    clean_score=100.0
    revive_used=false
    assist_used=SaveSystem.get_level_failures(level_number)>=2
    state="LOADING"
