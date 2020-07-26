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
	--table.foreach(self, function(k,v) print(k,v); end);

	local actionType, slotId, subType = GetActionInfo(self.action);
	-- actionType can be item or spell (all skill buttong are has actionType="spell")
	-- print("slotId=",slotId," actionType=",actionType," subType=",subType);

	if profIDs[slotId] ~= nil then
		-- tooltip is for proffesion button

		local creatableItems = NS.whatCanPlayerCreateNow(NS.data.knownRecipes);

		if creatableItems[profIDs[slotId]] ~= nil then
			GameTooltip:AddLine(cGreen1.."Can create:");

			for itemName, itemCount in pairs(creatableItems[profIDs[slotId]]) do
				GameTooltip:AddDoubleLine(itemName, itemCount, 1,1,0,0,1,0);
			end

			GameTooltip:Show();

		end

	end

	return;	
end

function hookedItemTooltip(tooltip)
	local itemName, itemLink = tooltip:GetItem();
	local usedInRecipes = NS.whereIsItemUsed(NS.data.knownRecipes, itemName);
	if usedInRecipes ~= nil and #usedInRecipes > 0 then
		tooltip:AddLine("Used in:");
		for recipeName,v in ipairs(usedInRecipes) do
			tooltip:AddLine(cWhite..v);
		end
		tooltip:Show();
	end
end


initProffesionList();

-- hook for all actionbuttons tooltips
hooksecurefunc("ActionButton_SetTooltip", hookedActionButtonTooltip);

-- hook for all items in bags tooltips
GameTooltip:HookScript("OnTooltipSetItem", hookedItemTooltip)
