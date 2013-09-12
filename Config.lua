local ADDON_NAME, addon = ...
local ADDON_TITLE = GetAddOnMetadata(ADDON_NAME, "Title")
local module = addon:NewModule("Config")

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local icon = LibStub("LibDBIcon-1.0", true)

local instanceMapData = {}
local mapData = {
	-- Map IDs from raids not in the Encounter Journal (http://www.wowpedia.org/MapID)
	-- Classic
	[696] = 1, -- Molten Core
	[717] = 1, -- Ruins of Ahn'Qiraj
	[755] = 1, -- Blackwing Lair
	[766] = 1, -- Ahn'Qiraj
	-- The Burning Crusade
	[775] = 2, -- Hyjal Summit
	[776] = 2, -- Gruul's Lair
	[779] = 2, -- Magtheridon's Lair
	[780] = 2, -- Serpentshrine Cavern
	[782] = 2, -- The Eye
	[789] = 2, -- Sunwell Plateau
	[796] = 2, -- Black Temple
	[799] = 2, -- Karazhan
	-- Wrath of the Lich King
	[527] = 3, -- The Eye of Eternity
	[529] = 3, -- Ulduar
	[531] = 3, -- The Obsidian Sanctum
	[532] = 3, -- Vault of Archavon
	[535] = 3, -- Naxxramas
	[543] = 3, -- Trial of the Crusader
	[604] = 3, -- Icecrown Citadel
	[609] = 3, -- The Ruby Sanctum
	[718] = 3, -- Onyxia's Lair
}

local function GetOptions()
	local db = addon.db.profile
	local options = {
		name = ADDON_TITLE,
		type = "group",
		get = function(info) return db[info[#info]] end,
		set = function(info, value) db[info[#info]] = value end,
		args = {
			desc = {
				type = "description",
				name = GetAddOnMetadata(ADDON_NAME, "Notes").."\n",
				fontSize = "medium",
				order = 0,
			},
			prompt = {
				type = "toggle",
				name = L["Prompt on new zone"],
				desc = L["Prompt to enable logging when entering a new raid instance."],
				order = 1,
			},
			chat = {
				type = "toggle",
				name = L["Log chat"],
				desc = L["Enable chat logging when combat logging is enabled."],
				order = 2,
			},
			minimap = {
				type = "toggle",
				name = L["Show minimap icon"],
				desc = L["Toggle showing or hiding the minimap icon."],
				get = function() return not db.minimap.hide end,
				set = function(info, value)
					db.minimap.hide = not db.minimap.hide
					if db.minimap.hide then
						icon:Hide(ADDON_NAME)
					else
						icon:Show(ADDON_NAME)
					end
				end,
				hidden = function() return not icon or not icon:IsRegistered(ADDON_NAME) end,
				order = 10,
			},
		},
	}

	if next(db.zones) then
		for id, difficulties in next, db.zones do
			local mapID = instanceMapData[id]
			local name = mapID and GetMapNameByID(mapID) or ("Unknown Zone (%d)"):format(id)
			local catIndex = mapID and mapData[mapID] or 0
			local cat = EJ_GetTierInfo(catIndex) or UNKNOWN

			if not options.args[cat] then
				options.args[cat] = {
					type = "group",
					name = cat,
					order = 100 - catIndex,
					args = {},
				}
			end

			local values = {}
			for diff in next, difficulties do
				values[diff] = GetDifficultyInfo(diff)
			end

			options.args[cat].args[name] = {
				type = "multiselect",
				name = name,
				--desc = BINDING_NAME_TOGGLECOMBATLOG,
				values = values,
				get = function(info, key) return difficulties[key] end,
				set = function(info, key, value)
					difficulties[key] = value
					addon:CheckInstance()
				end,
			}
		end

	else
		options.args.noraid = {
			type = "description",
			name = "\n" .. L["You have not entered a raid instance yet! Zones will be listed after you enter them."],
			fontSize = "large",
			order = 90,
		}

	end

	return options
end

function module:OnInitialize()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("LoggerHeadLite", GetOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LoggerHeadLite", ADDON_TITLE)

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("LoggerHeadLite/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db))
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LoggerHeadLite/Profiles", L["Profiles"], ADDON_TITLE)

	addon.dataObj = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
		type = "data source",
		label = COMBAT_LOG,
		icon = LoggingCombat() and "Interface\\AddOns\\LoggerHeadLite\\enabled" or "Interface\\AddOns\\LoggerHeadLite\\disabled",
		text = LoggingCombat() and L["Enabled"] or L["Disabled"],
		OnClick = function(self, button)
			if button == "RightButton" then
				addon:OpenOptions()
			elseif button == "LeftButton" then
				addon:ToggleLogging()
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine(ADDON_TITLE)
			tooltip:AddLine(" ")
			tooltip:AddLine(L["|cffeda55fClick|r to toggle combat logging\n|cffeda55fRight-Click|r to open the options menu"], .1, 1, .1)
		end
	})

	hooksecurefunc("LoggingCombat", function(enable)
		if type(enable) == "boolean" then
			if enable then
				addon.dataObj.icon = "Interface\\AddOns\\LoggerHeadLite\\enabled"
				addon.dataObj.text = L["Enabled"]
			else
				addon.dataObj.icon = "Interface\\AddOns\\LoggerHeadLite\\disabled"
				addon.dataObj.text = L["Disabled"]
			end
		end
	end)

	if icon then
		icon:Register(ADDON_NAME, addon.dataObj, addon.db.profile.minimap)
		if not addon.db.profile.minimap.hide then
			icon:Show(ADDON_NAME)
		end
	end
end

function module:OnEnable()
	-- pull map ids for raids from the EJ
	for tier=4, EJ_GetNumTiers() do
		EJ_SelectTier(tier)
		for i=1, 100 do
			local _, _, _, _, _, _, mapID = EJ_GetInstanceByIndex(i, true)
			if not mapID then break end
			mapData[mapID] = tier
		end
	end

	-- map the localizable mapID to GetInstanceInfo's areaID
	for mapID in next, mapData do
		local areaID = GetAreaMapInfo(mapID)
		if not areaID then print("WHAT THE FUCK", mapID, areaID) end
		if areaID then
			instanceMapData[areaID] = mapID
		end
	end
end

function addon:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE)
end

SLASH_LOGGERHEAD1 = "/loggerhead"
SLASH_LOGGERHEAD2 = "/lh"
SlashCmdList["LOGGERHEAD"] = addon.OpenOptions
