local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "deDE")
if not L then return end

L["Enabled"] = "|cff00ff00Aktiviert|r"
L["Disabled"] = "|cffff0000Deaktiviert|r"
L["You have entered |cffd9d919%s|r. Enable logging for this zone?"] = "Du hast |cffd9d919%s|r betreten. Die Aufzeichnung für dieses Gebiet aktivieren?"
L["|cffeda55fClick|r to toggle combat logging\n|cffeda55fRight-Click|r to open the options menu"] = "Klicken um die Kampf-Aufzeichnung ein/auszuschalten\nRechtsklick um das Optionsmenü zu öffnen"

L["Enable chat logging"] = "Chat-Aufzeichnung aktivieren"
L["Enable chat logging when combat logging is enabled."] = "Chat-Aufzeichnung immer aktivieren wenn die Aufzeichnung des Kampflogs aktiviert ist"
L["Profiles"] = "Profile"
L["Prompt on new zone"] = "Abfrage bei Zonenwechsel"
L["Prompt to enable logging when entering a new raid instance."] = "Abfrage bei Betreten einer neuen Instanz?"
L["Show minimap icon"] = "Minimap-Symbol anzeigen"
L["Toggle showing or hiding the minimap icon."] = "Die Anzeige des Minimap-Symbols ein/ausschalten"
L["You have not entered a raid instance yet! Zones will be listed after you enter them."] = true
L["Zones"] = "Zonen"

