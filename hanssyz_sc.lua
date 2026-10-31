--[[
    Hanssyz Sc | Steal An Egg Premium Hub
    Version: 2.0 (Extended & Detailed)
    Features: Multi-tab UI, Live Monitor, Smooth Animations, Notification System
]]

-- ==========================================
-- 1. SERVICES & KONFIGURASI
-- ==========================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    HubName = "Hanssyz Sc",
    Version = "v2.0",
    MainColor = Color3.fromRGB(88, 166, 255),   -- Biru Neon
    AccentColor = Color3.fromRGB(190, 130, 255),-- Ungu
    SuccessColor = Color3.fromRGB(100, 255, 160),-- Hijau
    DangerColor = Color3.fromRGB(255, 120, 120),-- Merah
    BgMain = Color3.fromRGB(15, 18, 42),        -- Navy Gelap
    BgCard = Color3.fromRGB(28, 32, 58),        -- Card Navy
    TextMain = Color3.fromRGB(245, 248, 255),   -- Putih
    TextSub = Color3.fromRGB(180, 190, 220),    -- Abu-abu kebiruan
    Font = Enum.Font.GothamBold,
    FontRegular = Enum.Font.Gotham
}

local State = {
    Running = false,
    SuccessCount = 0,
    FailCount = 0,
    ActiveTab = "Home"
}

-- ==========================================
-- 2. UTILITY FUNCTIONS (Helper)
-- ==========================================
local function Create(className, properties, parent)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color,
        Thickness = thickness,
        Transparency = transparency or 0
    }, parent)
end

local function Notify(title, text, color)
    local notifyFrame = Create("Frame", {
        Size = UDim2.new(0, 250, 0, 60),
        Position = UDim2.new(1, -270, 0, 20),
        BackgroundColor3 = Config.BgCard,
        BorderSizePixel = 0,
        ZIndex = 100
    }, PlayerGui.HanssyzUI)
    
    AddCorner(notifyFrame, 10)
    AddStroke(notifyFrame, color, 2, 0)
    
    Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        Font = Config.Font,
        TextColor3 = color,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101
    }, notifyFrame)
    
    Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1,
        Text = text,
        Font = Config.FontRegular,
        TextColor3 = Config.TextMain,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101
    }, notifyFrame)
    
    local tweenIn = TweenService:Create(notifyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -270, 0, 20)
    })
    -- Start offscreen
    notifyFrame.Position = UDim2.new(1, 0, 0, 20)
    tweenIn:Play()
    
    task.delay(3, function()
        local tweenOut = TweenService:Create(notifyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 0, 0, 20)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notifyFrame:Destroy()
    end)
end

-- ==========================================
-- 3. UI SETUP (ScreenGui & Main Frame)
-- ==========================================
if PlayerGui:FindFirstChild("HanssyzUI") then
    PlayerGui.HanssyzUI:Destroy()
end

local ScreenGui = Create("ScreenGui", {
    Name = "HanssyzUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local MainFrame = Create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 560, 0, 420),
    Position = UDim2.new(0.5, -280, 0.5, -210),
    BackgroundColor3 = Config.BgMain,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true
}, ScreenGui)

AddCorner(MainFrame, 16)
AddStroke(MainFrame, Config.MainColor, 1, 0.5)

-- Background Gradient & Animasi Orb
local BgFrame = Create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(20, 22, 45),
    ZIndex = 1
}, MainFrame)

local BgGradient = Create("UIGradient", {
    Rotation = 45,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.BgMain),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 22, 58))
    })
}, BgFrame)

local function CreateOrb(color, size, startX, startY)
    local orb = Create("Frame", {
        Size = UDim2.new(0, size, 0, size),
        Position = UDim2.new(0, startX, 0, startY),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        ZIndex = 1
    }, BgFrame)
    AddCorner(orb, size / 2)
    
    task.spawn(function()
        local t = 0
        while orb.Parent do
            t = t + task.wait(0.03)
            orb.Position = UDim2.new(0, startX + math.sin(t) * 50, 0, startY + math.cos(t) * 50)
        end
    end)
end

