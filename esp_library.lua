--========================================================--
--  ESP FUNCTIONS
--========================================================--

repeat wait()
until _G.DependenciesLoaded == true

local Config = _G.Config

_G.ESPDrawings = {}
_G.ESPHighlights = {}
_G.ESPRadarComponents = {}
_G.ESPDirectionalArrows = {}
_G.ESPSettings = Config.ESP

local Drawing = Drawing

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera

local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

local function InitRadar()
	_G.ESPRadarComponents = {
		Background = Drawing.new("Circle"),
		Border = Drawing.new("Circle"),
		LocalPlayerDot = Drawing.new("Circle"),
		CrosshairH = Drawing.new("Line"),
		CrosshairV = Drawing.new("Line"),
		Circles = {},
		PlayerDots = {}
	}

	local radar = _G.ESPRadarComponents

	radar.Background.Visible = false
	radar.Background.Filled = true
	radar.Background.Color = Config.ESP.RadarBackgroundColor
	radar.Background.Transparency = Config.ESP.RadarBackgroundTransparency
	radar.Background.NumSides = Config.ESP.RadarSegments
	radar.Background.Radius = Config.ESP.RadarSize / 2

	radar.Border.Visible = false
	radar.Border.Filled = false
	radar.Border.Color = Config.ESP.RadarBorderColor
	radar.Border.Thickness = Config.ESP.RadarBorderThickness
	radar.Border.Transparency = 1
	radar.Border.NumSides = Config.ESP.RadarSegments
	radar.Border.Radius = Config.ESP.RadarSize / 2

	radar.LocalPlayerDot.Visible = false
	radar.LocalPlayerDot.Filled = true
	radar.LocalPlayerDot.Color = Config.ESP.RadarLocalPlayerColor
	radar.LocalPlayerDot.Radius = Config.ESP.RadarDotSize
	radar.LocalPlayerDot.NumSides = 30
	radar.LocalPlayerDot.Transparency = 1

	radar.CrosshairH.Visible = false
	radar.CrosshairH.Color = Color3.fromRGB(100, 100, 100)
	radar.CrosshairH.Thickness = 1
	radar.CrosshairH.Transparency = 0.5

	radar.CrosshairV.Visible = false
	radar.CrosshairV.Color = Color3.fromRGB(100, 100, 100)
	radar.CrosshairV.Thickness = 1
	radar.CrosshairV.Transparency = 0.5

	for i = 1, 3 do
		local circle = Drawing.new("Circle")
		circle.Visible = false
		circle.Filled = false
		circle.Color = Color3.fromRGB(80, 80, 80)
		circle.Thickness = 1
		circle.Transparency = 0.3
		circle.NumSides = Config.ESP.RadarSegments
		radar.Circles[i] = circle
	end
end

local function CreateArrow(player)
	if player == LocalPlayer then return end

	local arrow = {
		Triangle = Drawing.new("Triangle"),
		DistanceText = Drawing.new("Text")
	}

	arrow.Triangle.Visible = false
	arrow.Triangle.Color = Config.ESP.Colors.Arrow
	arrow.Triangle.Filled = true
	arrow.Triangle.Thickness = Config.ESP.DirectionalArrowsThickness
	arrow.Triangle.Transparency = Config.ESP.DirectionalArrowsTransparency

	arrow.DistanceText.Visible = false
	arrow.DistanceText.Color = Config.ESP.Colors.Arrow
	arrow.DistanceText.Size = Config.ESP.DirectionalArrowsDistanceTextSize
	arrow.DistanceText.Center = true
	arrow.DistanceText.Outline = true
	arrow.DistanceText.Font = 2

	_G.ESPDirectionalArrows[player] = arrow
end

local function RemoveArrow(player)
	local arrow = _G.ESPDirectionalArrows[player]
	if arrow then
		pcall(function() arrow.Triangle:Remove() end)
		pcall(function() arrow.DistanceText:Remove() end)
		_G.ESPDirectionalArrows[player] = nil
	end
end

local function UpdateArrows()
	if not Config.ESP.DirectionalArrowsEnabled then
		for _, arrow in pairs(_G.ESPDirectionalArrows) do
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
		end
		return
	end

	local localChar = LocalPlayer.Character
	if not localChar then return end

	local localRoot = localChar:FindFirstChild("HumanoidRootPart")
	if not localRoot then return end

	local localPos = localRoot.Position
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		if not _G.ESPDirectionalArrows[player] then
			CreateArrow(player)
		end

		local arrow = _G.ESPDirectionalArrows[player]
		local character = player.Character

		if not character then
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
			continue
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
			continue
		end

		local distance = (rootPart.Position - localPos).Magnitude

		if distance > Config.ESP.DirectionalArrowsDistance then
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
			continue
		end

		local targetScreenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

		if onScreen and targetScreenPos.Z > 0 then
			local targetPos2D = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
			local distanceFromCenter = (targetPos2D - screenCenter).Magnitude

			if distanceFromCenter < Config.ESP.DirectionalArrowsOffset then
				arrow.Triangle.Visible = false
				arrow.DistanceText.Visible = false
				continue
			end
		end

		local directionTo3D = (rootPart.Position - localPos)

		local cameraLook = Camera.CFrame.LookVector
		local cameraRight = Camera.CFrame.RightVector
		local cameraUp = Camera.CFrame.UpVector

		local screenX = directionTo3D:Dot(cameraRight)
		local screenY = -directionTo3D:Dot(cameraUp)

		local angleOnScreen = math.atan2(screenY, screenX)

		local arrowBaseX = screenCenter.X + math.cos(angleOnScreen) * Config.ESP.DirectionalArrowsOffset
		local arrowBaseY = screenCenter.Y + math.sin(angleOnScreen) * Config.ESP.DirectionalArrowsOffset
		local arrowBase = Vector2.new(arrowBaseX, arrowBaseY)

		local arrowSize = Config.ESP.DirectionalArrowsSize

		local tipOffset = arrowSize * 0.8
		local tip = Vector2.new(
			arrowBase.X + math.cos(angleOnScreen) * tipOffset,
			arrowBase.Y + math.sin(angleOnScreen) * tipOffset
		)

		local baseWidth = arrowSize * 0.5
		local perpAngle1 = angleOnScreen + math.rad(90)
		local perpAngle2 = angleOnScreen - math.rad(90)

		local base1 = Vector2.new(
			arrowBase.X + math.cos(perpAngle1) * baseWidth,
			arrowBase.Y + math.sin(perpAngle1) * baseWidth
		)

		local base2 = Vector2.new(
			arrowBase.X + math.cos(perpAngle2) * baseWidth,
			arrowBase.Y + math.sin(perpAngle2) * baseWidth
		)

		arrow.Triangle.PointA = tip
		arrow.Triangle.PointB = base1
		arrow.Triangle.PointC = base2
		arrow.Triangle.Color = Config.ESP.Colors.Arrow
		arrow.Triangle.Transparency = Config.ESP.DirectionalArrowsTransparency
		arrow.Triangle.Visible = true

		if Config.ESP.DirectionalArrowsShowDistance then
			arrow.DistanceText.Text = math.floor(distance) .. "m"
			arrow.DistanceText.Position = Vector2.new(
				arrowBase.X + math.cos(angleOnScreen) * (tipOffset + 15),
				arrowBase.Y + math.sin(angleOnScreen) * (tipOffset + 15)
			)
			arrow.DistanceText.Color = Config.ESP.Colors.Arrow
			arrow.DistanceText.Size = Config.ESP.DirectionalArrowsDistanceTextSize
			arrow.DistanceText.Visible = true
		else
			arrow.DistanceText.Visible = false
		end
	end
