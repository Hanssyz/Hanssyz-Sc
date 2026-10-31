local PlayersService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorageService = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = PlayersService.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Configuration = {
    HubName = "Hanssyz Sc",
    HubVersion = "v14.0",
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
    SuccessCounter = 0,
    FailCounter = 0,
    SelectedRarity = "All Rarity",
    SelectedZone = "All Zone",
    IsMenuExpanded = true,
    SafeZonePosition = CFrame.new(0, 10, 0)
}

local ColorTheme = {
    PrimaryColor = Color3.fromRGB(88, 166, 255),
    SuccessColor = Color3.fromRGB(100, 255, 160),
    DangerColor = Color3.fromRGB(255, 120, 120),
    BackgroundMain = Color3.fromRGB(12, 15, 30),
    BackgroundSidebar = Color3.fromRGB(20, 24, 45),
    BackgroundCard = Color3.fromRGB(30, 35, 60),
    TextColorMain = Color3.fromRGB(245, 248, 255),
    TextColorSecondary = Color3.fromRGB(150, 160, 190)
}

local function CreateUIInstance(ClassName, PropertiesTable, ParentObject)
    local NewInstance = Instance.new(ClassName)
    for PropertyKey, PropertyValue in pairs(PropertiesTable) do
        NewInstance[PropertyKey] = PropertyValue
    end
    if ParentObject then
        NewInstance.Parent = ParentObject
    end
    return NewInstance
end

local function ApplyUICorner(ParentObject, CornerRadiusValue)
    local UICornerInstance = Instance.new("UICorner")
    UICornerInstance.CornerRadius = UDim.new(0, CornerRadiusValue)
    UICornerInstance.Parent = ParentObject
    return UICornerInstance
end

local function ApplyUIStroke(ParentObject, StrokeColor, StrokeThickness, StrokeTransparency)
    local UIStrokeInstance = Instance.new("UIStroke")
    UIStrokeInstance.Color = StrokeColor
    UIStrokeInstance.Thickness = StrokeThickness
    UIStrokeInstance.Transparency = StrokeTransparency or 0
    UIStrokeInstance.Parent = ParentObject
    return UIStrokeInstance
end

if PlayerGui:FindFirstChild("HanssyzUI") then
    PlayerGui.HanssyzUI:Destroy()
end

task.spawn(function()
    task.wait(1.5)
    local SpawnLocationObject = workspace:FindFirstChildOfClass("SpawnLocation")
    if SpawnLocationObject then
        StateManager.SafeZonePosition = SpawnLocationObject.CFrame + Vector3.new(0, 3, 0)
    elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        StateManager.SafeZonePosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
end)

local ScreenGuiInstance = CreateUIInstance("ScreenGui", {
    Name = "HanssyzUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local MainFrameInstance = CreateUIInstance("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 520, 0, 380),
    Position = UDim2.new(0.5, -260, 0.5, -190),
    BackgroundColor3 = ColorTheme.BackgroundMain,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true
}, ScreenGuiInstance)
ApplyUICorner(MainFrameInstance, 16)
ApplyUIStroke(MainFrameInstance, ColorTheme.PrimaryColor, 2, 0.5)

local SidebarFrameInstance = CreateUIInstance("Frame", {
    Name = "SidebarFrame",
    Size = UDim2.new(0, 140, 1, 0),
    BackgroundColor3 = ColorTheme.BackgroundSidebar,
    BorderSizePixel = 0
}, MainFrameInstance)
ApplyUICorner(SidebarFrameInstance, 16)

local SidebarTitleLabel = CreateUIInstance("TextLabel", {
    Name = "SidebarTitleLabel",
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundTransparency = 1,
    Text = "Hanssyz Sc",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.PrimaryColor,
    TextSize = 18
}, SidebarFrameInstance)

local AutoMenuButton = CreateUIInstance("TextButton", {
    Name = "AutoMenuButton",
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.new(0, 10, 0, 60),
    BackgroundColor3 = ColorTheme.PrimaryColor,
    Text = "Auto",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 14
}, SidebarFrameInstance)
ApplyUICorner(AutoMenuButton, 8)

