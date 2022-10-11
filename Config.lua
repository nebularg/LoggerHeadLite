local ADDON_NAME, addon = ...
local module = addon:NewModule("Config")

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local icon = LibStub("LibDBIcon-1.0", true)

local ADDON_TITLE = "LoggerHead Lite"
local COMBAT_LOG = _G.COMBAT_LOG
local ENABLED = "|cff00ff00"..L["Enabled"].."|r"
local DISABLED = "|cffff0000"..L["Disabled"].."|r"
local UNKNOWN = _G.UNKNOWN
local UNKNOWN_ID = UNKNOWN.." (%d)"

local GetDifficultyInfo = _G.GetDifficultyInfo

local getTierName, getInstanceInfo

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	function getTierName(index)
		local name = EJ_GetTierInfo(index)
		return name
	end

	local function getInstanceName(id, tier, isRaid)
		EJ_SelectTier(tier)
		local index = 1
		local journalInstanceID, instanceName, _, _, _, _, _, _, _, _, instanceID = EJ_GetInstanceByIndex(index, isRaid)
		repeat
			if instanceID == id and (not isRaid or tier < 5 or index > 1) then
				-- starting with MoP raids, index 1 is world bosses, but uses the instanceID of index 2 z.z
				return instanceName, index
			end
			index = index + 1
			journalInstanceID, instanceName, _, _, _, _, _, _, _, _, instanceID = EJ_GetInstanceByIndex(index, isRaid)
		until not journalInstanceID
	end

	function getInstanceInfo(id)
		for tier = 1, EJ_GetNumTiers() do
			local name, index = getInstanceName(id, tier, true)
			if name then
				return tier, index, name
			end
			if tier > 4 then -- MoP+ for challenge mode dungeons
				name, index = getInstanceName(id, tier, false)
				if name then
					return tier, index, name
				end
			end
		end
		return 0, 0, GetRealZoneText(id)
	end
