local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "deDE")
if not L then return end

L["EXPANSION_NAME0"] = "Classic"
L["EXPANSION_NAME1"] = "Burning Crusade"
L["EXPANSION_NAME2"] = "Wrath of the Lich King"
L["Normal"] = "Normal"
L["20 Player"] = "20 Spieler"
L["40 Player"] = "40 Spieler"
L["Dungeons"] = "Dungeons"

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore")@
