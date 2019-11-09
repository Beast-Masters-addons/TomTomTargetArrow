local HBD = LibStub("HereBeDragons-2.0")
-- local ttta = LibStub("AceAddon-3.0"):NewAddon("ttta", "AceConsole-3.0", "AceEvent-3.0")

local frame = CreateFrame("FRAME", "TomTomTargetArrowFrame");
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("GROUP_JOINED");
frame:RegisterEvent("GROUP_LEFT")


---------------------------------------------------------------------------------------------
-- Variables

local updateCounter = 0;
local updateFrequency = 0.05;
local playerName = UnitName("player");
local in_group = false

local defaultGroupTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Normal";
local targetTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Target";
local stickTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Stick";

local RAID_CLASS_COLORS = RAID_CLASS_COLORS;

---------------------------------------------------------------------------------------------
-- SLASHCOMMAND STUFF
local doStick = false;
local target = "target";

function TTTA_SlashCommand(msg)
	if (msg) then
		args = GetWords(msg, "^ *([^%s]+) *");

		if (args[1] == "stick" and UnitName("target") ~= nil) then
			doStick = true;
			DEFAULT_CHAT_FRAME:AddMessage( "Stick on");
			target = UnitName("target");
		elseif (args[1] == "unstick") then
			doStick = false;
			DEFAULT_CHAT_FRAME:AddMessage( "Stick off");
			target = "target";
			-- Release arrow in case there is no target
			TomTom:ReleaseCrazyArrow();
		elseif (args[1] == "debug") then
			print('HBD player: ', HBD:GetUnitWorldPosition("player"))
			print('HBD target: ', HBD:GetUnitWorldPosition("target"))
			print('UnitPosition', UnitPosition("player"))
		end
	end
end

-- Important detail: The below 3 lines have to be put after the definition of the function TTTA_SlashCommand to work.
SLASH_TomTomTargetArrow1 = "/TomTomTargetArrow";
SLASH_TomTomTargetArrow2 = "/ttta";
SlashCmdList["TomTomTargetArrow"] = TTTA_SlashCommand;

---------------------------------------------------------------------------------------------
-- EVENTS


--function ttta:OnInitialize()
--	self:RegisterEvent("PLAYER_TARGET_CHANGED", ttta_Player_Target_Changed);
	--self:RegisterEvent("ZONE_CHANGED", ttta_Zone_Changed);
	--self:RegisterEvent("PARTY_MEMBERS_CHANGED", ttta_Party_Menbers_Changed);
--	TomTomTargetArrow:SetScript("OnUpdate", ttta_OnUpdate);

--	updateCounter = 0;
--	playerName = UnitName("player");
-- end

local currentTarget;
function ttta_Player_Target_Changed()
	if (UnitGUID("target") == UnitGUID("player") or (not UnitPlayerOrPetInParty(target) and not UnitPlayerOrPetInRaid(target))) then
		TomTom:ReleaseCrazyArrow();
	end

	currentTarget = UnitName("target");
end

--function ttta_Zone_Changed()
	--DEFAULT_CHAT_FRAME:AddMessage(GetMapInfo() .. "_" .. GetCurrentMapDungeonLevel());
--	if (not UnitPlayerOrPetInParty(target) and not UnitPlayerOrPetInRaid(target)) then
--		TomTom:ReleaseCrazyArrow();
--	end
--end

local player_instance, px, py, tx, ty
function update_position (self, elapsed)
	if not in_group then
		return
	end
	local dist, dx, dy, target_instance
	updateCounter = updateCounter + elapsed;

	if (updateCounter >= updateFrequency) then
		px, py, player_instance = HBD:GetPlayerWorldPosition()


		local targetName = UnitName(target);

		HighlightTargetOnMap(targetName);

		if ((UnitPlayerOrPetInParty(target) or UnitPlayerOrPetInRaid(target)) and targetName ~= playerName) then

			tx, ty, target_instance = HBD:GetUnitWorldPosition(target)
			if (target_instance ~= player_instance) then
				-- print("Player and target is not in the same instance", player_instance, target_instance)
				return
			end

			if (px and py and tx and ty ~= nil) then
				UpdateTomTomArrow(px, py, tx, ty);

				dist, dx, dy = HBD:GetWorldDistance(player_instance, px, py, tx, ty)
				if (dist) then
					if (doStick) then
						TomTom:SetCrazyArrowTitle("Sticky:"..target, floor(dist).." yards");
					else
						TomTom:SetCrazyArrowTitle(UnitName("target"), floor(dist).." yards");
					end
				else
					TomTom:SetCrazyArrowTitle("");
				end
			else
				-- tx and ty can sometimes become nil if player zones into an instance while targeted
				-- in which case we release the arrow.
				TomTom:ReleaseCrazyArrow();
			end
		end
		updateCounter = 0;
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

function UpdateTomTomArrow(px, py, tx, ty)
	if not TomTom:CrazyArrowIsHijacked() then
		TomTom:HijackCrazyArrow(UpdateArrow())
	end

	UpdateArrow(self, elapsed);
end

function UpdateArrow(self, elapsed)

	local angle, distance = HBD:GetWorldVector(player_instance, px, py, tx, ty)
	local arrow_angle = GetPlayerFacing() - angle
	arrow_angle = -arrow_angle

	TomTom:SetCrazyArrowDirection(arrow_angle);
end

function HighlightTargetOnMap(targetName)
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

frame:SetScript("OnEvent", function(self, event,...)
	if event == 'PLAYER_TARGET_CHANGED' then
		ttta_Player_Target_Changed()
	end
	if event == 'GROUP_LEFT' then
		in_group = false
		frame:SetScript("OnUpdate", nil)
	elseif event == 'GROUP_JOINED' then
		in_group = true
		frame:SetScript("OnUpdate", update_position)
	end

end)