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

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local GetDifficultyInfo = _G.GetDifficultyInfo
local Settings = _G.Settings

local settingsCategoryID

local getTierName, getInstanceInfo

if isRetail then
	function getTierName(index)
		if index > 0 then
			local name = EJ_GetTierInfo(index)
			return name
		end
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
				return tier, index, name, "raid"
			end
			if tier > 4 then -- MoP+ for challenge mode dungeons
				name, index = getInstanceName(id, tier, false)
				if name then
					return tier, index, name, "party"
				end
			end
		end
		return 0, 0, GetRealZoneText(id), "raid"
	end
else
	local mapData = {
		-- Classic Era Raids
		[48] = {isClassicEra and 1 or 0, isClassicEra and 1 or 0}, -- Blackfathom Deeps (SoD)
		[90] = {isClassicEra and 1 or 0, isClassicEra and 2 or 0}, -- Gnomeregan (SoD)
		[109] = {isClassicEra and 1 or 0, isClassicEra and 3 or 0}, -- Sunken Temple (SoD)
		[2789] = {isClassicEra and 1 or 0, isClassicEra and 4 or 0}, -- The Tainted Scar (SoD)
		[2791] = {isClassicEra and 1 or 0, isClassicEra and 5 or 0}, -- Storm Cliffs (SoD)
		[2804] = {isClassicEra and 1 or 0, isClassicEra and 6 or 0}, -- The Crystal Vale (SoD)
		[2832] = {isClassicEra and 1 or 0, isClassicEra and 7 or 0}, -- Nightmare Grove (SoD)
		[2856] = {isClassicEra and 1 or 0, isClassicEra and 8 or 0}, -- Scarlet Enclave (SoD)
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
		[558] = {2, 1, "party"},  -- Auchenai Crypts
		[543] = {2, 2, "party"},  -- Hellfire Ramparts
		[585] = {2, 3, "party"},  -- Magisters' Terrace
		[557] = {2, 4, "party"},  -- Mana-Tombs
		[560] = {2, 5, "party"},  -- Old Hillsbrad Foothills
		[556] = {2, 6, "party"},  -- Sethekk Halls
		[555] = {2, 7, "party"},  -- Shadow Labyrinth
		[552] = {2, 8, "party"},  -- The Arcatraz
		[269] = {2, 9, "party"},  -- The Black Morass
		[542] = {2, 10, "party"}, -- The Blood Furnace
		[553] = {2, 11, "party"}, -- The Botanica
		[554] = {2, 12, "party"}, -- The Mechanar
		[540] = {2, 13, "party"}, -- The Shattered Halls
		[547] = {2, 14, "party"}, -- The Slave Pens
		[545] = {2, 15, "party"}, -- The Steamvault
		[546] = {2, 16, "party"}, -- The Underbog
		-- Wrath Raids
		[624] = {3, 1},  -- Vault of Archavon
		[615] = {3, 3},  -- The Obsidian Sanctum
		[616] = {3, 4},  -- The Eye of Eternity
		[603] = {3, 5},  -- Ulduar
		[649] = {3, 6},  -- Trial of the Crusader
		[631] = {3, 8},  -- Icecrown Citadel
		[724] = {3, 9},  -- The Ruby Sanctum
		-- Wrath Dungeons
		[619] = {3, 1, "party"},  -- Ahn'kahet: The Old Kingdom
		[601] = {3, 2, "party"},  -- Azjol-Nerub
		[600] = {3, 3, "party"},  -- Drak'Tharon Keep
		[604] = {3, 4, "party"},  -- Gundrak
		[602] = {3, 5, "party"},  -- Halls of Lightning
		[668] = {3, 6, "party"},  -- Halls of Reflection
		[599] = {3, 7, "party"},  -- Halls of Stone
		[658] = {3, 8, "party"},  -- Pit of Saron
		[595] = {3, 9, "party"},  -- The Culling of Stratholme
		[632] = {3, 10, "party"}, -- The Forge of Souls
		[576] = {3, 11, "party"}, -- The Nexus
		[578] = {3, 12, "party"}, -- The Oculus
		[608] = {3, 13, "party"}, -- The Violet Hold
		[650] = {3, 14, "party"}, -- Trial of the Champion
		[574] = {3, 15, "party"}, -- Utgarde Keep
		[575] = {3, 16, "party"}, -- Utgarde Pinnacle
		-- Cata Raids
		[757] = {4, 1}, -- Baradin Hold
		[669] = {4, 2}, -- Blackwing Descent
		[967] = {4, 3}, -- Dragon Soul
		[720] = {4, 4}, -- Firelands
		[671] = {4, 5}, -- The Bastion of Twilight
		[754] = {4, 6}, -- Throne of the Four Winds
		-- Cata Dungeons
		[645] = {4, 1, "party"}, -- Blackrock Caverns
		[36] = {not isClassicEra and 4 or 0, not isClassicEra and 2 or 0, "party"}, -- The Deadmines
		[938] = {4, 3, "party"}, -- End Time
		[670] = {4, 4, "party"}, -- Grim Batol
		[644] = {4, 5, "party"}, -- Halls of Origination
		[940] = {4, 6, "party"}, -- Hour of Twilight
		[755] = {4, 7, "party"}, -- Lost City of the Tol'vir
		[33] = {not isClassicEra and 4 or 0, not isClassicEra and 8 or 0, "party"}, -- Shadowfang Keep
		[725] = {4, 9, "party"}, -- The Stonecore
		[657] = {4, 10, "party"}, -- The Vortex Pinnacle
		[643] = {4, 11, "party"}, -- Throne of the Tides
		[939] = {4, 12, "party"}, -- Well of Eternity
		[568] = {4, 13, "party"}, -- Zul'Aman
		[859] = {not isClassicEra and 4 or 0, not isClassicEra and 14 or 0, "party"}, -- Zul'Gurub

		-- EJ is available with all dungeons, but only Cata and Mists raids
		-- Mists Raids
		[1008] = {5, 1}, -- Mogu'shan Vaults
		[1009] = {5, 2}, -- Heart of Fear
		[996] = {5, 3}, -- Terrace of Endless Spring
		[1098] = {5, 4}, -- Throne of Thunder
		[1136] = {5, 5}, -- Siege of Orgrimmar
		-- Mists Dungeons
		[962] = {5, 1, "party"}, -- Gate of the Setting Sun
		[994] = {5, 2, "party"}, -- Mogu'Shan Palace
		[1001] = {not isClassicEra and 5 or 0, not isClassicEra and 3 or 0}, -- Scarlet Halls
		[1004] = {not isClassicEra and 5 or 0, not isClassicEra and 4 or 0}, -- Scarlet Monastery
		[1007] = {not isClassicEra and 5 or 0, not isClassicEra and 5 or 0}, -- Scholomance
		[959] = {5, 6, "party"}, -- Shado-pan Monastery
		[1011] = {5, 7, "party"}, -- Siege of Niuzao Temple
		[961] = {5, 8, "party"}, -- Stormstout Brewery
		[960] = {5, 9, "party"}, -- Temple of the Jade Serpent
	}

	function getTierName(tier)
		if tier > 0 and tier <= GetServerExpansionLevel() + 1 then
			return L["EXPANSION_NAME"..(tier - 1)]
		end
	end

	function getInstanceInfo(id)
		if mapData[id] then
			return mapData[id][1], mapData[id][2], GetRealZoneText(id), mapData[id][3] or "raid"
		end
		return 0, 0, GetRealZoneText(id), "raid"
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
				local tier, index, name, itype = getInstanceInfo(id)
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

				local values
				if itype == "party" then
					values = next(difficulties)
				else
					values = {}
					for diff in next, difficulties do
						values[diff] = GetDifficultyInfo(diff) or UNKNOWN_ID:format(diff)
					end
				end

				if type(values) == "table" then
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
				else
					if not options.args[tierName].args["dungeons"] then
						options.args[tierName].args["dungeons"] = {
							type = "group", inline = true,
							name = L["Dungeons"],
							get = function(info) return db.zones[info.arg][values] end,
							set = function(info, value)
								db.zones[info.arg][values] = value
								addon:CheckInstance()
							end,
							order = -1,
							args = {},
						}
					end
					options.args[tierName].args["dungeons"].args[name] = {
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
	settingsCategoryID = select(2, LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LoggerHeadLite", ADDON_TITLE))

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("LoggerHeadLite/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db))
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LoggerHeadLite/Profiles", L["Profiles"], ADDON_TITLE)

	local dataObj = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
		type = "data source",
		label = COMBAT_LOG,
		icon = LoggingCombat() and "Interface\\AddOns\\LoggerHeadLite\\enabled" or "Interface\\AddOns\\LoggerHeadLite\\disabled",
		text = LoggingCombat() and ENABLED or DISABLED,
		OnClick = function(_, button)
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
	Settings.OpenToCategory(settingsCategoryID)
end

SLASH_LOGGERHEAD1 = "/loggerhead"
SLASH_LOGGERHEAD2 = "/lh"
SlashCmdList["LOGGERHEAD"] = addon.OpenOptions
