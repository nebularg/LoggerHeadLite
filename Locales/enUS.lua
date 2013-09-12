local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true, nil)


L["Enabled"] = "|cff00ff00Enabled|r"
L["Disabled"] = "|cffff0000Disabled|r"
L["You have entered |cffd9d919%s|r. Enable logging for this zone?"] = true
L["|cffeda55fClick|r to toggle combat logging\n|cffeda55fRight-Click|r to open the options menu"] = true

L["Log chat"] = true
L["Enable chat logging when combat logging is enabled."] = true
L["Enable Transcriptor"] = true
L["Enable Transcriptor when logging is *manually* enabled. Transcriptor will be stopped when combat logging stops."] = true
L["Profiles"] = true
L["Prompt on new zone"] = true
L["Prompt to enable logging when entering a new raid instance."] = true
L["Show minimap icon"] = true
L["Toggle showing or hiding the minimap icon."] = true
L["You have not entered a raid instance yet! Zones will be listed after you enter them."] = true
L["Zones"] = true

