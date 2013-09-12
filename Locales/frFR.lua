local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "frFR")
if not L then return end

L["Enabled"] = "|cff00ff00Activé|r"
L["Disabled"] = "|cffff0000Désactivé|r"
L["You have entered |cffd9d919%s|r. Enable logging for this zone?"] = "Vous êtes entré dans |cffd9d919%s|r. Voulez-vous activer les logs pour cette zone/instance?"
L["|cffeda55fClick|r to toggle combat logging\n|cffeda55fRight-Click|r to open the options menu"] = "|cffeda55fCliquer|r pour activer/désactiver le log de combat\n|cffeda55fClic droit|r pour ouvrir le menu des options"

L["Enable chat logging"] = "Activer le log de chat"
L["Enable chat logging when combat logging is enabled."] = "Activer le log de chat dès que le log de combat est activé."
L["Profiles"] = "Profils"
L["Prompt on new zone"] = "Rappeler dans une nouvelle zone"
L["Prompt to enable logging when entering a new raid instance."] = "Rappeler en entrant dans une nouvelle zone?"
L["Show minimap icon"] = "Montrer l'icône sur la mini-carte"
L["Toggle showing or hiding the minimap icon."] = "Activer/désactiver l'affichage de l'icône sur la mini-carte."
L["You have not entered a raid instance yet! Zones will be listed after you enter them."] = true
L["Zones"] = "Zones"

