--[[
================================================================================
    HANSSYZ SC - STEAL AN EGG PREMIUM HUB
================================================================================
    Version     : 7.0 (Over-engineered & Fully Commented)
    Author      : Hanssyz
    Features    : 
    - Auto Steal (Teleport -> Fire Remote -> Safe Zone)
    - Rarity Filter (Dropdown UI)
    - Live Success/Fail Monitor
    - Minimize to Floating Icon (Maskot "H")
    - Smooth Tween Animations & Hover Effects
    - Bypass Ping Timeout (Customizable Delay)
================================================================================
]]

-- ==============================================================================
-- 1. SERVICES & DEPENDENCIES
-- ==============================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==============================================================================
-- 2. KONFIGURASI GLOBAL (UBAH DI SINI KALAU MAU CUSTOM)
-- ==============================================================================
local Config = {
    -- Informasi Hub
    HubName = "Hanssyz Sc",
    Version = "v7.0",
    
    -- Koordinat Safe Zone [SESUAIKAN DENGAN BASE LU]
    -- Cara ngecek: Berdiri di safe zone, print posisi HumanoidRootPart lu
    SafeZoneCFrame = CFrame.new(0, 10, 0), 
    
    -- Jeda Waktu (Tweak ini kalau ping lu tinggi/merah)
    TeleportDelay = 0.4,  -- Jeda setelah teleport ke egg
    ActionDelay = 1.5,    -- Jeda setelah nembak remote (biar server sempet proses)
    
    -- Nama Remote (Berdasarkan hasil Spy)
    RemoteFolderName = "ToolTrigger",
    RemoteEventName = "Trigger",
    
    -- Warna Tema
    Colors = {
        Main = Color3.fromRGB(88, 166, 255),
        Accent = Color3.fromRGB(190, 130, 255),
        Success = Color3.fromRGB(100, 255, 160),
        Danger = Color3.fromRGB(255, 120, 120),
        BgMain = Color3.fromRGB(15, 18, 42),
        BgCard = Color3.fromRGB(28, 32, 58),
        TextMain = Color3.fromRGB(245, 248, 255),
        TextSub = Color3.fromRGB(180, 190, 220)
    },
    
    -- Font
    FontBold = Enum.Font.GothamBold,
    FontRegular = Enum.Font.Gotham
}

local State = {
    Running = false,
    SuccessCount = 0,
    FailCount = 0,
    SelectedRarity = "All",
    IsMinimized = false
}

-- ==============================================================================
-- 3. HELPER FUNCTIONS (Fungsi Bantuan Biar Ga Ngetik Panjang)
-- ==============================================================================
local function CreateInstance(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function AddUICorner(parent, radius)
    return CreateInstance("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function AddUIStroke(parent, color, thickness, transparency)
    return CreateInstance("UIStroke", {
        Color = color,
        Thickness = thickness,
        Transparency = transparency or 0
    }, parent)
end

local function PlayClickSound()
    -- Fitur suara klik (Opsional, kalau executor support)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://6895079853" -- Suara klik standar Roblox
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    task.delay(1, function() sound:Destroy() end)
end

-- ==============================================================================
-- 4. SETUP UI (SCREEN GUI & MAIN FRAME)
-- ==============================================================================
-- Hapus UI lama kalau script di-execute ulang
if PlayerGui:FindFirstChild("HanssyzUI") then 
    PlayerGui.HanssyzUI:Destroy() 
end

local ScreenGui = CreateInstance("ScreenGui", {
    Name = "HanssyzUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
}, PlayerGui)

-- Main Frame (Kotak Besar)
local MainFrame = CreateInstance("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 500, 0, 400),
    Position = UDim2.new(0.5, -250, 0.5, -200),
    BackgroundColor3 = Config.Colors.BgMain,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true
}, ScreenGui)
AddUICorner(MainFrame, 16)
AddUIStroke(MainFrame, Config.Colors.Main, 2, 0.3)

-- Header Bar
local HeaderBar = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Config.Colors.BgCard,
    BorderSizePixel = 0
}, MainFrame)
AddUICorner(HeaderBar, 16)

local TitleLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text = Config.HubName .. " | " .. Config.Version,
    Font = Config.FontBold,
    TextColor3 = Config.Colors.TextMain,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left
}, HeaderBar)

-- Tombol Minimize (-)
local MinimizeBtn = CreateInstance("TextButton", {
    Size = UDim2.new(0, 35, 0, 35),
    Position = UDim2.new(1, -85, 0.5, -17.5),
    BackgroundColor3 = Config.Colors.Main,
    Text = "-",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.TextMain,
    TextSize = 20
}, HeaderBar)
AddUICorner(MinimizeBtn, 8)

-- Tombol Close (X)
local CloseBtn = CreateInstance("TextButton", {
    Size = UDim2.new(0, 35, 0, 35),
    Position = UDim2.new(1, -45, 0.5, -17.5),
    BackgroundColor3 = Config.Colors.Danger,
    Text = "X",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.TextMain,
    TextSize = 16
}, HeaderBar)
AddUICorner(CloseBtn, 8)

-- ==============================================================================
-- 5. CONTENT AREA (TAB & FITUR)
-- ==============================================================================
local ContentArea = CreateInstance("Frame", {
    Size = UDim2.new(1, -40, 1, -80),
    Position = UDim2.new(0, 20, 0, 70),
    BackgroundTransparency = 1
}, MainFrame)

-- 5A. Rarity Filter Dropdown
local RarityLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(0.4, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "Target Rarity:",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.TextSub,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
}, ContentArea)

local DropdownBtn = CreateInstance("TextButton", {
    Size = UDim2.new(0.4, 0, 0, 35),
    Position = UDim2.new(0.4, 0, 0, 2),
    BackgroundColor3 = Config.Colors.BgCard,
    Text = "All Rarities",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.Main,
    TextSize = 14
}, ContentArea)
AddUICorner(DropdownBtn, 8)
AddUIStroke(DropdownBtn, Config.Colors.Main, 1, 0.5)

local DropdownMenu = CreateInstance("ScrollingFrame", {
    Size = UDim2.new(0.4, 0, 0, 150),
    Position = UDim2.new(0.4, 0, 0, 40),
    BackgroundColor3 = Config.Colors.BgMain,
    BorderSizePixel = 0,
    Visible = false,
    CanvasSize = UDim2.new(0, 0, 0, 200),
    ZIndex = 10
}, ContentArea)
AddUICorner(DropdownMenu, 8)
AddUIStroke(DropdownMenu, Config.Colors.Main, 1, 0)

local RarityList = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine"}
for i, rarity in ipairs(RarityList) do
    local OptBtn = CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, (i - 1) * 30),
        BackgroundColor3 = Config.Colors.BgCard,
        BackgroundTransparency = 0.5,
        Text = rarity,
        Font = Config.FontRegular,
        TextColor3 = Config.Colors.TextMain,
        TextSize = 13,
        ZIndex = 11
    }, DropdownMenu)
    
    OptBtn.MouseButton1Click:Connect(function()
        State.SelectedRarity = rarity
        DropdownBtn.Text = rarity .. " Rarities"
        DropdownMenu.Visible = false
        PlayClickSound()
    end)
end

DropdownBtn.MouseButton1Click:Connect(function()
    DropdownMenu.Visible = not DropdownMenu.Visible
    PlayClickSound()
end)

-- 5B. Auto Steal Toggle
local ToggleContainer = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    Position = UDim2.new(0, 0, 0, 60),
    BackgroundColor3 = Config.Colors.BgCard,
    BorderSizePixel = 0
}, ContentArea)
AddUICorner(ToggleContainer, 10)

local ToggleLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(0.7, 0, 1, 0),
    Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text = "Auto Steal (Teleport Mode)",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.TextMain,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, ToggleContainer)

