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

local cYellow = "\124cFFFFFF00";  -- cFF + R + G + B
local cWhite = "\124cFFFFFFFF";
local cRed = "\124cFFFF0000";
local cLightBlue = "\124cFFadd8e6";
local cGreen1 = "\124cFF38FFBE";
local cGray = "\124cFF9D9D9D";



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


-- Hook tooltip for all action buttons. For skill buttons show list of creatable items by that skill
local function hookedActionButtonTooltip(self)
	local actionType, slotId, subType = GetActionInfo(self.action);
	-- actionType can be item or spell (all skill buttong are has actionType="spell")

	local verbose = IsShiftKeyDown();

	if profIDs[slotId] ~= nil then -- this tooltip is for proffesion action button
		
		local skillName = profIDs[slotId]; -- blacksmithing, cooking...


		if verbose == false then

			local craftableItems = NS.whatCanPlayerCreateNow(NS.data.knownRecipes);

			if craftableItems[profIDs[slotId]] ~= nil then -- found something craftable for this profession
				GameTooltip:AddLine(cGreen1.."Can create:");

				for i, item in ipairs(craftableItems[profIDs[slotId]]) do
					local color = NS.skillTypes[item.skillType]; -- skill color
					GameTooltip:AddDoubleLine(item.recipeName, item.count, color.r,color.g,color.b,0,1,0);
				end

				GameTooltip:Show();

			end

		else -- verbose == true, show partially craftable
			-- I am not happy with this, need to be improved somehow, too long list, not much use now

			local fullyCraftableItemsList, partiallyCraftableItemsList = NS.getAllWhatCanPlayerCreateNow(NS.data.knownRecipes, skillName);

			GameTooltip:AddLine("Partially craftable:");
			for i, item in ipairs(partiallyCraftableItemsList) do

				local missingReagentsList = NS.whichReagentsAreMissing(item.recipeName, NS.data.knownRecipes);
				local color = NS.skillTypes[item.skillType]; -- skill color

				if missingReagentsList ~= nil then
					GameTooltip:AddLine(item.recipeName..cGray.." - missing: "..table.concat(missingReagentsList, ","), color.r, color.g, color.b);
				end
			end	

			GameTooltip:Show();
		end
	end

	return;	
end

-- Hook tooltip for all items, show for which recipes they are used for
function hookedItemTooltip(tooltip)
	local itemName, itemLink = tooltip:GetItem();
	local usedInRecipes = NS.whereIsItemUsed(itemName, NS.data.knownRecipes);

	local verbose = IsShiftKeyDown();

	if usedInRecipes ~= nil and #usedInRecipes > 0 then

		tooltip:AddLine("Used in:");
		for _,recipeInfo in ipairs(usedInRecipes) do
			local color = NS.skillTypes[recipeInfo.skillType];

			if verbose == true then
				local missingReagentsList = NS.whichReagentsAreMissing(recipeInfo.recipeName, NS.data.knownRecipes);

				if missingReagentsList ~= nil then

					if #missingReagentsList == 0 then
						-- no missing reagents
						tooltip:AddLine("* "..recipeInfo.recipeName, color.r, color.g, color.b);
					else
						-- some reagent missing
						tooltip:AddLine(recipeInfo.recipeName..cGray.." - missing: "..table.concat(missingReagentsList, ","), color.r, color.g, color.b);
					end
				end
			else -- no verbose, show only list of items
				tooltip:AddLine(recipeInfo.recipeName, color.r, color.g, color.b);
			end
		end
		tooltip:Show();
	end
end


initProffesionList();

-- hook for all actionbuttons tooltips
hooksecurefunc("ActionButton_SetTooltip", hookedActionButtonTooltip);

-- hook for all items in bags tooltips
GameTooltip:HookScript("OnTooltipSetItem", hookedItemTooltip)
