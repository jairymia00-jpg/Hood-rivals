-- TTK Testing client visual/aim assist for standard Roblox player characters.
-- F1: menu. F10: unload. Re-running replaces the previous instance.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local shared = (type(getgenv) == "function" and getgenv()) or _G
if type(shared.TTKTestingAssistUnload) == "function" then
    pcall(shared.TTKTestingAssistUnload)
end

local settings = {
    aimKey = Enum.UserInputType.MouseButton2,
    mode = "Hold",
    part = "Head",
    radius = 150,
    aimEnabled = true,
    espEnabled = true,
    visibleOnly = true,
    teamFilter = false, -- deathmatch default; turn on in team modes
    smoothness = 18,
}
local holding, toggled, binding, unloaded = false, false, false, false
local connections, overlays = {}, {}
local renderName = "TTKTestingAssistRender"

local gui = Instance.new("ScreenGui")
gui.Name = "TTKTestingAssist"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
local ok = pcall(function() gui.Parent = CoreGui end)
if not ok then gui.Parent = PlayerGui end

local function new(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props) do obj[key] = value end
    obj.Parent = parent
    return obj
end

local circle = new("Frame", {
    Name = "FOV", BackgroundTransparency = 1, Size = UDim2.fromOffset(300, 300),
    AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
    ZIndex = 4,
}, gui)
new("UICorner", {CornerRadius = UDim.new(1, 0)}, circle)
new("UIStroke", {Color = Color3.fromRGB(255, 72, 72), Thickness = 1.5, Transparency = .1}, circle)

local menu = new("Frame", {
    Name = "Menu", BackgroundColor3 = Color3.fromRGB(22, 22, 28),
    BorderSizePixel = 0, Size = UDim2.fromOffset(250, 338),
    Position = UDim2.fromOffset(24, 120), ZIndex = 20,
}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, menu)
new("UIStroke", {Color = Color3.fromRGB(130, 45, 65), Thickness = 1}, menu)
new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromOffset(226, 31),
    Position = UDim2.fromOffset(12, 7), Text = "TTK TESTING  |  F1 menu",
    Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 21,
}, menu)

local function button(y, value)
    local b = new("TextButton", {
        BackgroundColor3 = Color3.fromRGB(38, 38, 47), BorderSizePixel = 0,
        Size = UDim2.fromOffset(226, 29), Position = UDim2.fromOffset(12, y),
        Text = value, Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = Color3.fromRGB(235, 235, 240), ZIndex = 21,
    }, menu)
    new("UICorner", {CornerRadius = UDim.new(0, 5)}, b)
    return b
end

local aimButton = button(42, "Aim: ON")
local espButton = button(75, "Skeleton ESP: ON")
local modeButton = button(108, "Mode: Hold")
local keyButton = button(141, "Aim key: MouseButton2")
local partButton = button(174, "Target: Head")
local sightButton = button(207, "Visible only: ON")
local minusButton = button(240, "FOV  -")
minusButton.Size = UDim2.fromOffset(70, 29)
local radiusButton = button(240, "150 px")
radiusButton.Position = UDim2.fromOffset(88, 240)
radiusButton.Size = UDim2.fromOffset(74, 29)
radiusButton.AutoButtonColor = false
local plusButton = button(240, "+  FOV")
plusButton.Position = UDim2.fromOffset(166, 240)
plusButton.Size = UDim2.fromOffset(72, 29)
local teamButton = button(273, "Team filter: OFF (FFA)")
local status = new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromOffset(226, 24),
    Position = UDim2.fromOffset(12, 307), Text = "Targets: 0",
    Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = Color3.fromRGB(180, 190, 190), ZIndex = 21,
}, menu)

table.insert(connections, aimButton.MouseButton1Click:Connect(function()
    settings.aimEnabled = not settings.aimEnabled
    aimButton.Text = "Aim: " .. (settings.aimEnabled and "ON" or "OFF")
end))
table.insert(connections, espButton.MouseButton1Click:Connect(function()
    settings.espEnabled = not settings.espEnabled
    espButton.Text = "Skeleton ESP: " .. (settings.espEnabled and "ON" or "OFF")
end))
table.insert(connections, modeButton.MouseButton1Click:Connect(function()
    settings.mode = settings.mode == "Hold" and "Toggle" or "Hold"
    holding, toggled = false, false
    modeButton.Text = "Mode: " .. settings.mode
end))
table.insert(connections, keyButton.MouseButton1Click:Connect(function()
    binding = true
    keyButton.Text = "Press a key / mouse button..."
end))
table.insert(connections, partButton.MouseButton1Click:Connect(function()
    settings.part = settings.part == "Head" and "Chest"
        or settings.part == "Chest" and "Feet" or "Head"
    partButton.Text = "Target: " .. settings.part
end))
table.insert(connections, sightButton.MouseButton1Click:Connect(function()
    settings.visibleOnly = not settings.visibleOnly
    sightButton.Text = "Visible only: " .. (settings.visibleOnly and "ON" or "OFF")
end))
table.insert(connections, teamButton.MouseButton1Click:Connect(function()
    settings.teamFilter = not settings.teamFilter
    teamButton.Text = settings.teamFilter and "Team filter: ON" or "Team filter: OFF (FFA)"
end))
local function changeRadius(delta)
    settings.radius = math.clamp(settings.radius + delta, 40, 400)
    radiusButton.Text = settings.radius .. " px"
end
table.insert(connections, minusButton.MouseButton1Click:Connect(function() changeRadius(-20) end))
table.insert(connections, plusButton.MouseButton1Click:Connect(function() changeRadius(20) end))

