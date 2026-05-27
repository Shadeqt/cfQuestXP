cfQuestXP = cfQuestXP or {}
local addon = cfQuestXP

addon.KEYS = {
	ENABLED = "Enabled",
}

local defaults = {
	[addon.KEYS.ENABLED] = true,
}

cfQuestXPDB = cfQuestXPDB or {}
for key, value in pairs(defaults) do
	if cfQuestXPDB[key] == nil then
		cfQuestXPDB[key] = value
	end
end
for key in pairs(cfQuestXPDB) do
	if defaults[key] == nil then
		cfQuestXPDB[key] = nil
	end
end

addon.db = cfQuestXPDB

EventUtil.ContinueOnAddOnLoaded("cfQuestXP", function()
	addon.InitSettings()
	if addon.db[addon.KEYS.ENABLED] then
		addon.EnableQuestXP()
	end
end)
