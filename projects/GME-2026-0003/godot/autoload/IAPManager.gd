extends Node
signal products_loaded(products:Array)
signal purchase_completed(product_id:String)
signal purchase_failed(product_id:String,error:String)
signal restore_completed
var online: bool = false
var products: Dictionary = {
    "diamond_small":{"diamonds":80,"price":"$0.99"},
    "diamond_medium":{"diamonds":400,"price":"$4.99"},
    "diamond_large":{"diamonds":900,"price":"$9.99"},
    "diamond_epic":{"diamonds":2000,"price":"$19.99"},
    "remove_ads":{"diamonds":0,"price":"$2.99"}
}

func init()->void:
    products_loaded.emit(products.keys())

func request_products()->void:
    products_loaded.emit(products.keys())

func purchase(product_id:String)->void:
    if not online:
        purchase_failed.emit(product_id,"Offline")
        return
    purchase_failed.emit(product_id,"Native store adapter not configured")

func restore_purchases()->void:
    restore_completed.emit()
