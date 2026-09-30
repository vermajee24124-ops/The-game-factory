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
