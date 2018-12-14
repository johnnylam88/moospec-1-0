--[[--------------------------------------------------------------------
    Copyright (C) 2018 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- GLOBALS: assert
-- GLOBALS: LibStub

local MAJOR, MINOR = "MooSpec-1.0", 8
assert(LibStub, MAJOR .. " requires LibStub")
assert(LibStub("CallbackHandler-1.0", true), MAJOR .. " requires CallbackHandler-1.0")
assert(LibStub("MooInspect-1.0", true), MAJOR .. " requires MooInspect-1.0")
assert(LibStub("MooUnit-1.0", true), MAJOR .. " requires MooUnit-1.0")
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

------------------------------------------------------------------------

local format = string.format
local next = next
local pairs = pairs
local setmetatable = setmetatable
local strfind = string.find
local strjoin = strjoin
local strmatch = string.match
local tonumber = tonumber
local tostring = tostring
local tostringall = tostringall
local type = type
local wipe = wipe
-- GLOBALS: _G
-- GLOBALS: GetAddOnMetadata
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local GREEN_FONT_COLOR_CODE = GREEN_FONT_COLOR_CODE
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE

local MooInspect = LibStub("MooInspect-1.0")
local MooUnit = LibStub("MooUnit-1.0")

--[[--------------------------------------------------------------------
    Debugging code from LibResInfo-1.0 by Phanx.
    https://github.com/Phanx/LibResInfo
--]]--------------------------------------------------------------------

local isAddon = GetAddOnMetadata(MAJOR, "Version")

local DEBUG_LEVEL = isAddon and 2 or 0
local DEBUG_FRAME = ChatFrame3

local function debug(level, text, ...)
	if level <= DEBUG_LEVEL then
		if ... then
			if type(text) == "string" and strfind(text, "%%[dfqsx%d%.]") then
				text = format(text, ...)
			else
				text = strjoin(" ", tostringall(text, ...))
			end
		else
			text = tostring(text)
		end
		DEBUG_FRAME:AddMessage(GREEN_FONT_COLOR_CODE .. MAJOR .. FONT_COLOR_CODE_CLOSE .. " " .. text)
	end
end

if isAddon then
	-- GLOBALS: SLASH_MOOSPEC1
	-- GLOBALS: SlashCmdList
	SLASH_MOOSPEC1 = "/moospec"
	SlashCmdList.MOOSPEC = function(input)
		input = tostring(input or "")

		local CURRENT_CHAT_FRAME
		for i = 1, 10 do
			local cf = _G["ChatFrame"..i]
			if cf and cf:IsVisible() then
				CURRENT_CHAT_FRAME = cf
				break
			end
		end

		local of = DEBUG_FRAME
		DEBUG_FRAME = CURRENT_CHAT_FRAME

		if strmatch(input, "^%s*[0-9]%s*$") then
			local v = tonumber(input)
			debug(0, "Debug level set to", input)
			DEBUG_LEVEL = v
			DEBUG_FRAME = of
			return
		end

		local f = _G[input]
		if type(f) == "table" and type(f.AddMessage) == "function" then
			debug(0, "Debug frame set to", input)
			DEBUG_FRAME = f
			return
		end

		debug(0, "Version " .. MINOR .. " loaded. Usage:")
		debug(0, format("%s%s %s%s - change debug verbosity, valid range is 0-6",
			NORMAL_FONT_COLOR_CODE, SLASH_MOOSPEC1, DEBUG_LEVEL, FONT_COLOR_CODE_CLOSE))
		debug(0, format("%s%s %s%s -- change debug output frame",
			NORMAL_FONT_COLOR_CODE, SLASH_MOOSPEC1, of:GetName(), FONT_COLOR_CODE_CLOSE))

		DEBUG_FRAME = of
	end
end

------------------------------------------------------------------------

lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)
lib.callbacksInUse = lib.callbacksInUse or {}

local eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame = eventFrame
eventFrame:UnregisterAllEvents()

local function OnEvent(frame, event, ...)
	return frame[event] and frame[event](frame, event, ...)
end

eventFrame:SetScript("OnEvent", OnEvent)

function lib.callbacks:OnUsed(lib, callback)
	if not next(lib.callbacksInUse) then
		debug(1, "Callbacks in use! Starting up...")
		eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")
		MooInspect.RegisterCallback(eventFrame, "MooInspect_InspectReady", "OnInspectReady")
		MooUnit.RegisterCallback(eventFrame, "MooUnit_UnitChanged", "OnUnitChanged")
		MooUnit.RegisterCallback(eventFrame, "MooUnit_UnitJoined", "OnUnitJoined")
		MooUnit.RegisterCallback(eventFrame, "MooUnit_UnitLeft", "OnUnitLeft")
	end
	lib.callbacksInUse[callback] = true
end

function lib.callbacks:OnUnused(lib, callback)
	lib.callbacksInUse[callback] = nil
	if not next(lib.callbacksInUse) then
		debug(1, "No callbacks in use. Shutting down...")
		eventFrame:UnregisterAllEvents()
		MooInspect.UnregisterCallback(eventFrame, "MooInspect_InspectReady")
		MooUnit.UnregisterCallback(eventFrame, "MooUnit_UnitChanged")
		MooUnit.UnregisterCallback(eventFrame, "MooUnit_UnitJoined")
		MooUnit.UnregisterCallback(eventFrame, "MooUnit_UnitLeft")
	end
end

------------------------------------------------------------------------

-- GLOBALS: GetInspectSpecialization
-- GLOBALS: GetSpecialization
-- GLOBALS: GetSpecializationInfo
-- GLOBALS: UnitClass
-- GLOBALS: UnitGroupRolesAssigned
-- GLOBALS: UnitGUID
-- GLOBALS: UnitIsPlayer

-- Preserve mappings across library upgrades.
local blizzardRoleByGUID = lib.blizzardRoleByGUID or {}
local classByGUID = lib.classByGUID or {}
local roleByGUID = lib.roleByGUID or {}
local specializationByGUID = lib.specializationByGUID or {}

lib.blizzardRoleByGUID = blizzardRoleByGUID
lib.classByGUID = classByGUID
lib.roleByGUID = roleByGUID
lib.specializationByGUID = specializationByGUID

local playerGUID = UnitGUID("player")

-- Default roles for each class.
local roleByClass = {
	DEATHKNIGHT = "melee",
	DEMONHUNTER = "melee",
	DRUID = "ranged",
	HUNTER = "ranged",
	MAGE = "ranged",
	MONK = "melee",
	PALADIN = "melee",
	PRIEST = "ranged",
	ROGUE = "melee",
	SHAMAN = "ranged",
	WARLOCK = "ranged",
	WARRIOR = "melee",
}

-- Map return values from GetInspectSpecialization() to roles.
-- ref: https://www.wowpedia.org/API_GetInspectSpecialization
local roleBySpecialization = {
	-- Death Knight
	[250] = "tank", -- Blood
	[251] = "melee", -- Frost
	[252] = "melee", -- Unholy
	-- Demon Hunter
	[577] = "melee", -- Havoc
	[581] = "tank", -- Vengeance
	-- Druid
	[102] = "ranged", -- Balance
	[103] = "melee", -- Feral
	[104] = "tank", -- Guardian
	[105] = "healer", -- Restoration
	-- Hunter
	[253] = "ranged", -- Beast Mastery
	[254] = "ranged", -- Marksmanship
	[255] = "melee", -- Survival
	-- Mage
	[62] = "ranged", -- Arcane
	[63] = "ranged", -- Fire
	[64] = "ranged", -- Frost
	-- Monk
	[268] = "tank", -- Brewmaster
	[270] = "healer", -- Mistweaver
	[269] = "melee", -- Windwalker
	-- Paladin
	[65] = "healer", -- "Holy
	[66] = "tank", -- "Protection
	[70] = "melee", -- "Retribution
	-- Priest
	[256] = "healer", -- Discipline
	[257] = "healer", -- Holy
	[258] = "ranged", -- Shadow
	-- Rogue
	[259] = "melee", -- Assassination
	[260] = "melee", -- Outlaw
	[261] = "melee", -- Subtlety
	-- Shaman
	[262] = "ranged", -- Elemental
	[263] = "melee", -- Enhancement
	[264] = "healer", -- Restoration
	-- Warlock
	[265] = "ranged", -- Affliction
	[266] = "ranged", -- Demonology
	[267] = "ranged", -- Destruction
	-- Warrior
	[71] = "melee", -- Arms
	[72] = "melee", -- Fury
	[73] = "tank", -- Protection
}

-- Map return values from GetInspectSpecialization() to names.
local specializationName = {
	-- Death Knight
	[250] = "blood",
	[251] = "frost",
	[252] = "unholy",
	-- Demon Hunter
	[577] = "havoc",
	[581] = "vengeance",
	-- Druid
	[102] = "balance",
	[103] = "feral",
	[104] = "guardian",
	[105] = "restoration",
	-- Hunter
	[253] = "beast_mastery",
	[254] = "marksmanship",
	[255] = "survival",
	-- Mage
	[62] = "arcane",
	[63] = "fire",
	[64] = "frost",
	-- Monk
	[268] = "brewmaster",
	[270] = "mistweaver",
	[269] = "windwalker",
	-- Paladin
	[65] = "holy",
	[66] = "protection",
	[70] = "retribution",
	-- Priest
	[256] = "discipline",
	[257] = "holy",
	[258] = "shadow",
	-- Rogue
	[259] = "assassination",
	[260] = "outlaw",
	[261] = "subtlety",
	-- Shaman
	[262] = "elemental",
	[263] = "enhancement",
	[264] = "restoration",
	-- Warlock
	[265] = "affliction",
	[266] = "demonology",
	[267] = "destruction",
	-- Warrior
	[71] = "arms",
	[72] = "fury",
	[73] = "protection",
}

local blizzardRoleByRole = {
	tank = "TANK",
	healer = "HEALER",
	melee = "DAMAGER",
	ranged = "DAMAGER",
	none = "NONE",
}

local function UpdateBlizzardRole(guid, unit, role)
	local oldRole = blizzardRoleByGUID[guid] or "NONE"
	if oldRole ~= role then
		blizzardRoleByGUID[guid] = role
		debug(2, "MooSpec_UnitBlizzardRoleChanged", guid, unit, oldRole, role)
		lib.callbacks:Fire("MooSpec_UnitBlizzardRoleChanged", guid, unit, oldRole, role)
	end
end

local function UpdateRole(guid, unit, role)
	local oldRole = roleByGUID[guid] or "none"
	if role and role ~= "none" then
		-- Only update the role if it's not "none".
		if oldRole ~= role then
			roleByGUID[guid] = role
			debug(2, "MooSpec_UnitRoleChanged", guid, unit, oldRole, role)
			lib.callbacks:Fire("MooSpec_UnitRoleChanged", guid, unit, oldRole, role)
		end
	end
end

local function UpdateSpecialization(guid, unit, specialization)
	local oldSpecialization = specializationByGUID[guid] or 0 -- zero seems to mean "can't get specialization"
	if specialization and roleBySpecialization[specialization] then
		-- Only update the specialization if it can be validated as a possible specialization ID.
		if oldSpecialization ~= specialization then
			specializationByGUID[guid] = specialization
			debug(2, "MooSpec_UnitSpecializationChanged", guid, unit, oldSpecialization, specialization)
			lib.callbacks:Fire("MooSpec_UnitSpecializationChanged", guid, unit, oldSpecialization, specialization)
		end
	end
end

local function UpdateClass(guid, unit)
	-- Only update class if it hasn't been determined yet.
	if not classByGUID[guid] then
		unit = unit or MooUnit:GetUnitByGUID(guid)
		if unit then
			local _, class = UnitClass(unit)
			if class then
				classByGUID[guid] = class
				-- Set a default role if this unit had no previous role.
				if not roleByGUID[guid] then
					local role = roleByClass[class]
					UpdateRole(guid, unit, role)
				end
				debug(2, "MooSpec_UnitClass", guid, unit, class)
				lib.callbacks:Fire("MooSpec_UnitClass", guid, unit, class)
			end
		end
	end
end

local function UpdateUnit(guid, unit)
	unit = unit or MooUnit:GetUnitByGUID(guid)
	if unit then
		local specialization
		if guid == playerGUID then
			-- The player's specialization information doesn't need to come through the
			-- inspection API -- use GetSpecialization() directly.
			local index = GetSpecialization()
			if index then
				specialization = GetSpecializationInfo(index)
			end
		elseif UnitIsPlayer(unit) then
			specialization = GetInspectSpecialization(unit)
		end
		if specialization then
			debug(3, "UpdateUnit", guid, unit)
			-- Validate the return value against the table of possible specialization IDs.
			if roleBySpecialization[specialization] then
				UpdateSpecialization(guid, unit, specialization)
				local role = roleBySpecialization[specialization]
				UpdateRole(guid, unit, role)
				local blizzardRole = lib:GetBlizzardRole(guid)
				UpdateBlizzardRole(guid, unit, blizzardRole)
			else
				local class = lib:GetClass(guid)
				debug(1, "Unknown player specialization:", guid, class, specialization)
			end
		end
	else
		-- GUID no longer maps to a usable unit ID.
		eventFrame:OnUnitLeft("UpdateUnit", guid)
	end
end

function lib:GetClass(guid)
	UpdateClass(guid)
	return classByGUID[guid]
end

function lib:GetBlizzardRole(guid)
	if not blizzardRoleByGUID[guid] then
		local unit = MooUnit:GetUnitByGUID(guid)
		if unit then
			blizzardRoleByGUID[guid] = UnitGroupRolesAssigned(unit)
		end
	end
	return blizzardRoleByGUID[guid] or "NONE"
end

function lib:GetRole(guid)
	return roleByGUID[guid] or "none"
end

function lib:GetSpecialization(guid)
	local specialization = specializationByGUID[guid]
	if specialization then
		local name = self:GetSpecializationName(specialization)
		return specialization, name
	end
	return nil
end

function lib:GetSpecializationName(specialization)
	return specializationName[specialization]
end

------------------------------------------------------------------------

-- GLOBALS: UnitGUID
-- GLOBALS: UnitIsPlayer
-- GLOBALS: UnitIsUnit

local function OnUnitSpecializationChanged(event, unit)
	debug(3, "OnUnitSpecializationChanged", event, unit)
	if unit == "player" or UnitIsUnit(unit, "player") then
		-- No need to inspect the player as the specialization info is already available.
		UpdateClass(playerGUID, "player")
		UpdateUnit(playerGUID, "player")
	elseif UnitIsPlayer(unit) then
		local guid = UnitGUID(unit)
		if guid then
			MooInspect:QueueInspect(guid)
		end
	end
end

function eventFrame:PLAYER_ENTERING_WORLD(event)
	OnUnitSpecializationChanged(event, "player")
end

function eventFrame:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	OnUnitSpecializationChanged(event, unit)
end

function eventFrame:ROLE_CHANGED_INFORM(event, changedPlayer, changedBy, oldRole, newRole)
	debug(3, event, changedPlayer, changedBy, oldRole, newRole)
	local guid = MooUnit:GetGUIDByName(changedPlayer)
	if guid then
		local unit = MooUnit:GetUnitByGUID(guid)
		if unit then
			UpdateBlizzardRole(guid, unit, newRole)
		else
			-- GUID no longer maps to a usable unit ID.
			self:OnUnitLeft(event, guid)
		end
	end
end

function eventFrame:OnInspectReady(event, guid)
	debug(3, event, guid)
	UpdateClass(guid)
	UpdateUnit(guid)
end

local function QueueUnit(guid, unit)
	-- Set a default role if this unit had no previous role.
	UpdateClass(guid, unit)
	local role = lib:GetRole(guid)
	if role == "none" then
		local class = lib:GetClass(guid)
		if class then
			role = roleByClass[class]
			UpdateRole(guid, unit, role)
		end
	end
	MooInspect:QueueInspect(guid)
end

function eventFrame:OnUnitJoined(event, guid, unit)
	if UnitIsPlayer(unit) then
		debug(3, "OnUnitJoined", event, guid, unit)
		UpdateClass(guid, unit)
		QueueUnit(guid, unit)
	end
end

function eventFrame:OnUnitLeft(event, guid)
	debug(3, "OnUnitLeft", event, guid)
	MooInspect:CancelInspect(guid)
	blizzardRoleByGUID[guid] = nil
	classByGUID[guid] = nil
	roleByGUID[guid] = nil
	specializationByGUID[guid] = nil
end

function eventFrame:OnUnitChanged(event, guid, unit, name)
	if MooUnit:IsGroupUnit(unit) and UnitIsPlayer(unit) then
		debug(3, "OnUnitChanged", event, guid, unit, name)
		UpdateClass(guid, unit)
		QueueUnit(guid, unit)
	end
end

------------------------------------------------------------------------

-- GLOBALS: UnitGUID
-- GLOBALS: UnitIsPlayer

function lib:InspectUnit(unit)
	if UnitIsPlayer(unit) then
		local guid = UnitGUID(unit)
		if guid then
			UpdateClass(guid, unit)
			QueueUnit(guid, unit)
		end
	end
end

function lib:InspectRoster()
	for guid, unit in MooUnit:IterateRoster() do
		if UnitIsPlayer(unit) then
			UpdateClass(guid, unit)
			QueueUnit(guid, unit)
		end
	end
end