end

_G.UpdateRadar = function()
	if not Config.ESP.RadarEnabled then
		if _G.ESPRadarComponents then
			_G.ESPRadarComponents.Background.Visible = false
			_G.ESPRadarComponents.Border.Visible = false
			_G.ESPRadarComponents.LocalPlayerDot.Visible = false
			_G.ESPRadarComponents.CrosshairH.Visible = false
			_G.ESPRadarComponents.CrosshairV.Visible = false
			for _, circle in ipairs(_G.ESPRadarComponents.Circles) do
				circle.Visible = false
			end
			for _, dot in pairs(_G.ESPRadarComponents.PlayerDots or {}) do
				if dot.Visible ~= nil then
					dot.Visible = false
				end
			end
		end
		return
	end

	if not _G.ESPRadarComponents then return end

	local radarCenter = Vector2.new(
		Config.ESP.RadarPositionX + Config.ESP.RadarSize / 2,
		Config.ESP.RadarPositionY + Config.ESP.RadarSize / 2
	)
	local radarRadius = Config.ESP.RadarSize / 2

	_G.ESPRadarComponents.Background.NumSides = Config.ESP.RadarSegments
	_G.ESPRadarComponents.Background.Radius = radarRadius   -- force redraw
	_G.ESPRadarComponents.Background.Position = radarCenter
	_G.ESPRadarComponents.Background.Color = Config.ESP.RadarBackgroundColor
	_G.ESPRadarComponents.Background.Transparency = Config.ESP.RadarBackgroundTransparency
	_G.ESPRadarComponents.Background.Visible = true

	_G.ESPRadarComponents.Border.NumSides = Config.ESP.RadarSegments
	_G.ESPRadarComponents.Border.Radius = radarRadius
	_G.ESPRadarComponents.Border.Position = radarCenter
	_G.ESPRadarComponents.Border.Color = Config.ESP.RadarBorderColor
	_G.ESPRadarComponents.Border.Thickness = Config.ESP.RadarBorderThickness
	_G.ESPRadarComponents.Border.Visible = true

	_G.ESPRadarComponents.LocalPlayerDot.Position = radarCenter
	_G.ESPRadarComponents.LocalPlayerDot.Color = Config.ESP.RadarLocalPlayerColor
	_G.ESPRadarComponents.LocalPlayerDot.Radius = Config.ESP.RadarDotSize
	_G.ESPRadarComponents.LocalPlayerDot.Visible = true

	if Config.ESP.RadarShowCrosshair then
		_G.ESPRadarComponents.CrosshairH.From = Vector2.new(radarCenter.X - radarRadius, radarCenter.Y)
		_G.ESPRadarComponents.CrosshairH.To = Vector2.new(radarCenter.X + radarRadius, radarCenter.Y)
		_G.ESPRadarComponents.CrosshairH.Visible = true

		_G.ESPRadarComponents.CrosshairV.From = Vector2.new(radarCenter.X, radarCenter.Y - radarRadius)
		_G.ESPRadarComponents.CrosshairV.To = Vector2.new(radarCenter.X, radarCenter.Y + radarRadius)
		_G.ESPRadarComponents.CrosshairV.Visible = true
	else
		_G.ESPRadarComponents.CrosshairH.Visible = false
		_G.ESPRadarComponents.CrosshairV.Visible = false
	end

	if Config.ESP.RadarShowCircles then
		for i = 1, 3 do
			local radius = radarRadius * (i / 3)
			_G.ESPRadarComponents.Circles[i].NumSides = Config.ESP.RadarSegments
			_G.ESPRadarComponents.Circles[i].Radius = radius
			_G.ESPRadarComponents.Circles[i].Position = radarCenter
			_G.ESPRadarComponents.Circles[i].Visible = true
		end
	else
		for _, circle in ipairs(_G.ESPRadarComponents.Circles) do
			circle.Visible = false
		end
	end

	local localChar = LocalPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart")
	if not localRoot then return end

	local localPos = localRoot.Position

	if not _G.ESPRadarComponents.PlayerDots then
		_G.ESPRadarComponents.PlayerDots = {}
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		local character = player.Character
		if not character then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		local distance = (rootPart.Position - localPos).Magnitude
		if distance > Config.ESP.RadarRange then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		if not _G.ESPRadarComponents.PlayerDots[player] then
			local dot = Drawing.new("Circle")
			dot.Filled = true
			dot.Radius = Config.ESP.RadarDotSize
			dot.NumSides = 30
			dot.Transparency = 1
			_G.ESPRadarComponents.PlayerDots[player] = dot
		end

		local dot = _G.ESPRadarComponents.PlayerDots[player]

		local relativePos = rootPart.Position - localPos

		local cameraCFrame = Camera.CFrame
		local lookVector = cameraCFrame.LookVector
		local rightVector = cameraCFrame.RightVector

		local flatRelative = Vector3.new(relativePos.X, 0, relativePos.Z)
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
		local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z).Unit

		local radarX = flatRelative:Dot(flatRight)
		local radarZ = flatRelative:Dot(flatLook)

		local rotatedPos = Vector3.new(radarX, 0, radarZ)

		local scale = radarRadius / Config.ESP.RadarRange
		local radarXPos = rotatedPos.X * scale
		local radarYPos = -rotatedPos.Z * scale

		local dotDistance = math.sqrt(radarXPos * radarXPos + radarYPos * radarYPos)
		if dotDistance > radarRadius - Config.ESP.RadarDotSize then
			local angle = math.atan2(radarYPos, radarXPos)
			radarXPos = math.cos(angle) * (radarRadius - Config.ESP.RadarDotSize)
			radarYPos = math.sin(angle) * (radarRadius - Config.ESP.RadarDotSize)
		end

		dot.Position = radarCenter + Vector2.new(radarXPos, radarYPos)

		dot.Color = Config.ESP.RadarEnemyColor
		dot.Radius = Config.ESP.RadarDotSize * Config.ESP.RadarScale
		dot.Visible = true
	end
