-- HyperShot client visual/aim assist for standard Roblox player characters.
-- F1: menu. F10: unload. Re-running replaces the previous instance.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local shared = (type(getgenv) == "function" and getgenv()) or _G
if type(shared.HypershotAssistUnload) == "function" then
    pcall(shared.HypershotAssistUnload)
end

local settings = {
    aimKey = Enum.UserInputType.MouseButton2,
    mode = "Hold",
    part = "Head",
    radius = 150,
    aimEnabled = true,
    espEnabled = true,
    visibleOnly = true,
    teamMode = "Auto", -- Auto, On, Off
    smoothness = 18,
    aimMethod = type(mousemoverel) == "function" and "Mouse" or "Camera",
}
local holding, toggled, binding, unloaded = false, false, false, false
local lockedPlayer = nil
local connections, overlays = {}, {}
local renderName = "HypershotAssistRender"

local gui = Instance.new("ScreenGui")
gui.Name = "HypershotAssist"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
local parented = false
if type(gethui) == "function" then
    parented = pcall(function()
        local root = gethui()
        if typeof(root) ~= "Instance" then error("No GUI root") end
        gui.Parent = root
    end)
end
if not parented then
    parented = pcall(function() gui.Parent = CoreGui end)
end
if not parented then gui.Parent = PlayerGui end

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
    BorderSizePixel = 0, Size = UDim2.fromOffset(250, 371),
    Position = UDim2.fromOffset(24, 120), ZIndex = 20,
}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, menu)
new("UIStroke", {Color = Color3.fromRGB(130, 45, 65), Thickness = 1}, menu)
new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromOffset(226, 31),
    Position = UDim2.fromOffset(12, 7), Text = "HYPERSHOT  |  F1 menu",
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
local espButton = button(75, "ESP + outline: ON")
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
local teamButton = button(273, "Team filter: Auto")
local methodButton = button(306, "Aim method: " .. settings.aimMethod)
local status = new("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.fromOffset(226, 24),
    Position = UDim2.fromOffset(12, 340), Text = "Players: 0 | FOV: 0",
    Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = Color3.fromRGB(180, 190, 190), ZIndex = 21,
}, menu)

