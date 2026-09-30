extends Node

signal products_loaded(products: Array)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal restore_completed

var online := false
var initialized := false

var products: Dictionary = {
    "diamond_small": {"diamonds":80, "price_usd":"$0.99"},
    "diamond_medium": {"diamonds":400, "price_usd":"$4.99"},
    "diamond_large": {"diamonds":900, "price_usd":"$9.99"},
    "diamond_epic": {"diamonds":2000, "price_usd":"$19.99"},
    "remove_ads": {"diamonds":0, "price_usd":"$2.99"}
}

func init() -> void:
    initialized = true
    products_loaded.emit(products.keys())

func set_online(value: bool) -> void:
    online = value

func request_products() -> void:
    if not online:
        products_loaded.emit([])
        return
    products_loaded.emit(products.keys())

func purchase(product_id: String) -> void:
    if not online:
        purchase_failed.emit(product_id, "Offline")
        return
    purchase_failed.emit(product_id, "Native Aptoide billing adapter not configured")

func restore_purchases() -> void:
    if not online:
        restore_completed.emit()
        return
    restore_completed.emit()

func apply_verified_entitlement(product_id: String) -> void:
    var owned: Array = SaveSystem.data["monetization"]["iap"]["owned_products"]
    if not owned.has(product_id):
        owned.append(product_id)
    if product_id == "remove_ads":
        SaveSystem.data["monetization"]["remove_ads"] = true
    elif products.has(product_id):
        var diamonds := int(products[product_id].get("diamonds", 0))
        if diamonds > 0:
            EconomyService.grant_diamonds(diamonds, "iap_verified")
    SaveSystem.save_now()
    purchase_completed.emit(product_id)