local ContentAreaFrameInstance = CreateUIInstance("Frame", {
    Name = "ContentAreaFrame",
    Size = UDim2.new(1, -160, 1, -20),
    Position = UDim2.new(0, 150, 0, 10),
    BackgroundTransparency = 1
}, MainFrameInstance)

local TopBarFrameInstance = CreateUIInstance("Frame", {
    Name = "TopBarFrame",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Active = true
}, ContentAreaFrameInstance)

local TopBarTitleLabel = CreateUIInstance("TextLabel", {
    Name = "TopBarTitleLabel",
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "Auto Steal Menu",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, TopBarFrameInstance)

local MinimizeButton = CreateUIInstance("TextButton", {
    Name = "MinimizeButton",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -70, 0.5, -15),
    BackgroundColor3 = ColorTheme.PrimaryColor,
    Text = "-",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 20
}, TopBarFrameInstance)
ApplyUICorner(MinimizeButton, 6)

local CloseButton = CreateUIInstance("TextButton", {
    Name = "CloseButton",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0.5, -15),
    BackgroundColor3 = ColorTheme.DangerColor,
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 16
}, TopBarFrameInstance)
ApplyUICorner(CloseButton, 6)

local ScrollingFrameInstance = CreateUIInstance("ScrollingFrame", {
    Name = "ScrollingFrame",
    Size = UDim2.new(1, 0, 1, -50),
    Position = UDim2.new(0, 0, 0, 50),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(0, 0, 0, 500)
}, ContentAreaFrameInstance)

local StealSectionFrameInstance = CreateUIInstance("Frame", {
    Name = "StealSectionFrame",
    Size = UDim2.new(1, -10, 0, 45),
    BackgroundColor3 = ColorTheme.BackgroundCard
}, ScrollingFrameInstance)
ApplyUICorner(StealSectionFrameInstance, 8)

local StealSectionLabel = CreateUIInstance("TextLabel", {
    Name = "StealSectionLabel",
    Size = UDim2.new(1, -40, 1, 0),
    Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    Text = "Steal Egg",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
}, StealSectionFrameInstance)

local ExpandArrowButton = CreateUIInstance("TextButton", {
    Name = "ExpandArrowButton",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -40, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(50, 55, 80),
    Text = "▼",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 12
}, StealSectionFrameInstance)
ApplyUICorner(ExpandArrowButton, 6)

local StealContentFrameInstance = CreateUIInstance("Frame", {
    Name = "StealContentFrame",
    Size = UDim2.new(1, -10, 0, 230),
    Position = UDim2.new(0, 0, 0, 50),
    BackgroundTransparency = 1
}, ScrollingFrameInstance)