end

local function UpdateRadar()
	if not Config.ESP.RadarEnabled then
		if _G.ESPRadarComponents then
			_G.ESPRadarComponents.Background.Visible = false
			_G.ESPRadarComponents.Border.Visible = false
			_G.ESPRadarComponents.LocalPlayerDot.Visible = false
			_G.ESPRadarComponents.CrosshairH.Visible = false
			_G.ESPRadarComponents.CrosshairV.Visible = false
			for _, circle in ipairs(_G.ESPRadarComponents.Circles) do
				circle.Visible = false
			end
			for _, dot in pairs(_G.ESPRadarComponents.PlayerDots or {}) do
				if dot.Visible ~= nil then
					dot.Visible = false
				end
			end
		end
		return
	end

	if not _G.ESPRadarComponents then return end

	local radarCenter = Vector2.new(
		Config.ESP.RadarPositionX + Config.ESP.RadarSize / 2,
		Config.ESP.RadarPositionY + Config.ESP.RadarSize / 2
	)
	local radarRadius = Config.ESP.RadarSize / 2

	_G.ESPRadarComponents.Background.NumSides = Config.ESP.RadarSegments
	_G.ESPRadarComponents.Background.Radius = radarRadius   -- force redraw
	_G.ESPRadarComponents.Background.Position = radarCenter
	_G.ESPRadarComponents.Background.Color = Config.ESP.RadarBackgroundColor
	_G.ESPRadarComponents.Background.Transparency = Config.ESP.RadarBackgroundTransparency
	_G.ESPRadarComponents.Background.Visible = true

	_G.ESPRadarComponents.Border.NumSides = Config.ESP.RadarSegments
	_G.ESPRadarComponents.Border.Radius = radarRadius
	_G.ESPRadarComponents.Border.Position = radarCenter
	_G.ESPRadarComponents.Border.Color = Config.ESP.RadarBorderColor
	_G.ESPRadarComponents.Border.Thickness = Config.ESP.RadarBorderThickness
	_G.ESPRadarComponents.Border.Visible = true

	_G.ESPRadarComponents.LocalPlayerDot.Position = radarCenter
	_G.ESPRadarComponents.LocalPlayerDot.Color = Config.ESP.RadarLocalPlayerColor
	_G.ESPRadarComponents.LocalPlayerDot.Radius = Config.ESP.RadarDotSize
	_G.ESPRadarComponents.LocalPlayerDot.Visible = true

	if Config.ESP.RadarShowCrosshair then
		_G.ESPRadarComponents.CrosshairH.From = Vector2.new(radarCenter.X - radarRadius, radarCenter.Y)
		_G.ESPRadarComponents.CrosshairH.To = Vector2.new(radarCenter.X + radarRadius, radarCenter.Y)
		_G.ESPRadarComponents.CrosshairH.Visible = true

		_G.ESPRadarComponents.CrosshairV.From = Vector2.new(radarCenter.X, radarCenter.Y - radarRadius)
		_G.ESPRadarComponents.CrosshairV.To = Vector2.new(radarCenter.X, radarCenter.Y + radarRadius)
		_G.ESPRadarComponents.CrosshairV.Visible = true
	else
		_G.ESPRadarComponents.CrosshairH.Visible = false
		_G.ESPRadarComponents.CrosshairV.Visible = false
	end

	if Config.ESP.RadarShowCircles then
		for i = 1, 3 do
			local radius = radarRadius * (i / 3)
			_G.ESPRadarComponents.Circles[i].NumSides = Config.ESP.RadarSegments
			_G.ESPRadarComponents.Circles[i].Radius = radius
			_G.ESPRadarComponents.Circles[i].Position = radarCenter
			_G.ESPRadarComponents.Circles[i].Visible = true
		end
	else
		for _, circle in ipairs(_G.ESPRadarComponents.Circles) do
			circle.Visible = false
		end
	end

	local localChar = LocalPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart")
	if not localRoot then return end

	local localPos = localRoot.Position

	if not _G.ESPRadarComponents.PlayerDots then
		_G.ESPRadarComponents.PlayerDots = {}
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		local character = player.Character
		if not character then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		local distance = (rootPart.Position - localPos).Magnitude
		if distance > Config.ESP.RadarRange then
			if _G.ESPRadarComponents.PlayerDots[player] then
				_G.ESPRadarComponents.PlayerDots[player].Visible = false
			end
			continue
		end

		if not _G.ESPRadarComponents.PlayerDots[player] then
			local dot = Drawing.new("Circle")
			dot.Filled = true
			dot.Radius = Config.ESP.RadarDotSize
			dot.NumSides = 30
			dot.Transparency = 1
			_G.ESPRadarComponents.PlayerDots[player] = dot
		end

		local dot = _G.ESPRadarComponents.PlayerDots[player]

		local relativePos = rootPart.Position - localPos

		local cameraCFrame = Camera.CFrame
		local lookVector = cameraCFrame.LookVector
		local rightVector = cameraCFrame.RightVector

		local flatRelative = Vector3.new(relativePos.X, 0, relativePos.Z)
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
		local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z).Unit

		local radarX = flatRelative:Dot(flatRight)
		local radarZ = flatRelative:Dot(flatLook)

		local rotatedPos = Vector3.new(radarX, 0, radarZ)

		local scale = radarRadius / Config.ESP.RadarRange
		local radarXPos = rotatedPos.X * scale
		local radarYPos = -rotatedPos.Z * scale

		local dotDistance = math.sqrt(radarXPos * radarXPos + radarYPos * radarYPos)
		if dotDistance > radarRadius - Config.ESP.RadarDotSize then
			local angle = math.atan2(radarYPos, radarXPos)
			radarXPos = math.cos(angle) * (radarRadius - Config.ESP.RadarDotSize)
			radarYPos = math.sin(angle) * (radarRadius - Config.ESP.RadarDotSize)
		end

		dot.Position = radarCenter + Vector2.new(radarXPos, radarYPos)

		dot.Color = Config.ESP.RadarEnemyColor
		dot.Radius = Config.ESP.RadarDotSize * Config.ESP.RadarScale
		dot.Visible = true
	end
