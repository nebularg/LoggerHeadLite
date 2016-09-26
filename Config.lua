local ADDON_NAME, addon = ...
local ADDON_TITLE = "LoggerHead Lite"
local module = addon:NewModule("Config")

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local icon = LibStub("LibDBIcon-1.0", true)

local COMBAT_LOG = COMBAT_LOG
local ENABLED = "|cff00ff00"..VIDEO_OPTIONS_ENABLED.."|r"
local DISABLED = "|cffff0000"..VIDEO_OPTIONS_DISABLED.."|r"

local instanceMapData = {}
local mapData = {
	-- Map IDs for raids not in the Encounter Journal (http://www.wowpedia.org/MapID)
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
				name = L["Automatically turns on the combat log for selected raid and mythic+ instances."].."\n",
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
			local tierIndex = mapID and mapData[mapID] or 0
			local tier = EJ_GetTierInfo(tierIndex) or UNKNOWN

			if not options.args[tier] then
				options.args[tier] = {
					type = "group",
					name = tier,
					order = 100 - tierIndex,
					args = {},
				}
			end

			local values = {}
			for diff in next, difficulties do
				values[diff] = GetDifficultyInfo(diff)
			end

			options.args[tier].args[name] = {
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

	local dataObj = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
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
		if enable == true or enable == 1 then
			dataObj.icon = "Interface\\AddOns\\LoggerHeadLite\\enabled"
			dataObj.text = L["Enabled"]
		elseif enable == false then
			dataObj.icon = "Interface\\AddOns\\LoggerHeadLite\\disabled"
			dataObj.text = L["Disabled"]
		end
	end)

	if icon then
		icon:Register(ADDON_NAME, dataObj, addon.db.profile.minimap)
		if not addon.db.profile.minimap.hide then
			icon:Show(ADDON_NAME)
		end
	end
end

function module:OnEnable()
	-- pull the mapID for raids from the EJ
	for tier=4, EJ_GetNumTiers() do
		EJ_SelectTier(tier)
		local index = 1
		local instanceID = EJ_GetInstanceByIndex(index, true)
		while instanceID do
			EJ_SelectInstance(instanceID)
			local _, _, _, _, _, _, mapID = EJ_GetInstanceInfo()
			if mapID and mapID > 0 and not mapData[mapID] then
				mapData[mapID] = tier
			end

			index = index + 1
			instanceID = EJ_GetInstanceByIndex(index, true)
		end
	end

	-- and dungeons
	for tier=4, EJ_GetNumTiers() do
		EJ_SelectTier(tier)
		local index = 1
		local instanceID = EJ_GetInstanceByIndex(index, false)
		while instanceID do
			EJ_SelectInstance(instanceID)
			local _, _, _, _, _, _, mapID = EJ_GetInstanceInfo()
			if mapID and mapID > 0 and not mapData[mapID] then
				mapData[mapID] = tier
			end

			index = index + 1
			instanceID = EJ_GetInstanceByIndex(index, false)
		end
	end

	-- map the localizable mapID to GetInstanceInfo's areaID
	for mapID in next, mapData do
		local areaID = GetAreaMapInfo(mapID)
		if areaID then
			instanceMapData[areaID] = mapID
		end
	end
end

function addon:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE)
	InterfaceOptionsFrame_OpenToCategory(ADDON_TITLE)
end

SLASH_LOGGERHEAD1 = "/loggerhead"
SLASH_LOGGERHEAD2 = "/lh"
SlashCmdList["LOGGERHEAD"] = addon.OpenOptions
