
local version = "4.1.1"

local defaults = {
	x = 0,
	y = -150,
	w = 200,
	h = 10,
	b = 2,
	a = 1,
	s = 1,
	move = "off",
	icons = 1,
	timers = 1,
	style = 0
}
local settings = {
	x = "Bar X position",
	y = "Bar Y position",
	w = "Bar width",
	h = "Bar height",
	b = "Border height",
	a = "Alpha between 0 and 1",
	s = "Bar scale",
	icons = "Show weapon icons (1 = show, 0 = hide)",
	timers = "Show weapon timers (1 = show, 0 = hide)",
	style = "Choose 1, 2, 3, 4, 5 or 6",
	move = "Enable bars movement",
}
local armorDebuffs = {
	["Interface\\Icons\\Ability_Warrior_Sunder"] = 450, 
	["Interface\\Icons\\Spell_Shadow_Unholystrength"] = 640, 
	["Interface\\Icons\\Spell_Nature_Faeriefire"] = 505, 
	["Interface\\Icons\\Ability_Warrior_Riposte"] = 2550,
	["Interface\\Icons\\Inv_Axe_12"] = 200
}
local combatStrings = {
	SPELLLOGSELFOTHER,			-- Your %s hits %s for %d.
	SPELLLOGCRITSELFOTHER,		-- Your %s crits %s for %d.
	SPELLDODGEDSELFOTHER,		-- Your %s was dodged by %s.
	SPELLPARRIEDSELFOTHER,		-- Your %s is parried by %s.
	SPELLMISSSELFOTHER,			-- Your %s missed %s.
	SPELLBLOCKEDSELFOTHER,		-- Your %s was blocked by %s.
	SPELLDEFLECTEDSELFOTHER,	-- Your %s was deflected by %s.
	SPELLEVADEDSELFOTHER,		-- Your %s was evaded by %s.
	SPELLIMMUNESELFOTHER,		-- Your %s failed. %s is immune.
	SPELLLOGABSORBSELFOTHER,	-- Your %s is absorbed by %s.
	SPELLREFLECTSELFOTHER,		-- Your %s is reflected back by %s.
	SPELLRESISTSELFOTHER		-- Your %s was resisted by %s.
}
for index in combatStrings do
	for _, pattern in {"%%s", "%%d"} do
		combatStrings[index] = gsub(combatStrings[index], pattern, "(.*)")
	end
end
--------------------------------------------------------------------------------
local weapon = nil
local offhand = nil
local combat = false
local prevWepSpeed = nil;
local prevOHSpeed = nil;
local configmod = false;
local playersName = UnitName("player");
st_timer = 0.0
st_timerOff = 0.0
--------------------------------------------------------------------------------
local loc = {};
loc["enUS"] = {
	hit = "You hit",
	crit = "You crit",
	glancing = "glancing",
	block = "blocked",
	Warrior = "Warrior",
	combatSpells = {
		HS = "Heroic Strike",
		Cleave = "Cleave",
		Slam = "Slam",
		RS = "Raptor Strike",
		Maul = "Maul"
	}
}
loc["frFR"] = {
	hit = "Vous touchez",
	crit = "Vous infligez un coup critique",
	glancing = "érafle",
	block = "bloqué",
	Warrior = "Guerrier",
	combatSpells = {
		HS = "Frappe héroïque",
		Cleave = "Enchainement",
		Slam = "Heurtoir",
		RS = "Attaque du raptor",
		Maul = "Mutiler"
	}
}
local L = loc[GetLocale()];
if (L == nil) then 
	L = loc['enUS']; 
