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


local frame = CreateFrame("FRAME");
local events = {};


function events.ADDON_LOADED(...)
	if DIYSharedData == nil then
		DIYSharedData = {};
	end

	if DIYSettings == nil then
		DIYSettings = {};
	end

	if DIYData == nil then
		DIYData = {};
	end

	if DIYData.knownRecipes == nil then
		DIYData.knownRecipes = {};
	end	

	--make addon persistent data available over all addon files
	NS.sharedData = DIYSharedData;
	NS.settings = DIYSettings;
	NS.data = DIYData;
end

function frame:OnEvent(event, ...)
	local arg1 = select(1, ...);

	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			events.ADDON_LOADED(...)
		end
	elseif event == "TRADE_SKILL_UPDATE" then
		--print(cLightBlue..event);

		local skillName, curSkill, maxSkill = GetTradeSkillLine();
		if skillName ~= nil and skillName ~= "UNKNOWN" then -- sometimes data are not ready yet
			--print(skillName, curSkill, maxSkill);
			NS.data.knownRecipes[skillName] = NS.getKnownTradeSkillRecipes();
		end

	elseif event == "CRAFT_UPDATE" then
		print(cLightBlue..event);
		-- TODO similar like TRADE_SKILL_UPDATE

		-- https://github.com/satan666/WOW-UI-SOURCE/blob/master/AddOns/Blizzard_TrainerUI/Blizzard_TrainerUI.lua
		-- https://github.com/satan666/WOW-UI-SOURCE/blob/master/AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillUI.lua
		-- https://github.com/satan666/WOW-UI-SOURCE/blob/master/AddOns/Blizzard_CraftUI/Blizzard_CraftUI.lua
		--GetCraftDescription(index) text line, nefunguje??
		--GetCraftNumReagents(index)
		--GetCraftReagentInfo(index, reagentIndex); = name, texture-id, howmuchneed, howmuchhave

	elseif event == "BAG_UPDATE" then
		NS.updateActionButtonBorders();
	else
		print(cRed.."ERROR. Received unhandled event.");
		print(event, ...);
	end

end


frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("TRADE_SKILL_UPDATE");
frame:RegisterEvent("CRAFT_UPDATE");
frame:RegisterEvent("BAG_UPDATE");

frame:SetScript("OnEvent", frame.OnEvent);

