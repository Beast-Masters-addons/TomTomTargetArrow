local addonName = ...
local addon = _G.LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

local HBD = _G.LibStub("HereBeDragons-2.0")

---------------------------------------------------------------------------------------------
-- Variables

local defaultGroupTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Normal";
local targetTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Target";
local stickTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Stick";

--Global imports
local UnitName = _G.UnitName
local UnitGUID = _G.UnitGUID
local UnitPosition = _G.UnitPosition
local UnitExists = _G.UnitExists
local GetPlayerFacing = _G.GetPlayerFacing
local UnitPlayerOrPetInParty = _G.UnitPlayerOrPetInParty
local UnitPlayerOrPetInRaid = _G.UnitPlayerOrPetInRaid
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS;
local MAX_PARTY_MEMBERS = _G.MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = _G.MAX_RAID_MEMBERS

local TomTom = _G.TomTom


---------------------------------------------------------------------------------------------

function addon:slashHandler(msg)
    local arg1 = self:GetArgs(msg)
	if arg1 then
		if (arg1 == "stick" and self.targetName) then
            self:Print("Stick on")
            self.stickyTarget = self.targetName
        elseif (arg1 == "unstick") then
            self:Print("Stick off")
            self.stickyTarget = nil
            -- Release arrow in case there is no target
            self:disableUpdate()
		elseif (arg1 == "debug") then
            self:Print('HBD player: ', HBD:GetUnitWorldPosition("player"))
            self:Print('HBD target: ', HBD:GetUnitWorldPosition("target"))
            self:Print('UnitPosition', UnitPosition("player"))
		end
	end
end

---------------------------------------------------------------------------------------------
-- EVENTS
function addon:targetInGroup()
    if not self.targetName then
        return false
    end
    return UnitPlayerOrPetInParty(self.targetName) or UnitPlayerOrPetInRaid(self.targetName)
end

function addon:OnInitialize()
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("PLAYER_FOCUS_CHANGED")
    self:RegisterEvent("GROUP_LEFT")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.playerInGroup = _G.UnitInAnyGroup("player")
    self.targetName = _G.UnitName("target")
    self.targetIsSelf = true
    self.stickyTarget = nil
    self.metric = TomTom:RegionIsMetric() or false
    self:RegisterChatCommand('TomTomTargetArrow', 'slashHandler')
    self:RegisterChatCommand('ttta', 'slashHandler')
end

function addon:PLAYER_TARGET_CHANGED()
    self.targetName = UnitName("target")
    if not self.targetName then
        self.targetIsSelf = true
    else
        self.targetIsSelf = UnitGUID(self.targetName) == UnitGUID("player")
    end
    if self.stickyTarget then
        return
    end

    --print("Target", self.targetName, self.targetIsSelf, self:targetInGroup())

    if (self.targetIsSelf or not self:targetInGroup()) then
        self:disableUpdate()
    else
        self:enableUpdate()
    end
    HighlightTargetOnMap(self.targetName);
end

function addon:PLAYER_FOCUS_CHANGED()
    self.stickyTarget = UnitName("focus")
    if self.stickyTarget then
        self:enableUpdate()
        self:Printf("Sticky focus %s", self.stickyTarget)
    else
        if not self.targetName then
            self:disableUpdate()
        end
        self:Print("Sticky focus off")
    end
end

function addon:disableUpdate()
    TomTom:ReleaseCrazyArrow()
end

function addon:enableUpdate()
    TomTom:HijackCrazyArrow(function()
        self:update_position()
    end)
end

function addon:GROUP_LEFT()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self.playerInGroup = false
    self:disableUpdate()
end

function addon:GROUP_JOINED()
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:enableUpdate()
    self.playerInGroup = true
end

---Disable updates if unit is in dungeon
function addon:ZONE_CHANGED_NEW_AREA()
    if not self.playerInGroup then
        return
    end
    local x, y = UnitPosition("player")
    if x == y == nil then
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self.in_instance = true
        self:disableUpdate()
    else
        self.in_instance = false
        self:enableUpdate()
    end
end

