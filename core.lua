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

-- Grab known recipes from currently opened window of one tradeskill
-- return: { "recipe name 1" = { "reagent1" = count, "reagent2" = count }, "recipe name 2" = {...}, ... }
function NS.getKnownTradeSkillRecipes()
		local recipes = {};

		-- iterate all lines, some are recipes some are headers
		for i = 1, GetNumTradeSkills() do
			local recipeName = GetTradeSkillInfo(i); -- https://wowwiki.fandom.com/wiki/API_GetTradeSkillInfo
			local numReagents = GetTradeSkillNumReagents(i);

			--print(i, recipeName, " # ", numReagents);
			if numReagents > 0 then
				local recipe = {};

				for reagent = 1,numReagents do
					--print(" # ", GetTradeSkillReagentInfo(i, reagent));
					-- https://wowwiki.fandom.com/wiki/API_GetTradeSkillReagentInfo
					-- reagentName, reagentTexture, reagentCount, playerReagentCount

					local reagentName, _, reagentCount = GetTradeSkillReagentInfo(i, reagent);
					if reagentName == nil or reagentCount == nil or tonumber(reagentCount) == nil then
						print(cRed,"ERROR reagentName is nil, ignoring this recipe");
					else
						recipe[reagentName] = tonumber(reagentCount);
					end
				end

				recipes[recipeName] = recipe;
			end
		end

		return recipes;
end

-- check all recepies and ingredients
-- list what can player create from them now
function NS.whatCanPlayerCreateNow(knownRecipes)

	local allReagents = NS.listAllReagentNames(knownRecipes);
	local foundReagents = NS.countReagentsInBags(allReagents);
	local doableRecipes = NS.checkDoableRecipes(knownRecipes, foundReagents);

	-- TODO: only for trade skill, missing craft skills (např. enchanting)
	return doableRecipes;
end

-- get table with all reagent names from table with recipes
-- return: { "reagent1" = 0, "reagent2" = 0, ... }
function NS.listAllReagentNames(recipes)
	local reagents = {};

	for skillName,recipesList in pairs(recipes) do

		for recipe,reagentsList in pairs(recipesList) do

			for reagentName, _ in pairs(reagentsList) do
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

-- check for which recipes has player enough reagents
-- return: { "skillname1" = { "recipe 1" = count, "recipe 2" = count, ... }, "skillname2" = {...}, ... }
function NS.checkDoableRecipes(recipes, reagents)
	local doable = {};

	for skillName, recipesList in pairs(recipes) do

		for recipeName,reagentsList in pairs(recipesList) do
			local howMany = 0; -- how many can create

			for reagentName, reagentCount in pairs(reagentsList) do
				if reagents[reagentName] == nil or reagents[reagentName] < reagentCount then
					-- not enough of this reagent, we do not need to check any other
					howMany = 0;
					break;
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

				--print("Can create:", recipeName, howMany);
				doable[skillName][recipeName] = howMany;
			end
		end

	end

	return doable;
end