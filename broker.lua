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

local dataobj;

local cYellow = "\124cFFFFFF00";
local cWhite = "\124cFFFFFFFF";
local cRed = "\124cFFFF0000";
local cLightBlue = "\124cFFadd8e6";
local cGreen1 = "\124cFF38FFBE";

-- updateBrokerText: must work correctly even when there is no broker library loaded
function NS.updateBrokerText(text)
	if dataobj == nil then
		return;
	end

	dataobj.text = text;
end

if LibStub == nil then
	print(addonName, "ERROR: LibStub not found.");
	return;
end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true);
if ldb == nil then
	print(addonName, "ERROR: LibDataBroker not found.");
	return;
end

-- LibDataBroker documentation: https://github.com/tekkub/libdatabroker-1-1/wiki/How-to-provide-a-dataobject
-- List of WOW UI icons: https://github.com/Gethe/wow-ui-textures/tree/live/ICONS

dataobj = ldb:NewDataObject(addonName, {
	type = "data source",
	text = "",
	icon = "Interface\\Icons\\Trade_Engineering",
});


function dataobj:OnTooltipShow()
	self:AddLine(addonName.." v"..GetAddOnMetadata(addonName, "version"));
	self:AddLine(cWhite.."Craftable:");
	self:AddLine(" ");

	local verbose = IsShiftKeyDown();

	if verbose == false then

		local creatableItems = NS.whatCanPlayerCreateNow(NS.data.knownRecipes);

		for skillName, creatableItemsList in pairs(creatableItems) do
			self:AddLine(cGreen1..skillName);

			for i, item in pairs(creatableItemsList) do
				local color = NS.skillTypes[item.skillType];
				self:AddDoubleLine(item.recipeName, item.count, color.r,color.g,color.b,0,1,0);
			end

			self:AddLine(" ");
		end

	else

		-- TODO not good, is really too long
		local fullyCraftableItemsList, partiallyCraftableItemsList = NS.getAllWhatCanPlayerCreateNow(NS.data.knownRecipes);

		self:AddLine("Craftable:");

		for i, item in ipairs(fullyCraftableItemsList) do
			self:AddLine(item);
		end

		self:AddLine("Partially craftable:");
		for i, item in ipairs(partiallyCraftableItemsList) do
			self:AddLine(item);
		end		
	end

end