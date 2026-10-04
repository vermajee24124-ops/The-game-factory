from pathlib import Path

INDEX = Path(__file__).resolve().parents[0] / ".." / "artifacts" / "web" / "index.html"

SDK_BLOCK = r"""
<style>
.turbo-web-banner{position:fixed;z-index:9999;display:none;left:50%;transform:translateX(-50%);width:320px;height:50px;background:transparent}
#turbo-banner-top{top:0}
#turbo-banner-bottom{bottom:0}
</style>
<script>
window.TURBO_RUSH_GD_GAME_ID = window.TURBO_RUSH_GD_GAME_ID || "";
window.TurboRushWebAds = {
  available:false, provider:"none",
  _loadScript(src,id){return new Promise((resolve,reject)=>{if(document.getElementById(id)){resolve();return}
    const s=document.createElement("script");s.id=id;s.src=src;s.onload=resolve;s.onerror=reject;document.head.appendChild(s);});},
  async init(){
    const host=location.hostname;
    const useCrazy=host==="localhost"||host==="127.0.0.1"||host==="crazygames.com"||host.endsWith(".crazygames.com");
    if(useCrazy){
      try{
        await this._loadScript("https://sdk.crazygames.com/crazygames-sdk-v3.js","turbo-crazy-sdk");
        if(window.CrazyGames&&window.CrazyGames.SDK){
          await window.CrazyGames.SDK.init();
          this.provider="crazygames";this.available=true;
        }
      }catch(e){console.warn("CrazyGames SDK unavailable",e);}
    }
    const gdId=window.TURBO_RUSH_GD_GAME_ID;
    if(!this.available&&gdId){
      window.GD_OPTIONS={gameId:gdId,advertisementSettings:{autoplay:false},
        onEvent:function(event){
          if(event&&event.name==="SDK_REWARDED_WATCH_COMPLETE"&&window.__turboRushRewardCallback){
            window.__turboRushRewardCallback(true);
          }
        }};
      try{
        await this._loadScript("https://html5.api.gamedistribution.com/main.min.js","gamedistribution-jssdk");
        this.provider="gamedistribution";this.available=true;
      }catch(e){console.warn("GameDistribution SDK unavailable",e);}
    }
    return this.available;
  },
  showStartupBanners(){
    if(this.provider!=="crazygames")return;
    const top=document.getElementById("turbo-banner-top"),bottom=document.getElementById("turbo-banner-bottom");
    if(!top||!bottom)return;
    top.style.display="block";bottom.style.display="block";
    try{
      window.CrazyGames.SDK.banner.requestBanner({id:"turbo-banner-top",width:320,height:50});
      window.CrazyGames.SDK.banner.requestBanner({id:"turbo-banner-bottom",width:320,height:50});
    }catch(e){console.warn("banner request failed",e);}
  },
  hideStartupBanners(){
    const top=document.getElementById("turbo-banner-top"),bottom=document.getElementById("turbo-banner-bottom");
    if(this.provider==="crazygames"&&window.CrazyGames&&window.CrazyGames.SDK.banner){
      try{window.CrazyGames.SDK.banner.clearBanner("turbo-banner-top");window.CrazyGames.SDK.banner.clearBanner("turbo-banner-bottom");}catch(e){}
    }
    if(top)top.style.display="none"; if(bottom)bottom.style.display="none";
  },
  showMidgame(){
    if(this.provider==="crazygames"&&window.CrazyGames&&window.CrazyGames.SDK.ad){
      try{window.CrazyGames.SDK.ad.requestAd("midgame",{adStarted:()=>{},adError:()=>{},adFinished:()=>{}});}catch(e){}
    }else if(this.provider==="gamedistribution"&&window.gdsdk&&window.gdsdk.showAd){
      try{window.gdsdk.showAd();}catch(e){}
    }
  },
  showRewarded(){
    const done=ok=>{if(window.__turboRushRewardCallback)window.__turboRushRewardCallback(!!ok);};
    if(this.provider==="crazygames"&&window.CrazyGames&&window.CrazyGames.SDK.ad){
      try{
        window.CrazyGames.SDK.ad.requestAd("rewarded",{adStarted:()=>{},adError:()=>done(false),adFinished:()=>done(true)});
      }catch(e){done(false);}
    }else if(this.provider==="gamedistribution"&&window.gdsdk&&window.gdsdk.showAd){
      try{Promise.resolve(window.gdsdk.showAd("rewarded")).then(()=>done(true)).catch(()=>done(false));}catch(e){done(false);}
    }else{done(false);}
  }
};
</script>
"""

BANNER_BLOCK = '<div id="turbo-banner-top" class="turbo-web-banner"></div>\n<div id="turbo-banner-bottom" class="turbo-web-banner"></div>\n'

if not INDEX.exists():
    raise SystemExit(f"Missing Web export: {INDEX}")

html = INDEX.read_text(encoding="utf-8")

if "window.TurboRushWebAds" not in html:
    html = html.replace("</head>", SDK_BLOCK + "\n</head>", 1)

if 'id="turbo-banner-top"' not in html:
    html = html.replace("</body>", BANNER_BLOCK + "</body>", 1)

INDEX.write_text(html, encoding="utf-8")
print(f"Patched {INDEX}")
