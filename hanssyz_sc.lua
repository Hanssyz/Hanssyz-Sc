-- Hanssyz Sc | Final Master Version
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= KONFIGURASI =================
local Config = {
    HubName = "Hanssyz Sc",
    Version = "Final v1.0",
    -- [PENTING] GANTI ANGKA INI SAMA POSISI SAFE ZONE LU
    SafeZoneCFrame = CFrame.new(0, 10, 0), 
    RemoteFolderName = "ToolTrigger",
    RemoteEventName = "Trigger"
}

local State = {
    Running = false,
    Minimized = false,
    Success = 0,
    Fail = 0,
    Rarity = "All",
    Blacklist = {}
}

local C = {
    Main = Color3.fromRGB(88, 166, 255),
    Succ = Color3.fromRGB(100, 255, 160),
    Danger = Color3.fromRGB(255, 120, 120),
    Bg = Color3.fromRGB(15, 18, 42),
    Card = Color3.fromRGB(28, 32, 58),
    Text = Color3.fromRGB(245, 248, 255),
    Sub = Color3.fromRGB(180, 190, 220)
}
local Font = Enum.Font.GothamBold
local FontReg = Enum.Font.Gotham

-- ================= HELPER FUNCTIONS =================
if PlayerGui:FindFirstChild("HanssyzUI") then PlayerGui.HanssyzUI:Destroy() end

local function Create(inst, props, parent)
    local obj = Instance.new(inst)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function AddCorner(parent, rad)
    return Create("UICorner", {CornerRadius = UDim.new(0, rad)}, parent)
end