CreateOrb(Config.MainColor, 150, -50, -50)
CreateOrb(Config.AccentColor, 120, 400, 250)

-- ==========================================
-- 4. SIDEBAR & HEADER
-- ==========================================
local Sidebar = Create("Frame", {
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Config.BgCard,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 5
}, MainFrame)

local Header = Create("Frame", {
    Size = UDim2.new(1, -140, 0, 60),
    Position = UDim2.new(0, 140, 0, 0),
    BackgroundTransparency = 1,
    ZIndex = 5
}, MainFrame)

Create("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text = Config.HubName .. " | " .. Config.Version,
    Font = Config.Font,
    TextColor3 = Config.TextMain,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5
}, Header)

local MinimizeBtn = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -70, 0.5, -15),
    BackgroundColor3 = Config.DangerColor,
    Text = "-",
    Font = Config.Font,
    TextColor3 = Config.TextMain,
    TextSize = 18,
    ZIndex = 6
}, Header)
AddCorner(MinimizeBtn, 6)

local CloseBtn = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(255, 80, 80),
    Text = "X",
    Font = Config.Font,
    TextColor3 = Config.TextMain,
    TextSize = 14,
    ZIndex = 6
}, Header)
AddCorner(CloseBtn, 6)

-- ==========================================
-- 5. TAB NAVIGATION
-- ==========================================
local ContentArea = Create("Frame", {
    Size = UDim2.new(1, -160, 1, -80),
    Position = UDim2.new(0, 150, 0, 70),
    BackgroundTransparency = 1,
    ZIndex = 5,
    ClipsDescendants = true
}, MainFrame)

local Pages = {}
local TabButtons = {}

local function CreatePage(name)
    local page = Create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ZIndex = 5
    }, ContentArea)
    Pages[name] = page
    return page
end

local HomePage = CreatePage("Home")
local SettingsPage = CreatePage("Settings")

local function CreateTabBtn(name, yPos)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = Config.MainColor,
        BackgroundTransparency = 1,
        Text = "  " .. name,
        Font = Config.Font,
        TextColor3 = Config.TextSub,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    }, Sidebar)
    AddCorner(btn, 8)
    TabButtons[name] = btn
    
    btn.MouseEnter:Connect(function()
        if State.ActiveTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.9}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if State.ActiveTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        State.ActiveTab = name
        for tabName, page in pairs(Pages) do
            page.Visible = (tabName == name)
        end
        for tabName, tBtn in pairs(TabButtons) do
            if tabName == name then
                TweenService:Create(tBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, TextColor3 = Config.TextMain}):Play()
            else
                TweenService:Create(tBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Config.TextSub}):Play()
            end
        end
    end)
end

CreateTabBtn("Home", 20)
CreateTabBtn("Settings", 70)

-- ==========================================
-- 6. HOME PAGE (Auto Steal & Monitor)
-- ==========================================
local FeatureCard = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 60),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = Config.BgCard,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0
}, HomePage)
AddCorner(FeatureCard, 10)

Create("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text = "Auto Steal (Steal An Egg)",
    Font = Config.Font,
    TextColor3 = Config.TextMain,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, FeatureCard)

local ToggleBtn = Create("TextButton", {
    Size = UDim2.new(0, 50, 0, 26),
    Position = UDim2.new(1, -70, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(50, 55, 80),
    Text = "",
    ZIndex = 6
}, FeatureCard)
AddCorner(ToggleBtn, 13)

local Knob = Create("Frame", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(0, 2, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BorderSizePixel = 0
}, ToggleBtn)
AddCorner(Knob, 11)

-- Monitor Panel
local MonitorPanel = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 0),
    Position = UDim2.new(0, 10, 0, 80),
    BackgroundColor3 = Color3.fromRGB(18, 22, 40),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false
}, HomePage)
AddCorner(MonitorPanel, 10)