function addon.setArrowDirection(angle)
    local facing = GetPlayerFacing()
    if facing == nil then
        return
    end

    local arrow_angle = facing - angle
    arrow_angle = -arrow_angle
    if TomTom.CrazyArrowThemeHandler ~= nil then
        local theme = TomTom.CrazyArrowThemeHandler.active.tbl
        local texture = theme.arrowTexture
        local left, right, top, bottom = theme.navCoordResolver(arrow_angle)
        texture:SetTexCoord(left, right, top, bottom)
    else
        TomTom:SetCrazyArrowDirection(arrow_angle);
    end
end

function addon:setArrowDistanceText(dist)
    if dist then
        local distance_text
        if TomTom.GetFormattedDistance then
            distance_text = TomTom:GetFormattedDistance(dist)
        else
            distance_text = floor(dist) .. " yards"
        end

        if self.stickyTarget then
            TomTom:SetCrazyArrowTitle("Sticky: " .. self.stickyTarget, distance_text);
        else
            TomTom:SetCrazyArrowTitle(UnitName("target"), distance_text);
        end
    else
        TomTom:SetCrazyArrowTitle("");
    end
end

function addon:update_position()
    if not self.stickyTarget and (not self.playerInGroup or self.targetIsSelf) then
        return
    end

    local px, py, player_instance = HBD:GetPlayerWorldPosition()
    local tx, ty, target_instance = HBD:GetUnitWorldPosition(self.stickyTarget or self.targetName)
    if (target_instance ~= player_instance) then
        --print("Player and target is not in the same instance", player_instance, target_instance)
        return
    end

    if (px and py and tx and ty ~= nil) then
        local angle, distance = HBD:GetWorldVector(player_instance, px, py, tx, ty)

        self.setArrowDirection(angle)
        self:setArrowDistanceText(distance)
    else
        -- tx and ty can sometimes become nil if player zones into an instance while targeted
        -- in which case we release the arrow.
        self:disableUpdate()
    end
end

------------------------------------------------------------------
-- Helper functions

function GetWords(str, fs)
   local ret = {};
   local pos=0;
   while(true) do
     local word;
     _,pos,word=string.find(str, fs, pos+1);
     if(not word) then
       return ret;
     end
     word = string.lower(word);
     table.insert(ret, word);
   end
end

function HighlightTargetOnMap(targetName)
    local currentTarget = addon.targetName
	for i=1, MAX_PARTY_MEMBERS, 1 do
		if UnitExists("party"..i) then

		local dotFrame = getglobal("WorldMapParty"..i);

		if (dotFrame ~= nil) then
			local _, class = UnitClass("Party"..i)
			local t = RAID_CLASS_COLORS[class]
			if (t ~= nil) then
				dotFrame.icon:SetVertexColor(t.r, t.g, t.b)
			end

			dotFrame.icon:SetTexCoord(0, 1, 0, 1);
			dotFrame.icon.SetTexCoord = function() end
			dotFrame.icon:SetTexture(defaultGroupTexture);

			if (currentTarget == UnitName("Party"..i)) then
				dotFrame.icon:SetTexture(targetTexture);
			end
			if (doStick == true and targetName == UnitName("Party"..i)) then
				dotFrame.icon:SetTexture(stickTexture);
			end
		end
		end
	end

	for i=1, MAX_RAID_MEMBERS, 1 do
		local dotFrame = getglobal("WorldMapRaid"..i);

		if (dotFrame ~= nil) then

			local _, class = UnitClass("Raid"..i);
			local t = RAID_CLASS_COLORS[class]
			if (t ~= nil) then
				dotFrame.icon:SetVertexColor(t.r, t.g, t.b)
			end

			dotFrame.icon:SetTexCoord(0, 1, 0, 1);
			dotFrame.icon.SetTexCoord = function() end
			dotFrame.icon:SetTexture(defaultGroupTexture);

			if (currentTarget == UnitName("Raid"..i)) then
				dotFrame.icon:SetTexture(targetTexture);
			end
			if (doStick == true and targetName == UnitName("Raid"..i)) then
				dotFrame.icon:SetTexture(stickTexture);
			end
		end
	end

end
