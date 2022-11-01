-- Created by RedSaber for 'The Scala Universe'
-- Services --

local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")


-- Player Refs --

local localPlayer = PlayerService.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()
local gun = nil


-- GUI Refs --

local gui = localPlayer.PlayerGui
local main = gui:WaitForChild("Main")
local frame = gui:WaitForChild("Core"):WaitForChild("ScreenFrame")
local added = frame:WaitForChild("Added")
local crosshairs = frame:WaitForChild("Crosshairs")


-- Zoom values --

local defaultSensitivity = 0.5
local zoomedSensitivity = 0.2


local defaultZoomLevel = 70
local gunZoomLevel = defaultZoomLevel
local zoomInSpeed = 200
local zoomOutSpeed = 200
local zoomBuffer = 2

local defaultCrossPos = 0.5
local gunCrossDif = 0.075
local idealCrossPos = defaultCrossPos
local crossMoveSpeed = 0.1
local crossBuffer = 0


-- Script Variables --

local lastSetTransparency = 0
local zoomedIn = false
local lastHeldGun = nil



-- Set the zoom level to the desired level
local function SetZoomLevel(newZoomLevel)
	camera.FieldOfView = newZoomLevel
end

-- Check if the player has a changed guns
-- If so, we want to remove current zoom
local function CheckNewGun(gun)
	if gun ~= lastHeldGun then
		lastHeldGun = gun
		idealZoomLevel = defaultZoomLevel
		idealCrossPos = defaultCrossPos
	end
end

-- Check if the player is holding a gun
-- If yes, adjust variables and check if it's a new one
local function PlayerHoldingGun()
	local characterParts = localPlayer.Character:GetChildren()
	local found = false
	for i,part in ipairs(characterParts) do
		if CollectionService:HasTag(part, "Gun") and part:GetAttribute("Zoom") ~= nil then
			gunZoomLevel = part:GetAttribute("Zoom")
			gun = part
			CheckNewGun(part)
			found = true
		end
	end
	
	return found
end

-- Adjust the zoom to the set value gradually
local function AdjustZoom(deltaTime)
	-- If the player isn't holding a gun, remove any zoom or effects
	if not PlayerHoldingGun() then
		gun = nil
		gunZoomLevel = defaultZoomLevel
		idealZoomLevel = defaultZoomLevel
		idealCrossPos = defaultCrossPos
	end
	
	-- If the player has a gun and we have a ref to it
	if gun ~= nil then
		local gunName = gun.Name
		
		-- Set the appropriate scope image to enabled (using the name of the gun)
		local activated = false
		for i,child in ipairs(added:GetChildren()) do
			if child.Name == gunName and zoomedIn then
				child.Visible = true
				activated = true
			else
				child.Visible = false
			end
		end
		-- Set the appropriate crosshair image to be enabled
		for i,child in ipairs(crosshairs:GetChildren()) do
			-- If the crosshair matches the gun and we haven't already activated a scope image
			if child.Name == gunName and not activated then
				child.Visible = true
			else
				child.Visible = false
			end
			
			-- Adjust crosshair size for zoomed in or out
			if zoomedIn then
				crosshairs.Size = UDim2.new(0.05,0,0.05,0)
			else
				crosshairs.Size = UDim2.new(0.08,0,0.08,0)
			end
		end
		
		-- These 2 guns have scopes that require the score info and player model to be hidden
		local shouldShow = (gunName ~= "SP-4" and gunName ~= "S-5") or not zoomedIn
		-- Enable/disable score info
		main.Enabled = shouldShow
		-- If the player's model should be visible and it's not
		if shouldShow and lastSetTransparency == 1 then
			
			-- Loop through the player character and its children and set them to visible (excepting the root and the gun handle)
			for i,part in ipairs(gun.Parent:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
				end
				for j,p in ipairs(part:GetChildren()) do
					if p:IsA("BasePart") and p.Name ~= "Handle" then
						p.Transparency = 0
					end
				end
			end
			lastSetTransparency = 0

		end
	else
		-- If no gun is equipped, equip only the default crosshair
		for i,child in ipairs(crosshairs:GetChildren()) do
			child.Visible = (child.Name == "None")
		end
		-- Disable all scope images
		for i,child in ipairs(added:GetChildren()) do
			child.Visible = false
		end
	end
	
	local currentZoomLevel = camera.FieldOfView --(workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.Focus.Position).magnitude
	
	-- Modify the zoom level, using an adjustable buffer so the camera doesn't go crazy around the ideal point
	if idealZoomLevel - currentZoomLevel > zoomBuffer then
		local zoomLevel = currentZoomLevel + (deltaTime * zoomOutSpeed)
		SetZoomLevel(zoomLevel)
	elseif idealZoomLevel - currentZoomLevel < -zoomBuffer then
		local zoomLevel = currentZoomLevel - (deltaTime * zoomInSpeed)
		SetZoomLevel(zoomLevel)
	elseif gun ~= nil then
		
		local gunName = gun.Name
		-- These 2 guns have scopes that require the score info and player model to be hidden
		local shouldShow = (gunName ~= "SP-4" and gunName ~= "S-5") or not zoomedIn
		-- If the player's model should be hidden and it's not
		if not shouldShow and lastSetTransparency == 0 then
			-- Loop through the player character and its children and set them to invisible
			for i,part in ipairs(gun.Parent:GetChildren()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
				for j,p in ipairs(part:GetChildren()) do
					if p:IsA("BasePart") then
						p.Transparency = 1
					end
				end
			end
			lastSetTransparency = 1
		end
	end
end

-- Heartbeat connection
RunService.Heartbeat:Connect(function(deltaTime)
	AdjustZoom(deltaTime)
end)

-- When the right mouse button is pressed
mouse.Button2Down:Connect(function()
	-- Adjust the ideal zoom level (this is used in the every frame zoom adjustemnt)
	idealZoomLevel = gunZoomLevel
	-- Make sure there's a BoolValue instance that will hold whether we're zoomed in (for other scripts)
	if not script.Parent:FindFirstChild("ZoomedIn") then
		local zoomValue = Instance.new("BoolValue", script.Parent)
		zoomValue.Name = "ZoomedIn"
	end
	-- Adjust the BoolValue's value
	script.Parent.ZoomedIn.Value = true
	-- Set zoomed in
	zoomedIn = true
	-- Reduce sensitivity to help with aiming (if the player is holding a gun)
	-- This is adjusted on a NumberValue instance which another script uses
	if PlayerHoldingGun() then
		script.Parent:WaitForChild("Sensitivity").Value = zoomedSensitivity
	end
end)

-- When the right mouse button is lifted
mouse.Button2Up:Connect(function()
	-- Adjust the ideal zoom level (this is used in the every frame zoom adjustemnt)
	idealZoomLevel = defaultZoomLevel
	-- Make sure there's a BoolValue instance that will hold whether we're zoomed in (for other scripts)
	if not script.Parent:FindFirstChild("ZoomedIn") then
		local zoomValue = Instance.new("BoolValue", script.Parent)
		zoomValue.Name = "ZoomedIn"
	end
	-- Adjust the BoolValue's value
	script.Parent.ZoomedIn.Value = false
	-- Set zoomed in
	zoomedIn = false
	-- Increase sensitivity now that the player isn't zoomed
	-- This is adjusted on a NumberValue instance which another script uses
	script.Parent:WaitForChild("Sensitivity").Value = defaultSensitivity
end)



-- Start Game

-- Set the ideal zoom level and current zoom level to the default
idealZoomLevel = defaultZoomLevel
SetZoomLevel(idealZoomLevel)