local SwitchBtn = CreateInstance("TextButton", {
    Size = UDim2.new(0, 50, 0, 26),
    Position = UDim2.new(1, -70, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(50, 55, 80),
    Text = ""
}, ToggleContainer)
AddUICorner(SwitchBtn, 13)

local Knob = CreateInstance("Frame", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(0, 2, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255)
}, SwitchBtn)
AddUICorner(Knob, 11)

-- 5C. Monitor Panel (Success/Fail)
local MonitorPanel = CreateInstance("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.new(0, 0, 0, 130),
    BackgroundColor3 = Color3.fromRGB(18, 22, 40),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false
}, ContentArea)
AddUICorner(MonitorPanel, 10)

local SuccessLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(0.5, 0, 0, 45),
    Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text = "SUCCESS: 0",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.Success,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, MonitorPanel)

local FailLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(0.5, -20, 0, 45),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "FAIL: 0",
    Font = Config.FontBold,
    TextColor3 = Config.Colors.Danger,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Right
}, MonitorPanel)

local StatusLabel = CreateInstance("TextLabel", {
    Size = UDim2.new(1, -40, 0, 25),
    Position = UDim2.new(0, 20, 0, 45),
    BackgroundTransparency = 1,
    Text = "Status: Idle",
    Font = Config.FontRegular,
    TextColor3 = Config.Colors.TextSub,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left
}, MonitorPanel)

-- ==============================================================================
-- 6. LOGIC AUTO STEAL (TELEPORT -> TRIGGER -> SAFE ZONE)
-- ==============================================================================

local function FindClosestEgg()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local closestEgg = nil
    local shortestDistance = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Cek apakah object adalah Egg (bisa Model atau Part)
        local isEgg = false
        if obj:IsA("Model") and obj.Name:lower():find("egg") then
            isEgg = true
        elseif obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            isEgg = true
        end
        
        if isEgg then
            -- Filter Rarity
            if State.SelectedRarity ~= "All" then
                if not obj.Name:lower():find(State.SelectedRarity:lower()) then
                    continue
                end
            end
            
            -- Dapetin Posisi Egg
            local eggPosition = nil
            if obj:IsA("Model") and obj.PrimaryPart then
                eggPosition = obj.PrimaryPart.Position
            elseif obj:IsA("BasePart") then
                eggPosition = obj.Position
            else
                local success, pivotPos = pcall(function() return obj:GetPivot().Position end)
                if success then eggPosition = pivotPos end
            end
            
            if eggPosition then
                local distance = (rootPart.Position - eggPosition).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEgg = obj
                end
            end
        end
    end
    
    return closestEgg
end

local function PerformSteal()
    local egg = FindClosestEgg()
    
    if not egg then
        StatusLabel.Text = "Status: Egg tidak ditemukan (Kosong)"
        StatusLabel.TextColor3 = Config.Colors.Danger
        return false
    end
    
    local success = pcall(function()
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- Dapetin posisi akhir dari object egg
        local targetPos = nil
        if egg:IsA("Model") then
            targetPos = egg:GetPivot().Position
        else
            targetPos = egg.Position
        end
        
        -- 1. TELEPORT KE EGG
        rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        task.wait(Config.TeleportDelay)
        
        -- 2. FIRE REMOTE (TRIGGER)
        local toolTrigger = ReplicatedStorage:FindFirstChild(Config.RemoteFolderName)
        if toolTrigger then
            local triggerEvent = toolTrigger:FindFirstChild(Config.RemoteEventName)
            if triggerEvent then
                -- Sesuaikan argumen dengan hasil Spy
                triggerEvent:FireServer(egg.Name .. " (Tool)")
            end
        end
        
        -- 3. JEDA (Tunggu server konfirmasi)
        task.wait(Config.ActionDelay)
        
        -- 4. TELEPORT BALIK KE SAFE ZONE
        rootPart.CFrame = Config.SafeZoneCFrame
        
    end)
    
    return success
end

