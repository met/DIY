--[[
Copyright (c) 2020 Martin Hassman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local addonName, NS = ...;

local cYellow = "\124cFFFFFF00";
local cWhite = "\124cFFFFFFFF";
local cRed = "\124cFFFF0000";
local cLightBlue = "\124cFFadd8e6";
local cGreen1 = "\124cFF38FFBE";


-- IDs for professions
-- data from Classic db, ID are in URL eg. https://classicdb.ch/?spell=3413

NS.professions = {  -- from appretince, journeyman, expert, artisan
	["Cooking"]        = { 2550, 3102, 3413, 18260 },
	["First Aid"]      = { 3273, 3274, 7924, 10846 },
	["Fishing"]        = { 7620, 7731, 7732, 18248 },
	["Alchemy"]        = { 2259, 3101, 3464, 11611 },
	["Blacksmithing"]  = { 2018, 3100, 3538, 9785  }, 
	["Enchanting"]     = { 7411, 7412, 7413, 13920 },
	["Engineering"]    = { 4036, 4037, 4038, 12656 },
	["Herbalism"]      = {                         }, -- no icon
	["Leatherworking"] = { 2108, 3104, 3811, 10662 },
	["Mining"]         = { 2575, 2576, 3564, 10248, 2656 }, -- last is for smelting spell
	["Skinning"]       = { 8613, 8617, 8613, 10768 },
	["Tailoring"]      = { 3908, 3909, 3910, 12180 },
};

-- Colors for all skillTypes, based on Blizzard_TradeSkillUI.lua: TradeSkillTypeColor
NS.skillTypes = {};
NS.skillTypes["optimal"] = { r = 1.00, g = 0.50, b = 0.25}; -- orange
NS.skillTypes["medium"]  = { r = 1.00, g = 1.00, b = 0.00}; -- yellow
NS.skillTypes["easy"]    = { r = 0.25, g = 0.75, b = 0.25}; -- green
NS.skillTypes["trivial"] = { r = 0.50, g = 0.50, b = 0.50}; -- grey


--[[
   Grab known recipes from currently opened window of one tradeskill
   return: {
	"recipe name 1" = {
		reagents = {"reagent name1" = count, "reagent name2" = count, ... },
		skillType = "skillType"
	},
	"recipe name 2" = {...}, 
	... 
	}
--]]
function NS.getKnownTradeSkillRecipes()
	local recipes = {};

	-- iterate all lines, some are recipes some are headers
	for i = 1, GetNumTradeSkills() do
		local recipeName, skillType = GetTradeSkillInfo(i); -- https://wowwiki.fandom.com/wiki/API_GetTradeSkillInfo
		-- skillType can be "trivial", "easy", "medium", "optimal", "difficult" ..or "header"
		-- see NS.skillTypes

		local numReagents = GetTradeSkillNumReagents(i);

		if skillType ~= "header" and numReagents > 0 then

			if NS.skillTypes[skillType] == nill then
				NS.logWarning("In getKnownTradeSkillRecipes() unknown skillType: ", skillType, " in recipe: ", recipeName);
			end

			local reagents = NS.getReagentsForTradeSkill(i);

			if reagents ~= nil then
				recipes[recipeName] = { reagents = reagents, skillType = skillType };
			end
		end
	end

	return recipes;
end

--[[
   Grab known recipes from currently opened window of one craftskill
   return: {
	"recipe name 1" = {
		reagents = {"reagent name1" = count, "reagent name2" = count, ... },
		skillType = "skillType"
	},
	"recipe name 2" = {...}, 
	... 
	}
--]]
function NS.getKnownCraftRecipes()
	local recipes = {};

	for i = 1, GetNumCrafts() do -- iterate over all lines
		local recipeName, _, skillType = GetCraftInfo(i); -- https://wow.gamepedia.com/API_GetCraftInfo
		-- skillType can be "trivial", "easy", "medium", "optimal", "difficult" ..or "header", "used", "none" accoring to Blizzard_CraftUI.lua

		--print(i, GetCraftInfo(i));
		--print("Name:",recipeName,"skillType:", skillType);

		local numReagents = GetCraftNumReagents(i);

		if skillType ~= "header" and numReagents > 0 then
			if NS.skillTypes[skillType] == nill then
				NS.logWarning("In getKnownCraftRecipes() unknown skillType: ", skillType, " in recipe: ", recipeName);
			end

			local reagents = NS.getReagentsForCraft(i);

			if reagents ~= nil then
				recipes[recipeName] = { reagents = reagents, skillType = skillType };
			end
		end
	end

	return recipes;
end


-- get reagents for skill-th line from opened trade skill window
-- return {"reagent name1" = count, "reagent name2" = count, ... }
function NS.getReagentsForTradeSkill(skill)
	local recipeName = GetTradeSkillInfo(skill);
	local numReagents = GetTradeSkillNumReagents(skill);
	local recipe = {};

	for reagent = 1,numReagents do
		-- https://wowwiki.fandom.com/wiki/API_GetTradeSkillReagentInfo
		-- reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo()
		local reagentName, _, reagentCount = GetTradeSkillReagentInfo(skill, reagent);

		if reagentName == nil or reagentCount == nil or tonumber(reagentCount) == nil then
			-- sometimes data for all items are not loaded yet and GetTradeSkillReagentInfo fails
			-- we can retrieve information during some next call, now just log message
			NS.logDebug("In getReagentsForTradeSkill(). ReagentName is nil, ignoring recipe: ", recipeName);
			recipe = nil; -- if there is info about other reagents, delete it
			break;
		else
			recipe[reagentName] = tonumber(reagentCount);
		end
	end

	return recipe;
end


-- get reagents for skill-th line from opened craft window
-- return {"reagent name1" = count, "reagent name2" = count, ... }
function NS.getReagentsForCraft(skill)
	local recipeName = GetCraftInfo(skill);
	local numReagents = GetCraftNumReagents(skill);
	local reagents = {};

	for reagent = 1,numReagents do
		-- https://wowwiki.fandom.com/wiki/API_GetCraftReagentInfo
		local reagentName, _, reagentCount = GetCraftReagentInfo(skill, reagent);

		if reagentName == nil or reagentCount == nil or tonumber(reagentCount) == nil then
			-- sometimes data for all items are not loaded yet and GetTradeSkillReagentInfo fails
			-- we can retrieve information during some next call, now just log message
			NS.logDebug("In getReagentsForCraft(). ReagentName is nil, ignoring recipe: ", recipeName);
			reagents = nil; -- if there is info about other reagents, delete it
			break;
		else
			reagents[reagentName] = tonumber(reagentCount);
		end

	end

	return reagents;
end

-- check all recepies and ingredients
-- list what can player create from them now
function NS.whatCanPlayerCreateNow(knownRecipes)
	local allReagents = NS.listAllReagentNames(knownRecipes);
	local foundReagents = NS.countReagentsInBags(allReagents);
	local doableRecipes = NS.checkDoableRecipes(knownRecipes, foundReagents);

	return doableRecipes;
end


-- check all recepies and ingredients
-- list what can player create from them now, even partially craftable items
function NS.getAllWhatCanPlayerCreateNow(knownRecipes, optionalSkillFilter)

	local allReagents = NS.listAllReagentNames(knownRecipes);
	local foundReagents = NS.countReagentsInBags(allReagents);
	--local doableRecipes = NS.checkDoableRecipes(knownRecipes, foundReagents);

	-- return two lists, fullycraftable and partiallycraftable
	return NS.getFullyAndPartialyCraftableItems(knownRecipes, foundReagents, optionalSkillFilter);
end

-- get table with all reagent names from table with recipes
-- return: { "reagent1" = 0, "reagent2" = 0, ... }
function NS.listAllReagentNames(recipes)
	local reagents = {};

	for skillName,recipesList in pairs(recipes) do

		for recipe,skillInfo in pairs(recipesList) do

			for reagentName, _ in pairs(skillInfo.reagents) do
				reagents[reagentName] = 0;
			end

		end

	end

	return reagents;
end


-- check all bags for given reagents
-- arg: { "reagent1" = 0, "reagent2" = 0, ... }
-- return: { "reagent1" = count, "reagent2" = count, ... } -- contain only reagents with non-zero count
function NS.countReagentsInBags(reagents)
	local foundReagents = {};

	for bag=0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do 
			if GetContainerItemID(bag,slot)~=nil then
				local itemName = GetItemInfo(GetContainerItemID(bag,slot));
				local _, itemCount = GetContainerItemInfo(bag,slot);

				if reagents[itemName] ~= nil then
					if foundReagents[itemName] == nill then
						foundReagents[itemName] = 0;
					end

					foundReagents[itemName] = foundReagents[itemName] + tonumber(itemCount);
				end
			end 
		end
	end

	return foundReagents;
end


--[[
-- check for which recipes has player enough reagents

return: {
	["skillname1"] = {
		[0] = { recipeName = "recipe name 1", count = count, skillType = "skillType"},
		[1] = { recipeName = "recipe name 2", count = count, skillType = "skillType"},
	["skillname2"] = {...},
	... 
	}
]]--
function NS.checkDoableRecipes(recipes, reagents)
	local doable = {};

	for skillName, recipesList in pairs(recipes) do

		for recipeName,skillInfo in pairs(recipesList) do
			local howMany = 0; -- how many can create

			for reagentName, reagentCount in pairs(skillInfo.reagents) do
				if reagents[reagentName] == nil or reagents[reagentName] < reagentCount then
					howMany = 0;
					break; -- not enough of this reagent, we do not need to check any other
				end

				-- how many pieces can create? check for least available reagent
				local howManyWithThisReagent = math.floor(reagents[reagentName] / reagentCount);

				if howMany == 0 then
					howMany = howManyWithThisReagent;
				else 
					howMany = math.min(howMany, howManyWithThisReagent); -- get the lowest value
				end
			end

			if howMany > 0 then
				if doable[skillName] == nil then
					doable[skillName] = {};
				end

				table.insert(doable[skillName], { recipeName = recipeName, count = howMany, skillType = skillInfo.skillType });
			end
		end

	end

	return doable;
end


--[[
	Check if item is craftable
	return two boolean values: craftable, fullyCraftable

	For fully craftable return: true, true (we have enough reagents)
	For partially craftable return: true, false (we have some reagents but not enough)
	For noncraftable return: false, false (we have no reagents)	
--]]
function NS.isCraftable(reagentsList, reagentsAvailable)
	local reagents = {};

	-- make balance first
	for reagentName, reagentCountNeeded in pairs(reagentsList) do
		local available = 0;

		if reagentsAvailable[reagentName] ~= nil then
			available = reagentsAvailable[reagentName];
		end

		table.insert(reagents, { name = reagentName, need = reagentCountNeeded, available = available } );
	end

	
	-- now make calculations

	local someReagentMissingCompletelly = false;
	local someReagentFullyAvailable = false;
	local someReagentPartiallyAvailable = false;	

	for _,reagent in ipairs(reagents) do
		if reagent.available == 0 then
			someReagentMissingCompletelly = true;
		elseif reagent.need <= reagent.available then
			someReagentFullyAvailable = true;
		else
			someReagentPartiallyAvailable = true;
		end
	end

	if someReagentFullyAvailable == true and someReagentMissingCompletelly == false and someReagentPartiallyAvailable == false then
		return true, true; -- fully craftable
	elseif someReagentPartiallyAvailable == true or someReagentFullyAvailable == true then
		return true, false; -- partially craftable
	else
		return false, false; -- noncraftable
	end

end

-- find items for which we have some reagents but other reagents are missing
-- recipes = table with recipes and their ingredients(reagents), divided by skills (blacksmithing, mining...)
-- reagentsAvailable = list of reagents that player already has
-- return: 2 lists
function NS.getFullyAndPartialyCraftableItems(recipes, reagentsAvailable, optionalSkillFilter)
	local fullyCraftableList = {};
	local partiallyCraftableList = {};

	for skillName, recipesList in pairs(recipes) do

		if optionalSkillFilter == nil or optionalSkillFilter == skillName then -- if filter is specified, check only skillName given in filter

			for recipeName, recipeInfo in pairs(recipesList) do

				local craftable, fullyCraftable = NS.isCraftable(recipeInfo.reagents, reagentsAvailable);

				if fullyCraftable == true then
					--table.insert(fullyCraftableList, recipeName);
					table.insert(fullyCraftableList, {recipeName = recipeName, skillType = recipeInfo.skillType});
				elseif craftable == true then
					--table.insert(partiallyCraftableList, recipeName);
					table.insert(partiallyCraftableList, {recipeName = recipeName, skillType = recipeInfo.skillType});
				end
			end
		end
	end

	return fullyCraftableList, partiallyCraftableList;
end


--[[
-- check in which recepies (known to player) is itemName used
-- return { [0] = {recipeName = name1, skillType = skillType1 }, ...}
eg.: { 
	[0] = { recipeName = "Linen Bandage", skillType = "trivial"},
	[1] = { recipeName = "Heavy Linen Bandage", skillType = "optimal"},
	...
}
--]]
function NS.whereIsItemUsed(itemName, knownRecipes)
	local itemIsUsedIn = {};

	for skillName,recipesList in pairs(knownRecipes) do

		for recipe,skillInfo in pairs(recipesList) do

			for reagentName, _ in pairs(skillInfo.reagents) do
				if reagentName == itemName then
					table.insert(itemIsUsedIn, { recipeName = recipe, skillType = skillInfo.skillType });
					break; -- do not need to check other reagents for this recipe
				end
			end

		end

	end

	return itemIsUsedIn;
end


-- Identify missing reagents (return list of their names)
function NS.whichReagentsAreMissing(recipeName, knownRecipes)
	local recipe = NS.findRecipeByName(recipeName, knownRecipes);

	if recipe == nil then
		return nil; -- did not found recipe
	end

	local whatIsMissing =  {}; -- list with names of missing reagents

	local allReagents = NS.listAllReagentNames(knownRecipes);
	local haveReagents = NS.countReagentsInBags(allReagents);

	for reagentName,reagentCountNeed in pairs(recipe.reagents) do

		local reagentCountHave = haveReagents[reagentName];
		if reagentCountHave == nil then
			reagentCountHave = 0;
		end
		
		if reagentCountNeed > reagentCountHave then
			table.insert(whatIsMissing, reagentName);
		end
	end

	return whatIsMissing;
end

-- search in known recipes
function NS.findRecipeByName(recipeName, knownRecipes)
	local foundRecipe = nil;

	for skillName,recipesList in pairs(knownRecipes) do

		for recipe,recipeInfo in pairs(recipesList) do
			if recipe == recipeName then
				foundRecipe = recipeInfo;
				break;
			end
		end
	end

	return foundRecipe;
end

-- Check skillTypes from list o items and return the best found skilltype
function NS.getBestCraftableSkillType(items)
	local skillTypes = { ["trivial"] = 1, ["easy"] = 2, ["medium"] = 3, ["optimal"] = 4 };
	local bestFoundSkillType = "trivial";

	for i,item in ipairs(items) do
		if skillTypes[item.skillType] > skillTypes[bestFoundSkillType] then
			bestFoundSkillType = item.skillType;
		end
	end

	return bestFoundSkillType;
end


-- true if id belongs to some profession skill
function NS.isIdOfProfession(professionIdList, actionId)
	local found = false;

	for _,id in ipairs(professionIdList) do
		if actionId == id then
			found = true;
			break;
		end
	end

	return found;
end