else
	local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
	local mapData = {
		-- Classic Raids
		[249] = {isClassicEra and 1 or 3, isClassicEra and 1 or 7}, -- Onyxia's Lair
		[409] = {1, 2},  -- Molten Core
		[469] = {1, 3},  -- Blackwing Lair
		[309] = {1, 4},  -- Zul'Gurub
		[509] = {1, 5},  -- Ruins of Ahn'Qiraj
		[531] = {1, 6},  -- Ahn'Qiraj Temple
		[533] = {isClassicEra and 1 or 3, isClassicEra and 7 or 2}, -- Naxxramas
		-- TBC Raids
		[532] = {2, 1},  -- Karazhan
		[565] = {2, 2},  -- Gruul's Lair
		[544] = {2, 3},  -- Magtheridon's Lair
		[548] = {2, 4},  -- Serpentshrine Cavern
		[550] = {2, 5},  -- Tempest Keep
		[534] = {2, 6},  -- Hyjal Summit
		[564] = {2, 7},  -- Black Temple
		[568] = {2, 8},  -- Zul'Aman
		[580] = {2, 9},  -- Sunwell Plateau
		-- TBC Dungeons
		[558] = {2, 1},  -- Auchenai Crypts
		[543] = {2, 2},  -- Hellfire Ramparts
		[585] = {2, 3},  -- Magisters' Terrace
		[557] = {2, 4},  -- Mana-Tombs
		[560] = {2, 5},  -- Old Hillsbrad Foothills
		[556] = {2, 6},  -- Sethekk Halls
		[555] = {2, 7},  -- Shadow Labyrinth
		[552] = {2, 8},  -- The Arcatraz
		[269] = {2, 9},  -- The Black Morass
		[542] = {2, 10}, -- The Blood Furnace
		[553] = {2, 11}, -- The Botanica
		[554] = {2, 12}, -- The Mechanar
		[540] = {2, 13}, -- The Shattered Halls
		[547] = {2, 14}, -- The Slave Pens
		[545] = {2, 15}, -- The Steamvault
		[546] = {2, 16}, -- The Underbog
		-- Wrath Raids
		[624] = {3, 1},  -- Vault of Archavon
		[615] = {3, 3},  -- The Obsidian Sanctum
		[616] = {3, 4},  -- The Eye of Eternity
		[603] = {3, 5},  -- Ulduar
		[649] = {3, 6},  -- Trial of the Crusader
		[631] = {3, 8},  -- Icecrown Citadel
		[724] = {3, 9},  -- The Ruby Sanctum
		-- Wrath Dungeons
		[619] = {3, 1},  -- Ahn'kahet: The Old Kingdom
		[601] = {3, 2},  -- Azjol-Nerub
		[600] = {3, 3},  -- Drak'Tharon Keep
		[604] = {3, 4},  -- Gundrak
		[602] = {3, 5},  -- Halls of Lightning
		[668] = {3, 6},  -- Halls of Reflection
		[599] = {3, 7},  -- Halls of Stone
		[658] = {3, 8},  -- Pit of Saron
		[595] = {3, 9},  -- The Culling of Stratholme
		[632] = {3, 10}, -- The Forge of Souls
		[576] = {3, 11}, -- The Nexus
		[578] = {3, 12}, -- The Oculus
		[608] = {3, 13}, -- The Violet Hold
		[650] = {3, 14}, -- Trial of the Champion
		[574] = {3, 15}, -- Utgarde Keep
		[575] = {3, 16}, -- Utgarde Pinnacle
	}

	function getTierName(tier)
		if tier > 0 and tier <= GetServerExpansionLevel() + 1 then
			return L["EXPANSION_NAME"..(tier - 1)]
		end
	end

	function getInstanceInfo(id)
		if mapData[id] then
			return mapData[id][1], mapData[id][2], GetRealZoneText(id)
		end
		return 0, 0, GetRealZoneText(id)
	end

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		-- So classic left the function ... but it returns nothing.
		GetDifficultyInfo = function(id)
			if id == 1 or id == 184 then
				return L["Normal"]
			elseif id == 9 or id == 186 then
				return L["40 Player"]
			elseif id == 148 or id == 185 then
				return L["20 Player"]
			end
		end
	end
end

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
			if not next(difficulties) then
				db.zones[id] = nil
			else
				local tier, index, name = getInstanceInfo(id)
				if not name or name == "" then name = UNKNOWN_ID:format(id) end
				local tierName = getTierName(tier) or UNKNOWN

				if not options.args[tierName] then
					options.args[tierName] = {
						type = "group",
						name = tierName,
						order = 100 - tier,
						args = {},
					}
				end

				local difficultyName
				local values = {}
				for diff in next, difficulties do
					if diff == 8 then
						values = nil
						difficultyName = GetDifficultyInfo(diff)
						break
					elseif diff == 2 then
						values = nil
						difficultyName = L["Dungeons"]
						break
					end
					values[diff] = GetDifficultyInfo(diff) or UNKNOWN_ID:format(diff)
				end

				if values then
					options.args[tierName].args[name] = {
						type = "multiselect",
						name = name,
						values = values,
						get = function(info, key) return difficulties[key] end,
						set = function(info, key, value)
							difficulties[key] = value
							addon:CheckInstance()
						end,
						order = index,
					}
				elseif difficultyName and tierName ~= UNKNOWN then
					local diff = next(difficulties)
					if not options.args[tierName].args["keystone"] then
						options.args[tierName].args["keystone"] = {
							type = "group", inline = true,
							name = difficultyName,
							get = function(info) return db.zones[info.arg][diff] end,
							set = function(info, value)
								db.zones[info.arg][diff] = value
								addon:CheckInstance()
							end,
							order = -1,
							args = {},
						}
					end
					options.args[tierName].args["keystone"].args[name] = {
						type = "toggle",
						name = name,
						arg = id,
					}
				end
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
