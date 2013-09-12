local ADDON_NAME, addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "zhCN")
if not L then return end

L["Enabled"] = "|cff00ff00开启|r"
L["Disabled"] = "|cffff0000关闭|r"
L["You have entered |cffd9d919%s|r. Enable logging for this zone?"] = "你已经进入 |cffd9d919%s|r. 你想要为此地区/副本记录战斗日志吗？"
L["|cffeda55fClick|r to toggle combat logging\n|cffeda55fRight-Click|r to open the options menu"] = "点击开启/关闭记录战斗日志\n右键点击打开选项菜单"

L["Enable chat logging"] = "启用聊天纪录"
L["Enable chat logging when the combat log is enabled."] = "无论战斗纪录是否启用都启用聊天纪录"
L["Profiles"] = "配置文件"
L["Prompt on new zone"] = "切换地区时询问"
L["Prompt to enable logging when entering a new raid instance."] = "切换地区时询问是否记录战斗日志？"
L["Show minimap icon"] = "显示小地图图标"
L["Toggle showing or hiding the minimap icon."] = "显示或隐藏小地图图标."
L["You have not entered a raid instance yet! Zones will be listed after you enter them."] = true
L["Zones"] = "区域"

