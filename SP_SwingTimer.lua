
local weapon = nil
local slamTime = 1.5
local inCombat = false
st_timer = 0.0

local combatSpells = {
	["Heroic Strike"] = 1,
	["Cleave"] = 1,
	["Slam"] = 1,
	["Raptor Strike"] = 1,
}

local regions = {"SP_ST_Frame", "SP_ST_FrameTime", "SP_ST_FrameText"}

--------------------------------------------------------------------------------

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("[ST] "..msg, 1.0, 0.5, 1)
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
local function UpdateGlobal()
	if not SP_ST_GS then SP_ST_GS = {} end
	if not SP_ST_GS["x"] then SP_ST_GS["x"] = 0 end
	if not SP_ST_GS["y"] then SP_ST_GS["y"] = -150 end
	if not SP_ST_GS["w"] then SP_ST_GS["w"] = 300 end
	if not SP_ST_GS["h"] then SP_ST_GS["h"] = 15 end
	if not SP_ST_GS["a"] then SP_ST_GS["a"] = 1 end
end
local function UpdatePosition()
	SP_ST_Frame:SetPoint("CENTER", "UIParent", "CENTER", SP_ST_GS["x"], SP_ST_GS["y"])
end
local function UpdateSize()
	for _,region in ipairs(regions) do
		getglobal(region):SetWidth(SP_ST_GS["w"])
		getglobal(region):SetHeight(SP_ST_GS["h"])
	end
	UpdatePosition()
end
local function UpdateAlpha()
	for _,region in ipairs(regions) do
		getglobal(region):SetAlpha(SP_ST_GS["a"])
	end
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
local function SetBarText(msg)
	SP_ST_FrameText:SetText(msg)
end
local function UpdateDisplay()
	if (st_timer == 0) then
		SetBarText("0.0")
		SP_ST_FrameTime:Hide()

		if (not inCombat) then
			SP_ST_Frame:Hide()
		end
	else
		SP_ST_FrameTime:Show()
		local width = SP_ST_GS["w"]
		local size = (st_timer / GetWeaponSpeed()) * width
		if (size > width) then
			size = width
			SP_ST_FrameTime:SetTexture(1, 0, 0.6, 0.9)
		elseif (st_timer <= slamTime) then
			SP_ST_FrameTime:SetTexture(0, 1, 0, 0.9)
		else
			SP_ST_FrameTime:SetTexture(1, 0.6, 0, 0.8)
		end
		SP_ST_FrameTime:SetWidth(size)

		SetBarText(string.sub(st_timer, 1, 3))
	end
end

local function ChatHandler(msg)
	local vars = SplitString(msg, " ")
	for k,v in vars do
		if v == "" then
			v = nil
		end
	end

	local cmd, arg = vars[1], vars[2]

	if ((cmd == nil or cmd == "") and arg == nil) then
		Print("Chat commands: x, y, w, h, a, reset, show")
		Print("    Example: /st reset")
		Print("    Example: /st y -150")
	elseif (cmd == "x") then
		if (arg ~= nil) then
			SP_ST_GS["x"] = tonumber(arg)
			UpdatePosition()
			Print("X set: "..arg)
		else
			Print("Current x: "..SP_ST_GS["x"]..". To change x say: /st x [number]")
		end
	elseif (cmd == "y") then
		if (arg ~= nil) then
			SP_ST_GS["y"] = tonumber(arg)
			UpdatePosition()
			Print("Y set: "..arg)
		else
			Print("Current y: "..SP_ST_GS["y"]..". To change y say: /st y [number]")
		end
	elseif (cmd == "w") then
		if (arg ~= nil) then
			SP_ST_GS["w"] = tonumber(arg)
			UpdateSize()
			Print("W(idth) set: "..arg)
		else
			Print("Current w: "..SP_ST_GS["w"]..". To change w say: /st w [number]")
		end
	elseif (cmd == "h") then
		if (arg ~= nil) then
			SP_ST_GS["h"] = tonumber(arg)
			UpdateSize()
			Print("H(eight) set: "..arg)
		else
			Print("Current h: "..SP_ST_GS["h"]..". To change h say: /st h [number]")
		end
	elseif (cmd == "a") then
		if (arg ~= nil) then
			SP_ST_GS["a"] = math.max(math.min(tonumber(arg),1),0)
			UpdateAlpha()
			Print("A(lpha) set: "..SP_ST_GS["a"])
		else
			Print("Current alpha: "..SP_ST_GS["a"]..". To change a say: /st a [number]")
		end
	elseif (cmd == "reset") then
		SP_ST_GS = nil
		UpdateGlobal()
		UpdateSize()
		UpdatePosition()
		UpdateAlpha()
	elseif (cmd == "show") then
	end

	TestShow()
end

--------------------------------------------------------------------------------

StaticPopupDialogs["SP_ST_Install"] = {
	text = TEXT("Thanks for installing SP_SwingTimer 2.0! Use the chat command /st to change the settings."),
	button1 = TEXT(YES),
	timeout = 0,
	hideOnEscape = 1,
}

function SP_ST_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")
	this:RegisterEvent("PLAYER_REGEN_DISABLED")
	this:RegisterEvent("UNIT_INVENTORY_CHANGED")
	this:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
	this:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
	this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")

	SLASH_SPSWINGTIMER1 = "/st"
	SLASH_SPSWINGTIMER2 = "/swingtimer"
	SlashCmdList["SPSWINGTIMER"] = ChatHandler
end

function SP_ST_OnEvent()
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == "sp_swingtimer") then

			UpdateGlobal()
			UpdateWeapon()
			UpdateSize()
			UpdatePosition()
			UpdateAlpha()
			SP_ST_Frame:Hide()

			Print("SP_SwingTimer 2.0 loaded. Options: /st")
		end

	elseif (event == "PLAYER_REGEN_ENABLED") then
		inCombat = false
		UpdateDisplay()

	elseif (event == "PLAYER_REGEN_DISABLED") then
		inCombat = true

	elseif (event == "UNIT_INVENTORY_CHANGED") then
		if (arg1 == "player") then
			local oldWep = weapon
			UpdateWeapon()
			if (inCombat and oldWep ~= weapon) then
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
		local a,b,spell = string.find (arg1, "Your (.+) hits")
		if not spell then a,b,spell = string.find(arg1, "Your (.+) crits") end
		if not spell then a,b,spell = string.find(arg1, "Your (.+) is parried") end
		if not spell then a,b,spell = string.find(arg1, "Your (.+) was dodged") end
		if not spell then a,b,spell = string.find(arg1, "Your (.+) missed") end

		if spell and combatSpells[spell] then
			ResetTimer()
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
