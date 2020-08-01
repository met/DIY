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



-- profIDs, table of pairs ["spellid"] = professionName, ["spellid"] = professionName, ...
-- ["2550"] = "Cooking", ["3102"] = "Cooking", ...
-- reverse of NS.professions table
local profIDs = {};

-- transform professions{} into profIDs{}
local function initProffesionList()
	for k,v in pairs(NS.professions) do
		for k1,v1 in ipairs(v) do
			profIDs[v1] = k;
		end
	end
	--table.foreach(profIDs, print);
end


local function hookedActionButtonTooltip(self)
	local actionType, slotId, subType = GetActionInfo(self.action);
	-- actionType can be item or spell (all skill buttong are has actionType="spell")
	-- print("slotId=",slotId," actionType=",actionType," subType=",subType);

	if profIDs[slotId] ~= nil then -- this tooltip is for proffesion action button
		
		local craftableItems = NS.whatCanPlayerCreateNow(NS.data.knownRecipes);

		if craftableItems[profIDs[slotId]] ~= nil then -- found something craftable for this profession
			GameTooltip:AddLine(cGreen1.."Can create:");

			for i, item in ipairs(craftableItems[profIDs[slotId]]) do
				local color = NS.skillTypes[item.skillType]; -- skill color
				GameTooltip:AddDoubleLine(item.recipeName, item.count, color.r,color.g,color.b,0,1,0);
			end

			GameTooltip:Show();

		end

	end

	return;	
end

function hookedItemTooltip(tooltip)
	local itemName, itemLink = tooltip:GetItem();
	local usedInRecipes = NS.whereIsItemUsed(itemName, NS.data.knownRecipes);

	if usedInRecipes ~= nil and #usedInRecipes > 0 then

		tooltip:AddLine("Used in:");
		for _,recipeInfo in ipairs(usedInRecipes) do
			local color = NS.skillTypes[recipeInfo.skillType];
			tooltip:AddLine(recipeInfo.recipeName, color.r, color.g, color.b);
		end
		tooltip:Show();
	end

	--TODO with shift can show more information (e.g. which recepies are craftable, amount, and for noncraftable which other reagents are missing)
	-- need to go though all bags NS.countReagentsInBags() (and cache, that is invalidated by BAG UPDATE event) and make invertoty of reagents, then go through all recipes and mark which are craftable, which are partly craftable (and what is missing) (also cache this)
end


initProffesionList();

-- hook for all actionbuttons tooltips
hooksecurefunc("ActionButton_SetTooltip", hookedActionButtonTooltip);

-- hook for all items in bags tooltips
GameTooltip:HookScript("OnTooltipSetItem", hookedItemTooltip)