end

_G.UpdateESPSettings = function()
	for key, value in pairs(Config.ESP) do
		_G.ESPSettings[key] = value
	end
end

function UpdateESPSettings()
	for key, value in pairs(Config.ESP) do
		_G.ESPSettings[key] = value
	end
end

_G.ToggleESP = function(enabled)
	Config.ESP.Enabled = enabled

	if enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				if not _G.ESPDrawings[player] then
					CreateESP(player)
				end
			end
		end
	else
		for _, player in ipairs(Players:GetPlayers()) do
			if _G.ESPDrawings[player] then
				local esp = _G.ESPDrawings[player]
				if esp.Box then
					for _, line in pairs(esp.Box) do
						line.Visible = false
					end
				end

				if esp.Tracer then
					esp.Tracer.Visible = false
				end

				if esp.HealthBar then
					esp.HealthBar.Outline.Visible = false
					esp.HealthBar.Fill.Visible = false
					esp.HealthBar.Text.Visible = false
				end

				if esp.Info then
					esp.Info.Name.Visible = false
					esp.Info.Distance.Visible = false
				end

				if esp.Skeleton then
					for _, line in pairs(esp.Skeleton) do
						line.Visible = false
					end
				end
			end

			if _G.ESPHighlights[player] then
				_G.ESPHighlights[player].Enabled = false
			end
		end
	end
end

function ToggleESP(enabled)
	Config.ESP.Enabled = enabled

	if enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				if not _G.ESPDrawings[player] then
					CreateESP(player)
				end
			end
		end
	else
		for _, player in ipairs(Players:GetPlayers()) do
			if _G.ESPDrawings[player] then
				local esp = _G.ESPDrawings[player]
				if esp.Box then
					for _, line in pairs(esp.Box) do
						line.Visible = false
					end
				end

				if esp.Tracer then
					esp.Tracer.Visible = false
				end

				if esp.HealthBar then
					esp.HealthBar.Outline.Visible = false
					esp.HealthBar.Fill.Visible = false
					esp.HealthBar.Text.Visible = false
				end

				if esp.Info then
					esp.Info.Name.Visible = false
					esp.Info.Distance.Visible = false
				end

				if esp.Skeleton then
					for _, line in pairs(esp.Skeleton) do
						line.Visible = false
					end
				end
			end

			if _G.ESPHighlights[player] then
				_G.ESPHighlights[player].Enabled = false
			end
		end
	end
end

function GetHealthColor(health, maxHealth)
	local percentage = health / maxHealth
	if percentage > 0.5 then
		return Config.ESP.Colors.HealthHigh
	elseif percentage > 0.2 then
		return Config.ESP.Colors.HealthMedium
	else
		return Config.ESP.Colors.HealthLow
	end
end

function GetTracerOrigin()
	local viewportSize = Camera.ViewportSize

	if Config.ESP.TracerOrigin == "Bottom" then
		return Vector2.new(viewportSize.X / 2, viewportSize.Y)
	elseif Config.ESP.TracerOrigin == "Top" then
		return Vector2.new(viewportSize.X / 2, 0)
	elseif Config.ESP.TracerOrigin == "Mouse" then
		local mousePos = UserInputService:GetMouseLocation()
		return mousePos
	else
		return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
	end
end

function CreateBoxes(player)
	if player == LocalPlayer then return end

	if not _G.ESPDrawings[player] then
		_G.ESPDrawings[player] = {}
	end

	_G.ESPDrawings[player].Box = {
		TopLeft = Drawing.new("Line"),
		TopRight = Drawing.new("Line"),
		BottomLeft = Drawing.new("Line"),
		BottomRight = Drawing.new("Line"),
		Top = Drawing.new("Line"),
		Bottom = Drawing.new("Line"),
		Left = Drawing.new("Line"),
		Right = Drawing.new("Line")
	}

	for _, line in pairs(_G.ESPDrawings[player].Box) do
		line.Visible = false
		line.Color = Config.ESP.Colors.Box
		line.Thickness = Config.ESP.BoxThickness
	end
end

function CreateTracers(player)
	if player == LocalPlayer then return end

	if not _G.ESPDrawings[player] then
		_G.ESPDrawings[player] = {}
	end

	_G.ESPDrawings[player].Tracer = Drawing.new("Line")
	_G.ESPDrawings[player].Tracer.Visible = false
	_G.ESPDrawings[player].Tracer.Color = Config.ESP.Colors.Tracer
	_G.ESPDrawings[player].Tracer.Thickness = Config.ESP.TracerThickness
end

function CreateHealthBars(player)
	if player == LocalPlayer then return end

	if not _G.ESPDrawings[player] then
		_G.ESPDrawings[player] = {}
	end

	_G.ESPDrawings[player].HealthBar = {
		Outline = Drawing.new("Square"),
		Fill = Drawing.new("Square"),
		Text = Drawing.new("Text")
	}

	_G.ESPDrawings[player].HealthBar.Outline.Visible = false
	_G.ESPDrawings[player].HealthBar.Outline.Color = Color3.fromRGB(0, 0, 0)
	_G.ESPDrawings[player].HealthBar.Outline.Filled = true
	_G.ESPDrawings[player].HealthBar.Outline.Thickness = 1

	_G.ESPDrawings[player].HealthBar.Fill.Visible = false
	_G.ESPDrawings[player].HealthBar.Fill.Color = Config.ESP.Colors.Health
	_G.ESPDrawings[player].HealthBar.Fill.Filled = true

	_G.ESPDrawings[player].HealthBar.Text.Visible = false
	_G.ESPDrawings[player].HealthBar.Text.Color = Color3.fromRGB(255, 255, 255)
	_G.ESPDrawings[player].HealthBar.Text.Size = Config.ESP.TextSize
	_G.ESPDrawings[player].HealthBar.Text.Outline = true
	_G.ESPDrawings[player].HealthBar.Text.Center = true
