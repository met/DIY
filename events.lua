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

NS.msgPrefix = cYellow.."["..addonName.."] "..cWhite;

local function setDefaultSettings(setts)
	setts.debug = false;
end

function events.ADDON_LOADED(...)
	local arg1 = select(1, ...);

	-- ADDON_LOADED event is raised for every running addon,
	-- 1st argument contains that addon name
	-- we response only for our addon call and ignore the others
	if arg1 ~= addonName then
		return;
	end

	print(NS.msgPrefix.."v"..GetAddOnMetadata(addonName, "version")..". Use "..NS.mainCmd.." for help");

	if DIYSharedData == nil then
		DIYSharedData = {};
	end

	if DIYSettings == nil then
		DIYSettings = {};
		setDefaultSettings(DIYSettings);
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

-- Window with player's trading skills has been opened, load all known recipes
function events.TRADE_SKILL_UPDATE(...)
	local skillName, curSkill, maxSkill = GetTradeSkillLine();

	if skillName ~= nil and skillName ~= "UNKNOWN" then -- sometimes data are not ready yet
		NS.data.knownRecipes[skillName] = NS.getKnownTradeSkillRecipes();
	end
end

-- Window with player's crafting skills has been opened, load all known recipes
function events.CRAFT_UPDATE(...)
	-- TODO similar like TRADE_SKILL_UPDATE

	-- https://github.com/satan666/WOW-UI-SOURCE/blob/master/AddOns/Blizzard_TrainerUI/Blizzard_TrainerUI.lua
	-- https://github.com/satan666/WOW-UI-SOURCE/blob/master/AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillUI.lua
	-- https://github.com/satan666/WOW-UI-SOURCE/blob/master/AddOns/Blizzard_CraftUI/Blizzard_CraftUI.lua
	--GetCraftDescription(index) text line, nefunguje??
	--GetCraftNumReagents(index)
	--GetCraftReagentInfo(index, reagentIndex); = name, texture-id, howmuchneed, howmuchhave
end


function events.BAG_UPDATE(...)
	--items in bag changes, calculate craftable items and adjust skill button borders
	NS.updateActionButtonBorders();
end


function events.ACTIONBAR_SLOT_CHANGED(...)
	--player changed some buttons, we need to adjust borders
	NS.skillButtonsCache = nil; -- invalidate cache for skill buttons, buttons were changed
	NS.hideAllActionButtonBorders();
	NS.updateActionButtonBorders();
end

-- Call event handlers or log error for unknow events
function frame:OnEvent(event, ...)
	if events[event] ~= nil then
		events[event](...);
	else
		NS.logError("Received unhandled event:", event, ...);
	end
end

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("TRADE_SKILL_UPDATE");
frame:RegisterEvent("CRAFT_UPDATE");
frame:RegisterEvent("BAG_UPDATE");
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");

frame:SetScript("OnEvent", frame.OnEvent);