end
--------------------------------------------------------------------------------
StaticPopupDialogs["SP_ST_Install"] = {
	text = TEXT("Thanks for installing SP_SwingTimer " ..version .. "! Use the chat command /st to change the settings."),
	button1 = TEXT(YES),
	timeout = 0,
	hideOnEscape = 1,
}
--------------------------------------------------------------------------------
function MakeMovable(frame)
    frame:SetMovable(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function() this:StartMoving() end);
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end);
end
--------------------------------------------------------------------------------
local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0.5)
end
local function SplitString(s,t)
	local l = {n=0}
	local f = function (s)
		l.n = l.n + 1
		l[l.n] = s
	end
	local p = "%s*(.-)%s*"..t.."%s*"
	s = string.gsub(s,"^%s+","")
	s = string.gsub(s,"%s+$","")
	s = string.gsub(s,p,f)
	l.n = l.n + 1
	l[l.n] = string.gsub(s,"(%s%s*)$","")
	return l
end

-- This function is realy useful
local function has_value (tab, val)
    for value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    if (tab[val] ~= nil) then
        return true
    end

    return false
end

function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

--------------------------------------------------------------------------------

local function UpdateSettings()
	if not SP_ST_GS then SP_ST_GS = {} end
	for option, value in defaults do
		if SP_ST_GS[option] == nil then
			SP_ST_GS[option] = value
		end
	end
end

--------------------------------------------------------------------------------