-- ================= UI SETUP =================
local GUI = Create("ScreenGui", {Name="HanssyzUI", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, PlayerGui)
local Main = Create("Frame", {Name="Main", Size=UDim2.new(0, 480, 0, 420), Position=UDim2.new(0.5, -240, 0.5, -210), BackgroundColor3=C.Bg, BorderSizePixel=0, Active=true, ClipsDescendants=true}, GUI)
AddCorner(Main, 16)
Create("UIStroke", {Color=C.Main, Thickness=2, Transparency=0.3}, Main)

local Header = Create("Frame", {Size=UDim2.new(1, 0, 0, 50), BackgroundTransparency=1, Active=true}, Main)
Create("TextLabel", {Size=UDim2.new(1, -90, 1, 0), Position=UDim2.new(0, 20, 0, 0), BackgroundTransparency=1, Text=Config.HubName.." | "..Config.Version, Font=Font, TextColor3=C.Text, TextSize=18, TextXAlignment=Enum.TextXAlignment.Left}, Header)

local MinBtn = Create("TextButton", {Size=UDim2.new(0, 30, 0, 30), Position=UDim2.new(1, -75, 0.5, -15), BackgroundColor3=C.Main, Text="-", Font=Font, TextColor3=C.Text, TextSize=20}, Header)
AddCorner(MinBtn, 6)

local CloseBtn = Create("TextButton", {Size=UDim2.new(0, 30, 0, 30), Position=UDim2.new(1, -40, 0.5, -15), BackgroundColor3=C.Danger, Text="X", Font=Font, TextColor3=C.Text, TextSize=16}, Header)
AddCorner(CloseBtn, 6)

local Content = Create("Frame", {Size=UDim2.new(1, -40, 1, -80), Position=UDim2.new(0, 20, 0, 70), BackgroundTransparency=1}, Main)

-- RARITY DROPDOWN
local RarBox = Create("Frame", {Size=UDim2.new(1, 0, 0, 45), BackgroundColor3=C.Card}, Content)
AddCorner(RarBox, 10)
Create("TextLabel", {Size=UDim2.new(0.5, 0, 1, 0), Position=UDim2.new(0, 15, 0, 0), BackgroundTransparency=1, Text="Rarity Filter:", Font=Font, TextColor3=C.Sub, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, RarBox)

local DropBtn = Create("TextButton", {Size=UDim2.new(0.4, 0, 0, 30), Position=UDim2.new(0.55, 0, 0.5, -15), BackgroundColor3=C.Main, Text="All", Font=Font, TextColor3=C.Text, TextSize=13}, RarBox)
AddCorner(DropBtn, 8)

local DropMenu = Create("ScrollingFrame", {Size=UDim2.new(0.4, 0, 0, 160), Position=UDim2.new(0.55, 0, 1, 5), BackgroundColor3=C.Bg, BorderSizePixel=0, Visible=false, CanvasSize=UDim2.new(0,0,0,210), ZIndex=10}, RarBox)
AddCorner(DropMenu, 8)
Create("UIStroke", {Color=C.Main, Thickness=1}, DropMenu)

for i, r in ipairs({"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}) do
    local Opt = Create("TextButton", {Size=UDim2.new(1, 0, 0, 30), Position=UDim2.new(0, 0, 0, (i-1)*30), BackgroundColor3=C.Card, BackgroundTransparency=0.3, Text=r, Font=FontReg, TextColor3=C.Text, TextSize=13, ZIndex=11}, DropMenu)
    Opt.MouseButton1Click:Connect(function()
        State.Rarity = r
        DropBtn.Text = r
        DropMenu.Visible = false
    end)
end
DropBtn.MouseButton1Click:Connect(function() DropMenu.Visible = not DropMenu.Visible end)

-- TOGGLE
local TogBox = Create("Frame", {Size=UDim2.new(1, 0, 0, 60), Position=UDim2.new(0, 0, 0, 60), BackgroundColor3=C.Card}, Content)
AddCorner(TogBox, 10)
Create("TextLabel", {Size=UDim2.new(0.7, 0, 1, 0), Position=UDim2.new(0, 20, 0, 0), BackgroundTransparency=1, Text="Auto Steal (One-by-One)", Font=Font, TextColor3=C.Text, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left}, TogBox)

local TogBtn = Create("TextButton", {Size=UDim2.new(0, 55, 0, 28), Position=UDim2.new(1, -75, 0.5, -14), BackgroundColor3=Color3.fromRGB(50, 55, 80), Text=""}, TogBox)
AddCorner(TogBtn, 14)
local Knob = Create("Frame", {Size=UDim2.new(0, 24, 0, 24), Position=UDim2.new(0, 2, 0.5, -12), BackgroundColor3=Color3.fromRGB(255,255,255)}, TogBtn)
AddCorner(Knob, 12)

-- MONITOR
local MonPanel = Create("Frame", {Size=UDim2.new(1, 0, 0, 0), Position=UDim2.new(0, 0, 0, 130), BackgroundColor3=Color3.fromRGB(18, 22, 40), ClipsDescendants=true, Visible=false}, Content)
AddCorner(MonPanel, 10)
local SucLbl = Create("TextLabel", {Size=UDim2.new(0.5, 0, 0, 45), Position=UDim2.new(0, 20, 0, 0), BackgroundTransparency=1, Text="SUCCESS: 0", Font=Font, TextColor3=C.Succ, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left}, MonPanel)
local FailLbl = Create("TextLabel", {Size=UDim2.new(0.5, -20, 0, 45), Position=UDim2.new(0.5, 0, 0, 0), BackgroundTransparency=1, Text="FAIL: 0", Font=Font, TextColor3=C.Danger, TextSize=16, TextXAlignment=Enum.TextXAlignment.Right}, MonPanel)
local StatLbl = Create("TextLabel", {Size=UDim2.new(1, -40, 0, 25), Position=UDim2.new(0, 20, 0, 45), BackgroundTransparency=1, Text="Status: Idle", Font=FontReg, TextColor3=C.Sub, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left}, MonPanel)

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
        
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        task.wait(0.4)
        
        local folder = ReplicatedStorage:FindFirstChild(Config.RemoteFolderName)
        if folder then
            local remote = folder:FindFirstChild(Config.RemoteEventName)
            if remote then
                remote:FireServer(egg.Name .. " (Tool)")
            end
        end
        
        task.wait(1.5)
        hrp.CFrame = Config.SafeZoneCFrame
        task.wait(1.0)
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
                State.Success += 1
                SucLbl.Text = "SUCCESS: " .. State.Success
                StatLbl.Text = "Status: Sukses, cari lagi..."
                StatLbl.TextColor3 = C.Succ
            else
                State.Fail += 1
                FailLbl.Text = "FAIL: " .. State.Fail
                StatLbl.Text = "Status: Habis / Gagal"
                StatLbl.TextColor3 = C.Danger
                task.wait(2)
            end
            task.wait(1)
        end
    end)
end

-- ================= BUTTON ACTIONS =================
TogBtn.MouseButton1Click:Connect(function()
    State.Running = not State.Running
    if State.Running then
        State.Blacklist = {}
        TweenService:Create(TogBtn, TweenInfo.new(0.2), {BackgroundColor3=C.Main}):Play()
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
    
    local Icon = Create("TextButton", {Size=UDim2.new(0,50,0,50), Position=UDim2.new(0,20,0,100), BackgroundColor3=C.Card, Text="H", Font=Font, TextColor3=C.Main, TextSize=24, ZIndex=50}, GUI)
    AddCorner(Icon, 12)
    Create("UIStroke", {Color=C.Main, Thickness=2}, Icon)
    
    Icon.MouseButton1Click:Connect(function()
        State.Minimized = false
        Main.Visible = true
        Icon:Destroy()
    end)
end)

CloseBtn.MouseButton1Click:Connect(function() GUI:Destroy() end)

-- ================= DRAGGABLE =================
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