end

function CreateNames(player)
	if player == LocalPlayer then return end

	if not _G.ESPDrawings[player] then
		_G.ESPDrawings[player] = {}
	end

	_G.ESPDrawings[player].Info = {
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text")
	}

	_G.ESPDrawings[player].Info.Name.Visible = false
	_G.ESPDrawings[player].Info.Name.Center = true
	_G.ESPDrawings[player].Info.Name.Size = Config.ESP.TextSize
	_G.ESPDrawings[player].Info.Name.Color = Config.ESP.Colors.Text
	_G.ESPDrawings[player].Info.Name.Outline = true

	_G.ESPDrawings[player].Info.Distance.Visible = false
	_G.ESPDrawings[player].Info.Distance.Center = true
	_G.ESPDrawings[player].Info.Distance.Size = Config.ESP.TextSize
	_G.ESPDrawings[player].Info.Distance.Color = Config.ESP.Colors.Distance
	_G.ESPDrawings[player].Info.Distance.Outline = true
end

function CreateSkeleton(player)
	if player == LocalPlayer then return end

	if not _G.ESPDrawings[player] then
		_G.ESPDrawings[player] = {}
	end

	_G.ESPDrawings[player].Skeleton = {}

	local skeletonConnections = {
		"Head", "UpperSpine", "LeftShoulder", "LeftUpperArm", "LeftLowerArm",
		"RightShoulder", "RightUpperArm", "RightLowerArm",
		"LeftHip", "LeftUpperLeg", "LeftLowerLeg",
		"RightHip", "RightUpperLeg", "RightLowerLeg"
	}

	for i = 1, 14 do
		local line = Drawing.new("Line")
		line.Visible = false
		line.Color = Config.ESP.Colors.Skeleton
		line.Thickness = Config.ESP.SkeletonThickness
		line.Transparency = Config.ESP.SkeletonTransparency
		_G.ESPDrawings[player].Skeleton[i] = line
	end
end

local function NewQuad(color)
	local quad = Drawing.new("Quad")
	quad.Visible = false
	quad.PointA = Vector2.new(0,0)
	quad.PointB = Vector2.new(0,0)
	quad.PointC = Vector2.new(0,0)
	quad.PointD = Vector2.new(0,0)
	quad.Color = color
	quad.Filled = true
	quad.Thickness = 1
	quad.Transparency = 0
	return quad
end

function CreateChams(player)
	if player == LocalPlayer then return end
	if not _G.ESPDrawings[player] then
		_G.ESPDrawings[player] = {}
	end
	_G.ESPDrawings[player].ChamsQuads = {}
end

function CreateESP(player)
	if player == LocalPlayer then return end

	CreateBoxes(player)
	CreateTracers(player)
	CreateHealthBars(player)
	CreateNames(player)
	CreateSkeleton(player)
	CreateChams(player)
	CreateArrow(player)

end

function RemoveESP(player)
	if _G.ESPDrawings[player] then
		if _G.ESPDrawings[player].Box then
			for _, line in pairs(_G.ESPDrawings[player].Box) do
				pcall(function() line:Remove() end)
			end
		end

		if _G.ESPDrawings[player].Tracer then
			pcall(function() _G.ESPDrawings[player].Tracer:Remove() end)
		end

		if _G.ESPDrawings[player] and _G.ESPDrawings[player].ChamsQuads then
			for partName, quads in pairs(_G.ESPDrawings[player].ChamsQuads) do
				for _, quad in ipairs(quads) do
					pcall(function() quad:Remove() end)
				end
			end
			_G.ESPDrawings[player].ChamsQuads = nil
		end

		if _G.ESPDrawings[player].HealthBar then
			pcall(function() _G.ESPDrawings[player].HealthBar.Outline:Remove() end)
			pcall(function() _G.ESPDrawings[player].HealthBar.Fill:Remove() end)
			pcall(function() _G.ESPDrawings[player].HealthBar.Text:Remove() end)
		end

		if _G.ESPDrawings[player].Info then
			pcall(function() _G.ESPDrawings[player].Info.Name:Remove() end)
			pcall(function() _G.ESPDrawings[player].Info.Distance:Remove() end)
		end

		if _G.ESPDrawings[player].Skeleton then
			for _, line in pairs(_G.ESPDrawings[player].Skeleton) do
				pcall(function() line:Remove() end)
			end
		end

		_G.ESPDrawings[player] = nil
	end

	if _G.ESPHighlights[player] then
		pcall(function() _G.ESPHighlights[player]:Destroy() end)
		_G.ESPHighlights[player] = nil
	end

	RemoveArrow(player)
end

