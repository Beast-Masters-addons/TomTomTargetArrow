local HBD = LibStub("HereBeDragons-2.0")
local ttta = LibStub("AceAddon-3.0"):NewAddon("ttta", "AceConsole-3.0", "AceEvent-3.0")
local aceGUI = LibStub("AceGUI-3.0");


-- Variable holding zoneData
local zoneData = setmetatable({}, {__index=function(tbl, key)
	-- check for live data
	local _,l,t,r,b = GetCurrentMapZone();
	if (not l) then
		return;
	end
	tbl[key] = {
		["height"] = l-r,
		["width"] = t-b,
	}
	return tbl[key];
end});

local defaults = {
	["ArathiBasin_0"] = {
		["height"] = 1116.023025952007,
		["width"] = 1763.014014241485,
	},
	["AlteracValley_0"] = {
		["height"] = 2637.873902894055,
		["width"] = 4154.202959556035,
	},
	["NetherstormArena_0"] = {
		["height"] = 1422.981271502256,
		["width"] = 2278.120171091045,
	},
	["WarsongGulch_0"] = {
		["height"] = 713.3058234896934,
		["width"] = 1076.464849483253,
	},
	["StrandoftheAncients_0"] = {
		["height"] = 1081.93597429492,
		["width"] = 1644.10982966969,
	},
	["AzjolNerub_1"] = {
		["height"] = 469.4752924913463,
		["width"] = 9977.01041426628,
	},
	["Ulduar_0"] = {
		["height"] = 2045.933337601483,
		["width"] = 3071.259553513405,
	},
}

local db;

---------------------------------------------------------------------------------------------
-- Variables

local updatecounter = 0;
local updateFrequency = 0.05;
local playerName = "";

local defaultGroupTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Normal";
local targetTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Target";
local stickTexture = "Interface\\Addons\\TomTomTargetArrow\\Artwork\\Stick";

local RAID_CLASS_COLORS = RAID_CLASS_COLORS;

-- Reference objects to x and y scale labels.
local xScale;
local yScale;

-- Reference objects to x and y Difference labels.
local xDiff;
local yDiff;



local calibrator = aceGUI:Create("Frame");
calibrator:Hide();

function InitCalibratorFrame()
	calibrator:SetWidth(460);
	calibrator:SetHeight(200);

	group, xDiff, yScale = DiffGroup("xDiff");
	calibrator:AddChild(group);

	group, yDiff, xScale = DiffGroup("yDiff");
	calibrator:AddChild(group);

	-- Add Button to save calibration with
	group = aceGUI:Create("SimpleGroup");
	group:SetLayout("Flow");
	group:SetFullWidth(true);

	saveButton = aceGUI:Create("Button");
	saveButton:SetWidth(120);
	saveButton:SetCallback("OnClick", CalibrateNow)
	saveButton:SetText("Calibrate");
	group:AddChild(saveButton);
	calibrator:AddChild(group);

	group = aceGUI:Create("SimpleGroup");
	group:SetLayout("Flow");
	group:SetFullWidth(true);
end

function DiffGroup(label, button)
	group = aceGUI:Create("SimpleGroup");
	group:SetLayout("Flow");
	group:SetFullWidth(true);

	diffLabel = aceGUI:Create("Label");
	diffLabel:SetText(label);
	diffLabel:SetWidth(60);
	group:AddChild(diffLabel);

	diffLabel = aceGUI:Create("Label");
	diffLabel:SetWidth(180);
	diffLabel:SetText("");
	group:AddChild(diffLabel);

	calibrationLabel = aceGUI:Create("Label");
	calibrationLabel:SetText("");
	calibrationLabel:SetWidth(120);
	group:AddChild(calibrationLabel);
	
	return group, diffLabel, calibrationLabel;
end

---------------------------------------------------------------------------------------------
-- SLASHCOMMAND STUFF
local doStick = false;
local target = "target";

function TTTA_SlashCommand(msg)
	--calibrator:Show();
	local arg1, arg2, arg3, arg4;
    

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
		elseif (args[1] == "calibrate") then
			calibrator:Show();
		elseif (args[1] == "debug") then
			print('HBD player: ', HBD:GetUnitWorldPosition("player"))
			print('HBD target: ', HBD:GetUnitWorldPosition("target"))
			print('UnitPosition', UnitPosition("player"))
		end
	end
end

