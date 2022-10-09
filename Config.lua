local ADDON_NAME, addon = ...
local module = addon:NewModule("Config")

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local icon = LibStub("LibDBIcon-1.0", true)

local ADDON_TITLE = "LoggerHead Lite"
local COMBAT_LOG = COMBAT_LOG
local ENABLED = "|cff00ff00"..VIDEO_OPTIONS_ENABLED.."|r"
local DISABLED = "|cffff0000"..VIDEO_OPTIONS_DISABLED.."|r"
local UNKNOWN_ZONE = UNKNOWN.." (%d)"

local mapData = {}
local mapOverrides = {
	-- For when EJ_GetInstanceInfo and GetRealZoneText don't use the same name /wrists
	[320] = 531, -- Temple of Ahn'Qiraj -> Ahn'Qiraj Temple
	[334] = 550, -- The Eye -> Tempest Keep
}

local setMapData

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	local function getMapIDs(tier, isRaid)
		EJ_SelectTier(tier)
		local index = 1
		local journalInstanceID, instanceName, _, _, _, _, _, mapID = EJ_GetInstanceByIndex(index, isRaid)
		repeat
			if mapID and mapID > 0 then
				if mapOverrides[mapID] then
					instanceName = GetRealZoneText(mapOverrides[mapID])
				end
				mapData[instanceName] = tier
			end
			index = index + 1
			journalInstanceID, instanceName, _, _, _, _, _, mapID = EJ_GetInstanceByIndex(index, isRaid)
		until not journalInstanceID
	end

	function setMapData()
		for tier = 1, EJ_GetNumTiers() do
			getMapIDs(tier, true)
			if tier > 4 then -- MoP+ for challenge mode dungeons
				getMapIDs(tier, false)
			end
		end
		mapOverrides = nil
	end
else
	mapData = {
		-- Classic
		[249] = 1, -- Onyxia's Lair
		[409] = 1, -- Molten Core
		[469] = 1, -- Blackwing Lair
		[509] = 1, -- Ruins of Ahn'Qiraj
		[531] = 1, -- Ahn'Qiraj Temple
		[533] = 1, -- Naxxramas
		[309] = 1, -- Zul'Gurub
		-- TBC
		[532] = 2, -- Karazhan
		[565] = 2, -- Gruul's Lair
		[544] = 2, -- Magtheridon's Lair
		[564] = 2, -- Black Temple
		[534] = 2, -- Hyjal Summit
		[548] = 2, -- Serpentshrine Cavern
		[550] = 2, -- Tempest Keep
		[580] = 2, -- Sunwell Plateau
		[568] = 2, -- Zul'Aman
		-- Wrath
		[631] = 3, -- Icecrown Citadel
		[533] = 3, -- Naxxramas
		[249] = 3, -- Onyxia's Lair
		[616] = 3, -- The Eye of Eternity
		[615] = 3, -- The Obsidian Sanctum
		[724] = 3, -- The Ruby Sanctum
		[649] = 3, -- Trial of the Crusader
		[603] = 3, -- Ulduar
		[624] = 3, -- Vault of Archavon
	}
	mapOverrides = nil

	function setMapData()
		for k, v in next, mapData do
			if tonumber(k) then
				local z = GetRealZoneText(k)
				if z then
					mapData[z] = v
				end
				mapData[k] = nil
			end
		end
	end
end

local function GetOptions()
	if setMapData then
		setMapData()
		setMapData = nil
	end

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
			partial = {
				type = "toggle",
				name = L["Ignore partial group"],
				desc = L["Skip the prompt if your instance group has less than five players."],
				disabled = function() return not db.prompt end,
				order = 2,
			},
			chat = {
				type = "toggle",
				name = L["Log chat"],
				desc = L["Enable chat logging when combat logging is enabled."],
				order = 3,
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
			local name = GetRealZoneText(id) or UNKNOWN_ZONE:format(id)
			local tierIndex = mapData[name] or 0
			local tier = L["EXPANSION_NAME"..(tierIndex - 1)] or UNKNOWN

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
				if diff == 8 then
					values = nil
					break
				end
				values[diff] = GetDifficultyInfo(diff)
			end

			if values then
				options.args[tier].args[name] = {
					type = "multiselect",
					name = name,
					values = values,
					get = function(info, key) return difficulties[key] end,
					set = function(info, key, value)
						difficulties[key] = value
						addon:CheckInstance()
					end,
					order = 0,
				}
			else
				if not options.args[tier].args["keystone"] then
					options.args[tier].args["keystone"] = {
						type = "group", inline = true,
						name = GetDifficultyInfo(8),
						get = function(info) return db.zones[info.arg][8] end,
						set = function(info, value)
							db.zones[info.arg][8] = value
							addon:CheckInstance()
						end,
						order = 1,
						args = {},
					}
				end
				options.args[tier].args["keystone"].args[name] = {
					type = "toggle",
					name = name,
					arg = id,
				}
			end
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
		text = LoggingCombat() and ENABLED or DISABLED,
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
			dataObj.text = ENABLED
		elseif enable == false then
			dataObj.icon = "Interface\\AddOns\\LoggerHeadLite\\disabled"
			dataObj.text = DISABLED
		end
	end)

	if icon then
		icon:Register(ADDON_NAME, dataObj, addon.db.profile.minimap)
		if not addon.db.profile.minimap.hide then
			icon:Show(ADDON_NAME)
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