function UpdateBoxes(player, esp, character, humanoid, rootPart)

	local head = character:FindFirstChild("Head")
	if not head then
		if esp.Box then
			for _, line in pairs(esp.Box) do
				line.Visible = false
			end
		end
		return nil, nil
	end

	local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
	local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

	if not (headOnScreen and rootOnScreen) or headPos.Z < 0 or rootPos.Z < 0 then
		if esp.Box then
			for _, line in pairs(esp.Box) do
				line.Visible = false
			end
		end
		return nil, nil 
	end

	local screenHeight = math.abs(headPos.Y - rootPos.Y)
	local screenWidth = screenHeight * 0.5

	local boxPosition = Vector2.new(
		headPos.X - screenWidth / 2,
		headPos.Y
	)
	local boxSize = Vector2.new(screenWidth, screenHeight)
	if Config.ESP.BoxESP and esp.Box then
		if Config.ESP.BoxStyle == "Corner" then
			local cornerSize = screenWidth * 0.25

			esp.Box.TopLeft.From = boxPosition
			esp.Box.TopLeft.To = boxPosition + Vector2.new(0, cornerSize)
			esp.Box.TopLeft.Color = Config.ESP.Colors.Box
			esp.Box.TopLeft.Thickness = Config.ESP.BoxThickness
			esp.Box.TopLeft.Visible = true

			esp.Box.TopRight.From = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.TopRight.To = boxPosition + Vector2.new(boxSize.X, cornerSize)
			esp.Box.TopRight.Color = Config.ESP.Colors.Box
			esp.Box.TopRight.Thickness = Config.ESP.BoxThickness
			esp.Box.TopRight.Visible = true

			esp.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.BottomLeft.To = boxPosition + Vector2.new(0, boxSize.Y - cornerSize)
			esp.Box.BottomLeft.Color = Config.ESP.Colors.Box
			esp.Box.BottomLeft.Thickness = Config.ESP.BoxThickness
			esp.Box.BottomLeft.Visible = true

			esp.Box.BottomRight.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.BottomRight.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y - cornerSize)
			esp.Box.BottomRight.Color = Config.ESP.Colors.Box
			esp.Box.BottomRight.Thickness = Config.ESP.BoxThickness
			esp.Box.BottomRight.Visible = true

			esp.Box.Top.From = boxPosition
			esp.Box.Top.To = boxPosition + Vector2.new(cornerSize, 0)
			esp.Box.Top.Color = Config.ESP.Colors.Box
			esp.Box.Top.Thickness = Config.ESP.BoxThickness
			esp.Box.Top.Visible = true

			esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.Bottom.To = boxPosition + Vector2.new(cornerSize, boxSize.Y)
			esp.Box.Bottom.Color = Config.ESP.Colors.Box
			esp.Box.Bottom.Thickness = Config.ESP.BoxThickness
			esp.Box.Bottom.Visible = true

			esp.Box.Left.From = boxPosition + Vector2.new(boxSize.X - cornerSize, 0)
			esp.Box.Left.To = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.Left.Color = Config.ESP.Colors.Box
			esp.Box.Left.Thickness = Config.ESP.BoxThickness
			esp.Box.Left.Visible = true

			esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X - cornerSize, boxSize.Y)
			esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.Right.Color = Config.ESP.Colors.Box
			esp.Box.Right.Thickness = Config.ESP.BoxThickness
			esp.Box.Right.Visible = true
		else
			for _, line in pairs(esp.Box) do
				line.Visible = false
			end
			esp.Box.Left.From = boxPosition
			esp.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.Left.Color = Config.ESP.Colors.Box
			esp.Box.Left.Thickness = Config.ESP.BoxThickness
			esp.Box.Left.Visible = true

			esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.Right.Color = Config.ESP.Colors.Box
			esp.Box.Right.Thickness = Config.ESP.BoxThickness
			esp.Box.Right.Visible = true

			esp.Box.Top.From = boxPosition
			esp.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0)
			esp.Box.Top.Color = Config.ESP.Colors.Box
			esp.Box.Top.Thickness = Config.ESP.BoxThickness
			esp.Box.Top.Visible = true

			esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
			esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
			esp.Box.Bottom.Color = Config.ESP.Colors.Box
			esp.Box.Bottom.Thickness = Config.ESP.BoxThickness
			esp.Box.Bottom.Visible = true

			esp.Box.TopLeft.Visible = false
			esp.Box.TopRight.Visible = false
			esp.Box.BottomLeft.Visible = false
			esp.Box.BottomRight.Visible = false
		end
	else
		if esp.Box then
			for _, line in pairs(esp.Box) do
				line.Visible = false
			end
		end
	end
	return boxPosition, boxSize
end

function UpdateTracers(player, esp, rootPart)
	if not Config.ESP.TracerESP or not esp.Tracer then
		if esp.Tracer then
			esp.Tracer.Visible = false
		end
		return
	end

	local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
	if not onScreen or pos.Z < 0 then
		esp.Tracer.Visible = false
		return
	end

	local tracerOrigin = GetTracerOrigin()
	esp.Tracer.From = tracerOrigin
	esp.Tracer.To = Vector2.new(pos.X, pos.Y)
	esp.Tracer.Color = Config.ESP.Colors.Tracer
	esp.Tracer.Thickness = Config.ESP.TracerThickness
	esp.Tracer.Visible = true
end

function UpdateHealthBars(player, esp, character, humanoid, boxPosition, boxSize, screenHeight)
	if not Config.ESP.HealthESP or not esp.HealthBar then
		if esp.HealthBar then
			esp.HealthBar.Outline.Visible = false
			esp.HealthBar.Fill.Visible = false
			esp.HealthBar.Text.Visible = false
		end
		return
	end

	local health = humanoid.Health
	local maxHealth = humanoid.MaxHealth
	local healthPercent = math.clamp(health / maxHealth, 0, 1)

	local barHeight = screenHeight * 0.9
	local barWidth = 4
	local barPos = Vector2.new(
		boxPosition.X - barWidth - 4,
		boxPosition.Y + (screenHeight - barHeight) / 2
	)

	esp.HealthBar.Outline.Size = Vector2.new(barWidth + 2, barHeight + 2)
	esp.HealthBar.Outline.Position = barPos - Vector2.new(1, 1)
	esp.HealthBar.Outline.Color = Color3.fromRGB(0, 0, 0)
	esp.HealthBar.Outline.Filled = true
	esp.HealthBar.Outline.Visible = true

	local fillHeight = barHeight * healthPercent
	esp.HealthBar.Fill.Size = Vector2.new(barWidth, fillHeight)
	esp.HealthBar.Fill.Position = Vector2.new(barPos.X, barPos.Y + barHeight - fillHeight)
	esp.HealthBar.Fill.Color = GetHealthColor(health, maxHealth)
	esp.HealthBar.Fill.Filled = true
	esp.HealthBar.Fill.Visible = true

	if Config.ESP.HealthStyle == "Both" or Config.ESP.HealthStyle == "Text" then
		esp.HealthBar.Text.Text = math.floor(health) .. (Config.ESP.HealthTextSuffix or "")
		esp.HealthBar.Text.Position = Vector2.new(barPos.X - 15, barPos.Y + barHeight / 2)
		esp.HealthBar.Text.Color = Color3.fromRGB(255, 255, 255)
		esp.HealthBar.Text.Size = Config.ESP.TextSize
		esp.HealthBar.Text.Visible = true
	else
		esp.HealthBar.Text.Visible = false
	end
end

