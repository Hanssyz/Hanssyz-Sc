-- ==============================================================================
-- FINAL CODE: HANSSYZ SC (ALL FEATURES)
-- ==============================================================================

local PlayersService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorageService = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = PlayersService.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    HubName = "Hanssyz Sc",
    Version = "v40.0",
    StealToolName = "Burrowing Owl Egg (Tool)", 
    TriggerFolderName = "ToolTrigger",
    TriggerEventName = "Trigger",
    CarryFolderName = "EggWorld",
    CarryEventName = "AskFieldEggCarry",
    DelayAfterTeleport = 0.4,
    DelayAfterTrigger = 0.5,
    DelayAfterCarry = 1.5,
    DelayAfterSafeZone = 0.5
}

local StateManager = {
    IsRunning = false,
    IsMinimized = false,
    IsExpanded = true,
    SuccessCounter = 0,
    FailCounter = 0,
    SelectedRarity = "All Rarity",
    SelectedZone = "All Zone",
    Theme = "Ocean Blue",
    SafeZonePosition = CFrame.new(0, 10, 0),
    Blacklist = {},
    AntiKnockbackEnabled = true
}

local Themes = {
    ["Ocean Blue"] = {Main = Color3.fromRGB(88, 166, 255), Bg1 = Color3.fromRGB(15, 23, 42), Bg2 = Color3.fromRGB(30, 41, 59)},
    ["Crimson Red"] = {Main = Color3.fromRGB(255, 99, 132), Bg1 = Color3.fromRGB(30, 15, 20), Bg2 = Color3.fromRGB(50, 25, 35)},
    ["Emerald Green"] = {Main = Color3.fromRGB(50, 255, 150), Bg1 = Color3.fromRGB(10, 25, 20), Bg2 = Color3.fromRGB(20, 45, 35)},
    ["Royal Purple"] = {Main = Color3.fromRGB(190, 130, 255), Bg1 = Color3.fromRGB(20, 15, 30), Bg2 = Color3.fromRGB(35, 25, 50)},
    ["Midnight Dark"] = {Main = Color3.fromRGB(200, 200, 200), Bg1 = Color3.fromRGB(10, 10, 12), Bg2 = Color3.fromRGB(25, 25, 30)}
}

local C = {
    Succ = Color3.fromRGB(100, 255, 160),
    Fail = Color3.fromRGB(255, 120, 120),
    Text = Color3.fromRGB(245, 248, 255),
    Sub = Color3.fromRGB(180, 190, 220),
    Card = Color3.fromRGB(40, 45, 65)
}

local function Create(inst, props, parent)
    local obj = Instance.new(inst)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(p, r) Create("UICorner", {CornerRadius=UDim.new(0,r)}, p) end
local function Stroke(p, c, t, tr) Create("UIStroke", {Color=c, Thickness=t, Transparency=tr or 0}, p) end

task.spawn(function()
    task.wait(1)
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then StateManager.SafeZonePosition = spawn.CFrame + Vector3.new(0,3,0)
    elseif LocalPlayer.Character then StateManager.SafeZonePosition = LocalPlayer.Character.HumanoidRootPart.CFrame end
end)

local function ApplyAKB(ch)
    local h = ch:WaitForChild("Humanoid", 5)
    if h then 
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not StateManager.AntiKnockbackEnabled)
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not StateManager.AntiKnockbackEnabled) 
    end
end
LocalPlayer.CharacterAdded:Connect(ApplyAKB)
if LocalPlayer.Character then ApplyAKB(LocalPlayer.Character) end

local oldNC
oldNC = hookmetamethod(game, "__namecall", function(self, ...)
    if not StateManager.AntiKnockbackEnabled then return oldNC(self, ...) end
    if getnamecallmethod() == "FireServer" then
        for _, v in pairs({...}) do
            if typeof(v) == "string" and (v:lower():find("ragdoll") or v:lower():find("knockback")) then return end
        end
    end
    return oldNC(self, ...)
end)

if PlayerGui:FindFirstChild("HanssyzUI") then PlayerGui.HanssyzUI:Destroy() end

