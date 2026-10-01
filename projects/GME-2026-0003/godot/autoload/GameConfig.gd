extends Node
const GAME_VERSION := "1.0.0"
const MAX_UPGRADE_LEVEL := 10
const REVIVE_DIAMOND_COST := 5
const PLAYER_CAR_COUNT := 1
const AI_CAR_COUNT := 5
const TOTAL_RACERS := 6
const COUNTDOWN_SECONDS := 3.0
const UNLOCK_POSITION_REQUIREMENT := 5
const EXPECTED_SPEED_FACTOR := 0.66
const MAX_TRACK_COINS := 260
const MAX_TRAFFIC := 45
const MAX_OBSTACLES := 40
const UPGRADE_COSTS := [0,120,220,380,650,1050,1700,2700,4300,6800,10500]
const UPGRADE_LEVEL_REQ := [0,1,4,8,13,20,28,38,50,65,85]
const CARS := {
 "rookie_gt":{"name":"Rookie GT","level":1,"cost":0,"top_speed":140.0,"accel":8.0,"grip":1.00,"brake":12.0,"boost_power":25.0,"boost_duration":2.0,"stability":1.00},
 "street_king":{"name":"Street King","level":8,"cost":2500,"top_speed":148.0,"accel":8.6,"grip":1.03,"brake":12.5,"boost_power":27.0,"boost_duration":2.1,"stability":1.00},
 "turbo_viper":{"name":"Turbo Viper","level":18,"cost":7500,"top_speed":155.0,"accel":9.1,"grip":1.01,"brake":12.2,"boost_power":32.0,"boost_duration":2.2,"stability":0.98},
 "canyon_falcon":{"name":"Canyon Falcon","level":32,"cost":18000,"top_speed":149.0,"accel":8.8,"grip":1.05,"brake":13.2,"boost_power":28.0,"boost_duration":2.2,"stability":1.08},
 "circuit_phantom":{"name":"Circuit Phantom","level":55,"cost":45000,"top_speed":162.0,"accel":9.6,"grip":1.06,"brake":13.0,"boost_power":34.0,"boost_duration":2.3,"stability":1.02},
 "hyper_nova":{"name":"Hyper Nova","level":90,"cost":120000,"top_speed":170.0,"accel":10.2,"grip":1.04,"brake":13.5,"boost_power":38.0,"boost_duration":2.4,"stability":1.00}
}
const WHEELS := {
 "wheel_stock":{"name":"Stock","level":1,"cost":0,"premium":false},
 "street_steel":{"name":"Street Steel","level":5,"cost":0,"premium":false},
 "alloy_sport":{"name":"Alloy Sport","level":12,"cost":500,"premium":false},
 "turbo_fan":{"name":"Turbo Fan","level":20,"cost":1200,"premium":false},
 "carbon_track":{"name":"Carbon Track","level":45,"cost":4000,"premium":false},
 "chrome_racer":{"name":"Chrome Racer","level":70,"cost":8000,"premium":false},
 "neon_glow":{"name":"Neon Glow","level":60,"cost":60,"premium":true},
 "golden_crown":{"name":"Golden Crown","level":80,"cost":100,"premium":true},
 "nova_edge":{"name":"Nova Edge","level":100,"cost":150,"premium":true}
}
const PAINTS := {
 "paint_red":{"name":"Turbo Red","level":1,"cost":0,"currency":"coins","type":"basic","color":"#FF3B30"},
 "paint_blue":{"name":"Electric Blue","level":1,"cost":250,"currency":"coins","type":"basic","color":"#23C4FF"},
 "paint_green":{"name":"Rush Green","level":5,"cost":500,"currency":"coins","type":"basic","color":"#3BD47A"},
 "paint_violet":{"name":"Violet Pulse","level":25,"cost":2000,"currency":"coins","type":"metallic","color":"#B77BFF"},
 "paint_matte":{"name":"Matte Shadow","level":40,"cost":3500,"currency":"coins","type":"matte","color":"#2E3442"},
 "paint_chrome":{"name":"Chrome Finish","level":70,"cost":50,"currency":"diamonds","type":"chrome","color":"#DDE3F0"},
 "paint_animated":{"name":"Animated Gradient","level":120,"cost":120,"currency":"diamonds","type":"animated","color":"#6BE1FF"},
 "paint_legendary":{"name":"Legendary Rush","level":150,"cost":300,"currency":"diamonds","type":"legendary","color":"#FFC93C"}
}
const ENVIRONMENTS := [
 ["sunrise_city","Sunrise City"],["coastal_highway","Coastal Highway"],["desert_canyon","Desert Canyon"],["mountain_pass","Mountain Pass"],["industrial_night","Industrial Night"],["snowline","Snowline"],["neon_metro","Neon Metro"],["volcanic_rim","Volcanic Rim"]
]
const CONDITIONS := ["Clear","Sunset","Night","Rain","Fog","Snow","Sandstorm","Ash Haze"]
const MODIFIERS := ["Traffic Rush","Slippery Zones","Boost Famine","Narrow Works","Night Run","Mirror Layout"]
func car(id:String)->Dictionary: return CARS.get(id,CARS["rookie_gt"])
func wheel(id:String)->Dictionary: return WHEELS.get(id,WHEELS["wheel_stock"])
func paint(id:String)->Dictionary: return PAINTS.get(id,PAINTS["paint_red"])