function UpdateNames(player, esp, character, rootPart, boxPosition, boxSize)
	if not esp.Info then return end

	if Config.ESP.NameESP and esp.Info.Name then
		local nameText = Config.ESP.NameMode == "UserName" and player.Name or player.DisplayName
		esp.Info.Name.Text = nameText
		esp.Info.Name.Position = Vector2.new(
			boxPosition.X + boxSize.X / 2,
			boxPosition.Y - 18
		)
		esp.Info.Name.Color = Config.ESP.Colors.Text
		esp.Info.Name.Size = Config.ESP.TextSize
		esp.Info.Name.Visible = true
	elseif esp.Info.Name then
		esp.Info.Name.Visible = false
	end

	if esp.Info.Distance then
		esp.Info.Distance.Visible = false
	end
end

function UpdateSkeleton(player, esp, character)
	if not Config.ESP.SkeletonESP or not esp.Skeleton then
		if esp.Skeleton then
			for _, line in pairs(esp.Skeleton) do
				line.Visible = false
			end
		end
		return
	end

	local bones = {
		Head = character:FindFirstChild("Head"),
		UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
		LowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso"),

		LeftUpperArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
		LeftLowerArm = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm"),
		LeftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"),

		RightUpperArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
		RightLowerArm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm"),
		RightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"),

		LeftUpperLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
		LeftLowerLeg = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg"),
		LeftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),

		RightUpperLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
		RightLowerLeg = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg"),
		RightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
	}

	if not (bones.Head and bones.UpperTorso) then
		for _, line in pairs(esp.Skeleton) do
			line.Visible = false
		end
		return
	end

	local connections = {
		{bones.Head, bones.UpperTorso},
		{bones.UpperTorso, bones.LowerTorso},
		{bones.UpperTorso, bones.LeftUpperArm},
		{bones.LeftUpperArm, bones.LeftLowerArm},
		{bones.LeftLowerArm, bones.LeftHand},
		{bones.UpperTorso, bones.RightUpperArm},
		{bones.RightUpperArm, bones.RightLowerArm},
		{bones.RightLowerArm, bones.RightHand},
		{bones.LowerTorso, bones.LeftUpperLeg},
		{bones.LeftUpperLeg, bones.LeftLowerLeg},
		{bones.LeftLowerLeg, bones.LeftFoot},
		{bones.LowerTorso, bones.RightUpperLeg},
		{bones.RightUpperLeg, bones.RightLowerLeg},
		{bones.RightLowerLeg, bones.RightFoot}
	}

	for i, connection in ipairs(connections) do
		local from, to = connection[1], connection[2]
		local line = esp.Skeleton[i]

		if from and to and line then
			local fromPos, fromOnScreen = Camera:WorldToViewportPoint(from.Position)
			local toPos, toOnScreen = Camera:WorldToViewportPoint(to.Position)

			if fromOnScreen and toOnScreen and fromPos.Z > 0 and toPos.Z > 0 then
				line.From = Vector2.new(fromPos.X, fromPos.Y)
				line.To = Vector2.new(toPos.X, toPos.Y)
				line.Color = Config.ESP.Colors.Skeleton
				line.Thickness = Config.ESP.SkeletonThickness
				line.Transparency = Config.ESP.SkeletonTransparency
				line.Visible = true
			else
				line.Visible = false
			end
		elseif line then
			line.Visible = false
		end
	end
end

function UpdateChams(player, character)
	if not Config.ESP.ChamsEnabled then
		if _G.ESPDrawings[player] and _G.ESPDrawings[player].ChamsQuads then
			for partName, quads in pairs(_G.ESPDrawings[player].ChamsQuads) do
				for _, quad in ipairs(quads) do
					quad.Visible = false
				end
			end
		end
		return
	end

	if player == LocalPlayer or not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		if _G.ESPDrawings[player] and _G.ESPDrawings[player].ChamsQuads then
			for partName, quads in pairs(_G.ESPDrawings[player].ChamsQuads) do
				for _, quad in ipairs(quads) do
					quad.Visible = false
				end
			end
		end
		return
	end

	local fillColor = Config.ESP.Colors.Chams
	local transparency = Config.ESP.ChamsTransparency

	local esp = _G.ESPDrawings[player]
	if not esp then
		esp = {}
		_G.ESPDrawings[player] = esp
	end
	if not esp.ChamsQuads then
		esp.ChamsQuads = {}
	end
	local quadsForPlayer = esp.ChamsQuads

	local partNames = {
		"Head", "UpperTorso", "LowerTorso", 
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand", 
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot"
	}
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
		if distance > Config.ESP.MaxDistance then
			for partName, quads in pairs(quadsForPlayer) do
				for _, quad in ipairs(quads) do
					quad.Visible = false
				end
			end
			return
		end
	end
	local ViewportSize = Camera.ViewportSize

	for _, partName in ipairs(partNames) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			if not quadsForPlayer[partName] then
				local quads = {}
				for i = 1, 6 do
					quads[i] = NewQuad(fillColor)
				end
				quadsForPlayer[partName] = quads
			end
			local quads = quadsForPlayer[partName]
			local size = part.Size
			local cf = part.CFrame
			local corners = {
				cf * CFrame.new(-size.X/2,  size.Y/2, -size.Z/2),
				cf * CFrame.new(-size.X/2,  size.Y/2,  size.Z/2),
				cf * CFrame.new( size.X/2,  size.Y/2,  size.Z/2),
				cf * CFrame.new( size.X/2,  size.Y/2, -size.Z/2),
				cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
				cf * CFrame.new(-size.X/2, -size.Y/2,  size.Z/2),
				cf * CFrame.new( size.X/2, -size.Y/2,  size.Z/2),
				cf * CFrame.new( size.X/2, -size.Y/2, -size.Z/2)
			}
			local points = {}
			local anyCornerVisible = false
			local allCornersBehind = true

			for i, corner in ipairs(corners) do
				local pos, onScreen = Camera:WorldToViewportPoint(corner.Position)
				points[i] = Vector2.new(pos.X, pos.Y)
				if pos.Z > 0 then
					allCornersBehind = false
					if pos.X >= 0 and pos.X <= ViewportSize.X 
						and pos.Y >= 0 and pos.Y <= ViewportSize.Y then
						anyCornerVisible = true
					end
				end
			end
			local faces = {
				{1,2,3,4},
				{5,6,7,8},
				{1,2,6,5}, 
				{2,3,7,6},
				{3,4,8,7}, 
				{4,1,5,8} 
			}
			if allCornersBehind or not anyCornerVisible then
				for i = 1, 6 do
					quads[i].Visible = false
				end
			else
				for i, face in ipairs(faces) do
					local quad = quads[i]
					quad.PointA = points[face[1]]
					quad.PointB = points[face[2]]
					quad.PointC = points[face[3]]
					quad.PointD = points[face[4]]
					quad.Color = fillColor
					quad.Transparency = transparency
					quad.Visible = true
				end
			end
		else
			if quadsForPlayer[partName] then
				for _, quad in ipairs(quadsForPlayer[partName]) do
					quad.Visible = false
				end
			end
		end
	end
	for partName, quads in pairs(quadsForPlayer) do
		if not character:FindFirstChild(partName) then
			for _, quad in ipairs(quads) do
				quad.Visible = false
			end
		end
	end