local function UpdateAppearance()
	SP_ST_Frame:ClearAllPoints()
	SP_ST_FrameOFF:ClearAllPoints()
	
	SP_ST_Frame:SetPoint("TOPLEFT", SP_ST_GS["x"], SP_ST_GS["y"])
	SP_ST_maintimer:SetPoint("RIGHT", "SP_ST_Frame", "RIGHT", -2, 0)
	SP_ST_maintimer:SetFont("Fonts\\FRIZQT__.TTF", SP_ST_GS["h"]-6)
	SP_ST_maintimer:SetTextColor(1,1,1,1);

	SP_ST_FrameOFF:SetPoint("TOPLEFT", "SP_ST_Frame", "BOTTOMLEFT", 0, -2);
	SP_ST_offtimer:SetPoint("RIGHT", "SP_ST_FrameOFF", "RIGHT", -2, 0)
	SP_ST_offtimer:SetFont("Fonts\\FRIZQT__.TTF", SP_ST_GS["h"]-6)
	SP_ST_offtimer:SetTextColor(1,1,1,1);

	if (SP_ST_GS["icons"] ~= 0) then
		SP_ST_mainhand:SetTexture(GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")));
		SP_ST_mainhand:SetHeight(SP_ST_GS["h"]+1);
		SP_ST_mainhand:SetWidth(SP_ST_GS["h"]+1);
		SP_ST_mainhand:SetDrawLayer("OVERLAY");
		SP_ST_offhand:SetTexture(GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")));
		SP_ST_offhand:SetHeight(SP_ST_GS["h"]+1);
		SP_ST_offhand:SetWidth(SP_ST_GS["h"]+1);
		SP_ST_offhand:SetDrawLayer("OVERLAY");
	else 
		SP_ST_mainhand:SetTexture(nil);
		SP_ST_mainhand:SetWidth(0);
		SP_ST_offhand:SetTexture(nil);
		SP_ST_offhand:SetWidth(0);
	end

	if (SP_ST_GS["timers"] ~= 0) then
		SP_ST_maintimer:Show();
		SP_ST_offtimer:Show();
	else
		SP_ST_maintimer:Hide();
		SP_ST_offtimer:Hide();
	end
	
	SP_ST_FrameTime:ClearAllPoints()
	SP_ST_FrameTime2:ClearAllPoints()

	local style = SP_ST_GS["style"]
	if style == 1 or style == 2 then
		SP_ST_mainhand:SetPoint("LEFT", "SP_ST_Frame", "LEFT");
		SP_ST_offhand:SetPoint("LEFT", "SP_ST_FrameOFF", "LEFT");
		SP_ST_FrameTime:SetPoint("LEFT", "SP_ST_mainhand", "LEFT")
		SP_ST_FrameTime2:SetPoint("LEFT", "SP_ST_FrameOFF", "LEFT")
	elseif style == 3 or style == 4 then
		SP_ST_mainhand:SetPoint("RIGHT", "SP_ST_Frame", "RIGHT");
		SP_ST_offhand:SetPoint("RIGHT", "SP_ST_FrameOFF", "RIGHT");
		SP_ST_FrameTime:SetPoint("RIGHT", "SP_ST_mainhand", "RIGHT")
		SP_ST_FrameTime2:SetPoint("RIGHT", "SP_ST_offhand", "RIGHT")
	else
		SP_ST_mainhand:SetTexture(nil);
		SP_ST_mainhand:SetWidth(0);
		SP_ST_offhand:SetTexture(nil);
		SP_ST_offhand:SetWidth(0);
		SP_ST_FrameTime:SetPoint("CENTER", "SP_ST_Frame", "CENTER")
		SP_ST_FrameTime2:SetPoint("CENTER", "SP_ST_FrameOFF", "CENTER")
	end

	SP_ST_Frame:SetWidth(SP_ST_GS["w"])
	SP_ST_Frame:SetHeight(SP_ST_GS["h"])
	SP_ST_FrameOFF:SetWidth(SP_ST_GS["w"])
	SP_ST_FrameOFF:SetHeight(SP_ST_GS["h"])

	SP_ST_FrameTime:SetWidth(SP_ST_GS["w"] - SP_ST_mainhand:GetWidth())
	SP_ST_FrameTime:SetHeight(SP_ST_GS["h"] - SP_ST_GS["b"])
	SP_ST_FrameTime2:SetWidth(SP_ST_GS["w"] - SP_ST_offhand:GetWidth())
	SP_ST_FrameTime2:SetHeight(SP_ST_GS["h"] - SP_ST_GS["b"])

	SP_ST_Frame:SetAlpha(SP_ST_GS["a"])
	SP_ST_Frame:SetScale(SP_ST_GS["s"])
	SP_ST_FrameOFF:SetAlpha(SP_ST_GS["a"])
	SP_ST_FrameOFF:SetScale(SP_ST_GS["s"])
end

local function GetWeaponSpeed(off)
	local speedMH, speedOH = UnitAttackSpeed("player")
	if (off) then 
		return speedOH; 
	else
		return speedMH;
	end
end

local function isDualWield()
	return (GetWeaponSpeed(true) ~= nil);
end

local function ShouldResetTimer(off)
	local timer = st_timer;
	if (off) then timer = st_timerOff end

	local percentTime = timer / GetWeaponSpeed(off)
	return (percentTime < 0.025)
end

local function UpdateWeapon()
	weapon = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
	if (SP_ST_GS["icons"] ~= 0) then
		SP_ST_mainhand:SetTexture(GetInventoryItemTexture("player", GetInventorySlotInfo("MainHandSlot")));
	end
	if (isDualWield()) then
		offhand = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
		if (SP_ST_GS["icons"] ~= 0) then
			SP_ST_offhand:SetTexture(GetInventoryItemTexture("player", GetInventorySlotInfo("SecondaryHandSlot")));
		end
	else SP_ST_FrameOFF:Hide();
	end
end

local function ResetTimer(off)
	prevWepSpeed = GetWeaponSpeed(false);

	if (isDualWield()) then 
		prevOHSpeed = GetWeaponSpeed(true); 
	end
	
	if (not off) then
		st_timer = GetWeaponSpeed(off)
		if (isDualWield() and st_timerOff < 0.2) then
			st_timerOff = 0.2;
		end
	else
		st_timerOff = GetWeaponSpeed(off)
		if (isDualWield() and st_timer < 0.2) then
			st_timer = 0.2;
		end
	end

	SP_ST_Frame:Show()
	if (isDualWield()) then SP_ST_FrameOFF:Show() end
	
end

local function TestShow()
	ResetTimer(false)
end

local function CheckDamageSource(dmg, dmgType)
	if (not UnitExists("target")) then return end
	if (dmg == nil) then return end
	if (not isDualWield()) then return "MAIN" end
	-- Only work for NPC as they have standard armor values
	if (not UnitIsPlayer("target")) then
		-- we will do armor check on the target here
		local basearmor = {
			[L['Warrior']] = 3791,
			['Paladin'] = 3075,
			['Mage']	= 1923,
		};
		local unitClass = UnitClass("target");
		local armor = basearmor[unitClass];
		for i=1,16 do
			debuffTexture, debuffApplications = UnitDebuff("target", i);
			if (has_value(armorDebuffs,debuffTexture)) then
				armor = armor - (armorDebuffs[debuffTexture]*debuffApplications);
			end
		end

		local tarLVL = UnitLevel("target");
		if (UnitLevel("target") == -1) then
			tarLVL = 63;
		end 

		local dmgRed = 1 - (armor/(armor+((467.5*tarLVL)-22167.5)));
		if (dmgRed < 0) then 
			dmgRed = 0 
		end

		local wpDmg = {};
		wpDmg["mainMin"], wpDmg["mainMax"], wpDmg["offMin"], wpDmg["offMax"], _, _, _ = UnitDamage("player");

		if (dmgType == "crit") then
			wpDmg["mainMin"] = wpDmg["mainMin"] * 2;
			wpDmg["mainMax"] = wpDmg["mainMax"] * 2;
			wpDmg["offMin"] = wpDmg["offMin"] * 2;
			wpDmg["offMax"] = wpDmg["offMax"] * 2;

		elseif (dmgType == "glancing")then
			local mobDef = tarLVL * 5;
			local mComp, mCompMod, oComp, oCompMod = UnitAttackBothHands("player");
			local pCompMain = mComp + mCompMod;
			local pCompOff = oComp + oCompMod;

			--Glancing values for mainhand
			local mainLOW = 1.3-(0.05*(mobDef - pCompMain));
			if (mainLOW < 0.1) then mainLOW = 0.1 end;
			if (mainLOW > 0.91) then mainLOW = 0.91 end;
			local mainHIGH = 1.2-(0.03*(mobDef - pCompMain));
			if (mainHIGH < 0.2) then mainHIGH = 0.2 end;
			if (mainHIGH > 0.99) then mainHIGH = 0.99 end;
			wpDmg["mainMin"] = wpDmg["mainMin"] * mainLOW;
			wpDmg["mainMax"] = wpDmg["mainMax"] * mainHIGH;

			--Glancing values for offhand
			local offLOW = 1.3-(0.05*(mobDef - pCompOff));
			if (offLOW < 0.1) then offLOW = 0.1 end;
			if (offLOW > 0.91) then offLOW = 0.91 end;
			local offHIGH = 1.2-(0.03*(mobDef - pCompOff));
			if (offHIGH < 0.2) then offHIGH = 0.2 end;
			if (offHIGH > 0.99) then offHIGH = 0.99 end;
			wpDmg["offMin"] = wpDmg["offMin"] * offLOW;
			wpDmg["offMax"] = wpDmg["offMax"] * offHIGH;
		end

		-- We could be a bit off, so we'll consider a 15% error margin
		if (dmg > ((wpDmg['mainMin'] * dmgRed)*0.85) and dmg < ((wpDmg['mainMax'] * dmgRed)*1.15)) then
			return "MAIN";
		elseif (dmg > ((wpDmg['offMin'] * dmgRed)*0.85) and dmg < ((wpDmg['offMax'] * dmgRed)*1.15)) then
			return "OFF";
		else 
			--print("DEBUG : "..dmgType.." "..dmg.."\nMAIN = "..(wpDmg['mainMin'] * dmgRed)*0.9.." - "..(wpDmg['mainMax'] * dmgRed)*1.1.."\nOFF = "..(wpDmg['offMin'] * dmgRed)*0.9.." - "..(wpDmg['offMax'] * dmgRed)*1.1);
			return "UNKNOWN"
		end

	end

	return "UNKNOWN";
end

local function UpdateDisplay()
	local style = SP_ST_GS["style"]
	if (st_timer <= 0) then
		if style == 2 or style == 4 or style == 6 then
			--nothing
		else
			SP_ST_FrameTime:Hide()
		end

		if (not combat and not configmod) then
			SP_ST_Frame:Hide()
		end
	else
		SP_ST_FrameTime:Show()
		local width = SP_ST_GS["w"]
		local size = (st_timer / GetWeaponSpeed(false)) * width
		if style == 2 or style == 4 or style == 6 then
			size = width - size
		end
		if (size > width) then
			size = width
			SP_ST_FrameTime:SetTexture(1, 0.8, 0.8, 1)
		else
			SP_ST_FrameTime:SetTexture(1, 1, 1, 1)
		end
		SP_ST_FrameTime:SetWidth(size)
		if (SP_ST_GS["timers"] ~= 0) then
			local showtmr = round(st_timer, 1);
			if (math.floor(showtmr) == showtmr) then
				showtmr = showtmr..".0";
			end
			SP_ST_maintimer:SetText(showtmr);
		end
	end
	if (isDualWield()) then
		if (st_timerOff <= 0) then
			if style == 2 or style == 4 or style == 6 then
				--nothing
			else
				SP_ST_FrameTime2:Hide()
			end
	
			if (not combat and not configmod) then
				SP_ST_FrameOFF:Hide()
			end
		else
			SP_ST_FrameTime2:Show()
			local width = SP_ST_GS["w"]
			local size2 = (st_timerOff / GetWeaponSpeed(true)) * width
			if style == 2 or style == 4 or style == 6 then
				size2 = width - size2
			end
			if (size2 > width) then
				size2 = width
				SP_ST_FrameTime2:SetTexture(1, 0.8, 0.8, 1)
			else
				SP_ST_FrameTime2:SetTexture(1, 1, 1, 1)
			end
			SP_ST_FrameTime2:SetWidth(size2)
			if (SP_ST_GS["timers"] ~= 0) then
				local showtmr = round(st_timerOff, 1);
				if (math.floor(showtmr) == showtmr) then
					showtmr = showtmr..".0";
				end
				SP_ST_offtimer:SetText(showtmr);
			end
		end
	end
end

--------------------------------------------------------------------------------

function SP_ST_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")
	this:RegisterEvent("PLAYER_REGEN_DISABLED")
	this:RegisterEvent("UNIT_INVENTORY_CHANGED")
	this:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
	this:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
	this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
	this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
end

function SP_ST_OnEvent()
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == "sp_swingtimer") then

			if (SP_ST_GS == nil) then
				StaticPopup_Show("SP_ST_Install")
			end
			
			if (SP_ST_GS ~= nil) then 
				for k,v in pairs(defaults) do
					if (SP_ST_GS[k] == nil) then
						SP_ST_GS[k] = defaults[k];
					end
				end
			end

			UpdateSettings()
			UpdateWeapon()
			UpdateAppearance()

			print("SP_SwingTimer " .. version .. " loaded. Options: /st")
		end

	elseif (event == "PLAYER_REGEN_ENABLED")
		or (event == "PLAYER_ENTERING_WORLD") then
		combat = false
		UpdateDisplay()

	elseif (event == "PLAYER_REGEN_DISABLED") then
		combat = true

	elseif (event == "UNIT_INVENTORY_CHANGED") then
		if (arg1 == "player") then
			local oldWep = weapon
			local oldOff = offhand

			UpdateWeapon()
			if (combat and oldWep ~= weapon) then
				ResetTimer(false)
			end
			if (combat and isDualWield() and oldOff ~= offhand) then
				ResetTimer(true)
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES") then
		if (ShouldResetTimer(false)) then
			ResetTimer(false)
		elseif (ShouldResetTimer(true) and isDualWield()) then
			ResetTimer(true)
		end

	elseif (event == "CHAT_MSG_COMBAT_SELF_HITS") then
		if (string.find(arg1, L['hit']) or string.find(arg1, L['crit']) or string.find(arg1, playersName.." hits") or string.find(arg1, playersName.." crits")) then
			local dmgtype = "hit";
			if (string.find(arg1, L['crit']) or string.find(arg1, playersName.." crits")) then
				dmgtype = "crit";
			elseif (string.find(arg1, L['glancing'])) then
				dmgtype = "glancing";
			end
			local _, _, dmg, restOfArg = string.find(arg1, "(%d+)");
			dmg = tonumber(dmg);

			if (string.find(arg1, L['block'])) then
				local p = string.find(arg1, "(.)");
				local restOfArg = string.sub(arg1, p, string.len(arg1));
				local _, _, blVal = string.find(restOfArg, "(%d+)");
				dmg = dmg + tonumber(blVal);
			end
			
			if (CheckDamageSource(dmg, dmgtype) == "MAIN" and ShouldResetTimer(false)) then
				ResetTimer(false)
			elseif (CheckDamageSource(dmg, dmgtype) == "OFF" and ShouldResetTimer(true)) then
				ResetTimer(true)
			else
				if ShouldResetTimer(false) then
					ResetTimer(false)
				elseif isDualWield() then
					ResetTimer(true)
				end
			end
		end

	elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
		for k,v in L['combatSpells'] do
			if (string.find(arg1, v)) then
				ResetTimer(false)
			end
		end

	-- Here we check at every aura gain/loss if the weaponspeed is changed, if it is we modify the timer acordingly 
	elseif (event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS") or (event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE") or (event == "CHAT_MSG_SPELL_AURA_GONE_SELF") then
		if (prevWepSpeed ~= nil) then
			local newSpeed = GetWeaponSpeed(false);
			if (prevWepSpeed ~= newSpeed) then
				local perc = st_timer / prevWepSpeed;
				st_timer = newSpeed * perc;
			end
			if (isDualWield()) then
				local newOHspeed = GetWeaponSpeed(true);
				if (prevOHSpeed ~= newOHspeed) then
					perc = st_timerOff / prevOHSpeed;
					st_timerOff = newOHspeed * perc;
				end
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES") then
		if (string.find(arg1, ".* attacks. You parry.")) then
			local minimum = GetWeaponSpeed(false) * 0.20
			if (st_timer > minimum) then
				local reduct = GetWeaponSpeed(false) * 0.40
				local newTimer = st_timer - reduct
				if (newTimer < minimum) then
					st_timer = minimum
				else
					st_timer = newTimer
				end
			end
		end
	end
end

function SP_ST_OnUpdate(delta)
	if (st_timer > 0) then
		st_timer = st_timer - delta
		if (st_timer < 0) then
			st_timer = 0
		end
	end
	if (st_timerOff > 0) then
		st_timerOff = st_timerOff - delta
		if (st_timerOff < 0) then
			st_timerOff = 0
		end
	end
	UpdateDisplay()
end

--------------------------------------------------------------------------------

SLASH_SPSWINGTIMER1 = "/st"
SLASH_SPSWINGTIMER2 = "/swingtimer"

local function ChatHandler(msg)
	local vars = SplitString(msg, " ")
	for k,v in vars do
		if v == "" then
			v = nil
		end
	end
	local cmd, arg = vars[1], vars[2]
	if cmd == "reset" then
		SP_ST_GS = nil
		UpdateSettings()
		UpdateAppearance()
		print("Reset to defaults.")
	elseif cmd == "move" then
		if (arg == "on") then
			configmod = true;
			SP_ST_Frame:Show();
			SP_ST_FrameOFF:Show();
			MakeMovable(SP_ST_Frame);
		else
			SP_ST_Frame:SetMovable(false);
			_,_,_,SP_ST_GS["x"], SP_ST_GS["y"]= SP_ST_Frame:GetPoint()
			configmod = false;
			UpdateAppearance();
		end
	elseif settings[cmd] ~= nil then
		if arg ~= nil then
			local number = tonumber(arg)
			if number then
				SP_ST_GS[cmd] = number
				UpdateAppearance()
			else
				print("Error: Invalid argument")
			end
		end
		print(format("%s %s %s (%s)",
			SLASH_SPSWINGTIMER1, cmd, SP_ST_GS[cmd], settings[cmd]))
	else
		for k, v in settings do
			print(format("%s %s %s (%s)",
				SLASH_SPSWINGTIMER1, k, SP_ST_GS[k], v))
		end
	end
	TestShow()
end

SlashCmdList["SPSWINGTIMER"] = ChatHandler
