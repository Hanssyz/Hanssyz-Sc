--[[
    =========================================
    HANSSYZ UI + STEAL AN EGG LOGIC (V5)
    =========================================
    Fitur:
    - Custom UI (Biru, Minimize, Unload)
    - Player: WalkSpeed, JumpPower
    - Farm: Auto Steal (Trigger), Auto Teleport, Auto Carry
    - Visuals: Fullbright
    - Misc: Anti-AFK
--]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Konfigurasi Warna
local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Sidebar = Color3.fromRGB(15, 15, 20),
    Accent = Color3.fromRGB(0, 150, 255), -- Biru
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    ElementBg = Color3.fromRGB(30, 30, 35)
}

-- Hapus UI lama kalo ada
if CoreGui:FindFirstChild("HanssyzUI") then
    CoreGui.HanssyzUI:Destroy()
end

-- === STATE LOGIC (PENTING) ===
local Features = {
    AutoSteal = false,
    AutoTeleport = false,
    WalkSpeed = false,
    JumpPower = false,
    Fullbright = false,
    AntiAFK = false
}

-- === REMOTE GAME SETUP ===
local Networking = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking")
local TriggerEvent = Networking:WaitForChild("RE/ToolTrigger/Trigger")
local CarryFunction = Networking:WaitForChild("RF/EggWorld/AskFieldEggCarry")

-- === MAIN GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HanssyzUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- === MINIMIZED LOGO (H) ===
local MiniLogo = Instance.new("TextButton")
MiniLogo.Name = "MiniLogo"
MiniLogo.Size = UDim2.new(0, 40, 0, 40)
MiniLogo.Position = UDim2.new(0, 20, 0, 20)
MiniLogo.BackgroundColor3 = Theme.Accent
MiniLogo.Text = "H"
MiniLogo.TextColor3 = Theme.Text
MiniLogo.Font = Enum.Font.GothamBlack
MiniLogo.TextSize = 20
MiniLogo.Visible = false
MiniLogo.Parent = ScreenGui
Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(0, 8)

-- === MAIN FRAME ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Drop Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
Shadow.ZIndex = -1
Shadow.Parent = MainFrame

-- === SIDEBAR ===
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 50)
Title.Position = UDim2.new(0, 20, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Hanssyz"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Sidebar

-- === TOMBOL CLOSE (X) & MINIMIZE (-) ===
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 30, 0, 30)
MiniBtn.Position = UDim2.new(1, -80, 0, 10)
MiniBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
MiniBtn.Text = "-"
MiniBtn.TextColor3 = Theme.Text
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 16
MiniBtn.Parent = MainFrame
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)

-- === TAB SYSTEM ===
local TabsFrame = Instance.new("ScrollingFrame")
TabsFrame.Size = UDim2.new(1, 0, 1, -60)
TabsFrame.Position = UDim2.new(0, 0, 0, 60)
TabsFrame.BackgroundTransparency = 1
TabsFrame.ScrollBarThickness = 0
TabsFrame.Parent = Sidebar
Instance.new("UIListLayout", TabsFrame).Padding = UDim.new(0, 5)

-- === CONTENT FRAME ===
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -150, 1, 0)
ContentFrame.Position = UDim2.new(0, 150, 0, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, -40, 0, 50)
PageTitle.Position = UDim2.new(0, 20, 0, 10)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "Settings"
PageTitle.TextColor3 = Theme.Text
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextSize = 18
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Parent = ContentFrame

local FeatureContainer = Instance.new("Frame")
FeatureContainer.Size = UDim2.new(1, -40, 1, -70)
FeatureContainer.Position = UDim2.new(0, 20, 0, 60)
FeatureContainer.BackgroundTransparency = 1
FeatureContainer.Parent = ContentFrame
Instance.new("UIListLayout", FeatureContainer).Padding = UDim.new(0, 10)

-- === LOGIC DRAG & DROP ===
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === LOGIC MINIMIZE & CLOSE ===
MiniBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniLogo.Visible = true
end)

MiniLogo.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniLogo.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Wait()
    ScreenGui:Destroy()
    print("[Hanssyz] Script Unloaded.")
end)

-- === UI BUILDER ===
local function CreateFeature(name, defaultState, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Theme.ElementBg
    Frame.BorderSizePixel = 0
    Frame.Parent = FeatureContainer
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -80, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 40, 0, 20)
    Toggle.Position = UDim2.new(1, -55, 0.5, -10)
    Toggle.BackgroundColor3 = defaultState and Theme.Accent or Color3.fromRGB(80, 80, 80)
    Toggle.Text = ""
    Toggle.Parent = Frame
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Indicator.BackgroundColor3 = Theme.Text
    Indicator.Parent = Toggle
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    local isToggled = defaultState

    Toggle.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = isToggled and Theme.Accent or Color3.fromRGB(80, 80, 80)}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
        if callback then callback(isToggled) end
    end)
