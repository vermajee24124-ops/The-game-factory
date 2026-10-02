extends Node

## Turbo Rush content catalog.
## 54 cosmetic skins + 48 collectible cards.
## All catalog content is unlocked through gameplay and progression.

var SKINS: Dictionary = {}
var CARDS: Dictionary = {}

const SKIN_NAMES := ["Azure Strike","Crimson Pulse","Volt Lime","Midnight Graphite","Solar Gold","Arctic Ice","Violet Storm","Ruby Rush","Emerald Apex","Cobalt Flash","Sunset Blaze","Neon Mint","Magenta Drive","Pearl White","Titanium Gray","Electric Cyan","Inferno Orange","Royal Blue","Hyper Violet","Lunar Silver","Sapphire Edge","Toxic Green","Copper Heat","Rose Chrome","Phantom Matte","Glacier Blue","Quantum Pink","Velocity Yellow","Carbon Red","Ocean Teal","Galaxy Purple","Desert Bronze","Aurora Green","Steel Blue","Laser Red","Plasma Purple","Frost Silver","Turbo Orange","Deep Navy","Cyber Lime","Meteor Gray","Solar Flare","Pulse Pink","Storm Teal","Chrome Violet","Rally White","Circuit Gold","Night Rider","Prism Blue","Fusion Red","Horizon Green","Apex Black","Nova Cyan","Legend Gold"]
const SKIN_COLORS := ["#21A7FF","#FF3957","#86D72E","#343A46","#FFC83D","#D9F4FF","#9A64FF","#E33C4D","#33D17A","#2C77FF","#FF7A2F","#42FFD5","#FF4FD2","#F1F3F6","#8D96A6","#37E5FF","#FF6A2B","#315EFF","#7C4DFF","#C6CBD5","#438BFF","#9BE22F","#C8793A","#E67C9C","#252A33","#74CFFF","#F66CFF","#FFD83D","#9D303A","#2EB6A5","#6A49C8","#A87546","#7BF26C","#477BAA","#F23838","#A64DDB","#B8C4D6","#F06A24","#172B4D","#9CF229","#676E7B","#FFBA38","#FF5DA8","#4DC7B6","#7B57E8","#F4F5F7","#D7B443","#1B1D25","#4B6CFF","#D63F50","#53D37D","#101217","#39DDF0","#F0C33A"]
const CARD_NAMES := ["Nitro Core","Launch Control","Aero Grip","Brake Matrix","Boost Cell","Stability Frame","Coin Route","Clean Lap","Slipstream Pro","Corner Master","Turbo Charge","Road Shield","Rapid Start","Track Sense","Pit Saver","Boost Tuning","Speed Link","Grip Link","Brake Link","Armor Link","Coin Magnet","Perfect Line","Draft Master","Rush Meter","Overtake Lab","Apex Hunter","Sprint Core","Endurance Core","Elite Focus","Traffic Reader","Precision Drive","Smooth Operator","Diamond Finder","Lucky Line","Combo Engine","Fuel Saver","Boost Guard","Impact Guard","Racing IQ","Finish Surge","Gold Hunter","Time Attack","Rally Instinct","Circuit Sense","Velocity Chip","Neon Reflex","Champion Core","Legend Matrix"]
const CARD_TYPES := ["boost_power","acceleration","handling","braking","stability","coin_multiplier","damage_reduction","boost_duration","top_speed","acceleration","handling","damage_reduction"]

func _init() -> void:
    _build_skins()
    _build_cards()

func _build_skins() -> void:
    for i in range(SKIN_NAMES.size()):
        var n := i + 1
        var rarity := "common"
        if n >= 19 and n <= 36:
            rarity = "rare"
        elif n >= 37 and n <= 48:
            rarity = "epic"
        elif n >= 49:
            rarity = "legendary"
        SKINS["skin_%02d" % n] = {
            "id": "skin_%02d" % n,
            "name": str(SKIN_NAMES[i]),
            "color": str(SKIN_COLORS[i]),
            "rarity": rarity
        }

func _build_cards() -> void:
    for i in range(CARD_NAMES.size()):
        var n := i + 1
        var idx := i % CARD_TYPES.size()
        var type := str(CARD_TYPES[idx])
        var value := 0.0
        if type == "top_speed":
            value = 1.5 + float(i % 4) * 0.5
        elif type == "acceleration" or type == "braking":
            value = 0.10 + float(i % 4) * 0.05
        elif type == "handling" or type == "stability":
            value = 0.01 + float(i % 4) * 0.005
        elif type == "boost_power":
            value = 1.0 + float(i % 4) * 0.5
        elif type == "boost_duration":
            value = 0.05 + float(i % 4) * 0.03
        elif type == "coin_multiplier":
            value = 0.02 + float(i % 4) * 0.01
        elif type == "damage_reduction":
            value = 0.02 + float(i % 4) * 0.01
        var rarity := "common"
        if n >= 17 and n <= 32:
            rarity = "rare"
        elif n >= 33 and n <= 42:
            rarity = "epic"
        elif n >= 43:
            rarity = "legendary"
        CARDS["card_%02d" % n] = {
            "id": "card_%02d" % n,
            "name": str(CARD_NAMES[i]),
            "rarity": rarity,
            "type": type,
            "value": value
        }

func _ids(prefix: String, first_id: int, last_id: int) -> Array:
    var out: Array = []
    for n in range(first_id, last_id + 1):
        out.append("%s_%02d" % [prefix, n])
    return out

func _range_from_array(source:Array, first_index:int, last_index:int) -> Array:
    var out:Array=[]
    if source.is_empty(): return out
    var first:=clampi(first_index-1,0,source.size()-1)
    var last:=clampi(last_index,first+1,source.size())
    for i in range(first,last): out.append(source[i])
    return out

func skin(id: String) -> Dictionary:
    return SKINS.get(id, {})

func card(id: String) -> Dictionary:
    return CARDS.get(id, {})