local function StartAutoStealLoop()
    task.spawn(function()
        while State.Running do
            StatusLabel.Text = "Status: Mencari target..."
            StatusLabel.TextColor3 = Config.Colors.TextSub
            
            local stealSuccess = PerformSteal()
            
            if stealSuccess then
                State.SuccessCount = State.SuccessCount + 1
                SuccessLabel.Text = "SUCCESS: " .. State.SuccessCount
                StatusLabel.Text = "Status: Berhasil!"
                StatusLabel.TextColor3 = Config.Colors.Success
            else
                State.FailCount = State.FailCount + 1
                FailLabel.Text = "FAIL: " .. State.FailCount
                StatusLabel.Text = "Status: Gagal / Timeout"
                StatusLabel.TextColor3 = Config.Colors.Danger
            end
            
            -- Jeda sebelum loop berikutnya
            task.wait(1.5)
        end
    end)
end

-- ==============================================================================
-- 7. EVENT LISTENERS (TOGGLE, CLOSE, MINIMIZE)
-- ==============================================================================

SwitchBtn.MouseButton1Click:Connect(function()
    State.Running = not State.Running
    PlayClickSound()
    
    if State.Running then
        -- Animasi ON
        TweenService:Create(SwitchBtn, TweenInfo.new(0.2), {BackgroundColor3 = Config.Colors.Main}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -24, 0.5, -11)}):Play()
        
        -- Munculin Monitor
        MonitorPanel.Visible = true
        TweenService:Create(MonitorPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 70)
        }):Play()
        
        StartAutoStealLoop()
    else
        -- Animasi OFF
        TweenService:Create(SwitchBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 55, 80)}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -11)}):Play()
        
        -- Sembunyiin Monitor
        TweenService:Create(MonitorPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        
        StatusLabel.Text = "Status: Idle"
        task.delay(0.3, function() MonitorPanel.Visible = false end)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    ScreenGui:Destroy()
end)

-- FITUR MINIMIZE KE ICON
local FloatingIcon = nil

local function MinimizeUI()
    PlayClickSound()
    MainFrame.Visible = false
    State.IsMinimized = true
    
    if not FloatingIcon then
        FloatingIcon = CreateInstance("TextButton", {
            Name = "FloatingIcon",
            Size = UDim2.new(0, 55, 0, 55),
            Position = UDim2.new(0, 20, 0, 100),
            BackgroundColor3 = Config.Colors.BgCard,
            BorderSizePixel = 0,
            Text = "H", -- Bisa diganti pake ImageLabel pake Logo Roblox lu
            Font = Config.FontBold,
            TextColor3 = Config.Colors.Main,
            TextSize = 28,
            ZIndex = 50
        }, ScreenGui)
        
        AddUICorner(FloatingIcon, 12)
        AddUIStroke(FloatingIcon, Config.Colors.Main, 2, 0)
        
        -- Animasi pas di hover
        FloatingIcon.MouseEnter:Connect(function()
            TweenService:Create(FloatingIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
        end)
        FloatingIcon.MouseLeave:Connect(function()
            TweenService:Create(FloatingIcon, TweenInfo.new(0.2), {Size = UDim2.new(0, 55, 0, 55)}):Play()
        end)
        
        -- Pas di-klik, balikin UI
        FloatingIcon.MouseButton1Click:Connect(function()
            PlayClickSound()
            MainFrame.Visible = true
            State.IsMinimized = false
            FloatingIcon:Destroy()
            FloatingIcon = nil
        end)
    end
end

MinimizeBtn.MouseButton1Click:Connect(MinimizeUI)

-- ==============================================================================
-- 8. DRAGGABLE LOGIC (Biar UI Bisa Digeser)
-- ==============================================================================
local isDragging = false
local dragStart = nil
local startPos = nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if isDragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- ==============================================================================
-- 9. INITIALIZATION
-- ==============================================================================
print("[ " .. Config.HubName .. " ] Berhasil dimuat!")
print("[ " .. Config.HubName .. " ] Versi: " .. Config.Version)
print("[ " .. Config.HubName .. " ] Fitur Auto Steal siap digunakan.")
