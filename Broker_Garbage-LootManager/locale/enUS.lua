-- enUS / enGB / default localization file
local _, BGLM = ...

BGLM.locale = {
	CreatureTypeBeast = "Beast",
	GlobalSetting = "\n|cffffff9aThis setting is global.",

	-- Chat Messages
	couldNotLootValue = "Did not loot %sx%d because it's too cheap.",
	couldNotLootCompareValue = "Did not loot %sx%d. It's cheaper than all we've got. Inventory is full!",
	couldNotLootBlacklist = "Did not loot %sx%d because it's on your Junk List.",
	couldNotLootLocked = "Could not loot %sx%d because it is locked. Please loot manually.",
	couldNotLootSpace = "Could not loot %sx%d, you don't have any space!",
	couldNotLootLM = "You are the Loot Master, please distribute %s manually.",

	errorInventoryFull = "Something was not looted because your inventory is full. Please loot manually!",

	-- Loot Manager
	LMTitle = "Loot Manager",
	LMSubTitle = "The Loot Manager can take control of your looting and inventory space.",

	GroupLooting = "Looting",
	GroupInventory = "Inventory",
	GroupNotices = "Notices",
	GroupThreshold = "Tresholds",

	LMEnableInCombatTitle = "Enable in combat",
	LMEnableInCombatTooltip = "If checked, Broker_Garbage will try to loot even if you're in combat.",

	LMAutoLootTitle = "Autoloot",
	LMAutoLootTooltip = "Use this setting or any combination of the settings below to decide how/if Broker_Garbage handles looting.",
	disableBlizzAutoLoot = "\n|cffff0000Warning:|r Please disable Blizzard's Auto Loot.",

	LMAutoLootSkinningTitle = "Skinning",
	LMAutoLootSkinningTooltip = "Check to loot if you can skin this creature.",

	LMAutoLootPickpocketTitle = "Pickpocket",
	LMAutoLootPickpocketTooltip = "Check to loot if you are a Rogue and stealthed.",

	LMAutoLootFishingTitle = "Fishing",
	LMAutoLootFishingTooltip = "Check to loot if this is fishing loot.",

	LMAutoAcceptLootTitle = "Auto-Confirm BoP",
	LMAutoAcceptLootTooltip = "Check to automatically confirm loot that is BoP.",

	LMCloseLootTitle = "Close Window",
	LMCloseLootTooltip = "Check to automatically close the loot window once no interesting items are left inside.\n|cffff0000Caution|r: This may interfere with other addons.",

	LMKeepPLOpenTitle = "Keep open when personal",
	LMKeepPLOpenTooltip = "Check this to keep the loot window open when you can't loot something relevant in case you are currently dealing with personal loot (e.g. containers from your inventory, mining nodes).",

	LMForceClearTitle = "Force Clearing Mobs",
	LMForceClearTooltip = "Check to clear mobs (even if you aren't a skinner). You may loose money with this setting!",

	lootJunkTitle = "Loot 'Junk'",
	lootJunkTooltip = "Check to loot items on your 'Junk' list like regular items.",

	lootKeepTitle = "Loot 'Keep'",
	lootKeepTooltip = "Check to always loot items on your 'Keep' list",

	LMAutoDestroyTitle = "Autodestroy",
	LMAutoDestroyTooltip = "If checked, Broker_Garbage will take actions when your inventory space is (almost) full.",

	LMAutoDestroyInstantTitle = "enforce",
	LMAutoDestroyInstantTooltip = "If checked, Broker_Garbage may delete items the moment it loots them, otherwise deletion will take place only when you find something better to loot and need space.",
	LMAutoDestroyError_NoItems = "Error! I tried to make space but there is nothing left for me to delete!",

	printDebugTitle = "Print debug output",
	printDebugTooltip = "Check to display the LootManager's debug information. Tends to spam your chat frame, you have been warned.",

	LMFreeSlotsTitle = "Minimum free slots",
	LMFreeSlotsTooltip = "Set the minimum numer of free slots for autodestroy to take action.",

	LMWarnLMTitle = "Loot Master",
	LMWarnLMTooltip = "When checked, Broker_Garbage will print a notice reminding you to assign loot.",

	LMWarnInventoryFullTitle = "Inventory Full",
	LMWarnInventoryFullTooltip = "Check to have Broker_Garbage display a chat message whenever the 'Inventory is full.' error triggers.",

	printValueTitle = "Is below treshold",
	printValueText = "Check to get a chat message whenever Broker_Garbage doesn't loot an item due to its value being less than the minimum loot value (see below).",

	printCompareValueTitle = "Is too cheap",
	printCompareValueText = "Check to get a chat message whenever Broker_Garbage doesn't loot an item because it is less valuable than all you've already got.",

	printJunkTitle = "Is on Junk List",
	printJunkText = "Check to get a chat message whenever Broker_Garbage doesn't loot an item because it is on your junk list.",

	printSpaceTitle = "Out of space",
	printSpaceText = "Check to get a chat message whenever Broker_Garbage doesn't loot an item because your bags are full and auto destroy is disabled.",

	printLockedTitle = "Is Locked",
	printLockedText = "Check to get a chat message whenever Broker_Garbage doesn't loot an item because it is locked (e.g. someone else already loots this).",

	LMItemMinValue = "Min. item value to loot",

	minLootQualityTitle = "Minimum item quality",
	minLootQualityTooltip = "The LootManager will not loot any items below this threshold.",
}