local r15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}
local r6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function overlayFor(player)
    if overlays[player] then return overlays[player] end
    local entry = {lines = {}}
    for i = 1, #r15 do
        entry.lines[i] = new("Frame", {
            Name = "Bone", BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0, AnchorPoint = Vector2.new(.5, .5),
            Size = UDim2.fromOffset(1, 2), Visible = false, ZIndex = 11,
        }, gui)
    end
    entry.dot = new("Frame", {
        Name = "HeadDot", BackgroundColor3 = Color3.fromRGB(255, 30, 30),
        BorderSizePixel = 0, AnchorPoint = Vector2.new(.5, .5),
        Size = UDim2.fromOffset(8, 8), Visible = false, ZIndex = 12,
    }, gui)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, entry.dot)
    overlays[player] = entry
    return entry
end

local function hide(entry)
    entry.dot.Visible = false
    for _, line in ipairs(entry.lines) do line.Visible = false end
end

local function enemy(player)
    if player == LocalPlayer then return false end
    if settings.teamFilter and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return char and humanoid and humanoid.Health > 0
end

local function project(camera, part)
    if not part or not part:IsA("BasePart") then return nil end
    local p, onScreen = camera:WorldToViewportPoint(part.Position)
    if not onScreen or p.Z <= 0 then return nil end
    return Vector2.new(p.X, p.Y)
end

local function drawBone(line, a, b)
    local delta = b - a
    line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    line.Size = UDim2.fromOffset(delta.Magnitude, 2)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.Visible = true
end

local function aimPoint(char)
    if settings.part == "Head" then
        local part = char:FindFirstChild("Head")
        return part and part.Position
    elseif settings.part == "Chest" then
        local part = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        return part and part.Position
    else
        local left = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
        local right = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg")
        if left and right then return (left.Position + right.Position) / 2 end
        return (left or right) and (left or right).Position
    end
end

local function visible(camera, char, point)
    local origin = camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}
    params.IgnoreWater = true
    local hit = Workspace:Raycast(origin, point - origin, params)
    return hit ~= nil and hit.Instance:IsDescendantOf(char)
end

local function matches(input)
    if settings.aimKey.EnumType == Enum.KeyCode then
        return input.KeyCode == settings.aimKey
    end
    return input.UserInputType == settings.aimKey
end

local function unload()
    if unloaded then return end
    unloaded = true
    RunService:UnbindFromRenderStep(renderName)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, entry in pairs(overlays) do
        for _, line in ipairs(entry.lines) do line:Destroy() end
        entry.dot:Destroy()
    end
    gui:Destroy()
    if shared.TTKTestingAssistUnload == unload then shared.TTKTestingAssistUnload = nil end
end
shared.TTKTestingAssistUnload = unload

table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.F10 then unload(); return end
    if binding then
        if input.KeyCode == Enum.KeyCode.Escape then
            binding = false
            keyButton.Text = "Aim key: " .. settings.aimKey.Name
            return
        end
        local chosen = input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode or input.UserInputType
        if chosen ~= Enum.KeyCode.Unknown
            and chosen ~= Enum.KeyCode.F1 and chosen ~= Enum.KeyCode.F10
            and (input.UserInputType == Enum.UserInputType.Keyboard
                or input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3) then
            settings.aimKey = chosen
            holding, toggled, binding = false, false, false
            keyButton.Text = "Aim key: " .. chosen.Name
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.F1 then menu.Visible = not menu.Visible; return end
    if processed or UserInputService:GetFocusedTextBox() then return end
    if matches(input) then
        if settings.mode == "Toggle" then toggled = not toggled else holding = true end
    end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if matches(input) then holding = false end
end))

RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if unloaded then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    circle.Size = UDim2.fromOffset(settings.radius * 2, settings.radius * 2)
    circle.Visible = settings.aimEnabled
    local center = camera.ViewportSize / 2
    local bestPoint, bestDistance = nil, settings.radius
    local detected = 0

    for player, entry in pairs(overlays) do
        if player.Parent ~= Players then
            hide(entry)
            for _, line in ipairs(entry.lines) do line:Destroy() end
            entry.dot:Destroy()
            overlays[player] = nil
        else
            hide(entry)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if enemy(player) then
            detected = detected + 1
            local char = player.Character
            if settings.espEnabled then
                local entry = overlayFor(player)
                local segments = char:FindFirstChild("UpperTorso") and r15 or r6
                for i, pair in ipairs(segments) do
                    local a = project(camera, char:FindFirstChild(pair[1]))
                    local b = project(camera, char:FindFirstChild(pair[2]))
                    if a and b then drawBone(entry.lines[i], a, b) end
                end
                local head = project(camera, char:FindFirstChild("Head"))
                if head then
                    entry.dot.Position = UDim2.fromOffset(head.X, head.Y)
                    entry.dot.Visible = true
                end
            end
            if settings.aimEnabled and (holding or toggled) then
                local point = aimPoint(char)
                if point then
                    local projected, onScreen = camera:WorldToViewportPoint(point)
                    if onScreen and projected.Z > 0 then
                        local distance = (Vector2.new(projected.X, projected.Y) - center).Magnitude
                        if distance <= bestDistance
                            and (not settings.visibleOnly or visible(camera, char, point)) then
                            bestDistance, bestPoint = distance, point
                        end
                    end
                end
            end
        end
    end
    status.Text = "Targets: " .. detected

    if bestPoint then
        local origin = camera.CFrame.Position
        camera.CFrame = camera.CFrame:Lerp(
            CFrame.lookAt(origin, bestPoint), math.clamp(dt * settings.smoothness, 0, 1))
    end
end)