local RarityLabel = CreateUIInstance("TextLabel", {
    Name = "RarityLabel",
    Size = UDim2.new(0.4, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Rarity Filter:",
    Font = Enum.Font.Gotham,
    TextColor3 = ColorTheme.TextColorSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, StealContentFrameInstance)

local RarityDropdownButton = CreateUIInstance("TextButton", {
    Name = "RarityDropdownButton",
    Size = UDim2.new(0.5, 0, 0, 30),
    Position = UDim2.new(0.45, 0, 0, 0),
    BackgroundColor3 = ColorTheme.BackgroundCard,
    Text = StateManager.SelectedRarity,
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 12
}, StealContentFrameInstance)
ApplyUICorner(RarityDropdownButton, 6)

local ZoneLabel = CreateUIInstance("TextLabel", {
    Name = "ZoneLabel",
    Size = UDim2.new(0.4, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "Zone Filter:",
    Font = Enum.Font.Gotham,
    TextColor3 = ColorTheme.TextColorSecondary,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, StealContentFrameInstance)

local ZoneDropdownButton = CreateUIInstance("TextButton", {
    Name = "ZoneDropdownButton",
    Size = UDim2.new(0.5, 0, 0, 30),
    Position = UDim2.new(0.45, 0, 0, 40),
    BackgroundColor3 = ColorTheme.BackgroundCard,
    Text = StateManager.SelectedZone,
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 12
}, StealContentFrameInstance)
ApplyUICorner(ZoneDropdownButton, 6)

local ToggleLabel = CreateUIInstance("TextLabel", {
    Name = "ToggleLabel",
    Size = UDim2.new(0.6, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 90),
    BackgroundTransparency = 1,
    Text = "Auto Steal",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.TextColorMain,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
}, StealContentFrameInstance)

local ToggleSwitchButton = CreateUIInstance("TextButton", {
    Name = "ToggleSwitchButton",
    Size = UDim2.new(0, 45, 0, 24),
    Position = UDim2.new(0.8, 0, 0, 93),
    BackgroundColor3 = Color3.fromRGB(50, 55, 80),
    Text = ""
}, StealContentFrameInstance)
ApplyUICorner(ToggleSwitchButton, 12)

local ToggleKnob = CreateUIInstance("Frame", {
    Name = "ToggleKnob",
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(0, 2, 0.5, -10),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255)
}, ToggleSwitchButton)
ApplyUICorner(ToggleKnob, 10)

local MonitorBoxFrameInstance = CreateUIInstance("Frame", {
    Name = "MonitorBoxFrame",
    Size = UDim2.new(1, 0, 0, 60),
    Position = UDim2.new(0, 0, 0, 140),
    BackgroundColor3 = ColorTheme.BackgroundCard
}, StealContentFrameInstance)
ApplyUICorner(MonitorBoxFrameInstance, 8)

local SuccessLabel = CreateUIInstance("TextLabel", {
    Name = "SuccessLabel",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Text = "Eggs Brought: 0",
    Font = Enum.Font.GothamBold,
    TextColor3 = ColorTheme.SuccessColor,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
}, MonitorBoxFrameInstance)

local FailLabel = CreateUIInstance("TextLabel", {
    Name = "FailLabel",
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 30),
    BackgroundTransparency = 1,
    Text = "Failed: 0",
    Font = Enum.Font.Gotham,
    TextColor3 = ColorTheme.DangerColor,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}, MonitorBoxFrameInstance)

local function CreateDropdownMenuSystem(ParentButton, OptionsListTable, CallbackFunction)
    local IsDropdownOpen = false
    local DropdownMenuFrame = CreateUIInstance("ScrollingFrame", {
        Size = UDim2.new(0.5, 0, 0, 0),
        Position = UDim2.new(0.45, 0, 1, 5),
        BackgroundColor3 = ColorTheme.BackgroundSidebar,
        Visible = false,
        CanvasSize = UDim2.new(0, 0, 0, #OptionsListTable * 30),
        ZIndex = 10
    }, ParentButton.Parent)
    ApplyUICorner(DropdownMenuFrame, 6)
    ApplyUIStroke(DropdownMenuFrame, ColorTheme.PrimaryColor, 1, 0)
    
    for IndexValue, OptionTextValue in ipairs(OptionsListTable) do
        local OptionButton = CreateUIInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, (IndexValue - 1) * 30),
            BackgroundColor3 = ColorTheme.BackgroundCard,
            Text = OptionTextValue,
            Font = Enum.Font.Gotham,
            TextColor3 = ColorTheme.TextColorMain,
            TextSize = 12,
            ZIndex = 11
        }, DropdownMenuFrame)
        
        OptionButton.MouseButton1Click:Connect(function()
            ParentButton.Text = OptionTextValue
            DropdownMenuFrame.Visible = false
            TweenService:Create(DropdownMenuFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.5, 0, 0, 0)}):Play()
            CallbackFunction(OptionTextValue)
        end)
    end
    
    ParentButton.MouseButton1Click:Connect(function()
        IsDropdownOpen = not IsDropdownOpen
        DropdownMenuFrame.Visible = IsDropdownOpen
        TweenService:Create(DropdownMenuFrame, TweenInfo.new(0.2), {Size = IsDropdownOpen and UDim2.new(0.5, 0, 0, #OptionsListTable * 30) or UDim2.new(0.5, 0, 0, 0)}):Play()
    end)
end

CreateDropdownMenuSystem(RarityDropdownButton, {"All Rarity", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine"}, function(SelectedValue)
    StateManager.SelectedRarity = SelectedValue
end)

CreateDropdownMenuSystem(ZoneDropdownButton, {"All Zone", "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss", "Prehistoric", "Cosmic", "CherryBlossom", "TitanTemple"}, function(SelectedValue)
    StateManager.SelectedZone = SelectedValue
end)

local function FindClosestValidEgg()
    local CharacterObject = LocalPlayer.Character
    if not CharacterObject or not CharacterObject:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local HumanoidRootPartObject = CharacterObject.HumanoidRootPart
    local ClosestEggObject = nil
    local MinimumDistanceValue = math.huge

    for _, WorkspaceDescendant in pairs(workspace:GetDescendants()) do
        if WorkspaceDescendant.Name:lower():find("egg") and (WorkspaceDescendant.Name:lower():find("firstareaegg") or WorkspaceDescendant.Name:lower():find("spawnedegg")) then
            
            if StateManager.SelectedRarity ~= "All Rarity" and not WorkspaceDescendant.Name:lower():find(StateManager.SelectedRarity:lower()) then
                continue
            end
            
            if StateManager.SelectedZone ~= "All Zone" and not WorkspaceDescendant.Name:lower():find(StateManager.SelectedZone:lower()) then
                continue
            end
            
            local ObjectPosition = nil
            if WorkspaceDescendant:IsA("Model") then
                ObjectPosition = WorkspaceDescendant:GetPivot().Position
            elseif WorkspaceDescendant:IsA("BasePart") then
                ObjectPosition = WorkspaceDescendant.Position
            end
            
            if ObjectPosition then
                local CalculatedDistance = (HumanoidRootPartObject.Position - ObjectPosition).Magnitude
                if CalculatedDistance < MinimumDistanceValue then
                    ClosestEggObject = WorkspaceDescendant
                    MinimumDistanceValue = CalculatedDistance
                end
            end
        end
    end
    
    return ClosestEggObject
end

local function ExecuteAutoStealSequence()
    local TargetEggObject = FindClosestValidEgg()
    if not TargetEggObject then
        return false
    end

    local SequenceSuccess = pcall(function()
        local CharacterObject = LocalPlayer.Character
        local HumanoidRootPartObject = CharacterObject.HumanoidRootPart
        local TargetPositionValue = nil
        
        if TargetEggObject:IsA("Model") then
            TargetPositionValue = TargetEggObject:GetPivot().Position
        else
            TargetPositionValue = TargetEggObject.Position
        end
        
        HumanoidRootPartObject.CFrame = CFrame.new(TargetPositionValue + Vector3.new(0, 3, 0))
        task.wait(Configuration.DelayAfterTeleport)
        
        local TriggerFolderObject = ReplicatedStorageService:FindFirstChild(Configuration.TriggerFolderName)
        if TriggerFolderObject then
            local TriggerEventObject = TriggerFolderObject:FindFirstChild(Configuration.TriggerEventName)
            if TriggerEventObject then
                TriggerEventObject:FireServer(Configuration.StealToolName)
            end
        end
        
        task.wait(Configuration.DelayAfterTrigger)
        
        local CarryFolderObject = ReplicatedStorageService:FindFirstChild(Configuration.CarryFolderName)
        if CarryFolderObject then
            local CarryEventObject = CarryFolderObject:FindFirstChild(Configuration.CarryEventName)
            if CarryEventObject then
                CarryEventObject:FireServer(TargetEggObject)
            end
        end
        
        task.wait(Configuration.DelayAfterCarry)
        
        HumanoidRootPartObject.CFrame = StateManager.SafeZonePosition
        task.wait(Configuration.DelayAfterSafeZone)
    end)
    
    return SequenceSuccess
end

local function AutoStealMainLoop()
    task.spawn(function()
        while StateManager.IsRunning do
            local LoopSuccess = ExecuteAutoStealSequence()
            
            if LoopSuccess then
                StateManager.SuccessCounter = StateManager.SuccessCounter + 1
                SuccessLabel.Text = "Eggs Brought: " .. StateManager.SuccessCounter
            else
                StateManager.FailCounter = StateManager.FailCounter + 1
                FailLabel.Text = "Failed: " .. StateManager.FailCounter
            end
            
            task.wait(0.5)
        end
    end)
end

ToggleSwitchButton.MouseButton1Click:Connect(function()
    StateManager.IsRunning = not StateManager.IsRunning
    
    if StateManager.IsRunning then
        TweenService:Create(ToggleSwitchButton, TweenInfo.new(0.2), {BackgroundColor3 = ColorTheme.PrimaryColor}):Play()
        TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10)}):Play()
        AutoStealMainLoop()
    else
        TweenService:Create(ToggleSwitchButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 55, 80)}):Play()
        TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10)}):Play()
    end