table.insert(connections, aimButton.MouseButton1Click:Connect(function()
    settings.aimEnabled = not settings.aimEnabled
    aimButton.Text = "Aim: " .. (settings.aimEnabled and "ON" or "OFF")
end))
table.insert(connections, espButton.MouseButton1Click:Connect(function()
    settings.espEnabled = not settings.espEnabled
    espButton.Text = "ESP + outline: " .. (settings.espEnabled and "ON" or "OFF")
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
    settings.teamMode = settings.teamMode == "Auto" and "On"
        or settings.teamMode == "On" and "Off" or "Auto"
    teamButton.Text = "Team filter: " .. settings.teamMode
end))
table.insert(connections, methodButton.MouseButton1Click:Connect(function()
    settings.aimMethod = settings.aimMethod == "Mouse" and "Camera" or "Mouse"
    methodButton.Text = "Aim method: " .. settings.aimMethod
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
    for i = 1, 32 do
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
    entry.box = new("Frame", {
        Name = "ScreenBox", BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = false, ZIndex = 10,
    }, gui)
    new("UIStroke", {Color = Color3.fromRGB(255, 100, 100), Thickness = 1.5}, entry.box)
    entry.outline = new("Highlight", {
        Name = "HypershotOutline", FillTransparency = 1,
        OutlineColor = Color3.fromRGB(255, 65, 65),
        OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled = false,
    }, Workspace)
    overlays[player] = entry
    return entry
end

local function hide(entry)
    entry.dot.Visible = false
    entry.box.Visible = false
    entry.outline.Enabled = false
    for _, line in ipairs(entry.lines) do line.Visible = false end
end

local function filterTeams()
    if settings.teamMode == "On" then return true end
    if settings.teamMode == "Off" or not LocalPlayer.Team then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team ~= LocalPlayer.Team then
            return true
        end
    end
    return false
end

local function enemy(player, teamFilter)
    if player == LocalPlayer then return false end
    if teamFilter and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not char.Parent or (humanoid and humanoid.Health <= 0) then
        return false
    end
    return char:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function headPart(char)
    local possible = nil
    for _, descendant in ipairs(char:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local name = string.lower(descendant.Name)
            if name == "head" or name == "skull" or name == "headhitbox"
                or name == "head_hitbox" then
                return descendant
            end
            if not possible and (string.find(name, "head", 1, true)
                or string.find(name, "skull", 1, true))
                and not descendant:FindFirstAncestorOfClass("Accessory") then
                possible = descendant
            end
        end
    end
    return possible
end

local function aimPoint(char, zone, cf, size)
    if zone == "Head" then
        local head = headPart(char)
        return head and head.Position or cf:PointToWorldSpace(Vector3.new(0, size.Y * .37, 0))
    elseif zone == "Chest" then
        local chest = char:FindFirstChild("UpperTorso", true)
            or char:FindFirstChild("Torso", true)
        return chest and chest:IsA("BasePart") and chest.Position or cf.Position
    end
    local left = char:FindFirstChild("LeftFoot", true) or char:FindFirstChild("Left Leg", true)
    local right = char:FindFirstChild("RightFoot", true) or char:FindFirstChild("Right Leg", true)
    if left and right and left:IsA("BasePart") and right:IsA("BasePart") then
        return (left.Position + right.Position) / 2
    end
    return cf:PointToWorldSpace(Vector3.new(0, -size.Y * .43, 0))
end

local function projectWorld(camera, point)
    local p, onScreen = camera:WorldToViewportPoint(point)
    if not onScreen or p.Z <= 0 then return nil end
    return Vector2.new(p.X, p.Y)
end

local function project(camera, part)
    if not part or not part:IsA("BasePart") then return nil end
    return projectWorld(camera, part.Position)
end

local function drawBone(line, a, b)
    local delta = b - a
    line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    line.Size = UDim2.fromOffset(delta.Magnitude, 2)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.Visible = true
end

local function drawBox(entry, camera, cf, size)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local world = cf:PointToWorldSpace(Vector3.new(
                    x * size.X / 2, y * size.Y / 2, z * size.Z / 2))
                local screen = projectWorld(camera, world)
                if screen then
                    minX, minY = math.min(minX, screen.X), math.min(minY, screen.Y)
                    maxX, maxY = math.max(maxX, screen.X), math.max(maxY, screen.Y)
                end
            end
        end
    end
    if minX ~= math.huge then
        entry.box.Position = UDim2.fromOffset(minX, minY)
        entry.box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
        entry.box.Visible = true
    end
end

local function drawSkeleton(entry, camera, char, cf, size)
    if entry.rigChar ~= char then
        entry.rigChar, entry.joints = char, {}
        for _, joint in ipairs(char:GetDescendants()) do
            if joint:IsA("Motor6D") then table.insert(entry.joints, joint) end
        end
    end
    local count = 0
    for _, joint in ipairs(entry.joints) do
        if joint:IsA("Motor6D") and joint.Part0 and joint.Part1
            and joint.Part0:IsDescendantOf(char) and joint.Part1:IsDescendantOf(char) then
            local a, b = project(camera, joint.Part0), project(camera, joint.Part1)
            if a and b then
                count = count + 1
                if count <= #entry.lines then drawBone(entry.lines[count], a, b) end
            end
        end
    end
    if count >= 5 then return end
    for i = 1, count do entry.lines[i].Visible = false end
    count = 0

    local segments = char:FindFirstChild("UpperTorso", true) and r15 or r6
    for _, pair in ipairs(segments) do
        local a = project(camera, char:FindFirstChild(pair[1], true))
        local b = project(camera, char:FindFirstChild(pair[2], true))
        if a and b then
            count = count + 1
            drawBone(entry.lines[count], a, b)
        end
    end
    if count >= 4 then return end
    for i = 1, count do entry.lines[i].Visible = false end

    -- Last resort for a custom model without standard joints or part names.
    local function p(x, y)
        return projectWorld(camera, cf:PointToWorldSpace(
            Vector3.new(x * size.X, y * size.Y, 0)))
    end
    local points = {
        p(0, .39), p(0, .19), p(0, -.1), p(-.32, .17), p(-.42, -.08),
        p(.32, .17), p(.42, -.08), p(-.21, -.42), p(.21, -.42),
    }
    local links = {{1,2},{2,3},{2,4},{4,5},{2,6},{6,7},{3,8},{3,9}}
    for i, pair in ipairs(links) do
        local a, b = points[pair[1]], points[pair[2]]
        if a and b then drawBone(entry.lines[i], a, b) end
    end
end

local function visible(camera, char, point)
    local origin = camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {camera}
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local hit = Workspace:Raycast(origin, point - origin, params)
    return hit == nil or hit.Instance:IsDescendantOf(char)
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
        entry.box:Destroy()
        entry.outline:Destroy()
    end
    gui:Destroy()
    if shared.HypershotAssistUnload == unload then shared.HypershotAssistUnload = nil end
end
shared.HypershotAssistUnload = unload

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
    if UserInputService:GetFocusedTextBox() then return end
    -- Weapon scripts may mark M2 as handled. The bound aim key still needs it.
    if processed and not matches(input) then return end
    if matches(input) then
        if settings.mode == "Toggle" then toggled = not toggled else holding = true end
    end
end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if matches(input) then holding = false end
end))

RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value, function(dt)
    if unloaded then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    circle.Size = UDim2.fromOffset(settings.radius * 2, settings.radius * 2)
    circle.Visible = settings.aimEnabled
    local center = camera.ViewportSize / 2
    local bestPoint, bestScreen, bestPlayer, bestDistance = nil, nil, nil, settings.radius
    local detected, inCircle = 0, 0
    local teamFilter = filterTeams()

    for player, entry in pairs(overlays) do
        if player.Parent ~= Players then
            hide(entry)
            for _, line in ipairs(entry.lines) do line:Destroy() end
            entry.dot:Destroy()
            entry.box:Destroy()
            entry.outline:Destroy()
            overlays[player] = nil
        else
            hide(entry)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if enemy(player, teamFilter) then
            detected = detected + 1
            local char = player.Character
            local cf, size = char:GetBoundingBox()
            if settings.espEnabled then
                local entry = overlayFor(player)
                entry.outline.Adornee = char
                entry.outline.Enabled = true
                drawBox(entry, camera, cf, size)
                drawSkeleton(entry, camera, char, cf, size)
                local head = projectWorld(camera, aimPoint(char, "Head", cf, size))
                if head then
                    entry.dot.Position = UDim2.fromOffset(head.X, head.Y)
                    entry.dot.Visible = true
                end
            end
            if settings.aimEnabled then
                local point = aimPoint(char, settings.part, cf, size)
                if point then
                    local projected, onScreen = camera:WorldToViewportPoint(point)
                    if onScreen and projected.Z > 0 then
                        local distance = (Vector2.new(projected.X, projected.Y) - center).Magnitude
                        if distance <= settings.radius then inCircle = inCircle + 1 end
                        if (holding or toggled)
                            and distance <= settings.radius
                            and (not settings.visibleOnly or visible(camera, char, point)) then
                            local score = player == lockedPlayer and distance * .4 or distance
                            if score < bestDistance then
                                bestDistance, bestPoint = score, point
                                bestScreen, bestPlayer = Vector2.new(projected.X, projected.Y), player
                            end
                        end
                    end
                end
            end
        end
    end
    status.Text = "Players: " .. detected .. " | In FOV: " .. inCircle

    if bestPoint then
        lockedPlayer = bestPlayer
        local factor = math.clamp(dt * settings.smoothness, 0, 1)
        if settings.aimMethod == "Mouse" and type(mousemoverel) ~= "function" then
            settings.aimMethod = "Camera"
            methodButton.Text = "Aim method: Camera"
        end
        if settings.aimMethod == "Mouse" and type(mousemoverel) == "function" then
            local delta = bestScreen - center
            local ok = pcall(mousemoverel,
                math.floor(delta.X * factor + .5), math.floor(delta.Y * factor + .5))
            if not ok then
                settings.aimMethod = "Camera"
                methodButton.Text = "Aim method: Camera"
            end
        end
        if settings.aimMethod == "Camera" then
            local origin = camera.CFrame.Position
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(origin, bestPoint), factor)
        end
    else
        lockedPlayer = nil
    end
end)