end

-- === LOGIC IMPLEMENTASI ===
local function GetClosestEgg()
    local closest = nil
    local shortest = math.huge
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not myPos then return nil end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:find("Egg") or obj.Name:find("egg")) then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (myPos - part.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = obj
                end
            end
        end
    end
    return closest
end

-- Loop Utama (Jalan Terus)
task.spawn(function()
    while task.wait(0.1) do
        if not ScreenGui.Parent then break end -- Berhenti kalo UI di close
        
        local char = LocalPlayer.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        -- Logic WalkSpeed
        if Features.WalkSpeed and hum then hum.WalkSpeed = 290 end
        -- Logic JumpPower
        if Features.JumpPower and hum then hum.JumpPower = 100 end
        
        -- Logic Steal & Teleport
        if Features.AutoSteal and hrp and TriggerEvent then
            local targetEgg = GetClosestEgg()
            if targetEgg and targetEgg.PrimaryPart then
                local originalPos = hrp.CFrame
                
                if Features.AutoTeleport then
                    hrp.CFrame = targetEgg.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)
                end

                pcall(function()
                    TriggerEvent:FireServer(targetEgg.Name)
                    if CarryFunction then
                        CarryFunction:InvokeServer({Target = targetEgg})
                    end
                end)

                if Features.AutoTeleport then
                    task.wait(0.1)
                    hrp.CFrame = originalPos
                end
            end
        end
    end
end)

-- Anti AFK (Biar ga ke-kick)
task.spawn(function()
    while task.wait(60) do
        if Features.AntiAFK then
            if LocalPlayer.Character then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Physics)
            end
        end
    end
end)

-- === TAB CONTENT SETUP ===
local function SwitchTab(tabName)
    PageTitle.Text = tabName .. " Settings"
    for _, v in pairs(FeatureContainer:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    if tabName == "Player" then
        CreateFeature("WalkSpeed (290)", Features.WalkSpeed, function(on) Features.WalkSpeed = on end)
        CreateFeature("JumpPower (100)", Features.JumpPower, function(on) Features.JumpPower = on end)
        
    elseif tabName == "Farm" then
        CreateFeature("Auto Steal Egg", Features.AutoSteal, function(on) Features.AutoSteal = on end)
        CreateFeature("Auto Teleport (Fast)", Features.AutoTeleport, function(on) Features.AutoTeleport = on end)
        
    elseif tabName == "Visuals" then
        CreateFeature("Fullbright", Features.Fullbright, function(on)
            Features.Fullbright = on
            if on then
                game.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                game.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            else
                game.Lighting.Ambient = Color3.fromRGB(70, 70, 70)
                game.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end
        end)
    elseif tabName == "Combat" then
        CreateFeature("Kill Aura (Coming Soon)", false, function(on) print("Kill Aura: ", on) end)
    elseif tabName == "Misc" then
        CreateFeature("Anti-AFK", Features.AntiAFK, function(on) Features.AntiAFK = on end)
    elseif tabName == "Settings" then
        CreateFeature("Mobile Toggle Button", true, function(on) print("Mobile Toggle: ", on) end)
        CreateFeature("Lock Interface", false, function(on) print("Lock UI: ", on) end)
    end
end

-- === BIKIN TOMBOL TAB ===
local TabsList = {"Player", "Visuals", "Combat", "Farm", "Misc", "Settings"}
for _, tabName in ipairs(TabsList) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 35)
    TabBtn.BackgroundColor3 = Theme.Sidebar
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = "   " .. tabName
    TabBtn.TextColor3 = Theme.TextDim
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 14
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = TabsFrame
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    TabBtn.MouseButton1Click:Connect(function()
        for _, btn in pairs(TabsFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundTransparency = 1
                btn.TextColor3 = Theme.TextDim
            end
        end
        TabBtn.BackgroundTransparency = 0
        TabBtn.BackgroundColor3 = Theme.Accent
        TabBtn.TextColor3 = Theme.Text
        SwitchTab(tabName)
    end)

    if tabName == "Farm" then
        TabBtn.BackgroundTransparency = 0
        TabBtn.BackgroundColor3 = Theme.Accent
        TabBtn.TextColor3 = Theme.Text
        SwitchTab(tabName)
    end
end

print("[Hanssyz] UI + Logic Loaded Successfully.")
