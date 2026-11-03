--[[
    AUTO STEAL EGG - CUSTOM BUILD v2
    Delta Executor Compatible
    + Minimize panel with "H" logo
    Made for Boss by Kyriel
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- ============ CONFIG ============
local CONFIG = {
    autoSteal = true,
    tpSpeed = 350,
    scanRadius = 1000,
    eggNameContains = {"egg"},
    baseNameContains = {"base"},
    autoTreadmill = true,
    antiAfk = true,
    espEnabled = true,
}

-- ============ STATE ============
local carryingEgg = false
local currentEgg = nil
local currentBase = nil
local running = true

-- ============ UTIL ============
local function getNameMatch(name, patterns)
    local lower = name:lower()
    for _, p in ipairs(patterns) do
        if lower:find(p:lower()) then return true end
    end
    return false
end

local function getMyBase()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            if getNameMatch(v.Name, CONFIG.baseNameContains) then
                local full = v:GetFullName():lower()
                if full:find(lp.Name:lower()) then
                    return v
                end
                local ok, owner = pcall(function() return v:GetAttribute("Owner") end)
                if ok and owner == lp.Name then return v end
            end
        end
    end
    return nil
end

local function getAllEggs()
    local eggs = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and getNameMatch(v.Name, CONFIG.eggNameContains) then
            if v.Parent and v.Parent:FindFirstChild("Humanoid") == nil then
                local dist = (v.Position - hrp.Position).Magnitude
                if dist <= CONFIG.scanRadius then
                    table.insert(eggs, v)
                end
            end
        end
    end
    return eggs
end

local function getNearestEgg()
    local eggs = getAllEggs()
    local nearest, nearestDist = nil, math.huge
    for _, egg in ipairs(eggs) do
        local dist = (egg.Position - hrp.Position).Magnitude
        if dist < nearestDist then
            nearest, nearestDist = egg, dist
        end
    end
    return nearest, nearestDist
end

local function tpTo(pos)
    if not hrp or not hrp.Parent then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

local function tpToPart(part)
    if not part or not part.Parent then return end
    local pos = part:IsA("BasePart") and part.Position or part:GetPivot().Position
    tpTo(pos)
end

local function fireProximityPrompts(origin)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                local pos = parent:IsA("BasePart") and parent.Position or parent:GetPivot().Position
                if (pos - origin).Magnitude < 15 then
                    if v.Enabled then
                        pcall(function() v:InputHoldBegin() end)
                        task.wait(0.2)
                        pcall(function() v:InputHoldEnd() end)
                    end
                end
            end
        end
    end
end

local function fireRemotes()
    local remotes = {}
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local name = v.Name:lower()
            if name:find("steal") or name:find("egg") or name:find("take")
               or name:find("pick") or name:find("grab") or name:find("interact") then
                table.insert(remotes, v)
            end
        end
    end
    for _, r in ipairs(remotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer()
            else
                r:InvokeServer()
            end
        end)
        task.wait(0.05)
    end
end

-- ============ ESP ============
local espFolder = Instance.new("Folder")
espFolder.Name = "KyrielESP"
espFolder.Parent = game.CoreGui

local function createESP(part, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EGG_ESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = part
    billboard.Parent = espFolder

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "EGG"
    text.TextColor3 = color or Color3.fromRGB(0, 255, 100)
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Parent = billboard
    return billboard
end

local espCache = {}
local function updateESP()
    if not CONFIG.espEnabled then return end
    local eggs = getAllEggs()
    local seen = {}
    for _, egg in ipairs(eggs) do
        seen[egg] = true
        if not espCache[egg] then
            espCache[egg] = createESP(egg)
        end
    end
    for part, gui in pairs(espCache) do
        if not seen[part] or not part.Parent then
            gui:Destroy()
            espCache[part] = nil
        end
    end
end

-- ============ MAIN LOOP ============
local function mainLoop()
    while running do
        pcall(function()
            char = lp.Character
            if char then
                hrp = char:FindFirstChild("HumanoidRootPart")
                humanoid = char:FindFirstChild("Humanoid")
            end
            if not hrp or not humanoid then task.wait(1) return end
            if humanoid.Health <= 0 then task.wait(1) return end

            if CONFIG.autoSteal then
                local egg = getNearestEgg()
                if egg then
                    tpToPart(egg)
                    task.wait(0.15)
                    fireProximityPrompts(egg.Position)
                    task.wait(0.1)
                    fireRemotes()
                    task.wait(0.2)

                    local base = getMyBase()
                    if base then
                        tpToPart(base)
                        task.wait(0.2)
                        fireProximityPrompts(base:IsA("BasePart") and base.Position or base:GetPivot().Position)
                    end
                end
            end
            task.wait(0.1)
        end)
        task.wait(0.1)
    end
end

-- ============ ANTI AFK ============
if CONFIG.antiAfk then
    task.spawn(function()
        while running do
            pcall(function()
                if lp.Character then
                    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Jump = true end
                end
            end)
            task.wait(30)
        end
    end)
end

-- ============ AUTO TREADMILL ============
if CONFIG.autoTreadmill then
    task.spawn(function()
        while running do
            pcall(function()
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name:lower():find("treadmill") then
                        if v:IsA("BasePart") then
                            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:MoveTo(v.Position)
                            end
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "KyrielStealEgg"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Panel utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 200)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Visible = true
frame.Parent = gui

-- Tombol minimize (—) di kanan atas title
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -30, 0, 2)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
minBtn.BorderSizePixel = 0
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(255, 200, 60)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "Kyriel | Steal an Egg"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

-- === TOMBOL MINIMIZE BUNDAR "H" ===
local hButton = Instance.new("TextButton")
hButton.Name = "HMinimized"
hButton.Size = UDim2.new(0, 50, 0, 50)
hButton.Position = UDim2.new(0, 20, 0, 20)
hButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
hButton.BorderSizePixel = 0
hButton.Text = "H"
hButton.TextColor3 = Color3.fromRGB(0, 255, 150)
hButton.Font = Enum.Font.GothamBlack
hButton.TextSize = 26
hButton.Visible = false
hButton.Active = true
hButton.Draggable = true
hButton.Parent = gui

-- Bikin H bundar
local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(1, 0)
hCorner.Parent = hButton

-- Stroke biar keliatan keren
local hStroke = Instance.new("UIStroke")
hStroke.Color = Color3.fromRGB(0, 255, 150)
hStroke.Thickness = 2
hStroke.Parent = hButton

-- Panel utama juga dibikin rounded dikit
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(0, 8)
fCorner.Parent = frame

-- === LOGIC MINIMIZE / RESTORE ===
local function minimize()
    frame.Visible = false
    hButton.Visible = true
    -- posisi H ngikutin posisi frame terakhir
    hButton.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y)
end

local function restore()
    hButton.Visible = false
    frame.Visible = true
    frame.Position = UDim2.new(0, hButton.AbsolutePosition.X, 0, hButton.AbsolutePosition.Y)
end

minBtn.MouseButton1Click:Connect(minimize)
hButton.MouseButton1Click:Connect(restore)

-- Tombol-tombol fitur
local function makeBtn(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local btnSteal = makeBtn("Auto Steal: ON", 40, function()
    CONFIG.autoSteal = not CONFIG.autoSteal
    btnSteal.Text = "Auto Steal: " .. (CONFIG.autoSteal and "ON" or "OFF")
end)

local btnESP = makeBtn("ESP: ON", 73, function()
    CONFIG.espEnabled = not CONFIG.espEnabled
    btnESP.Text = "ESP: " .. (CONFIG.espEnabled and "ON" or "OFF")
    if not CONFIG.espEnabled then
        for _, g in pairs(espCache) do g:Destroy() end
        espCache = {}
    end
end)

local btnTread = makeBtn("Treadmill: ON", 106, function()
    CONFIG.autoTreadmill = not CONFIG.autoTreadmill
    btnTread.Text = "Treadmill: " .. (CONFIG.autoTreadmill and "ON" or "OFF")
end)

local btnKill = makeBtn("Destroy GUI", 139, function()
    running = false
    gui:Destroy()
    for _, g in pairs(espCache) do g:Destroy() end
end)

-- ============ START ============
task.spawn(mainLoop)

task.spawn(function()
    while running do
        pcall(updateESP)
        task.wait(1)
    end
end)

print("[Kyriel] Script v2 loaded. Minimize pake tombol H, boss.")
