-- TODO: 
-- swap out map icons out with something with transparency.
-- check if worldmap is shown before handling worldmap icons to optimize.
-- figure out a way to determine distances in battlegrounds.
-- Fix coord/zone-ajustment when player and target are en different zones but on same continent.

local Astrolabe = DongleStub("Astrolabe-0.4")

local updatecounter = 0;
local updateFrequency = 0.05;
local playerName = "";
local defaultGroupTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Normal";
local targetTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Target";
local RAID_CLASS_COLORS = RAID_CLASS_COLORS;

--local Map = GetMapInfo();
--DEFAULT_CHAT_FRAME:AddMessage(Map);

------------------------------------------------------------------
-- Eventhandlers

function TTTA_OnLoad() 
	DEFAULT_CHAT_FRAME:AddMessage("TomTomTargetArrow loading...");
	TomTomTargetArrow:RegisterEvent("PLAYER_TARGET_CHANGED");
	updateCounter = 0;
	playerName = UnitName("player");
	DEFAULT_CHAT_FRAME:AddMessage("TomTomTargetArrow loaded!");
end

function TTTA_OnEventTargetChanged()
	if (not UnitPlayerOrPetInParty("target") and not UnitPlayerOrPetInRaid("target")) then
		TomTom:ReleaseCrazyArrow();
	end
end


function TTTA_OnUpdate(self, elapsed)
	updateCounter = updateCounter + elapsed;

	if (updateCounter >= updateFrequency) then

		pc,pz,px,py = Astrolabe:GetCurrentPlayerPosition();

		targetName = UnitName("target");
		
		HighlightTargetOnMap(targetName);

		if ((UnitPlayerOrPetInParty("target") or UnitPlayerOrPetInRaid("target")) and targetName ~= playerName) then
			
			tc,tz,tx,ty = Astrolabe:GetUnitPosition("target", true)

			if (px and py and tx and ty ~= nil) then
				-- TODO: Fix ajustment when player and target are en different zones but on same continent.
				UpdateTomTomArrow(px, py, tx, ty);
				
				--inInstance, instanceType = IsInInstance();
				--if (inInstance == 1) then
				dist, dx, dy = Astrolabe:ComputeDistance( pc, pz, px, py, tc, tz, tx, ty )
    				if (floor(dist) > 0) then
					TomTom:SetCrazyArrowTitle(floor(dist).." yards");
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

function UpdateTomTomArrow(px, py, tx, ty)
	if not TomTom:CrazyArrowIsHijacked() then
		TomTom:HijackCrazyArrow(UpdateArrow())
	end

	UpdateArrow(self, elapsed);
end

function UpdateArrow(self, elapsed)
	angle = GetAngle(px, py, tx, ty);
	TomTom:SetCrazyArrowDirection(angle);
end

function GetAngle(px, py, tx, ty)
	angle = math.atan2(tx - px, py - ty) 
	if (angle < 0) then
		angle = (math.pi * 2) + angle
	end

	facingRadians = -GetPlayerFacing();
	angle = facingRadians - angle
;



	if (angle < 0) then
		angle = (math.pi * 2) + angle
	end

	return angle
end

function HighlightTargetOnMap(targetName)

	for i=1, MAX_PARTY_MEMBERS, 1 do

		local dotFrame = getglobal("WorldMapParty"..i);

		if (dotFrame ~= nil) then
			local _, class = UnitClass("Party"..i)
			local t = RAID_CLASS_COLORS[class]
			if (t ~= nil) then
				dotFrame.icon:SetVertexColor(t.r, t.g, t.b)
			end

			dotFrame.icon:SetTexture(defaultGroupTexture);


			
if (targetName == UnitName("Party"..i)) then
				dotFrame.icon:SetTexture(targetTexture);

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

			dotFrame.icon:SetTexture(defaultGroupTexture);


			
if (targetName == UnitName("Raid"..i)) then
				dotFrame.icon:SetTexture(targetTexture);

			end
		end
	end

end