end

function UpdateESP(player)
	if not Config.ESP.Enabled then
		if _G.ESPDrawings[player] then
			local esp = _G.ESPDrawings[player]
			if esp.Box then for _, line in pairs(esp.Box) do line.Visible = false end end
			if esp.Tracer then esp.Tracer.Visible = false end
			if esp.HealthBar then
				esp.HealthBar.Outline.Visible = false
				esp.HealthBar.Fill.Visible = false
				esp.HealthBar.Text.Visible = false
			end
			if esp.Info then
				esp.Info.Name.Visible = false
				esp.Info.Distance.Visible = false
			end
			if esp.Skeleton then
				for _, line in pairs(esp.Skeleton) do line.Visible = false end
			end
			if esp.ChamsQuads then
				for partName, quads in pairs(esp.ChamsQuads) do
					for _, quad in ipairs(quads) do
						quad.Visible = false
					end
				end
			end
		end
		if _G.ESPHighlights[player] then
			_G.ESPHighlights[player].Enabled = false
		end
		return
	end

	local esp = _G.ESPDrawings[player]
	if not esp then return end

	local function HideAllESP()
		if esp.Box then for _, line in pairs(esp.Box) do line.Visible = false end end
		if esp.Tracer then esp.Tracer.Visible = false end
		if esp.HealthBar then
			esp.HealthBar.Outline.Visible = false
			esp.HealthBar.Fill.Visible = false
			esp.HealthBar.Text.Visible = false
		end
		if esp.Info then
			esp.Info.Name.Visible = false
			esp.Info.Distance.Visible = false
		end
		if esp.Skeleton then
			for _, line in pairs(esp.Skeleton) do line.Visible = false end
		end
		if esp.ChamsQuads then
			for partName, quads in pairs(esp.ChamsQuads) do
				for _, quad in ipairs(quads) do
					quad.Visible = false
				end
			end
		end
	end

	if player == LocalPlayer or not player.Character then 
		HideAllESP()
		return 
	end

	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not (humanoid and rootPart and humanoid.Health > 0) then 
		HideAllESP()
		return 
	end

	local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude

	if distance > Config.ESP.MaxDistance then 
		HideAllESP()
		return 
	end

	local boxPosition, boxSize = UpdateBoxes(player, esp, character, humanoid, rootPart)

	if not boxPosition or not boxSize then
		HideAllESP()
		return
	end

	local screenHeight = boxSize.Y
	UpdateTracers(player, esp, rootPart)
	UpdateHealthBars(player, esp, character, humanoid, boxPosition, boxSize, screenHeight)
	UpdateNames(player, esp, character, rootPart, boxPosition, boxSize)

	UpdateSkeleton(player, esp, character)
	UpdateChams(player, character)
end

_G.ToggleRadar = function(enabled)
	Config.ESP.RadarEnabled = enabled
	if enabled and not _G.ESPRadarComponents.Background then
		InitRadar()
	end
end

function ToggleRadar(enabled)
	Config.ESP.RadarEnabled = enabled
	if enabled and not _G.ESPRadarComponents.Background then
		InitRadar()
	end
end

_G.ToggleDirectionalArrows = function(enabled)
	Config.ESP.DirectionalArrowsEnabled = enabled
	if not enabled then
		for player, arrow in pairs(_G.ESPDirectionalArrows) do
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
		end
	end
end

function ToggleDirectionalArrows(enabled)
	Config.ESP.DirectionalArrowsEnabled = enabled
	if not enabled then
		for player, arrow in pairs(_G.ESPDirectionalArrows) do
			arrow.Triangle.Visible = false
			arrow.DistanceText.Visible = false
		end
	end
end

InitRadar()

local lastESPUpdate = 0
local lastRadarUpdate = 0
local lastArrowUpdate = 0

RunService.RenderStepped:Connect(function()
	local currentTime = tick()

	if Config.ESP.Enabled and (currentTime - lastESPUpdate) >= Config.ESP.RefreshRate then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				if not _G.ESPDrawings[player] then
					CreateESP(player)
				end
				UpdateESP(player)
			end
		end
		lastESPUpdate = currentTime
	elseif not Config.ESP.Enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if _G.ESPDrawings[player] then
				local esp = _G.ESPDrawings[player]
				if esp.Box then for _, line in pairs(esp.Box) do line.Visible = false end end
				if esp.Tracer then esp.Tracer.Visible = false end
				if esp.HealthBar then
					esp.HealthBar.Outline.Visible = false
					esp.HealthBar.Fill.Visible = false
					esp.HealthBar.Text.Visible = false
				end
				if esp.Info then
					esp.Info.Name.Visible = false
					esp.Info.Distance.Visible = false
				end
				if esp.Skeleton then
					for _, line in pairs(esp.Skeleton) do line.Visible = false end
				end
				if esp.ChamsQuads then
					for partName, quads in pairs(esp.ChamsQuads) do
						for _, quad in ipairs(quads) do
							quad.Visible = false
						end
					end
				end
			end
			if _G.ESPHighlights[player] then
				_G.ESPHighlights[player].Enabled = false
			end
		end
	end

	if (currentTime - lastRadarUpdate) >= (1/30) then
		UpdateRadar()
		lastRadarUpdate = currentTime
	end

	if (currentTime - lastArrowUpdate) >= (1/30) then
		UpdateArrows()
		lastArrowUpdate = currentTime
	end
end)

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		CreateESP(player)
	end
end)

Players.PlayerRemoving:Connect(RemoveESP)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		CreateESP(player)
	end
end

task.wait()

_G.ESPLOADED = true