local GUI = Create("ScreenGui", {Name="HanssyzUI", ResetOnSpawn=false}, PlayerGui)
local Shadow = Create("Frame", {Size=UDim2.new(0,540,0,420), Position=UDim2.new(0.5,-270,0.5,-210), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.5, ZIndex=0}, GUI); Corner(Shadow, 20)
local Main = Create("Frame", {Size=UDim2.new(0,520,0,400), Position=UDim2.new(0.5,-260,0.5,-200), BackgroundColor3=Themes[StateManager.Theme].Bg1, ClipsDescendants=true, ZIndex=1}, GUI); Corner(Main, 16); local MStr = Create("UIStroke", {Color=Themes[StateManager.Theme].Main, Thickness=2, Transparency=0.2}, Main)
local BgG = Create("Frame", {Size=UDim2.new(1,0,1,0), BackgroundColor3=Themes[StateManager.Theme].Bg2, ZIndex=1}, Main)
local Grad = Create("UIGradient", {Rotation=45, Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Themes[StateManager.Theme].Bg1), ColorSequenceKeypoint.new(1,Themes[StateManager.Theme].Bg2)})}, BgG)

local Side = Create("Frame", {Size=UDim2.new(0,130,1,0), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.3, ZIndex=2}, Main); Corner(Side, 16)
local Title = Create("TextLabel", {Size=UDim2.new(1,0,0,60), BackgroundTransparency=1, Text="Hanssyz Sc", Font=Enum.Font.GothamBold, TextColor3=Themes[StateManager.Theme].Main, TextSize=18, ZIndex=3}, Side)

local function Sbtn(n, y) 
    local b = Create("TextButton", {Size=UDim2.new(1,-20,0,35), Position=UDim2.new(0,10,0,y), BackgroundColor3=Themes[StateManager.Theme].Main, BackgroundTransparency=(n=="Main") and 0.8 or 1, Text=n, Font=Enum.Font.Gotham, TextColor3=C.Text, TextSize=13, ZIndex=3}, Side); Corner(b, 8); return b 
end
local TbMain, TbMisc, TbSet = Sbtn("Main", 70), Sbtn("Misc", 115), Sbtn("Settings", 160)

local Cont = Create("Frame", {Size=UDim2.new(1,-150,1,-20), Position=UDim2.new(0,140,0,10), BackgroundTransparency=1, ZIndex=2}, Main)
local Top = Create("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Active=true, ZIndex=2}, Cont)
Create("TextLabel", {Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text="Dashboard", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, Top)
local MinB = Create("TextButton", {Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-70,0.5,-15), BackgroundColor3=Themes[StateManager.Theme].Main, Text="-", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=20, ZIndex=3}, Top); Corner(MinB, 6)
local ClsB = Create("TextButton", {Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-35,0.5,-15), BackgroundColor3=C.Fail, Text="X", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=16, ZIndex=3}, Top); Corner(ClsB, 6)

local Scr = Create("ScrollingFrame", {Size=UDim2.new(1,0,1,-50), Position=UDim2.new(0,0,0,50), BackgroundTransparency=1, ScrollBarThickness=2, CanvasSize=UDim2.new(0,0,0,500), ZIndex=2}, Cont)

