local ADDON_NAME, addon = ...
LibStub("AceAddon-3.0"):NewAddon(addon, ADDON_NAME, "AceEvent-3.0", "AceTimer-3.0")

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

local function sysprint(msg)
	local info = ChatTypeInfo["SYSTEM"]
	DEFAULT_CHAT_FRAME:AddMessage(msg, info.r, info.g, info.b, info.id)
end

local function ShowPrompt(zone, diff)
	if not StaticPopupDialogs["LoggerHeadLiteLogConfirm"] then
		StaticPopupDialogs["LoggerHeadLiteLogConfirm"] = {
			text = L["You have entered |cffd9d919%s|r. Enable logging for this zone?"],
			button1 = ENABLE,
			button2 = DISABLE,
			sound = SOUNDKIT.READY_CHECK,
			OnAccept = function() addon:CheckInstance(true) end,
			OnCancel = function() addon:CheckInstance(false) end,
			preferredIndex = STATICPOPUP_NUMDIALOGS,
		}
	end
	StaticPopup_Show("LoggerHeadLiteLogConfirm", ("%s %s"):format(diff, zone))
end

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LoggerHeadNDB", defaults, true)
end

function addon:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", "PLAYER_ENTERING_WORLD")
	self:CheckInstance()
end

function addon:PLAYER_ENTERING_WORLD()
	self:CheckInstance()
end

local checkAttempt = 0
function addon:CheckInstance(override)
	local zoneName, instanceType, difficulty, difficultyName, _, _, _, areaID = GetInstanceInfo()
	if difficulty == 0 and (instanceType == "raid" or instanceType == "party") then
		-- this shouldn't really be needed, but oh well
		if checkAttempt < 15 then
			checkAttempt = checkAttempt + 1
			self:ScheduleTimer("CheckInstance", 0.2)
		end
		return
	end
	checkAttempt = 0
	if instanceType == "raid" or difficulty == 8 then -- raid or challenge mode
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
				if difficulty == 8 then -- catch the m+ start event
					LoggingCombat(true)
				end
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
		sysprint(COMBATLOGENABLED)
	end

	if self.db.profile.chat and not LoggingChat() then
		LoggingChat(true)
		sysprint(CHATLOGENABLED)
	end
end

function addon:DisableLogging(auto)
	if LoggingCombat() then
		LoggingCombat(false)
		sysprint(COMBATLOGDISABLED)
	end

	if self.db.profile.chat and LoggingChat() then
		LoggingChat(false)
		sysprint(CHATLOGDISABLED)
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
