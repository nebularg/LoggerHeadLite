local ADDON_NAME, addon = ...
LibStub("AceAddon-3.0"):NewAddon(addon, ADDON_NAME, "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local defaults = {
	profile = {
		zones = {},
		prompt = true,
		chat = false,
		minimap = {
			hide = false,
		},
	}
}

local function print(msg)
	local info = ChatTypeInfo["SYSTEM"]
	DEFAULT_CHAT_FRAME:AddMessage(msg, info.r, info.g, info.b, info.id);
end

local function ShowPrompt(zone, diff)
	if not StaticPopupDialogs["LoggerHeadLiteLogConfirm"] then
		StaticPopupDialogs["LoggerHeadLiteLogConfirm"] = {
			text = L["You have entered |cffd9d919%s|r. Enable logging for this zone?"],
			button1 = ENABLE,
			button2 = DISABLE,
			sound = "levelup2",
			OnAccept = function() addon:CheckInstance(nil, true) end,
			OnCancel = function() addon:CheckInstance(nil, false) end,
			preferredIndex = STATICPOPUP_NUMDIALOGS,
		}
	end
	StaticPopup_Show("LoggerHeadLiteLogConfirm", ("%s %s"):format(diff, zone))
end

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LoggerHeadNDB", defaults, true)
end

function addon:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckInstance")
	self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", "CheckInstance")
	self:CheckInstance()
end

function addon:CheckInstance(_, override)
	local zoneName, instanceType, difficulty, difficultyName, _, _, _, areaID = GetInstanceInfo()
	if instanceType == "raid" then
		local db = self.db.profile
		if not db.zones[areaID] then
			db.zones[areaID] = {}
		end

		if override ~= nil then -- called from the prompt
			db.zones[areaID][difficulty] = override
		end

		if db.zones[areaID][difficulty] == nil then
			if db.prompt then
				ShowPrompt(zoneName, difficultyName)
				return
			else
				db.zones[areaID][difficulty] = false
			end
		end

		if db.zones[areaID][difficulty] then
			self:EnableLogging(true)
			return
		end
	end

	self:DisableLogging(true)
end

function addon:EnableLogging(auto)
	if not LoggingCombat() then
		LoggingCombat(true)
		print(COMBATLOGENABLED)
	end

	if self.db.profile.chat and not LoggingChat() then
		LoggingChat(true)
		print(CHATLOGENABLED)
	end
end

function addon:DisableLogging(auto)
	if LoggingCombat() then
		LoggingCombat(false)
		print(COMBATLOGDISABLED)
	end

	if self.db.profile.chat and LoggingChat() then
		LoggingChat(false)
		print(CHATLOGDISABLED)
	end
end

function addon:ToggleLogging()
	if LoggingCombat() then
		self:DisableLogging()
	else
		self:EnableLogging()
	end
end

SLASH_LOGTOGGLE1 = "/log"
SlashCmdList["LOGTOGGLE"] = function() addon:ToggleLogging() end
