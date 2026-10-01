extends Node
## Release configuration for Turbo Rush.
## Public identifiers may be stored here; private credentials must never be committed.

const GAME_NAME := "Turbo Rush"
const PACKAGE_NAME := "com.vermajeeverma.turborush"
const SUPPORT_EMAIL := "vermagamestudios@gmail.com"

const UNITY_ANDROID_GAME_ID := "6195679"
const UNITY_IOS_GAME_ID := "6195678"

# Unity Dashboard contains six active ad units:
# Banner_Android, Banner_iOS, Rewarded_Android, Rewarded_iOS,
# Interstitial_Android, Interstitial_iOS.
#
# The supplied screenshot shows their names but truncates the actual ID strings.
# Do not guess those values.
const UNITY_ANDROID_BANNER_AD_UNIT_ID := ""
const UNITY_ANDROID_REWARDED_AD_UNIT_ID := ""
const UNITY_ANDROID_INTERSTITIAL_AD_UNIT_ID := ""

# Aptoide Connect public key supplied by the developer.
const APTOIDE_PUBLIC_KEY := "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs7BrfGbVsDf9u79dPvua31mYkC/vg8opIgjJcOTzLpz56nUAg+vDWsXIq2F6LvRcjLov9fwHegyDbChAT3z0up+TTafDlpWwUNEqMSua1Pb5T6yDW7byEZ4iytz1NDOyd2YI7LLA44g0QlMha03QTnM75ZzRykX+oerR7+/LrGTM1wV1fd08sgTBL4Te5Wa7SYhi99zI3aMW5LTDj/2Y/FO03rKJfdutDW6XcTUkFnLg7dSn3OgSgolBXN1Ie4BEmEjd1zDJu61wgJzhR5g0Zs3F1KLTnVlNyLCmSnEwfpozS8YgK/7n0X3gyE6woulvI6ZSPFD/fgtBkgVXQp8eXwIDAQAB"

# Stable product IDs matching the existing Turbo Rush economy layer.
# Register the same IDs in Aptoide Connect before enabling live purchases.
const APTOIDE_PRODUCT_IDS := [
    "starter_garage",
    "racer_bundle",
    "pro_garage",
    "skin_vault_01",
    "skin_vault_02",
    "card_vault_01",
    "card_vault_02",
    "mega_rush",
    "ultimate_garage",
    "remove_ads"
]
