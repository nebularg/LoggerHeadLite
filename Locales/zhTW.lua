local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "zhTW")
if not L then return end

L["Enabled"] = "|cff00ff00已啟用|r"
L["Disabled"] = "|cffff0000已停用|r"
L["You have entered |cffd9d919%s|r. Enable logging for this zone?"] = "你已經進入 |cffd9d919%s|r. 你想要為此地區/副本記錄戰斗日志嗎？"
L["|cffeda55fClick|r to toggle combat logging\n|cffeda55fRight-Click|r to open the options menu"] = "點擊開啟/關閉記錄戰斗日志\n右鍵點擊打開選項菜單"

L["Enable chat logging"] = "啟用聊天紀錄"
L["Enable chat logging when the combat log is enabled."] = "無論戰斗紀錄是否啟用都啟用聊天紀錄"
L["Profiles"] = "配置文件"
L["Prompt on new zone"] = "切換地區時詢問"
L["Prompt to enable logging when entering a new raid instance."] = "切換地區時詢問是否記錄戰斗日志？"
L["Show minimap icon"] = "顯示小地圖圖標"
L["Toggle showing or hiding the minimap icon."] = "顯示或隱藏小地圖圖標."
L["You have not entered a raid instance yet! Zones will be listed after you enter them."] = true
L["Zones"] = "區域"

