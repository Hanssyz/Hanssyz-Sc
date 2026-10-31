--[[
    Hanssyz Sc | Final Auto-Spawn Version
    Fitur: Auto-Detect Spawn, Steal Satu-per-Satu, Minimize UI.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= KONFIGURASI =================
local Config = {
    HubName = "Hanssyz Sc",
    Version = "v18.0",
    -- [UDAH OTOMATIS] Kita ga pake koordinat manual lagi
    SafeZone = nil, 
    RemotePath = {"ToolTrigger", "Trigger"} 
}

local State = {
    Running = false,
    Minimized = false,
    Success = 0,
    Fail = 0,
    Rarity = "All",
    Blacklist = {}
}

local Colors = {
    Main = Color3.fromRGB(88, 166, 255),
    Succ = Color3.fromRGB(100, 255, 160),
    Danger = Color3.fromRGB(255, 120, 120),
    Bg = Color3.fromRGB(15, 18, 42),
    Card = Color3.fromRGB(28, 32, 58),
    Text = Color3.fromRGB(245, 248, 255),
    Sub = Color3.fromRGB(180, 190, 220)
}

-- ================= AUTO-DETECT SAFE ZONE =================
-- Fungsi buat nyari SpawnLocation di map
local function UpdateSafeZone()
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        Config.SafeZone = spawn.CFrame + Vector3.new(0, 3, 0)
    else
        -- Kalau ga nemu SpawnLocation (mungkin spawn-nya custom), kita simpen posisi lu sekarang
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Config.SafeZone = LocalPlayer.Character.HumanoidRootPart.CFrame
        end
    end
end

-- Jalanin auto-detect pas script di-load
task.spawn(function()
    task.wait(1) -- Tunggu map loading
    UpdateSafeZone()
end)

-- ================= UI SETUP =================
if PlayerGui:FindFirstChild("HanssyzUI") then PlayerGui.HanssyzUI:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name = "HanssyzUI"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 480, 0, 420)
Main.Position = UDim2.new(0.5, -240, 0.5, -210)
Main.BackgroundColor3 = Colors.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Colors.Main
MainStroke.Thickness = 2
MainStroke.Transparency = 0.3
MainStroke.Parent = Main

-- HEADER
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = Config.HubName .. " | " .. Config.Version
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Colors.Text
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -75, 0.5, -15)
MinBtn.BackgroundColor3 = Colors.Main
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextColor3 = Colors.Text
MinBtn.TextSize = 20
MinBtn.Parent = Header
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Colors.Danger
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Colors.Text
CloseBtn.TextSize = 16
CloseBtn.Parent = Header
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- CONTENT
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -40, 1, -80)
Content.Position = UDim2.new(0, 20, 0, 70)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- RARITY
local RarBox = Instance.new("Frame")
RarBox.Size = UDim2.new(1, 0, 0, 45)
RarBox.BackgroundColor3 = Colors.Card
RarBox.Parent = Content
local RarCorner = Instance.new("UICorner")
RarCorner.CornerRadius = UDim.new(0, 10)
RarCorner.Parent = RarBox

local RarLabel = Instance.new("TextLabel")
RarLabel.Size = UDim2.new(0.5, 0, 1, 0)
RarLabel.Position = UDim2.new(0, 15, 0, 0)
RarLabel.BackgroundTransparency = 1
RarLabel.Text = "Rarity Filter:"
RarLabel.Font = Enum.Font.GothamBold
RarLabel.TextColor3 = Colors.Sub
RarLabel.TextSize = 14
RarLabel.TextXAlignment = Enum.TextXAlignment.Left
RarLabel.Parent = RarBox

local DropBtn = Instance.new("TextButton")
DropBtn.Size = UDim2.new(0.4, 0, 0, 30)
DropBtn.Position = UDim2.new(0.55, 0, 0.5, -15)
DropBtn.BackgroundColor3 = Colors.Main
DropBtn.Text = "All"
DropBtn.Font = Enum.Font.GothamBold
DropBtn.TextColor3 = Colors.Text
DropBtn.TextSize = 13
DropBtn.Parent = RarBox
local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 8)
DropCorner.Parent = DropBtn

local DropMenu = Instance.new("ScrollingFrame")
DropMenu.Size = UDim2.new(0.4, 0, 0, 160)
DropMenu.Position = UDim2.new(0.55, 0, 1, 5)
DropMenu.BackgroundColor3 = Colors.Bg
DropMenu.BorderSizePixel = 0
DropMenu.Visible = false
DropMenu.CanvasSize = UDim2.new(0, 0, 0, 200)
DropMenu.ZIndex = 10
DropMenu.Parent = RarBox
local DropMenuCorner = Instance.new("UICorner")
DropMenuCorner.CornerRadius = UDim.new(0, 8)
DropMenuCorner.Parent = DropMenu
local DropMenuStroke = Instance.new("UIStroke")
DropMenuStroke.Color = Colors.Main
DropMenuStroke.Thickness = 1
DropMenuStroke.Parent = DropMenu

