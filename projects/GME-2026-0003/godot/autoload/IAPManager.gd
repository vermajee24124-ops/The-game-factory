extends Node

signal products_loaded(products: Array)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal restore_completed

var online := false
var initialized := false
var products: Dictionary = {}

func init() -> void:
    initialized = true
    _sync_catalog()
    products_loaded.emit(ReleaseConfig.APTOIDE_PRODUCT_IDS)

func set_online(value: bool) -> void:
    online = value

func request_products() -> void:
    _sync_catalog()
    if not online:
        products_loaded.emit([])
        return
    products_loaded.emit(ReleaseConfig.APTOIDE_PRODUCT_IDS)

func _sync_catalog() -> void:
    products.clear()
    for id in ReleaseConfig.APTOIDE_PRODUCT_IDS:
        if str(id) == "remove_ads":
            products[id] = {
                "id":"remove_ads",
                "name":"Remove Ads",
                "type":"non_consumable",
                "coins":0,
                "diamonds":0,
                "skins":[],
                "cards":[],
                "cars":[],
                "wheels":[],
                "reference_price_usd":2.99
            }
        else:
            var b:Dictionary=ContentCatalog.bundle(str(id))
            if not b.is_empty():
                products[id]=b

func product_summary(product_id:String) -> String:
    var item:Dictionary=products.get(product_id,{})
    if item.is_empty(): return ""
    var parts:Array=[]
    var coins:=int(item.get("coins",0))
    var diamonds:=int(item.get("diamonds",0))
    if coins>0: parts.append("%d Coins"%coins)
    if diamonds>0: parts.append("%d Diamonds"%diamonds)
    var skins:Array=item.get("skins",[])
    var cards:Array=item.get("cards",[])
    if not skins.is_empty(): parts.append("%d Skins"%skins.size())
    if not cards.is_empty(): parts.append("%d Cards"%cards.size())
    var cars:Array=item.get("cars",[])
    var wheels:Array=item.get("wheels",[])
    if not cars.is_empty(): parts.append("%d Cars"%cars.size())
    if not wheels.is_empty(): parts.append("%d Wheels"%wheels.size())
    if product_id=="remove_ads": return "Permanent ad removal"
    return " • ".join(parts)

func purchase(product_id: String) -> void:
    if not online:
        purchase_failed.emit(product_id, "Offline")
        return
    if not ReleaseConfig.APTOIDE_PRODUCT_IDS.has(product_id):
        purchase_failed.emit(product_id, "Unknown product")
        return
    if not Engine.has_singleton("AptoideBillingBridge"):
        purchase_failed.emit(product_id, "Aptoide Billing adapter not installed")
        return
    var bridge = Engine.get_singleton("AptoideBillingBridge")
    if not bridge.has_method("purchase"):
        purchase_failed.emit(product_id, "Aptoide Billing adapter unavailable")
        return
    bridge.purchase(product_id)

func restore_purchases() -> void:
    if not online:
        restore_completed.emit()
        return
    if Engine.has_singleton("AptoideBillingBridge"):
        var bridge = Engine.get_singleton("AptoideBillingBridge")
        if bridge.has_method("restore_purchases"):
            bridge.restore_purchases()
    restore_completed.emit()

func _record_transaction(transaction_id:String, product_id:String) -> bool:
    if transaction_id.is_empty():
        return true
    var tx:Array=SaveSystem.data["monetization"]["iap"]["transactions"]
    for row in tx:
        if str(row.get("id",""))==transaction_id:
            return false
    tx.append({"id":transaction_id,"product_id":product_id,"unix":Time.get_unix_time_from_system()})
    return true

## Call only after the native layer has verified the purchase/receipt.
func apply_verified_entitlement(product_id: String, transaction_id:String="") -> bool:
    if not products.has(product_id):
        return false
    if not _record_transaction(transaction_id, product_id):
        return true

    if product_id=="remove_ads":
        if not SaveSystem.data["monetization"]["iap"]["owned_products"].has(product_id):
            SaveSystem.data["monetization"]["iap"]["owned_products"].append(product_id)
        SaveSystem.data["monetization"]["remove_ads"]=true
        SaveSystem.save_now()
        purchase_completed.emit(product_id)
        return true

    var item:Dictionary=products[product_id]
    var coins:=int(item.get("coins",0))
    var diamonds:=int(item.get("diamonds",0))
    if coins>0: EconomyService.grant_coins(coins,"iap_bundle")
    if diamonds>0: EconomyService.grant_diamonds(diamonds,"iap_bundle")

    for skin_id in item.get("skins",[]):
        ProgressionService.grant_skin(str(skin_id))
    for card_id in item.get("cards",[]):
        ProgressionService.grant_card(str(card_id))
    for car_id in item.get("cars",[]):
        ProgressionService.grant_car(str(car_id))
    for wheel_id in item.get("wheels",[]):
        ProgressionService.grant_wheel(str(wheel_id))

    var owned:Array=SaveSystem.data["monetization"]["iap"]["owned_products"]
    if not owned.has(product_id):
        owned.append(product_id)
    SaveSystem.save_now()
    purchase_completed.emit(product_id)
    return true