function CalibrateNow()
	if (xScale.Value == nil and yScale.Value == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("Align with either X or Y axis and try again");
		return;
	end

	zoneKey = GetZoneKey();

	if (zoneData[zoneKey] == nil) then
		zoneData[zoneKey] = {};
	end
	
	if (xScale.Value ~= nil) then
		DEFAULT_CHAT_FRAME:AddMessage("Width calibrated for "..zoneKey.." to "..xScale.Value);
		zoneData[zoneKey].width = xScale.Value;
	end
	
	if (yScale.Value ~= nil) then 
		DEFAULT_CHAT_FRAME:AddMessage("Height calibrated for "..zoneKey.." to "..yScale.Value);
		zoneData[zoneKey].height = yScale.Value; 
	end
	db.global.zoneData = zoneData;

end

-- Important detail: The below 3 lines have to be put after the definition of the function TTTA_SlashCommand to work.
SLASH_TomTomTargetArrow1 = "/TomTomTargetArrow";
SLASH_TomTomTargetArrow2 = "/ttta";
SlashCmdList["TomTomTargetArrow"] = TTTA_SlashCommand;

---------------------------------------------------------------------------------------------
-- EVENTS


function ttta:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("TTTA_VAR");
	db = self.db;
	if (db.global.zoneData == nil) then 
		db.global.zoneData = defaults;
		print("Defaults loaded");
	end;
	
	zoneData = db.global.zoneData;

	self:RegisterEvent("PLAYER_TARGET_CHANGED", ttta_Player_Target_Changed);
	--self:RegisterEvent("ZONE_CHANGED", ttta_Zone_Changed);
	--self:RegisterEvent("PARTY_MEMBERS_CHANGED", ttta_Party_Menbers_Changed);
	TomTomTargetArrow:SetScript("OnUpdate", ttta_OnUpdate);	
	
	updateCounter = 0;
	playerName = UnitName("player");
	
	InitCalibratorFrame()
end

local currentTarget;
function ttta_Player_Target_Changed()
	if (UnitGUID("target") == UnitGUID("player") or (not UnitPlayerOrPetInParty(target) and not UnitPlayerOrPetInRaid(target))) then
		TomTom:ReleaseCrazyArrow();
		xScale:SetText("");
		xScale.Value = nil;
		yScale:SetText("");
		yScale.Value = nil;
	end
	
	currentTarget = UnitName("target");
end

function ttta_Zone_Changed()
	--DEFAULT_CHAT_FRAME:AddMessage(GetMapInfo() .. "_" .. GetCurrentMapDungeonLevel());
	if (not UnitPlayerOrPetInParty(target) and not UnitPlayerOrPetInRaid(target)) then
		TomTom:ReleaseCrazyArrow();
		xScale:SetText("");
		xScale.Value = nil;
		yScale:SetText("");
		yScale.Value = nil;
	end
end

local player_instance, px, py, tx, ty
function ttta_OnUpdate(self, elapsed)
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
			
			--if (calibrator.Visible) then
				-- Calibrate(px,py, tx,ty);
			--end
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

function Calibrate(px,py, tx,ty)
	zoneKey = GetZoneKey();
	if (zoneData[zoneKey] == nil) then
		xScale:SetText("");
		xScale.Value = nil;
		yScale:SetText("");
		yScale.Value = nil;
	else
		if (zoneData[zoneKey].height ~= nil) then
			xScale:SetText("Calibrated");
			xScale.Value = nil;
		end
		if (zoneData[zoneKey].width ~= nil) then
			yScale:SetText("Calibrated");
			yScale.Value = nil;
		end
	end

	if (px and py and tx and ty) then
		dx = abs(px*10000000-tx*10000000);
		dy = abs(py*10000000-ty*10000000);
		if (abs(dx) > abs(dy)) then
			if (abs(dy) > 500) then
				yDiff:SetText(dy);
			else
				yDiff:SetText("Ok");
				-- Calibrate using 40 yards spell
				xScale.Value = 40/(abs(px-tx));
				xScale:SetText(xScale.Value);
			end
		else
			if (abs(dx) > 500) then
				xDiff:SetText(dx);
			else
				xDiff:SetText("Ok");
				-- Calibrate using 40 yards spell
				yScale.Value = 40/(abs(py-ty));
				yScale:SetText(yScale.Value);
			end
		end
	end
end

function GetZoneKey()
	map = GetMapInfo();
	level = GetCurrentMapDungeonLevel();
	if (level == nil) then
		level = ""
	end
	if (map == nil) then
		map = "";
	end
	return map.."_"..level;
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
