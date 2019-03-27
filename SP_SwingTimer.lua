
local version = "3.0.1"

local defaults = {
	x = 0,
	y = -150,
	w = 200,
	h = 10,
	b = 2,
	a = 1,
	s = 1,
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
	style = "Choose 1, 2, 3, 4, 5 or 6"
}
local combatSpells = {
	["Heroic Strike"] = 1,
	["Cleave"] = 1,
	["Slam"] = 1,
	["Raptor Strike"] = 1,
	["Maul"] = 1,
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
local combat = false
st_timer = 0.0

--------------------------------------------------------------------------------

StaticPopupDialogs["SP_ST_Install"] = {
	text = TEXT("Thanks for installing SP_SwingTimer " ..version .. "! Use the chat command /st to change the settings."),
	button1 = TEXT(YES),
	timeout = 0,
	hideOnEscape = 1,
}

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

--------------------------------------------------------------------------------

local function UpdateSettings()
	if not SP_ST_GS then SP_ST_GS = {} end
	for option, value in defaults do
		if SP_ST_GS[option] == nil then
			SP_ST_GS[option] = value
		end
	end
end
local function UpdateAppearance()
	SP_ST_Frame:ClearAllPoints()
	SP_ST_Frame:SetPoint("CENTER", "UIParent", "CENTER", SP_ST_GS["x"], SP_ST_GS["y"])

	SP_ST_FrameTime:ClearAllPoints()
	local style = SP_ST_GS["style"]
	if style == 1 or style == 2 then
		SP_ST_FrameTime:SetPoint("LEFT", "SP_ST_Frame", "LEFT")
	elseif style == 3 or style == 4 then
		SP_ST_FrameTime:SetPoint("RIGHT", "SP_ST_Frame", "RIGHT")
	else
		SP_ST_FrameTime:SetPoint("CENTER", "SP_ST_Frame", "CENTER")
	end

	SP_ST_Frame:SetWidth(SP_ST_GS["w"])
	SP_ST_Frame:SetHeight(SP_ST_GS["h"])
	SP_ST_FrameTime:SetWidth(SP_ST_GS["w"])
	SP_ST_FrameTime:SetHeight(SP_ST_GS["h"] - SP_ST_GS["b"])

	SP_ST_Frame:SetAlpha(SP_ST_GS["a"])
	SP_ST_Frame:SetScale(SP_ST_GS["s"])
end
local function GetWeaponSpeed()
	local speedMH, speedOH = UnitAttackSpeed("player")
	return speedMH
end
local function ShouldResetTimer()
	local percentTime = st_timer / GetWeaponSpeed()
	return (percentTime < 0.025)
end
local function UpdateWeapon()
	weapon = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
end
local function ResetTimer()
	st_timer = GetWeaponSpeed()
	SP_ST_Frame:Show()
end
local function TestShow()
	ResetTimer()
end
local function UpdateDisplay()
	local style = SP_ST_GS["style"]
	if (st_timer <= 0) then
		if style == 2 or style == 4 or style == 6 then
			--nothing
		else
			SP_ST_FrameTime:Hide()
		end

		if (not combat) then
			SP_ST_Frame:Hide()
		end
	else
		SP_ST_FrameTime:Show()
		local width = SP_ST_GS["w"]
		local size = (st_timer / GetWeaponSpeed()) * width
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
end

function SP_ST_OnEvent()
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == "sp_swingtimer") then

			if (SP_ST_GS == nil) then
				StaticPopup_Show("SP_ST_Install")
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
			UpdateWeapon()
			if (combat and oldWep ~= weapon) then
				ResetTimer()
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES") then
		if (ShouldResetTimer()) then
			ResetTimer()
		end

	elseif (event == "CHAT_MSG_COMBAT_SELF_HITS") then
		if (string.find(arg1, "You hit") or string.find(arg1, "You crit")) then
			if (ShouldResetTimer()) then
				ResetTimer()
			end
		end

	elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
		for _, str in combatStrings do
			local _, _, spell = strfind(arg1, str)
			if spell and combatSpells[spell] then
				ResetTimer()
				break
			end
		end

	elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES") then
		if (string.find(arg1, ".* attacks. You parry.")) then
			--[[local percentTime = st_timer / GetWeaponSpeed()
			if (percentTime > 0.2) then
				local hypTimeLeft = st_timer - GetWeaponSpeed() * 0.4
				if (hypTimeLeft <= 0.0) then
					st_timer = 0.0
					UpdateDisplay()
				else
					local hypPercentTime = hypTimeLeft / GetWeaponSpeed()
					if (hypPercentTime > 0.2) then
						st_timer = hypTimeLeft
					end
				end
			end]]
			local minimum = GetWeaponSpeed() * 0.20
			if (st_timer > minimum) then
				local reduct = GetWeaponSpeed() * 0.40
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
