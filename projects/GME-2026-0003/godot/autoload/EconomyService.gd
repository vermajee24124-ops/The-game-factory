extends Node

func coins()->int: return int(SaveSystem.data["currencies"]["coins"])
func diamonds()->int: return int(SaveSystem.data["currencies"]["diamonds"])

func grant_coins(amount:int, _reason:String="")->bool:
    if amount<=0: return false
    SaveSystem.data["currencies"]["coins"]=clampi(coins()+amount,0,99999999)
    SaveSystem.data["stats"]["coins_earned_lifetime"]+=amount
    SaveSystem.save_now()
    return true

func spend_coins(amount:int, _reason:String="")->bool:
    if amount<=0 or coins()<amount: return false
    SaveSystem.data["currencies"]["coins"]-=amount
    SaveSystem.data["stats"]["coins_spent_lifetime"]+=amount
    SaveSystem.save_now()
    return true

func grant_diamonds(amount:int, _reason:String="")->bool:
    if amount<=0: return false
    SaveSystem.data["currencies"]["diamonds"]=clampi(diamonds()+amount,0,9999999)
    SaveSystem.data["stats"]["diamonds_earned_lifetime"]+=amount
    SaveSystem.save_now()
    return true

func spend_diamonds(amount:int, _reason:String="")->bool:
    if amount<=0 or diamonds()<amount: return false
    SaveSystem.data["currencies"]["diamonds"]-=amount
    SaveSystem.data["stats"]["diamonds_spent_lifetime"]+=amount
    SaveSystem.save_now()
    return true


func can_afford_combo(coins_cost:int, diamonds_cost:int) -> bool:
    return coins() >= maxi(0, coins_cost) and diamonds() >= maxi(0, diamonds_cost)

func spend_combo(coins_cost:int, diamonds_cost:int, reason:String="") -> bool:
    coins_cost=maxi(0,coins_cost)
    diamonds_cost=maxi(0,diamonds_cost)
    if not can_afford_combo(coins_cost,diamonds_cost):
        return false
    SaveSystem.data["currencies"]["coins"]-=coins_cost
    SaveSystem.data["currencies"]["diamonds"]-=diamonds_cost
    SaveSystem.data["stats"]["coins_spent_lifetime"]+=coins_cost
    SaveSystem.data["stats"]["diamonds_spent_lifetime"]+=diamonds_cost
    SaveSystem.save_now()
    return true
