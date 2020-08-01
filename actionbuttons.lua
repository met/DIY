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

-- caching NS.getAllActionButtons()
NS.actionButtonsCache = nil;

--[[
Create table that map action button ids to action button names
For all actionbuttons (even the empty ones).
ID is like order of button in the WOW interface. Come API calls need ID, some need names
Makeing this table for easy translation. 

Looks like: {1 = "ActionButton1", 2 = "ActionButton2", ... 61 = "MultibarBottomLeftButton1", 62 = "MultibarBottomLeftButton2", ...}
--]]
function NS.getAllActionButtons()
	if NS.actionButtonsCache ~= nil then -- use cache if exist
		return NS.actionButtonsCache;
	end

	local bars = { "Action", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight","MultiBarLeft"};
	local buttons = {};

	for _, bar in pairs(bars) do
		for i = 1,NUM_ACTIONBAR_BUTTONS do -- NUM_ACTIONBAR_BUTTONS=12
			local buttonName = bar.."Button"..i; 
			local button = _G[buttonName];

			if button ~= nil then
				local buttonId = tonumber(button.action);				
				buttons[buttonId] = buttonName; -- button.action is index used in GetAction* API functions;
			end
		end
	end

	NS.actionButtonsCache = buttons; -- save to cache

	return buttons;
end


NS.skillButtonsCache = nil; -- cache for NS.findSkillButtons()

-- find all buttons for skill skillName (eg. all buttons for Blacksmithing) in all actionbars, reurn list o buttonIDs
function NS.findSkillButtons(skillName, actionButtons)
	if NS.skillButtonsCache ~= nil and NS.skillButtonsCache[skillName] ~= nil then
		return NS.skillButtonsCache[skillName]; -- use cache if possible
	end

	local foundButtons = {};

	for buttonId, buttonName in pairs(actionButtons) do -- cannot use ipairs,some indexes might be missing
		local actionType, actionId, subType = GetActionInfo(buttonId);

		if NS.isIdOfProfession(NS.professions[skillName], actionId) then
			table.insert(foundButtons, buttonId);
		end
	end

	-- save to cache
	if NS.skillButtonsCache == nil then
		NS.skillButtonsCache = {};
	end
	NS.skillButtonsCache[skillName] = foundButtons;

	return foundButtons;	
end



-- thanks to https://gitlab.com/sigz/ColoredInventoryItems
local function createBorder(name, parent, r, g, b)
	local defaultWidth = 68;
	local defaultHeight = 68;

    local border = parent:CreateTexture(name .. 'MyBorder', 'OVERLAY');

    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");
    border:SetBlendMode('ADD');
    border:SetWidth(defaultWidth);
    border:SetHeight(defaultHeight);
    border:SetPoint("CENTER", parent, "CENTER", 0, 0);
    border:SetAlpha(0.9);
	border:SetVertexColor(r,g,b); -- rgb; 0-1.0, 0-1.0, 0-1.0
    border:Show();

    return border;
end

-- show border
-- if border does not exist yet, create one
local function showBorder(buttonName, r, g, b)
	if _G[buttonName].diyBorder == nil then
		local border = createBorder(buttonName.."Border", _G[buttonName], r, g, b);
		_G[buttonName].diyBorder = border;
	else
		_G[buttonName].diyBorder:SetVertexColor(r,g,b);
		_G[buttonName].diyBorder:Show(); --border exist, show it
	end
end

-- Hide our border, if exist on give button
local function hideBorder(buttonName)
	if _G[buttonName].diyBorder ~= nil then
		_G[buttonName].diyBorder:Hide(); -- Cannot delete border/texture in framexml, only hide and possibly reuse later
	end
end


-- Player changed UI, buttons positions are no longer valid, hide all created button borders
function NS.hideAllActionButtonBorders()
	local actionButtons = NS.getAllActionButtons();

	for positionId,positionName in pairs(actionButtons) do
		hideBorder(positionName);
	end
end

function NS.updateActionButtonBorders()
	local actionButtons = NS.getAllActionButtons();
	local craftableItems = NS.whatCanPlayerCreateNow(NS.data.knownRecipes);

	--cycle over all professions
	for skillName,_ in pairs(NS.professions) do
		local skillBtns = NS.findSkillButtons(skillName, actionButtons); -- get all actionbuttons for skill skillName

		if craftableItems[skillName] ~= nil then -- something can be crafted for skill skillName
			local bestSkillType = NS.getBestCraftableSkillType(craftableItems[skillName]);

			-- show border for all actionbuttons of skill skillName
			if skillBtns ~= nil then
				for _,buttonId in pairs(skillBtns) do
					local buttonName = actionButtons[buttonId];
					showBorder(buttonName, NS.skillTypes[bestSkillType].r, NS.skillTypes[bestSkillType].g, NS.skillTypes[bestSkillType].b);
				end
			end
		else
			--no doable recepies, remove old border if exist for all actionbutton of skill skillName
			if skillBtns ~= nil then
				for _,buttonId in pairs(skillBtns) do
					local buttonName = actionButtons[buttonId];
					hideBorder(buttonName);
				end			
			end
		end	
	end

	-- TODO need to react to  toolbar change 
	-- know I put border to all new buttons after toolbar change,
	-- but need also to remove border from old buttons after change, can cycle all buttons and remove border?
	-- or just remember the old ones somewhere?
end