-- Page Main
local PgMain = Create("Frame", {Size=UDim2.new(1,0,0,400), BackgroundTransparency=1, ZIndex=2}, Scr)
local Hdr = Create("Frame", {Size=UDim2.new(1,-10,0,45), BackgroundColor3=C.Card, ZIndex=2}, PgMain); Corner(Hdr, 8)
Create("TextLabel", {Size=UDim2.new(1,-40,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, Text="Steal Egg", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, Hdr)
local ArrB = Create("TextButton", {Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-40,0.5,-15), BackgroundColor3=Color3.fromRGB(50,55,80), Text="▼", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=12, ZIndex=3}, Hdr); Corner(ArrB, 6)

local Acc = Create("Frame", {Size=UDim2.new(1,-10,0,230), Position=UDim2.new(0,0,0,50), BackgroundTransparency=1, ClipsDescendants=true, ZIndex=2}, PgMain)
local RarB = Create("TextButton", {Size=UDim2.new(0.5,0,0,30), Position=UDim2.new(0.45,0,0,0), BackgroundColor3=C.Card, Text=StateManager.SelectedRarity, Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=12, ZIndex=4}, Acc); Corner(RarB, 6)
Create("TextLabel", {Size=UDim2.new(0.4,0,0,30), BackgroundTransparency=1, Text="Rarity:", Font=Enum.Font.Gotham, TextColor3=C.Sub, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, Acc)

local ZonB = Create("TextButton", {Size=UDim2.new(0.5,0,0,30), Position=UDim2.new(0.45,0,0,40), BackgroundColor3=C.Card, Text=StateManager.SelectedZone, Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=12, ZIndex=4}, Acc); Corner(ZonB, 6)
Create("TextLabel", {Size=UDim2.new(0.4,0,0,30), Position=UDim2.new(0,0,0,40), BackgroundTransparency=1, Text="Zone:", Font=Enum.Font.Gotham, TextColor3=C.Sub, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, Acc)

Create("TextLabel", {Size=UDim2.new(0.6,0,0,30), Position=UDim2.new(0,0,0,90), BackgroundTransparency=1, Text="Auto Steal", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, Acc)
local TogB = Create("TextButton", {Size=UDim2.new(0,45,0,24), Position=UDim2.new(0.8,0,0,93), BackgroundColor3=Color3.fromRGB(50,55,80), Text="", ZIndex=4}, Acc); Corner(TogB, 12)
local Knob = Create("Frame", {Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,2,0.5,-10), BackgroundColor3=Color3.new(1,1,1), ZIndex=5}, TogB); Corner(Knob, 10)

local Mon = Create("Frame", {Size=UDim2.new(1,0,0,60), Position=UDim2.new(0,0,0,140), BackgroundColor3=C.Card, ZIndex=3}, Acc); Corner(Mon, 8)
local SucL = Create("TextLabel", {Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,5), BackgroundTransparency=1, Text="Eggs: 0", Font=Enum.Font.GothamBold, TextColor3=C.Succ, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, Mon)
local FaiL = Create("TextLabel", {Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,10,0,30), BackgroundTransparency=1, Text="Fail: 0", Font=Enum.Font.Gotham, TextColor3=C.Fail, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, Mon)

-- Page Misc
local PgMisc = Create("Frame", {Size=UDim2.new(1,0,0,400), BackgroundTransparency=1, Visible=false, ZIndex=2}, Scr)
Create("TextLabel", {Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Text="Miscellaneous", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, PgMisc)
local AKBox = Create("Frame", {Size=UDim2.new(1,0,0,50), Position=UDim2.new(0,0,0,40), BackgroundColor3=C.Card, ZIndex=3}, PgMisc); Corner(AKBox, 8)
Create("TextLabel", {Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, Text="Anti Knockback", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, AKBox)
local AKT = Create("TextButton", {Size=UDim2.new(0,45,0,24), Position=UDim2.new(0.8,0,0.5,-12), BackgroundColor3=Themes[StateManager.Theme].Main, Text="", ZIndex=4}, AKBox); Corner(AKT, 12)
local AKK = Create("Frame", {Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-22,0.5,-10), BackgroundColor3=Color3.new(1,1,1), ZIndex=5}, AKT); Corner(AKK, 10)

-- Page Settings
local PgSet = Create("Frame", {Size=UDim2.new(1,0,0,400), BackgroundTransparency=1, Visible=false, ZIndex=2}, Scr)
Create("TextLabel", {Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Text="Theme Settings", Font=Enum.Font.GothamBold, TextColor3=C.Text, TextSize=16, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3}, PgSet)
local ThemB = Create("TextButton", {Size=UDim2.new(1,0,0,35), Position=UDim2.new(0,0,0,40), BackgroundColor3=C.Card, Text="Theme: "..StateManager.Theme, Font=Enum.Font.Gotham, TextColor3=C.Text, TextSize=13, ZIndex=4}, PgSet); Corner(ThemB, 6)

-- Dropdowns
local function MakeDD(btn, opts, cb)
    local op = false
    local m = Create("ScrollingFrame", {Size=UDim2.new(0.5,0,0,0), Position=UDim2.new(0.45,0,1,5), BackgroundColor3=Themes[StateManager.Theme].Bg2, Visible=false, CanvasSize=UDim2.new(0,0,0,#opts*30), ZIndex=999}, btn.Parent); Corner(m, 6)
    for i, o in ipairs(opts) do
        local ob = Create("TextButton", {Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,(i-1)*30), BackgroundColor3=C.Card, Text=o, Font=Enum.Font.Gotham, TextColor3=C.Text, TextSize=12, ZIndex=1000}, m)
        ob.MouseButton1Click:Connect(function() btn.Text=o; m.Visible=false; TweenService:Create(m, TweenInfo.new(0.2), {Size=UDim2.new(0.5,0,0,0)}):Play(); cb(o) end)
    end
    btn.MouseButton1Click:Connect(function() op=not op; m.Visible=op; TweenService:Create(m, TweenInfo.new(0.2), {Size=op and UDim2.new(0.5,0,0,#opts*30) or UDim2.new(0.5,0,0,0)}):Play() end)
end
MakeDD(RarB, {"All Rarity", "Common", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine"}, function(v) StateManager.SelectedRarity=v end)
MakeDD(ZonB, {"All Zone", "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Cosmic"}, function(v) StateManager.SelectedZone=v end)

local TList = {"Ocean Blue", "Crimson Red", "Emerald Green", "Royal Purple", "Midnight Dark"}
local top = false
local tMenu = Create("ScrollingFrame", {Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,1,5), BackgroundColor3=Themes[StateManager.Theme].Bg2, Visible=false, CanvasSize=UDim2.new(0,0,0,#TList*30), ZIndex=999}, ThemB.Parent); Corner(tMenu, 6)
for i, t in ipairs(TList) do
    local tb = Create("TextButton", {Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,(i-1)*30), BackgroundColor3=C.Card, Text=t, Font=Enum.Font.Gotham, TextColor3=C.Text, TextSize=12, ZIndex=1000}, tMenu)
    tb.MouseButton1Click:Connect(function()
        StateManager.Theme=t; ThemB.Text="Theme: "..t; tMenu.Visible=false
        Main.BackgroundColor3=Themes[t].Bg1; Grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Themes[t].Bg1), ColorSequenceKeypoint.new(1,Themes[t].Bg2)})
        MStr.Color=Themes[t].Main; Title.TextColor3=Themes[t].Main; TbMain.BackgroundColor3=Themes[t].Main; TbMisc.BackgroundColor3=Themes[t].Main; TbSet.BackgroundColor3=Themes[t].Main; MinB.BackgroundColor3=Themes[t].Main; AKT.BackgroundColor3=Themes[t].Main
    end)
end
ThemB.MouseButton1Click:Connect(function() top=not top; tMenu.Visible=top; TweenService:Create(tMenu, TweenInfo.new(0.2), {Size=top and UDim2.new(1,0,0,#TList*30) or UDim2.new(1,0,0,0)}):Play() end)

-- Tab Switching
local function SwTab(n)
    PgMain.Visible = (n=="Main"); PgMisc.Visible = (n=="Misc"); PgSet.Visible = (n=="Settings")
    TbMain.BackgroundTransparency = (n=="Main") and 0.8 or 1; TbMisc.BackgroundTransparency = (n=="Misc") and 0.8 or 1; TbSet.BackgroundTransparency = (n=="Settings") and 0.8 or 1
end
TbMain.MouseButton1Click:Connect(function() SwTab("Main") end); TbMisc.MouseButton1Click:Connect(function() SwTab("Misc") end); TbSet.MouseButton1Click:Connect(function() SwTab("Settings") end)

-- Steal Logic
local function IsBL(e) for _, v in pairs(StateManager.Blacklist) do if v==e then return true end end return false end
local function GetEgg()
    local c = LocalPlayer.Character; if not c or not c:FindFirstChild("HumanoidRootPart") then return nil end
    local h, cl, md = c.HumanoidRootPart, nil, math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower():find("egg") and (v:IsA("Model") or v:IsA("BasePart")) and not v.Name:lower():find("fitbounds") and not v.Name:lower():find("treadmill") and not v.Name:lower():find("machine") then
            if StateManager.SelectedRarity~="All Rarity" and not v.Name:lower():find(StateManager.SelectedRarity:lower()) then continue end
            if StateManager.SelectedZone~="All Zone" and not v.Name:lower():find(StateManager.SelectedZone:lower()) then continue end
            if IsBL(v) then continue end
            local p = v:IsA("Model") and v:GetPivot().Position or v.Position
            local d = (h.Position - p).Magnitude
            if d < md then cl = v; md = d end
        end
    end
    return cl
end

local function DoSt()
    local e = GetEgg(); if not e then return false end
    local ok = pcall(function()
        local h = LocalPlayer.Character.HumanoidRootPart
        h.CFrame = CFrame.new((e:IsA("Model") and e:GetPivot().Position or e.Position) + Vector3.new(0,3,0))
        task.wait(Config.DelayAfterTeleport)
        local f1 = ReplicatedStorageService:FindFirstChild(Config.TriggerFolderName); if f1 and f1:FindFirstChild(Config.TriggerEventName) then f1[Config.TriggerEventName]:FireServer(Config.StealToolName) end
        task.wait(Config.DelayAfterTrigger)
        local f2 = ReplicatedStorageService:FindFirstChild(Config.CarryFolderName); if f2 and f2:FindFirstChild(Config.CarryEventName) then f2[Config.CarryEventName]:FireServer(e) end
        task.wait(Config.DelayAfterCarry); h.CFrame = StateManager.SafeZonePosition; task.wait(Config.DelayAfterSafeZone)
    end)
    table.insert(StateManager.Blacklist, e); return ok
end

local function Lp()
    task.spawn(function()
        while StateManager.IsRunning do
            local ok = DoSt()
            if ok then StateManager.SuccessCounter=StateManager.SuccessCounter+1; SucL.Text="Eggs: "..StateManager.SuccessCounter
            else StateManager.FailCounter=StateManager.FailCounter+1; FaiL.Text="Fail: "..StateManager.FailCounter end
            task.wait(0.5)
        end
    end)
end

TogB.MouseButton1Click:Connect(function()
    StateManager.IsRunning = not StateManager.IsRunning
    if StateManager.IsRunning then StateManager.Blacklist={}; TweenService:Create(TogB, TweenInfo.new(0.2), {BackgroundColor3=Themes[StateManager.Theme].Main}):Play(); TweenService:Create(Knob, TweenInfo.new(0.2), {Position=UDim2.new(1,-22,0.5,-10)}):Play(); Lp()
    else TweenService:Create(TogB, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,55,80)}):Play(); TweenService:Create(Knob, TweenInfo.new(0.2), {Position=UDim2.new(0,2,0.5,-10)}):Play() end
end)

AKT.MouseButton1Click:Connect(function()
    StateManager.AntiKnockbackEnabled = not StateManager.AntiKnockbackEnabled
    if StateManager.AntiKnockbackEnabled then TweenService:Create(AKT, TweenInfo.new(0.2), {BackgroundColor3=Themes[StateManager.Theme].Main}):Play(); TweenService:Create(AKK, TweenInfo.new(0.2), {Position=UDim2.new(1,-22,0.5,-10)}):Play()
    else TweenService:Create(AKT, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,55,80)}):Play(); TweenService:Create(AKK, TweenInfo.new(0.2), {Position=UDim2.new(0,2,0.5,-10)}):Play() end
    if LocalPlayer.Character then ApplyAKB(LocalPlayer.Character) end
end)

ArrB.MouseButton1Click:Connect(function()
    StateManager.IsExpanded = not StateManager.IsExpanded
    if StateManager.IsExpanded then TweenService:Create(Acc, TweenInfo.new(0.3), {Size=UDim2.new(1,-10,0,230)}):Play(); ArrB.Text="▼"
    else TweenService:Create(Acc, TweenInfo.new(0.3), {Size=UDim2.new(1,-10,0,0)}):Play(); ArrB.Text="▲" end
end)

MinB.MouseButton1Click:Connect(function()
    if StateManager.IsMinimized then return end; StateManager.IsMinimized = true; Main.Visible=false; Shadow.Visible=false
    local I = Create("TextButton", {Size=UDim2.new(0,50,0,50), Position=UDim2.new(0,20,0,100), BackgroundColor3=Themes[StateManager.Theme].Bg1, Text="H", Font=Enum.Font.GothamBold, TextColor3=Themes[StateManager.Theme].Main, TextSize=24, ZIndex=50}, GUI); Corner(I, 12); Stroke(I, Themes[StateManager.Theme].Main, 2, 0)
    I.MouseButton1Click:Connect(function() StateManager.IsMinimized=false; Main.Visible=true; Shadow.Visible=true; I:Destroy() end)
end)

ClsB.MouseButton1Click:Connect(function() GUI:Destroy() end)

local dr, ds, sp
Top.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=true; ds=i.Position; sp=Main.Position end end)
Top.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=false end end)
UserInputService.InputChanged:Connect(function(i) if dr and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-ds; Main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y); Shadow.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X-10,sp.Y.Scale,sp.Y.Offset+d.Y-10) end end)