local SuccessLbl = Create("TextLabel", {
    Size = UDim2.new(0.5, 0, 0, 40),
    Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text = "SUCCESS: 0",
    Font = Config.Font,
    TextColor3 = Config.SuccessColor,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, MonitorPanel)

local FailLbl = Create("TextLabel", {
    Size = UDim2.new(0.5, -20, 0, 40),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "FAIL: 0",
    Font = Config.Font,
    TextColor3 = Config.DangerColor,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Right
}, MonitorPanel)

local StatusLbl = Create("TextLabel", {
    Size = UDim2.new(1, -40, 0, 25),
    Position = UDim2.new(0, 20, 1, 5),
    BackgroundTransparency = 1,
    Text = "Status: Idle",
    Font = Config.FontRegular,
    TextColor3 = Config.TextSub,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, MonitorPanel)

-- ==========================================
-- 7. SETTINGS PAGE
-- ==========================================
local SettingsCard = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 100),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = Config.BgCard,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0
}, SettingsPage)
AddCorner(SettingsCard, 10)

Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1,
    Text = "Settings",
    Font = Config.Font,
    TextColor3 = Config.TextMain,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, SettingsCard)

Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.new(0, 10, 0, 40),
    BackgroundTransparency = 1,
    Text = "Auto Steal Speed: (Coming Soon)\nESP Color: (Coming Soon)",
    Font = Config.FontRegular,
    TextColor3 = Config.TextSub,
    TextSize = 12,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextXAlignment = Enum.TextXAlignment.Left
}, SettingsCard)

-- ==========================================
-- 8. LOGIC AUTO STEAL (DUMMY & CORE)
-- ==========================================
local EGG_NAME = "Egg" 
local REMOTE_NAME = "RemoteEvent" 

local function GetClosestEgg()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp, closest, minDist = char.HumanoidRootPart, nil, math.huge
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:find(EGG_NAME) then
            local dist = (hrp.Position - v.Position).Magnitude
            if dist < minDist then closest, minDist = v, dist end
        end
    end
    return closest
end

local function ExecuteSteal()
    local egg = GetClosestEgg()
    if not egg then 
        StatusLbl.Text = "Status: Egg Kosong"
        return false 
    end

    local success, err = pcall(function()
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = egg.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
        
        local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        else
            local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
            if remote then remote:FireServer(egg) end
        end
        
        task.wait(0.3)
        hrp.CFrame = CFrame.new(0, 10, 0) 
    end)
    
    return success
end

local function AutoStealLoop()
    task.spawn(function()
        while State.Running do
            StatusLbl.Text = "Status: Mencari & Mencuri..."
            StatusLbl.TextColor3 = Config.TextSub
            
            local ok = ExecuteSteal()
            
            if ok then
                State.SuccessCount = State.SuccessCount + 1
                SuccessLbl.Text = "SUCCESS: " .. State.SuccessCount
                StatusLbl.Text = "Status: Berhasil!"
                StatusLbl.TextColor3 = Config.SuccessColor
            else
                State.FailCount = State.FailCount + 1
                FailLbl.Text = "FAIL: " .. State.FailCount
                StatusLbl.Text = "Status: Gagal / Error"
                StatusLbl.TextColor3 = Config.DangerColor
            end
            
            task.wait(1)
        end
    end)
end

-- ==========================================
-- 9. EVENT LISTENERS
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    State.Running = not State.Running
    
    if State.Running then
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Config.MainColor}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -24, 0.5, -11)}):Play()
        
        MonitorPanel.Visible = true
        TweenService:Create(MonitorPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -20, 0, 60)
        }):Play()
        
        Notify("Auto Steal", "Fitur berhasil dinyalakan!", Config.SuccessColor)
        AutoStealLoop()
    else
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 55, 80)}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -11)}):Play()
        
        TweenService:Create(MonitorPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(1, -20, 0, 0)
        }):Play()
        
        StatusLbl.Text = "Status: Idle"
        task.delay(0.3, function() MonitorPanel.Visible = false end)
        Notify("Auto Steal", "Fitur dimatikan.", Config.DangerColor)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("[Hanssyz Sc] UI ditutup.")
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    -- Simple minimize logic (hide main frame)
    MainFrame.Visible = false
    task.wait(1)
    MainFrame.Visible = true
end)

-- Draggable
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Default Tab
TabButtons["Home"].MouseButton1Click:Wait() -- Auto trigger home tab