end)

ExpandArrowButton.MouseButton1Click:Connect(function()
    StateManager.IsMenuExpanded = not StateManager.IsMenuExpanded
    
    if StateManager.IsMenuExpanded then
        TweenService:Create(StealContentFrameInstance, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 230)}):Play()
        ExpandArrowButton.Text = "▼"
    else
        TweenService:Create(StealContentFrameInstance, TweenInfo.new(0.3), {Size = UDim2.new(1, -10, 0, 0)}):Play()
        ExpandArrowButton.Text = "▲"
    end
end)

MinimizeButton.MouseButton1Click:Connect(function()
    if StateManager.IsMinimized then
        return
    end
    
    StateManager.IsMinimized = true
    MainFrameInstance.Visible = false
    
    local MinimizedIconObject = CreateUIInstance("TextButton", {
        Name = "MinimizedIcon",
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 20, 0, 100),
        BackgroundColor3 = ColorTheme.BackgroundCard,
        Text = "H",
        Font = Enum.Font.GothamBold,
        TextColor3 = ColorTheme.PrimaryColor,
        TextSize = 24,
        ZIndex = 50
    }, ScreenGuiInstance)
    
    ApplyUICorner(MinimizedIconObject, 12)
    ApplyUIStroke(MinimizedIconObject, ColorTheme.PrimaryColor, 2, 0)
    
    MinimizedIconObject.MouseButton1Click:Connect(function()
        StateManager.IsMinimized = false
        MainFrameInstance.Visible = true
        MinimizedIconObject:Destroy()
    end)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGuiInstance:Destroy()
