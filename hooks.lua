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

local professions = {  -- from appretince, journeyman, expert, artisan
	["Cooking"]        = {2550, 3102, 3413, 18260},
	["First Aid"]      = {3273, 3274, 7924, 10846},
	["Fishing"]        = {7620, 7731, 7732, 18248},
	["Alchemy"]        = {2259, 3101, 3464, 11611},
	["Blacksmithing"]  = {2018, 3100, 3538, 9785}, 
	["Enchanting"]     = {7411, 7412, 7413, 13920},
	["Engineering"]    = {4036, 4037, 4038, 12656},
	["Herbalism"]      = {}, -- no icon
	["Leatherworking"] = {2108, 3104, 3811, 10662},
	["Mining"]         = {2575, 2576, 3564, 10248, 2656}, -- last is for smelting spell
	["Skinning"]       = {8613, 8617, 8613, 10768},
	["Tailoring"]      = {3908, 3909, 3910, 12180},
};

-- profIDs, table of pairs ["spellid"] = professionName, ["spellid"] = professionName, ...
-- ["2550"] = "Cooking", ["3102"] = "Cooking", ...
-- reverse of professions table
local profIDs = {};

-- transform professions{} into profIDs{}
local function initProffesionList()
	for k,v in pairs(professions) do
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

		--GameTooltip:AddLine("Something...");
		--GameTooltip:Show();
	end

	return;	
end


initProffesionList();

-- hook for all actionbuttons tooltips
hooksecurefunc("ActionButton_SetTooltip", hookedActionButtonTooltip);