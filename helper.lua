-- to enable debug mode, run: /run BG_GlobalDB.debug = true
-- to disable debug mode (disabled by default) run: /run BG_GlobalDB.debug = false
_, BrokerGarbage = ...

-- Addon Basics
-- ---------------------------------------------------------
-- output functions
function BrokerGarbage:Print(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cffee6622Broker_Garbage|r "..text)
end

-- prints debug messages only when debug mode is active
function BrokerGarbage:Debug(...)
  if BG_GlobalDB and BG_GlobalDB.debug then
	BrokerGarbage:Print("! "..string.join(", ", tostringall(...)))
  end
end

-- warn the player by displaying a warning message
function BrokerGarbage:Warning(text)
	if BG_GlobalDB.showWarnings and time() - lastReminder >= 5 then
		BrokerGarbage:Print("|cfff0000"..BrokerGarbage.locale.warningMessagePrefix.."!|r ", text)
		lastReminder = time()
	end
end

-- check if a given value can be found in a table
function BrokerGarbage:Find(table, value)
	for k, v in pairs(table) do
		if (v == value) then return true end
	end
	return false
end

-- joins any number of non-basic index tables together, one after the other. elements within the input-tables will get mixed, though
function BrokerGarbage:JoinTables(...)
	local result = {}
	local tab
	
	for i=1,select("#", ...) do
		tab = select(i, ...)
		if tab then
			for index, value in pairs(tab) do
				result[index] = value
			end
		end
	end
	
	return result
end

-- joins numerically indexed tables
function BrokerGarbage:JoinSimpleTables(...)
	local result = {}
	local tab, i, j
	
	for i=1,select("#", ...) do
		tab = select(i, ...)
		if tab then
			for _, value in pairs(tab) do
				tinsert(result, value)
			end
		end
	end
	
	return result
end

-- counts table entries. for numerically indexed tables, use #table
function BrokerGarbage:Count(table)
  local i = 0
  for _, _ in pairs(table) do i = i + 1 end
  return i
end

-- Saved Variables Management / API
-- ---------------------------------------------------------
function BrokerGarbage:CheckSettings()
	-- check for settings
	local first
	if not BG_GlobalDB then BG_GlobalDB = {}; first = true end
	for key, value in pairs(BrokerGarbage.defaultGlobalSettings) do
		if BG_GlobalDB[key] == nil then
			BG_GlobalDB[key] = value
		end
	end
	
	if not BG_LocalDB then 
		BG_LocalDB = {}
		if not first then first = false end
	end
	for key, value in pairs(BrokerGarbage.defaultLocalSettings) do
		if BG_LocalDB[key] == nil then
			BG_LocalDB[key] = value
		end
	end
	
	if first ~= nil then
		BrokerGarbage:CreateDefaultLists(first)
	end
	
	-- update LDB string for older versions
	if BG_GlobalDB.LDBformat == "%1$sx%2$d (%3$s)" or string.find(BG_GlobalDB.LDBformat, "%%%d%$[sd]") then
		BG_GlobalDB.LDBformat = BrokerGarbage.defaultGlobalSettings.LDBformat
		BrokerGarbage:Print(BrokerGarbage.locale.resetLDB)
	end
end

-- inserts some basic list settings
function BrokerGarbage:CreateDefaultLists(global)
	if global then
		BG_GlobalDB.include[46069] = true											-- argentum lance
		BG_GlobalDB.include["Consumable.Water.Conjured"] = true
		BG_GlobalDB.include["Consumable.Food.Edible.Basic.Conjured"] = true
		BG_GlobalDB.forceVendorPrice["Consumable.Food.Edible.Basic"] = true
		BG_GlobalDB.forceVendorPrice["Consumable.Water.Basic"] = true
		BG_GlobalDB.forceVendorPrice["Tradeskill.Mat.BySource.Vendor"] = true
	end
	
	-- tradeskills
	local tradeSkills =  { GetProfessions() }
	for i = 1, 6 do	-- we get at most 6 professions (2x primary, cooking, fishing, first aid, archeology)
		local englishSkill, isGather = BrokerGarbage:UnLocalize(tradeSkills[i])
		BrokerGarbage:Print("Found "..(englishSkill or "nil"))
		if englishSkill then
			if isGather then
				BG_LocalDB.exclude["Tradeskill.Gather." .. englishSkill] = true
				if englishSkill ~= "Herbalism" then
					BG_LocalDB.exclude["Tradeskill.Tool." .. englishSkill] = true
				end
			else
				BG_LocalDB.exclude["Tradeskill.Mat.ByProfession." .. englishSkill] = true
				BG_LocalDB.exclude["Tradeskill.Tool." .. englishSkill] = true
			end
		end
	end
	
	-- class specific
	if BrokerGarbage.playerClass == "WARRIOR" or BrokerGarbage.playerClass == "ROGUE" or BrokerGarbage.playerClass == "DEATHKNIGHT" then
		BG_LocalDB.autoSellList["Consumable.Water"] = true
	
	elseif BrokerGarbage.playerClass == "SHAMAN" then
		if not BG_LocalDB.include[17058] then BG_LocalDB.include[17058] = 20 end	-- fish oil
		if not BG_LocalDB.include[17057] then BG_LocalDB.include[17057] = 20 end	-- scales
	end
	BG_LocalDB.exclude["Misc.Reagent.Class."..string.gsub(string.lower(BrokerGarbage.playerClass), "^.", string.upper)] = true
	
	BrokerGarbage:Print(BrokerGarbage.locale.listsUpdatedPleaseCheck)
	BrokerGarbage.itemsCache = {}
	BrokerGarbage:ScanInventory()
	if BrokerGarbage.ListOptionsUpdate then
		BrokerGarbage:ListOptionsUpdate()
	end
end

-- returns options for plugin use
function BrokerGarbage:GetOption(optionName, global)
	if global == nil then
		return BG_LocalDB[optionName], BG_GlobalDB[optionName]
	elseif global == false then
		return BG_LocalDB[optionName]
	else
		return BG_GlobalDB[optionName]
	end
end

-- Helpers
-- ---------------------------------------------------------
-- returns an item's itemID
function BrokerGarbage:GetItemID(itemLink)
	if not itemLink then return end
	local itemID = string.gsub(itemLink, ".-Hitem:([0-9]*):.*", "%1")
	return tonumber(itemID)
end

-- returns original English names for non-English locales
function BrokerGarbage:UnLocalize(skillName)
	BrokerGarbage:Print("Checking "..(skillName or "nil"))
	if not skillName then return nil, nil end
	skillName = GetProfessionInfo(skillName)
	BrokerGarbage:Print("Got name "..(skillName or "nil"))
	if string.find(GetLocale(), "en") then return skillName end
	
	-- crafting skills
	local searchString = ""
	for i = 2, 12 do
		searchString = select(i, GetAuctionItemSubClasses(9))
		if string.find(skillName, searchString) then
			return BrokerGarbage.tradeSkills[i], false
		end
	end
	
	-- gathering skills
	local skill
	if skillName == GetSpellInfo(8613) then
		skill = "Skinning"
	elseif skillName == GetSpellInfo(2575) then
		skill = "Mining"
	else
		-- herbalism sucks
		searchString = select(6, GetAuctionItemSubClasses(6))
		if string.find(skillName, searchString) then
			skill = "Herbalism"
		end
	end
	
	return skill, skill and true or nil
end

-- easier syntax for LDB display strings
function BrokerGarbage:FormatString(text)
	local item
	if not BrokerGarbage.cheapestItems or not BrokerGarbage.cheapestItems[1] then
		item = { itemID = 0, count = 0, value = 0 }
	else
		item = BrokerGarbage.cheapestItems[1]
	end
	
	-- [junkvalue]
	local junkValue = 0
	for i = 0, 4 do
		junkValue = junkValue + (BrokerGarbage.toSellValue[i] or 0)
	end
	text = string.gsub(text, "%[junkvalue%]", BrokerGarbage:FormatMoney(junkValue))
	
	-- [itemname][itemcount][itemvalue]
	text = string.gsub(text, "%[itemname%]", (select(2,GetItemInfo(item.itemID)) or ""))
	text = string.gsub(text, "%[itemcount%]", item.count)
	text = string.gsub(text, "%[itemvalue%]", BrokerGarbage:FormatMoney(item.value))
	
	-- [freeslots][totalslots]
	text = string.gsub(text, "%[freeslots%]", BrokerGarbage.totalFreeSlots + BrokerGarbage.freeSpecialSlots)
	text = string.gsub(text, "%[totalslots%]", BrokerGarbage.totalBagSpace + BrokerGarbage.specialSlots)

	-- [specialfree][specialslots][specialslots][basicslots]
	text = string.gsub(text, "%[specialfree%]", BrokerGarbage.freeSpecialSlots)
	text = string.gsub(text, "%[specialslots%]", BrokerGarbage.specialSlots)
	text = string.gsub(text, "%[basicfree%]", BrokerGarbage.totalFreeSlots)
	text = string.gsub(text, "%[basicslots%]", BrokerGarbage.totalBagSpace)
	
	-- [bagspacecolor][basicbagcolor][specialbagcolor][endcolor]
	text = string.gsub(text, "%[bagspacecolor%]", 
		BrokerGarbage:Colorize(BrokerGarbage.totalFreeSlots + BrokerGarbage.freeSpecialSlots, BrokerGarbage.totalBagSpace + BrokerGarbage.specialSlots))
	text = string.gsub(text, "%[basicbagcolor%]", 
			BrokerGarbage:Colorize(BrokerGarbage.totalFreeSlots, BrokerGarbage.totalBagSpace))
	text = string.gsub(text, "%[specialbagcolor%]", 
			BrokerGarbage:Colorize(BrokerGarbage.freeSpecialSlots, BrokerGarbage.specialSlots))
	text = string.gsub(text, "%[endcolor%]", "|r")
	
	return text
end

-- returns a red-to-green color depending on the given percentage
function BrokerGarbage:Colorize(min, max)
	local color
	if not min then
		return ""
	elseif type(min) == "table" then
		color = { min.r*255, min.g*255, min.b*255}
	else
		local percentage = min/(max and max ~= 0 and max or 1)
		if percentage <= 0.5 then
			color =  {255, percentage*510, 0}
		else
			color =  {510 - percentage*510, 255, 0}
		end
	end
	
	color = string.format("|cff%02x%02x%02x", color[1], color[2], color[3])
	return color
end

function BrokerGarbage:ResetMoney(which, global)
	if not global then
		if which == "lost" then
			BG_LocalDB.moneyLostByDeleting = 0
		elseif which == "earned" then
			BG_LocalDB.moneyEarned = 0
		end
	else
		if which == "lost" then
			BG_GlobalDB.moneyLostByDeleting = 0
		elseif which == "earned" then
			BG_GlobalDB.moneyEarned = 0
		end
	end
end

-- resets statistics. global = true -> global, otherwise local
function BrokerGarbage:ResetAll(global)
	if global then
		BG_GlobalDB.moneyEarned = 0
		BG_GlobalDB.moneyLostByDeleting = 0
		BG_GlobalDB.itemsDropped = 0
		BG_GlobalDB.itemsSold = 0
	else
		BG_LocalDB.moneyEarned = 0
		BG_LocalDB.moneyLostByDeleting = 0
	end
end

function BrokerGarbage:LPTDropDown(self, level, functionHandler)
	local dataTable = BrokerGarbage.PTSets or {}
	if UIDROPDOWNMENU_MENU_VALUE and string.find(UIDROPDOWNMENU_MENU_VALUE, ".") then
		local parts = { strsplit(".", UIDROPDOWNMENU_MENU_VALUE) } or {}
		for k = 1, #parts do
			dataTable = dataTable[ parts[k] ] or {}
		end
	elseif UIDROPDOWNMENU_MENU_VALUE then
		dataTable = dataTable[ UIDROPDOWNMENU_MENU_VALUE ] or {}
	end

	-- display a heading
	if (level == 1) then		
		local info = UIDropDownMenu_CreateInfo()
		info.isTitle = true
		info.notCheckable = true
		info.text = BrokerGarbage.locale.categoriesHeading
		UIDropDownMenu_AddButton(info, level)

		-- and some warning text, in case LPT is not available
		if not BrokerGarbage.PT then
			local info = UIDropDownMenu_CreateInfo()
			info.isTitle = true
			info.notCheckable = true
			info.text = BrokerGarbage.locale.LPTNotLoaded
			UIDropDownMenu_AddButton(info, level)
		end
	end
	
	for key, value in pairs(dataTable or {}) do
		local info = UIDropDownMenu_CreateInfo()
		local prefix = ""
		if UIDROPDOWNMENU_MENU_VALUE then
			prefix = UIDROPDOWNMENU_MENU_VALUE .. "."
		end
		
		info.text = key
		info.value = prefix .. key
		info.hasArrow = type(value) == "table" and true or false
		info.func = functionHandler
		
		UIDropDownMenu_AddButton(info, level);
	end
end

function BrokerGarbage:GetProfessionSkill(skill)
	if not skill or (type(skill) ~= "number" and type(skill) ~= "string") then return end
	if type(skill) == "number" then
		skill = GetSpellInfo(skill)
	end
	
	local rank, maxRank
	local professions = { GetProfessions() }
	for _, profession in ipairs(professions) do
		local pName, _, pRank, pMaxRank = GetProfessionInfo(profession)
		if pName and pName == skill then
			rank = pRank
			maxRank = pMaxRank
			break
		end
	end
	return rank, maxRank
end

local scanTooltip = CreateFrame('GameTooltip', 'BGItemScanTooltip', UIParent, 'GameTooltipTemplate')
-- misc: either "true" to check only for the current character, or a table {container, slot} for reference
function BrokerGarbage:CanDisenchant(itemLink, misc)
	if (itemLink) then
		local _, _, quality, level, _, _, _, count, bagSlot = GetItemInfo(itemLink)

		-- stackables are not DE-able, legendary/heirlooms are not DE-able
		if quality and quality >= 2 and quality < 5 and 
			string.find(bagSlot, "INVTYPE") and not string.find(bagSlot, "BAG") 
			and (not count or count == 1) then
			
			-- can this character disenchant?
			if IsUsableSpell(BrokerGarbage.enchanting) then
				local req = 0
				
				if level <=  20 then
					req = 1
				elseif level <=  60 then
					req = 5*5*math.ceil(level/5)-100
				elseif level <=  99 then
					req = 225
				elseif level <= 120 then
					req = 275
				else
					if quality == 2 then		-- green
						if level <= 150 then
							req = 325
						elseif level <= 200 then
							req = 350
						elseif level <= 305 then
							req = 425
						else
							req = 475
						end
					elseif quality == 3 then	-- blue
						if level <= 200 then
							req = 325
						elseif level <= 325 then
							req = 450
						else
							req = 500
						end
					elseif quality == 4 then	-- purple
						if level <= 199 then
							req = 300
						elseif level <= 277 then
							req = 375
						else
							req = 500
						end
					end
				end

				local rank = BrokerGarbage:GetProfessionSkill(BrokerGarbage.enchanting)
				if rank and rank >= req then
					return true
				end
				-- if skill rank is too low, still check if we can send it
			end
			-- misc = "true" => we only care if we ourselves can DE. no twink mail etc.
			if misc and type(misc) == "boolean" then return false end
			
			-- so we can't DE, but can we send it to someone who may? i.e. is the item not soulbound?
			if not BG_GlobalDB.hasEnchanter then return false end
			if misc and type(misc) == "table" then
				return not BrokerGarbage:IsItemSoulbound(itemLink, misc.bag, misc.slot)
			else 
				return not BrokerGarbage:IsItemSoulbound(itemLink)
			end
		end
	end
	return false
end

-- returns true if the given item is soulbound
function BrokerGarbage:IsItemSoulbound(itemLink, bag, slot)
	scanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	local searchString
	
	if not (bag and slot) then
		-- check if item is BOP
		scanTooltip:SetHyperlink(itemLink)
		searchString = ITEM_BIND_ON_PICKUP
	else
		-- check if item is soulbound
		scanTooltip:SetBagItem(bag, slot)
		searchString = ITEM_SOULBOUND
	end

	local numLines = scanTooltip:NumLines()
	for i = 1, numLines do
		local leftLine = getglobal("BGItemScanTooltip".."TextLeft"..i)
		local leftLineText = leftLine:GetText()
		
		if string.find(leftLineText, searchString) then
			return true
		end
	end
	return false
end

-- gets an item's classification and saves it to the item cache
function BrokerGarbage:UpdateCache(itemID)
	if not itemID then return nil end
	local class, temp, limit
	
	local hasData, itemLink, quality, _, _, _, subClass, stackSize, invType, _, value = GetItemInfo(itemID)
	local family = GetItemFamily(itemID)
	if not hasData then
		BrokerGarbage:Debug("UpdateCache("..(itemID or "<none>")..") failed - no GetItemInfo() data available!")
		return nil
	end
	
	-- check if item is excluded by itemID
	if BG_GlobalDB.exclude[itemID] or BG_LocalDB.exclude[itemID] then
		BrokerGarbage:Debug("Item "..itemID.." is excluded via its itemID.")
		class = BrokerGarbage.EXCLUDE
	end
	
	-- check if the item is classified by its itemID
	if not class or class ~= BrokerGarbage.EXCLUDE then
		if BG_GlobalDB.include[itemID] or BG_LocalDB.include[itemID] then
			
			if BG_LocalDB.include[itemID] and type(BG_LocalDB.include[itemID]) ~= "boolean" then
				-- limited item, local rule
				BrokerGarbage:Debug("Item "..itemID.." is locally limited via its itemID.")
				class = BrokerGarbage.LIMITED
				limit = BG_LocalDB.include[itemID]
			
			elseif BG_GlobalDB.include[itemID] and type(BG_GlobalDB.include[itemID]) ~= "boolean" then
				-- limited item, global rule
				BrokerGarbage:Debug("Item "..itemID.." is globally limited via its itemID.")
				class = BrokerGarbage.LIMITED
				limit = BG_GlobalDB.include[itemID]
			
			else
				BrokerGarbage:Debug("Item "..itemID.." is included via its itemID.")
				class = BrokerGarbage.INCLUDE
			end
		
		elseif BG_GlobalDB.forceVendorPrice[itemID] then
			BrokerGarbage:Debug("Item "..itemID.." has a forced vendor price via its itemID.")
			class = BrokerGarbage.VENDOR
		
		elseif BG_GlobalDB.autoSellList[itemID] or BG_LocalDB.autoSellList[itemID] then
			BrokerGarbage:Debug("Item "..itemID.." is to be auto-sold via its itemID.")
			class = BrokerGarbage.VENDORLIST
		
		elseif quality 
			and not IsUsableSpell(BrokerGarbage.enchanting)	and BrokerGarbage:IsItemSoulbound(itemLink)
			and string.find(invType, "INVTYPE") and not string.find(invType, "BAG") 
			and not BrokerGarbage.usableByClass[BrokerGarbage.playerClass][subClass]
			and not BrokerGarbage.usableByAll[invType] then
			
			BrokerGarbage:Debug("Item "..itemID.." should be sold as we can't ever wear it.")
			class = BrokerGarbage.UNUSABLE
			
		-- check if the item is classified by its category
		elseif BrokerGarbage.PT then
			-- check if item is excluded by its category
			for setName,_ in pairs(BrokerGarbage:JoinTables(BG_GlobalDB.exclude, BG_LocalDB.exclude)) do
				if type(setName) == "string" then
					_, temp = BrokerGarbage.PT:ItemInSet(itemID, setName)
				end
				if temp then
					BrokerGarbage:Debug("Item "..itemID.." is excluded via its category.")
					class = BrokerGarbage.EXCLUDE
					break
				end
			end
			
			-- Include List
			if not class then
				for setName,_ in pairs(BrokerGarbage:JoinTables(BG_LocalDB.include, BG_GlobalDB.include)) do
					if type(setName) == "string" then
						_, temp = BrokerGarbage.PT:ItemInSet(itemID, setName)
					end
					if temp then
						BrokerGarbage:Debug("Item "..itemID.." in included via its item category.")
						class = BrokerGarbage.INCLUDE
						break
					end
				end
			end
			
			-- Sell List
			if not class then
				for setName,_ in pairs(BrokerGarbage:JoinTables(BG_GlobalDB.autoSellList, BG_LocalDB.autoSellList)) do
					if type(setName) == "string" then
						_, temp = BrokerGarbage.PT:ItemInSet(itemID, setName)
					end
					if temp then
						BrokerGarbage:Debug("Item "..itemID.." is on the sell list via its item category.")
						class = BrokerGarbage.VENDORLIST
						break
					end
				end
			end
			
			-- Force Vendor Price List
			if not class then
				for setName,_ in pairs(BG_GlobalDB.forceVendorPrice) do
					if type(setName) == "string" then
						_, temp = BrokerGarbage.PT:ItemInSet(itemID, setName)
					end
					if temp then
						BrokerGarbage:Debug("Item "..itemID.." has a forced vendor price via its item category.")
						class = BrokerGarbage.VENDOR
						break
					end
				end
			end
		end
	end
	
	local tvalue, tclass = BrokerGarbage:GetSingleItemValue(itemID)
	if not class then class = tclass end
	if not (class == BrokerGarbage.VENDOR or class == BrokerGarbage.VENDORLIST or 
		(class == BrokerGarbage.INCLUDE and BG_GlobalDB.autoSellIncludeItems)) then 
		value = tvalue
	end
	
	-- save to items cache
	if not class or not quality then
		BrokerGarbage:Debug("Error! Caching item "..itemID.." failed!")
		return
	end
	if not BrokerGarbage.itemsCache[itemID] then
		BrokerGarbage.itemsCache[itemID] = {
			classification = class,
			quality = quality,
			family = family,
			value = value or 0,
			limit = limit,
			stackSize = stackSize,
			isClam = BrokerGarbage:Find(BrokerGarbage.clams, itemID),
		}
	else
		BrokerGarbage.itemsCache[itemID].classification = class
		BrokerGarbage.itemsCache[itemID].quality = quality
		BrokerGarbage.itemsCache[itemID].family = family
		BrokerGarbage.itemsCache[itemID].value = value or 0
		BrokerGarbage.itemsCache[itemID].limit = limit
		BrokerGarbage.itemsCache[itemID].stackSize = stackSize
		BrokerGarbage.itemsCache[itemID].isClam = BrokerGarbage:Find(BrokerGarbage.clams, itemID)
	end
end

-- fetch an item from the item cache, or insert if it doesn't exist yet
function BrokerGarbage:GetCached(itemID)
	if not BrokerGarbage.itemsCache[itemID] then
		BrokerGarbage:UpdateCache(itemID)
	end
	
	return BrokerGarbage.itemsCache[itemID]
end

-- returns total bag slots and free bag slots of your whole inventory
function BrokerGarbage:GetBagSlots()
	local numSlots, freeSlots = 0, 0
	local specialSlots, specialFree = 0, 0
	local bagSlots, emptySlots, bagType
	
	for i = 0, 4 do
		bagSlots = GetContainerNumSlots(i) or 0
		emptySlots, bagType = GetContainerNumFreeSlots(i)
		
		if bagType and bagType == 0 then
			numSlots = numSlots + bagSlots
			freeSlots = freeSlots + emptySlots
		else
			specialSlots = specialSlots + bagSlots
			specialFree = specialFree + emptySlots
		end
	end
	return numSlots, freeSlots, specialSlots, specialFree
end

-- formats money int values, depending on settings
function BrokerGarbage:FormatMoney(amount, displayMode)
	if not amount then return "" end
	displayMode = displayMode or BG_GlobalDB.showMoney
	
	local signum
	if amount < 0 then 
		signum = "-"
		amount = -amount
	else 
		signum = "" 
	end
	
	local gold   = floor(amount / (100 * 100))
	local silver = math.fmod(floor(amount / 100), 100)
	local copper = math.fmod(floor(amount), 100)
	
	if displayMode == 0 then
		return format(signum.."%i.%i.%i", gold, silver,copper)

	elseif displayMode == 1 then
		return format(signum.."|cffffd700%i|r.|cffc7c7cf%.2i|r.|cffeda55f%.2i|r", gold, silver, copper)

	-- copied from Ara Broker Money
	elseif displayMode == 2 then
		if amount>9999 then
			return format(signum.."|cffeeeeee%i|r|cffffd700g|r |cffeeeeee%.2i|r|cffc7c7cfs|r |cffeeeeee%.2i|r|cffeda55fc|r", floor(amount*.0001), floor(amount*.01)%100, amount%100 )
		
		elseif amount > 99 then
			return format(signum.."|cffeeeeee%i|r|cffc7c7cfs|r |cffeeeeee%.2i|r|cffeda55fc|r", floor(amount*.01), amount%100 )
		
		else
			return format(signum.."|cffeeeeee%i|r|cffeda55fc|r", amount)
		end
	
	-- copied from Haggler
	elseif displayMode == 3 then
		gold         = gold   > 0 and gold  .."|TInterface\\MoneyFrame\\UI-GoldIcon:0|t" or ""
		silver       = silver > 0 and silver.."|TInterface\\MoneyFrame\\UI-SilverIcon:0|t" or ""
		copper       = copper > 0 and copper.."|TInterface\\MoneyFrame\\UI-CopperIcon:0|t" or ""
		-- add spaces if needed
		copper       = (silver ~= "" and copper ~= "") and " "..copper or copper
		silver       = (gold   ~= "" and silver ~= "") and " "..silver or silver
	
		return signum..gold..silver..copper
		
	elseif displayMode == 4 then		
		gold         = gold   > 0 and "|cffeeeeee"..gold  .."|r|cffffd700g|r" or ""
		silver       = silver > 0 and "|cffeeeeee"..silver.."|r|cffc7c7cfs|r" or ""
		copper       = copper > 0 and "|cffeeeeee"..copper.."|r|cffeda55fc|r" or ""
		-- add spaces if needed
		copper       = (silver ~= "" and copper ~= "") and " "..copper or copper
		silver       = (gold   ~= "" and silver ~= "") and " "..silver or silver
	
		return signum..gold..silver..copper
	end
end