end)

local IsDraggingUI = false
local DragStartInputPosition = nil
local StartFramePositionValue = nil

TopBarFrameInstance.InputBegan:Connect(function(InputObject)
    if InputObject.UserInputType == Enum.UserInputType.MouseButton1 or InputObject.UserInputType == Enum.UserInputType.Touch then
        IsDraggingUI = true
        DragStartInputPosition = InputObject.Position
        StartFramePositionValue = MainFrameInstance.Position
    end
end)

TopBarFrameInstance.InputEnded:Connect(function(InputObject)
    if InputObject.UserInputType == Enum.UserInputType.MouseButton1 or InputObject.UserInputType == Enum.UserInputType.Touch then
        IsDraggingUI = false
    end
end)

UserInputService.InputChanged:Connect(function(InputObject)
    if IsDraggingUI and (InputObject.UserInputType == Enum.UserInputType.MouseMovement or InputObject.UserInputType == Enum.UserInputType.Touch) then
        local DragDelta = InputObject.Position - DragStartInputPosition
        MainFrameInstance.Position = UDim2.new(
            StartFramePositionValue.X.Scale,
            StartFramePositionValue.X.Offset + DragDelta.X,
            StartFramePositionValue.Y.Scale,
            StartFramePositionValue.Y.Offset + DragDelta.Y
        )
    end
end)