for i, r in ipairs({"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
    local Opt = Instance.new("TextButton")
    Opt.Size = UDim2.new(1, 0, 0, 30)
    Opt.Position = UDim2.new(0, 0, 0, (i-1)*30)
    Opt.BackgroundColor3 = Colors.Card
    Opt.BackgroundTransparency = 0.3
    Opt.Text = r
    Opt.Font = Enum.Font.Gotham
    Opt.TextColor3 = Colors.Text
    Opt.TextSize = 13
    Opt.ZIndex = 11
    Opt.Parent = DropMenu
    Opt.MouseButton1Click:Connect(function()
        State.Rarity = r
        DropBtn.Text = r
        DropMenu.Visible = false
    end)
end
DropBtn.MouseButton1Click:Connect(function() DropMenu.Visible = not DropMenu.Visible end)

-- TOGGLE
local TogBox = Instance.new("Frame")
TogBox.Size = UDim2.new(1, 0, 0, 60)
TogBox.Position = UDim2.new(0, 0, 0, 60)
TogBox.BackgroundColor3 = Colors.Card
TogBox.Parent = Content
local TogBoxCorner = Instance.new("UICorner")
TogBoxCorner.CornerRadius = UDim.new(0, 10)
TogBoxCorner.Parent = TogBox

local TogLabel = Instance.new("TextLabel")
TogLabel.Size = UDim2.new(0.7, 0, 1, 0)
TogLabel.Position = UDim2.new(0, 20, 0, 0)
TogLabel.BackgroundTransparency = 1
TogLabel.Text = "Auto Steal (One-by-One)"
TogLabel.Font = Enum.Font.GothamBold
TogLabel.TextColor3 = Colors.Text
TogLabel.TextSize = 16
TogLabel.TextXAlignment = Enum.TextXAlignment.Left
TogLabel.Parent = TogBox

local TogBtn = Instance.new("TextButton")
TogBtn.Size = UDim2.new(0, 55, 0, 28)
TogBtn.Position = UDim2.new(1, -75, 0.5, -14)
TogBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
TogBtn.Text = ""
TogBtn.Parent = TogBox
local TogBtnCorner = Instance.new("UICorner")
TogBtnCorner.CornerRadius = UDim.new(0, 14)
TogBtnCorner.Parent = TogBtn

local Knob = Instance.new("Frame")
Knob.Size = UDim2.new(0, 24, 0, 24)
Knob.Position = UDim2.new(0, 2, 0.5, -12)
Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Knob.Parent = TogBtn
local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(0, 12)
KnobCorner.Parent = Knob

-- MONITOR
local MonPanel = Instance.new("Frame")
MonPanel.Size = UDim2.new(1, 0, 0, 0)
MonPanel.Position = UDim2.new(0, 0, 0, 130)
MonPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 40)
MonPanel.ClipsDescendants = true
MonPanel.Visible = false
MonPanel.Parent = Content
local MonCorner = Instance.new("UICorner")
MonCorner.CornerRadius = UDim.new(0, 10)
MonCorner.Parent = MonPanel

local SucLbl = Instance.new("TextLabel")
SucLbl.Size = UDim2.new(0.5, 0, 0, 45)
SucLbl.Position = UDim2.new(0, 20, 0, 0)
SucLbl.BackgroundTransparency = 1
SucLbl.Text = "SUCCESS: 0"
SucLbl.Font = Enum.Font.GothamBold
SucLbl.TextColor3 = Colors.Succ
SucLbl.TextSize = 16
SucLbl.TextXAlignment = Enum.TextXAlignment.Left
SucLbl.Parent = MonPanel

local FailLbl = Instance.new("TextLabel")
FailLbl.Size = UDim2.new(0.5, -20, 0, 45)
FailLbl.Position = UDim2.new(0.5, 0, 0, 0)
FailLbl.BackgroundTransparency = 1
FailLbl.Text = "FAIL: 0"
FailLbl.Font = Enum.Font.GothamBold
FailLbl.TextColor3 = Colors.Danger
FailLbl.TextSize = 16
FailLbl.TextXAlignment = Enum.TextXAlignment.Right
FailLbl.Parent = MonPanel

local StatLbl = Instance.new("TextLabel")
StatLbl.Size = UDim2.new(1, -40, 0, 25)
StatLbl.Position = UDim2.new(0, 20, 0, 45)
StatLbl.BackgroundTransparency = 1
StatLbl.Text = "Status: Idle"
StatLbl.Font = Enum.Font.Gotham
StatLbl.TextColor3 = Colors.Sub
StatLbl.TextSize = 13
StatLbl.TextXAlignment = Enum.TextXAlignment.Left
StatLbl.Parent = MonPanel

-- ================= LOGIC STEAL =================
local function IsStolen(egg)
    for _, obj in pairs(State.Blacklist) do
        if obj == egg then return true end
    end
    return false
end

local function GetClosestEgg()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local closest, minDist = nil, math.huge

    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower():find("egg") and (v:IsA("Model") or v:IsA("BasePart")) then
            if State.Rarity ~= "All" and not v.Name:lower():find(State.Rarity:lower()) then continue end
            if IsStolen(v) then continue end

            local pos = v:IsA("Model") and v:GetPivot().Position or v.Position
            local dist = (hrp.Position - pos).Magnitude
            if dist < minDist then
                closest = v
                minDist = dist
            end
        end
    end
    return closest
end

local function DoSteal()
    local egg = GetClosestEgg()
    if not egg then return false end

    local success = pcall(function()
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local targetPos = egg:IsA("Model") and egg:GetPivot().Position or egg.Position
        
        -- 1. TP ke egg
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        task.wait(0.3)
        
        -- 2. Nembak Remote (Sesuai Spy Lu)
        local folder = ReplicatedStorage:FindFirstChild(Config.RemotePath[1])
        if folder then
            local remote = folder:FindFirstChild(Config.RemotePath[2])
            if remote then
                remote:FireServer(egg.Name .. " (Tool)")
            end
        end
        
        -- 3. Jeda Pas (1.2 detik)
        task.wait(1.2)
        
        -- 4. Balik Safe Zone (Pake Auto-Detect)
        if Config.SafeZone then
            hrp.CFrame = Config.SafeZone
        end
        task.wait(0.5)
    end)
    
    table.insert(State.Blacklist, egg)
    return success
end

local function Loop()
    task.spawn(function()
        while State.Running do
            StatLbl.Text = "Status: Mencari target..."
            local ok = DoSteal()
            
            if ok then
                State.Success = State.Success + 1
                SucLbl.Text = "SUCCESS: " .. State.Success
                StatLbl.Text = "Status: Sukses, lanjut..."
                StatLbl.TextColor3 = Colors.Succ
            else
                State.Fail = State.Fail + 1
                FailLbl.Text = "FAIL: " .. State.Fail
                StatLbl.Text = "Status: Gagal / Habis"
                StatLbl.TextColor3 = Colors.Danger
                task.wait(1)
            end
            task.wait(0.5)
        end
    end)
end

-- ================= EVENTS =================
TogBtn.MouseButton1Click:Connect(function()
    State.Running = not State.Running
    if State.Running then
        State.Blacklist = {}
        
        -- Panggil UpdateSafeZone lagi pas toggle dinyalain (jaga-jaga kalau lu pindah map)
        UpdateSafeZone()
        
        TweenService:Create(TogBtn, TweenInfo.new(0.2), {BackgroundColor3=Colors.Main}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position=UDim2.new(1,-26,0.5,-12)}):Play()
        MonPanel.Visible = true
        TweenService:Create(MonPanel, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,75)}):Play()
        Loop()
    else
        TweenService:Create(TogBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,55,80)}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position=UDim2.new(0,2,0.5,-12)}):Play()
        TweenService:Create(MonPanel, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,0)}):Play()
        StatLbl.Text = "Status: Idle"
        task.delay(0.3, function() MonPanel.Visible = false end)
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    if State.Minimized then return end
    State.Minimized = true
    Main.Visible = false
    
    local Icon = Instance.new("TextButton")
    Icon.Size = UDim2.new(0,50,0,50)
    Icon.Position = UDim2.new(0,20,0,100)
    Icon.BackgroundColor3 = Colors.Card
    Icon.Text = "H"
    Icon.Font = Enum.Font.GothamBold
    Icon.TextColor3 = Colors.Main
    Icon.TextSize = 24
    Icon.ZIndex = 50
    Icon.Parent = GUI
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 12)
    IconCorner.Parent = Icon
    local IconStroke = Instance.new("UIStroke")
    IconStroke.Color = Colors.Main
    IconStroke.Thickness = 2
    IconStroke.Parent = Icon
    
    Icon.MouseButton1Click:Connect(function()
        State.Minimized = false
        Main.Visible = true
        Icon:Destroy()
    end)
end)

CloseBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- Draggable (Hanya di Header)
local drag, dStart, sPos
Header.InputBegan:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
        drag=true; dStart=i.Position; sPos=Main.Position 
    end 
end)
Header.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
        drag=false 
    end 
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
    end
end)
