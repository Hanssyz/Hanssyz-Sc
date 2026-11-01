local players, tweenService, proximityPromptService, runService, workspaceService, statsService,
  teleportService, httpService, replicatedStorage, collectionService, userInputService,
  guiService, localPlayer, placeId, playerGui, getUserThumbnailAsync, v7, vector, v11,
  localPlayer2, v67, v68, v69, v70, speedPanel, header, arrow, content, textButton18, frame59,
  frame60, textLabel49, frame61, localPlayer3, v85, screenGui2, udim, miniSquare, textButton20,
  v86, mainPanel, frame64, textButton21, textLabel52

players = game:GetService("Players")

tweenService = game:GetService("TweenService")
proximityPromptService = game:GetService("ProximityPromptService")
runService = game:GetService("RunService")
workspaceService = game:GetService("Workspace")
statsService = game:GetService("Stats")
teleportService = game:GetService("TeleportService")
httpService = game:GetService("HttpService")
replicatedStorage = game:GetService("ReplicatedStorage")
collectionService = game:GetService("CollectionService")
userInputService = game:GetService("UserInputService")
guiService = game:GetService("GuiService")
local coreGui = game:GetService("CoreGui")
localPlayer = players.LocalPlayer
local currentCamera = workspaceService.CurrentCamera
placeId = game.PlaceId

if not playerGui then
  pcall(function() playerGui = coreGui end)
end

if not playerGui then
  playerGui = localPlayer:WaitForChild("PlayerGui")
end

local function f1(p1)
  if setclipboard then
    setclipboard(p1)
  elseif toclipboard then
    toclipboard(p1)
  end
end

local function f2()
  if readfile and isfile then
    local v1, v2 = pcall(isfile, "dreyvid_config_v2.txt")

    if v1 and v2 then
      local v3, v4 = pcall(readfile, "dreyvid_config_v2.txt")

      if v3 and v4 then
        local v5 = tonumber(v4)

        if v5 then
          return math.clamp(v5, 0.7, 1.15)
        end

        return 1
      end

      return 1
    end

    return 1
  end

  return 1
end

local function f3(p2)
  if writefile then
    pcall(function() writefile("dreyvid_config_v2.txt", tostring(p2)) end)
  end
end

getUserThumbnailAsync = players:GetUserThumbnailAsync(
  players:GetUserIdFromNameAsync("anki1362"), Enum.ThumbnailType.HeadShot,
  Enum.ThumbnailSize.Size420x420
)

local v6 = {
  CFrame.new(4747.71, 70.57, -335.25), CFrame.new(3520.94, 70.73, -343.74),
  CFrame.new(2446.02, 70.88, -351.18), CFrame.new(1352.11, 71.02, -358.75),
  CFrame.new(544.49, 71.13, -364.34),
}

v7 = false
local v8 = {}
local v9 = {}

local function f4()
  local character = localPlayer.Character

  if not character then
    return
  end

  local humanoid = character:FindFirstChildOfClass("Humanoid")
  local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
  local cframe, connect, v10

  if not humanoid or not humanoidRootPart then
    return
  else
    cframe = currentCamera.CFrame
    local cameraType = currentCamera.CameraType

    currentCamera.CameraType = Enum.CameraType.Scriptable
    currentCamera.CFrame = cframe

    humanoid.BreakJointsOnDeath = false

    for index, value in ipairs(character:GetDescendants()) do
      if value:IsA("Motor6D") then
        value.Enabled = true
      end
    end

    connect = nil

    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero

    for index2, value2 in ipairs(v6) do
      humanoid.PlatformStand = true
      humanoid.Health = 100

      humanoidRootPart.CFrame = value2
      humanoidRootPart.AssemblyLinearVelocity = Vector3.zero

      currentCamera.CFrame = cframe
      task.wait(0.02)
    end

    v10 = os.clock()

    connect = runService.Heartbeat:Connect(function()
      if os.clock() - v10 > 0.35 then
        connect:Disconnect()
        return
      end

      humanoid.Health = 100
      humanoid.PlatformStand = true

      humanoidRootPart.CFrame = v6[#v6]
      humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
      humanoidRootPart.AssemblyAngularVelocity = Vector3.zero

      currentCamera.CFrame = cframe
    end)

    task.wait(0.35)
    humanoid.PlatformStand = false
    currentCamera.CameraType = cameraType
    return
  end
end

local function f5(value3)
  if not (value3 and typeof(value3) == "Instance" and value3:IsA("ProximityPrompt")) then
    return
  end

  if v7 then
    if v8[value3] == nil then
      v8[value3] = value3.HoldDuration
    end

    value3.HoldDuration = 0
    value3.RequiresLineOfSight = false
  elseif v8[value3] ~= nil then
    value3.HoldDuration = v8[value3]
    v8[value3] = nil
  end
end

local function f6(p3)
  if p3 then
    for index3, value4 in ipairs(workspaceService:GetDescendants()) do
      f5(value4)
    end

    local descendantAdded = workspaceService.DescendantAdded
    table.insert(v9, descendantAdded:Connect(f5))
    local promptShown = proximityPromptService.PromptShown
    table.insert(v9, promptShown:Connect(f5))
  else
    for index4, value5 in ipairs(v9) do
    end

    v9 = {}

    for key, value6 in pairs(v8) do
      if key and key.Parent then
        key.HoldDuration = value6
      end
    end

    v8 = {}
  end
end

do
  vector = Vector3.new(200, 2, 200)
  v11 = false
  local v12 = setmetatable({}, { __mode = "k" })
  local v13 = {}

  local platInvisible = Instance.new("Folder")
  platInvisible.Name = "PlatInvisible"
  platInvisible.Parent = workspaceService

  local function f7(value7)
    if not value7 or not value7:IsA("ProximityPrompt") then
      return
    end

    if value7.HoldDuration <= 0 then
      return
    end

    if v12[value7] == nil then
      v12[value7] = value7.HoldDuration
    end

    pcall(function() value7.HoldDuration = 0 end)
  end

  local promptShown2 = proximityPromptService.PromptShown
  table.insert(v13, promptShown2:Connect(f7))
  local descendantAdded2 = workspaceService.DescendantAdded

  table.insert(v13, descendantAdded2:Connect(function(p4)
    if p4:IsA("ProximityPrompt") then
      f7(p4)
    end
  end))

  for index5, value8 in ipairs(workspaceService:GetDescendants()) do
    if value8:IsA("ProximityPrompt") then
      f7(value8)
    end
  end

  local v14 = {}
  local v15 = {}
  local getTagged = collectionService.GetTagged

  local function f8(key2)
    if not key2 or not key2:IsA("BasePart") then
      return
    end

    if v15[key2] == nil then
      v15[key2] = {
        Transparency = key2.Transparency,
        LocalTransparencyModifier = key2.LocalTransparencyModifier,
      }
    end

    pcall(function()
      key2.Transparency = 1
      key2.LocalTransparencyModifier = 1
    end)
  end

  local function f9(p5)
    if not p5 or not p5.Parent then
      return
    end

    local v16 = {}

    if p5:IsA("BasePart") then
      f8(p5)
      v16[#v16 + 1] = p5
    end

    for index6, value9 in ipairs(p5:GetDescendants()) do
      local v17 = value9

      if v17:IsA("BasePart") then
        f8(v17)
        v16[#v16 + 1] = v17
      elseif v17:IsA("Decal") or v17:IsA("Texture") then
        if v15[v17] == nil then
          v15[v17] = { Transparency = v17.Transparency }
        end

        pcall(function() v17.Transparency = 1 end)
        v16[#v16 + 1] = v17
      elseif v17:IsA("ParticleEmitter") or v17:IsA("Trail") or v17:IsA("Beam") then
        pcall(function() v17.Enabled = false end)
      elseif v17:IsA("PointLight") or v17:IsA("SpotLight") or v17:IsA("SurfaceLight") then
        pcall(function() v17.Enabled = false end)
      end
    end

    task.spawn(function()
      while p5 and p5.Parent do
        for index7, value10 in ipairs(v16) do
          local v18 = value10

          if v18.Parent then
            pcall(function()
              if v18:IsA("BasePart") then
                v18.Transparency = 1
                v18.LocalTransparencyModifier = 1
              elseif v18:IsA("Decal") or v18:IsA("Texture") then
                v18.Transparency = 1
              end
            end)
          end
        end

        runService.Heartbeat:Wait()
      end
    end)
  end

  local function f10(value11)
    if not value11 or not value11:IsA("BasePart") then
      return
    end

    if v14[value11] == nil then
      v14[value11] = value11.CanTouch
    end

    pcall(function() value11.CanTouch = false end)
  end

  local function f11(value12)
    if not value12 or not value12.Parent then
      return
    end

    if value12:IsA("BasePart") then
      f10(value12)
    end

    for index8, value13 in ipairs(value12:GetDescendants()) do
      if value13:IsA("BasePart") then
        f10(value13)
      end
    end

    f9(value12)
  end

  for index9, value14 in ipairs(getTagged(collectionService, "PlacedTrap")) do
    f11(value14)
  end

  collectionService:GetInstanceAddedSignal("PlacedTrap"):Connect(function(p6)
    task.defer(function() f11(p6) end)
  end)

  local function f12(position)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local v19 = { platInvisible }

    if localPlayer.Character then
      table.insert(v19, localPlayer.Character)
    end

    raycastParams.FilterDescendantsInstances = v19
    local raycast = workspaceService:Raycast(position, Vector3.new(0, -2000, 0), raycastParams)
    return raycast and raycast.Position.Y or position.Y
  end

  local function f13()
    local character2 = localPlayer.Character

    if not character2 then
      return nil, nil
    end

    return character2:FindFirstChild("HumanoidRootPart"), character2
  end

  local pisoInvisible

  local function makePart(x, z, p7)
    if pisoInvisible then
      pisoInvisible:Destroy()
    end

    pisoInvisible = Instance.new("Part")
    pisoInvisible.Name = "PisoInvisible"
    pisoInvisible.Anchored = true
    pisoInvisible.CanCollide = true
    pisoInvisible.CanQuery = false
    pisoInvisible.CanTouch = false
    pisoInvisible.Material = Enum.Material.SmoothPlastic
    pisoInvisible.Transparency = 1
    pisoInvisible.Size = vector
    pisoInvisible.CFrame = CFrame.new(x, p7, z)
    pisoInvisible.Parent = platInvisible
  end

  local v20, connect2

  local function f14()
    if connect2 then
      return
    end

    connect2 = runService.Stepped:Connect(function()
      if not v11 or not v20 then
        return
      else
        local v21 = f13()

        if not v21 then
          return
        end

        if pisoInvisible and pisoInvisible.Parent then
          local z2 = pisoInvisible.Position.Z
          local x2 = pisoInvisible.Position.X
          local z3 = v21.Position.Z
          local x3 = v21.Position.X

          if (x2 - x3) * (x2 - x3) + (z2 - z3) * (z2 - z3) > 4 then
            pisoInvisible.CFrame = CFrame.new(x3, v20 - 0.5, z3)
          end
        end

        if v21.Position.Y < v20 then
          local v22 = math.max(v21.AssemblyLinearVelocity.Y, 0)

          v21.CFrame = CFrame.new(v21.Position.X, v20, v21.Position.Z) * v21.CFrame.Rotation

          v21.AssemblyLinearVelocity = Vector3.new(
            v21.AssemblyLinearVelocity.X, v22, v21.AssemblyLinearVelocity.Z
          )

          v21.AssemblyAngularVelocity = Vector3.zero
        end

        return
      end
    end)
  end

  local function f15()
    if connect2 then
      pcall(function() connect2:Disconnect() end)
      connect2 = nil
    end
  end

  local v23 = false

  local function f16()
    if v23 or not v11 then
      return
    end

    local v24
    v24, v352 = f13()

    local vector2, rotation

    if not v24 then
      return
    else
      v23 = true
      v20 = f12(v24.Position) + 40
      makePart(v24.Position.X, v24.Position.Z, v20 - 0.5)
      local position2 = v24.Position
      vector2 = Vector3.new(position2.X, v20 + 3, position2.Z)
      rotation = v24.CFrame.Rotation
      local v25 = os.clock()

      while v23 do
        local v26 = math.clamp((os.clock() - v25) / 0.2375, 0, 1)
        local lerp = position2:Lerp(vector2, v26 * v26 * (3 - 2 * v26))

        pcall(function()
          v24.CFrame = CFrame.new(lerp) * rotation
          v24.AssemblyLinearVelocity = Vector3.zero
          v24.AssemblyAngularVelocity = Vector3.zero
        end)

        if v26 >= 1 then
          break
        end

        runService.Heartbeat:Wait()
      end

      if v24 and v24.Parent then
        pcall(function()
          v24.CFrame = CFrame.new(vector2) * rotation
          v24.AssemblyLinearVelocity = Vector3.zero
          v24.AssemblyAngularVelocity = Vector3.zero
        end)
      end

      f14()
      v23 = false
      return
    end
  end

  local function f17()
    if not v11 then
      return
    end

    task.wait(0.1)
    f16()
  end

  local function f18(character3)
    if not character3 then
      return
    end

    character3.ChildAdded:Connect(function(child)
      if child:IsA("Tool") then
        task.spawn(f17)
      end
    end)
  end

  localPlayer.CharacterAdded:Connect(f18)

  if localPlayer.Character then
    f18(localPlayer.Character)
  end

  localPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    v20 = nil

    if pisoInvisible then
      pisoInvisible:Destroy()
      pisoInvisible = nil
    end
  end)

  local function f19()
    v11 = false
    v20 = nil
    v23 = false
    f15()

    if pisoInvisible then
      pisoInvisible:Destroy()
      pisoInvisible = nil
    end
  end

  local function f20()
    v11 = true
  end

  local function makeFrame(frame, p8, p9, p10, p11, zindex)
    local frame2 = Instance.new("Frame")
    frame2.Size = UDim2.new(0, p8, 0, p9)
    frame2.Position = UDim2.new(0.5, p10, 0.5, p11)
    frame2.AnchorPoint = Vector2.new(0.5, 0.5)
    frame2.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
    frame2.BackgroundTransparency = 0.85
    frame2.BorderSizePixel = 0
    frame2.ZIndex = zindex
    frame2.Parent = frame

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = frame2

    local uiGradient = Instance.new("UIGradient")

    uiGradient.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 255)),
      ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 100, 255)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 220, 255)),
    })

    uiGradient.Rotation = 45
    uiGradient.Parent = frame2

    return frame2, uiGradient
  end

  local function makeFrame2(frame3, p12, p13, p14, p15, rotation2, color, zindex2)
    local frame4 = Instance.new("Frame")
    frame4.Size = UDim2.new(0, p12, 0, p13)
    frame4.Position = UDim2.new(0.5, p14, 0.5, p15)
    frame4.AnchorPoint = Vector2.new(0.5, 0.5)
    frame4.BackgroundColor3 = color
    frame4.BackgroundTransparency = 0.5
    frame4.BorderSizePixel = 0
    frame4.Rotation = rotation2
    frame4.ZIndex = zindex2
    frame4.Parent = frame3

    local uiCorner2 = Instance.new("UICorner")
    uiCorner2.CornerRadius = UDim.new(1, 0)
    uiCorner2.Parent = frame4

    return frame4
  end

  if playerGui:FindFirstChild("DreyvidHub") then
    playerGui.DreyvidHub:Destroy()
  end

  if playerGui:FindFirstChild("DreyvidIntro") then
    playerGui.DreyvidIntro:Destroy()
  end

  if playerGui:FindFirstChild("DreyvidKey") then
    playerGui.DreyvidKey:Destroy()
  end

  local function makeTextLabel(p16)
    local dreyvidIntro = Instance.new("ScreenGui")
    dreyvidIntro.Name = "DreyvidIntro"
    dreyvidIntro.ResetOnSpawn = false
    dreyvidIntro.IgnoreGuiInset = true
    dreyvidIntro.DisplayOrder = 998
    dreyvidIntro.Parent = playerGui

    local frame5 = Instance.new("Frame")
    frame5.Size = UDim2.new(1, 0, 1, 0)
    frame5.BackgroundColor3 = Color3.fromRGB(5, 7, 16)
    frame5.BackgroundTransparency = 1
    frame5.BorderSizePixel = 0
    frame5.ZIndex = 150
    frame5.Parent = dreyvidIntro

    local uiGradient2 = Instance.new("UIGradient")

    uiGradient2.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 9, 22)),
      ColorSequenceKeypoint.new(0.45, Color3.fromRGB(22, 13, 40)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 10, 26)),
    })

    uiGradient2.Rotation = 90
    uiGradient2.Parent = frame5

    local count = 0

    while true do
      count = 1 + count

      if not (count <= 18) then
        break
      end

      local frame6 = Instance.new("Frame")
      local v27 = math.random(2, 4)

      frame6.Size = UDim2.new(0, v27, 0, v27)

      frame6.BackgroundColor3 = count % 3 == 0 and Color3.fromRGB(185, 130, 255)
        or Color3.fromRGB(120, 190, 255)

      frame6.BackgroundTransparency = 0.5
      frame6.BorderSizePixel = 0
      frame6.ZIndex = 160
      frame6.Parent = dreyvidIntro

      local uiCorner3 = Instance.new("UICorner")
      uiCorner3.CornerRadius = UDim.new(1, 0)
      uiCorner3.Parent = frame6

      task.spawn(function()
        while dreyvidIntro.Parent do
          local v28 = math.random(2, 98) / 100
          local v29 = math.random(34, 62) / 10

          frame6.Position = UDim2.new(v28, 0, 1, math.random(0, 140))
          frame6.BackgroundTransparency = 0.5

          tweenService:Create(frame6, TweenInfo.new(v29, Enum.EasingStyle.Linear), {
            Position = UDim2.new(v28, 0, -0.08, 0),
            BackgroundTransparency = 1,
          }):Play()

          task.wait(v29 + math.random(4, 20) / 10)
        end
      end)
    end

    local frame7 = Instance.new("Frame")
    frame7.Size = UDim2.new(0, 560, 0, 350)
    frame7.Position = UDim2.new(0.5, -280, 0.5, -175)
    frame7.BackgroundTransparency = 1
    frame7.ZIndex = 200
    frame7.Parent = dreyvidIntro

    local v30, v31 = makeFrame(frame7, 420, 150, 0, -26, 198)
    v30.BackgroundTransparency = 1

    local v32, v33 = makeFrame(frame7, 320, 110, 0, -26, 199)
    v32.BackgroundTransparency = 1

    local v34 = makeFrame(frame7, 220, 70, 0, -26, 200)
    v34.BackgroundTransparency = 1

    local v35 = makeFrame2(frame7, 520, 2, 0, -74, 0, Color3.fromRGB(120, 180, 255), 197)
    local v36 = makeFrame2(frame7, 520, 2, 0, 22, 0, Color3.fromRGB(180, 120, 255), 197)
    local v37 = makeFrame2(frame7, 380, 1, 0, -92, 0, Color3.fromRGB(60, 220, 255), 196)
    local v38 = makeFrame2(frame7, 380, 1, 0, 40, 0, Color3.fromRGB(60, 220, 255), 196)
    local v39 = makeFrame2(frame7, 460, 1, 0, -26, 22, Color3.fromRGB(110, 200, 255), 196)
    local v40 = makeFrame2(frame7, 460, 1, 0, -26, -22, Color3.fromRGB(200, 110, 255), 196)

    for index10, value15 in ipairs({ v35, v36, v37, v38, v39, v40 }) do
      value15.BackgroundTransparency = 1
    end

    local frame8 = Instance.new("Frame")
    frame8.Size = UDim2.new(0, 92, 0, 92)
    frame8.Position = UDim2.new(0.5, -46, 0, 4)
    frame8.BackgroundTransparency = 1
    frame8.ZIndex = 210
    frame8.Parent = frame7

    local frame9 = Instance.new("Frame")
    frame9.Size = UDim2.new(1, 20, 1, 20)
    frame9.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame9.AnchorPoint = Vector2.new(0.5, 0.5)
    frame9.BackgroundTransparency = 1
    frame9.ZIndex = 209
    frame9.Parent = frame8

    local uiCorner4 = Instance.new("UICorner")
    uiCorner4.CornerRadius = UDim.new(1, 0)
    uiCorner4.Parent = frame9

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(140, 200, 255)
    uiStroke.Thickness = 1
    uiStroke.Transparency = 0.45
    uiStroke.Parent = frame9

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
    imageLabel.BackgroundTransparency = 0.15
    imageLabel.BorderSizePixel = 0
    imageLabel.ZIndex = 211
    imageLabel.Parent = frame8

    local uiCorner5 = Instance.new("UICorner")
    uiCorner5.CornerRadius = UDim.new(1, 0)
    uiCorner5.Parent = imageLabel

    local uiStroke2 = Instance.new("UIStroke")
    uiStroke2.Color = Color3.fromRGB(120, 180, 255)
    uiStroke2.Thickness = 2
    uiStroke2.Transparency = 0.1
    uiStroke2.Parent = imageLabel

    local uiGradient3 = Instance.new("UIGradient")

    uiGradient3.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 255)),
      ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 120, 255)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 220, 255)),
    })

    uiGradient3.Parent = uiStroke2

    pcall(function()
      imageLabel.Image = players:GetUserThumbnailAsync(
        localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420
      )
    end)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 60)
    textLabel.Position = UDim2.new(0, 0, 0, 104)
    textLabel.BackgroundTransparency = 1
    textLabel.RichText = true
    textLabel.Text = "Dreyvid Hub <font color='#96CDFF' size='28'> V3</font>"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 50
    textLabel.TextStrokeTransparency = 0.55
    textLabel.TextStrokeColor3 = Color3.fromRGB(50, 120, 220)
    textLabel.TextTransparency = 1
    textLabel.ZIndex = 210
    textLabel.Parent = frame7

    local uiGradient4 = Instance.new("UIGradient")

    uiGradient4.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
      ColorSequenceKeypoint.new(0.35, Color3.fromRGB(120, 200, 255)),
      ColorSequenceKeypoint.new(0.65, Color3.fromRGB(200, 140, 255)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })

    uiGradient4.Parent = textLabel

    local textLabel2 = Instance.new("TextLabel")
    textLabel2.Size = UDim2.new(1, 0, 0, 18)
    textLabel2.Position = UDim2.new(0, 0, 0, 162)
    textLabel2.BackgroundTransparency = 1
    textLabel2.Text = "STEAL AN EGG  ·  PREMIUM BUILD"
    textLabel2.TextColor3 = Color3.fromRGB(140, 190, 255)
    textLabel2.Font = Enum.Font.GothamBold
    textLabel2.TextSize = 12
    textLabel2.TextTransparency = 1
    textLabel2.ZIndex = 210
    textLabel2.Parent = frame7

    local textLabel3 = Instance.new("TextLabel")
    textLabel3.Size = UDim2.new(1, 0, 0, 20)
    textLabel3.Position = UDim2.new(0, 0, 0, 186)
    textLabel3.BackgroundTransparency = 1
    textLabel3.Text = "Bienvenido, " .. localPlayer.DisplayName
    textLabel3.TextColor3 = Color3.fromRGB(235, 240, 255)
    textLabel3.Font = Enum.Font.GothamMedium
    textLabel3.TextSize = 14
    textLabel3.TextTransparency = 1
    textLabel3.ZIndex = 210
    textLabel3.Parent = frame7

    local frame10 = Instance.new("Frame")
    frame10.Size = UDim2.new(0, 420, 0, 10)
    frame10.Position = UDim2.new(0.5, -210, 0, 228)
    frame10.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    frame10.BackgroundTransparency = 0.15
    frame10.BorderSizePixel = 0
    frame10.ZIndex = 210
    frame10.Parent = frame7

    local uiCorner6 = Instance.new("UICorner")
    uiCorner6.CornerRadius = UDim.new(1, 0)
    uiCorner6.Parent = frame10

    local uiStroke3 = Instance.new("UIStroke")
    uiStroke3.Color = Color3.fromRGB(70, 100, 150)
    uiStroke3.Thickness = 1
    uiStroke3.Transparency = 0.5
    uiStroke3.Parent = frame10

    local frame11 = Instance.new("Frame")
    frame11.Size = UDim2.new(0, 0, 1, 0)
    frame11.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
    frame11.BorderSizePixel = 0
    frame11.ZIndex = 211
    frame11.Parent = frame10

    local uiCorner7 = Instance.new("UICorner")
    uiCorner7.CornerRadius = UDim.new(1, 0)
    uiCorner7.Parent = frame11

    local uiGradient5 = Instance.new("UIGradient")

    uiGradient5.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 255)),
      ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 210, 255)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 120, 255)),
    })

    uiGradient5.Parent = frame11

    local textLabel4 = Instance.new("TextLabel")
    textLabel4.Size = UDim2.new(0, 300, 0, 16)
    textLabel4.Position = UDim2.new(0.5, -210, 0, 244)
    textLabel4.BackgroundTransparency = 1
    textLabel4.Text = ""
    textLabel4.TextColor3 = Color3.fromRGB(150, 165, 195)
    textLabel4.Font = Enum.Font.GothamMedium
    textLabel4.TextSize = 11
    textLabel4.TextXAlignment = Enum.TextXAlignment.Left
    textLabel4.TextTransparency = 1
    textLabel4.ZIndex = 210
    textLabel4.Parent = frame7

    local textLabel5 = Instance.new("TextLabel")
    textLabel5.Size = UDim2.new(0, 120, 0, 16)
    textLabel5.Position = UDim2.new(0.5, 90, 0, 244)
    textLabel5.BackgroundTransparency = 1
    textLabel5.Text = "0%"
    textLabel5.TextColor3 = Color3.fromRGB(120, 200, 255)
    textLabel5.Font = Enum.Font.GothamBold
    textLabel5.TextSize = 11
    textLabel5.TextXAlignment = Enum.TextXAlignment.Right
    textLabel5.TextTransparency = 1
    textLabel5.ZIndex = 210
    textLabel5.Parent = frame7

    local textLabel6 = Instance.new("TextLabel")
    textLabel6.Size = UDim2.new(1, 0, 0, 14)
    textLabel6.Position = UDim2.new(0, 0, 0, 268)
    textLabel6.BackgroundTransparency = 1
    textLabel6.Text = "v3  ·  https://discord.gg/MbQWs6SAgK"
    textLabel6.TextColor3 = Color3.fromRGB(90, 105, 135)
    textLabel6.Font = Enum.Font.GothamMedium
    textLabel6.TextSize = 10
    textLabel6.TextTransparency = 1
    textLabel6.ZIndex = 210
    textLabel6.Parent = frame7

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(v30, TweenInfo.new(
          1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.new(0, 480, 0, 175),
          BackgroundTransparency = 0.68,
        }):Play()

        task.wait(1.5)

        tweenService:Create(v30, TweenInfo.new(
          1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.new(0, 420, 0, 150),
          BackgroundTransparency = 0.78,
        }):Play()

        task.wait(1.5)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(v32, TweenInfo.new(
          1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.new(0, 360, 0, 130),
          BackgroundTransparency = 0.72,
        }):Play()

        task.wait(1.2)

        tweenService:Create(v32, TweenInfo.new(
          1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.new(0, 320, 0, 110),
          BackgroundTransparency = 0.82,
        }):Play()

        task.wait(1.2)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(v34, TweenInfo.new(
          1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.new(0, 250, 0, 86),
          BackgroundTransparency = 0.85,
        }):Play()

        task.wait(1)

        tweenService:Create(v34, TweenInfo.new(
          1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.new(0, 220, 0, 70),
          BackgroundTransparency = 0.92,
        }):Play()

        task.wait(1)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(v31, TweenInfo.new(3, Enum.EasingStyle.Linear), {
          Rotation = 405,
        }):Play()

        task.wait(3)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(v33, TweenInfo.new(2.4, Enum.EasingStyle.Linear), {
          Rotation = -315,
        }):Play()

        task.wait(2.4)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(uiStroke, TweenInfo.new(
          1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), { Transparency = 0, Thickness = 2 }):Play()

        tweenService:Create(uiGradient3, TweenInfo.new(1.4, Enum.EasingStyle.Linear), {
          Rotation = uiGradient3.Rotation + 180,
        }):Play()

        task.wait(1.4)

        tweenService:Create(uiStroke, TweenInfo.new(
          1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), { Transparency = 0.5, Thickness = 1 }):Play()

        task.wait(1.4)
      end
    end)

    task.spawn(function()
      local count2 = 0

      while dreyvidIntro.Parent do
        count2 = count2 + 1

        tweenService:Create(uiGradient4, TweenInfo.new(1.6, Enum.EasingStyle.Linear), {
          Rotation = count2 * 45,
        }):Play()

        task.wait(1.6)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        for index11, value16 in ipairs({ v35, v36 }) do
          tweenService:Create(value16, TweenInfo.new(
            1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
          ), {
            Size = UDim2.new(0, value16.Size.X.Offset + 70, 0, value16.Size.Y.Offset),
            BackgroundTransparency = 0.15,
          }):Play()
        end

        for index12, value17 in ipairs({ v37, v38 }) do
          tweenService:Create(value17, TweenInfo.new(
            1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
          ), {
            Size = UDim2.new(0, value17.Size.X.Offset + 40, 0, value17.Size.Y.Offset),
            BackgroundTransparency = 0.3,
          }):Play()
        end

        task.wait(1.3)

        for index13, value18 in ipairs({ v35, v36, v37, v38 }) do
          tweenService:Create(value18, TweenInfo.new(
            1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
          ), {
            Size = UDim2.new(
              0, math.max(240, value18.Size.X.Offset - 70), 0, value18.Size.Y.Offset
            ),
            BackgroundTransparency = 0.55,
          }):Play()
        end

        task.wait(1.3)
      end
    end)

    task.spawn(function()
      while dreyvidIntro.Parent do
        tweenService:Create(v39, TweenInfo.new(
          2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), { Rotation = 38, BackgroundTransparency = 0.2 }):Play()

        tweenService:Create(v40, TweenInfo.new(
          2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), { Rotation = -38, BackgroundTransparency = 0.2 }):Play()

        task.wait(2)

        tweenService:Create(v39, TweenInfo.new(
          2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), { Rotation = 12, BackgroundTransparency = 0.55 }):Play()

        tweenService:Create(v40, TweenInfo.new(
          2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), { Rotation = -12, BackgroundTransparency = 0.55 }):Play()

        task.wait(2)
      end
    end)

    task.spawn(function()
      local function f21(p17, p18, p19, p20)
        tweenService:Create(p17, TweenInfo.new(
          p19, p20 or Enum.EasingStyle.Quart, Enum.EasingDirection.Out
        ), p18):Play()
      end

      task.wait(0.02)

      frame8.Size = UDim2.new(0, 20, 0, 20)
      frame8.Position = UDim2.new(0.5, -10, 0, 40)

      f21(
        frame8, { Size = UDim2.new(0, 92, 0, 92), Position = UDim2.new(0.5, -46, 0, 4) }, 0.15,
        Enum.EasingStyle.Back
      )

      task.wait(0.03)

      f21(v30, { BackgroundTransparency = 0.78 }, 0.15, Enum.EasingStyle.Quint)
      f21(v32, { BackgroundTransparency = 0.82 }, 0.15, Enum.EasingStyle.Quint)
      f21(v34, { BackgroundTransparency = 0.9 }, 0.15, Enum.EasingStyle.Quint)

      task.wait(0.04)

      textLabel.TextTransparency = 0
      textLabel.TextSize = 30

      f21(textLabel, { TextSize = 50 }, 0.12, Enum.EasingStyle.Back)
      f21(textLabel2, { TextTransparency = 0 }, 0.1)
      f21(textLabel3, { TextTransparency = 0 }, 0.1)
      f21(textLabel4, { TextTransparency = 0 }, 0.1)
      f21(textLabel5, { TextTransparency = 0 }, 0.1)
      f21(textLabel6, { TextTransparency = 0 }, 0.1)
      f21(frame10, { BackgroundTransparency = 0.15 }, 0.1)
      f21(uiStroke3, { Transparency = 0.35 }, 0.1)

      for index14, value19 in ipairs({
        { texto = "Iniciando entorno seguro", avance = 0.18, espera = 0.08 },
        { texto = "Cargando librería del hub", avance = 0.36, espera = 0.08 },
        { texto = "Leyendo datos del juego", avance = 0.6, espera = 0.08 },
        { texto = "Preparando módulos", avance = 0.84, espera = 0.08 },
        { texto = "Listo. Abriendo panel", avance = 1, espera = 0.08 },
      }) do
        if not dreyvidIntro.Parent then
          return
        end

        textLabel4.Text = value19.texto

        tweenService:Create(frame11, TweenInfo.new(
          value19.espera * 0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out
        ), { Size = UDim2.new(value19.avance, 0, 1, 0) }):Play()

        textLabel5.Text = tostring(math.floor(value19.avance * 100)) .. "%"
        task.wait(value19.espera)
      end

      task.wait(0.03)

      if not dreyvidIntro.Parent then
        return
      end

      tweenService:Create(textLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quart), {
        TextTransparency = 1,
        TextSize = 64,
      }):Play()

      tweenService:Create(textLabel2, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
      tweenService:Create(textLabel3, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
      tweenService:Create(textLabel4, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
      tweenService:Create(textLabel5, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
      tweenService:Create(textLabel6, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()

      tweenService:Create(v30, TweenInfo.new(0.1), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 700, 0, 240),
      }):Play()

      tweenService:Create(v32, TweenInfo.new(0.1), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 520, 0, 180),
      }):Play()

      tweenService:Create(v34, TweenInfo.new(0.1), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 400, 0, 130),
      }):Play()

      tweenService:Create(frame8, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 130, 0, 130),
        Position = UDim2.new(0.5, -65, 0, -14),
      }):Play()

      tweenService:Create(imageLabel, TweenInfo.new(0.1), {
        ImageTransparency = 1,
        BackgroundTransparency = 1,
      }):Play()

      tweenService:Create(uiStroke2, TweenInfo.new(0.1), { Transparency = 1 }):Play()
      tweenService:Create(uiStroke, TweenInfo.new(0.1), { Transparency = 1 }):Play()
      tweenService:Create(frame10, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
      tweenService:Create(uiStroke3, TweenInfo.new(0.1), { Transparency = 1 }):Play()

      for index15, value20 in ipairs({ v35, v36, v37, v38, v39, v40 }) do
        tweenService:Create(value20, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
      end

      task.wait(0.15)
      dreyvidIntro:Destroy()

      if p16 then
        p16()
      end
    end)
  end

  local function makeTextButton(p21)
    local function f22(text)
      pcall(function()
        if writefile then
          writefile("DreyvidHub_Key.txt", text)
        end
      end)
    end

    local function f23()
      local dreyvidHubKeyTxt

      pcall(function()
        if readfile and isfile and isfile("DreyvidHub_Key.txt") then
          dreyvidHubKeyTxt = readfile("DreyvidHub_Key.txt")
        end
      end)

      return dreyvidHubKeyTxt
    end

    local dreyvidKey = Instance.new("ScreenGui")
    dreyvidKey.Name = "DreyvidKey"
    dreyvidKey.ResetOnSpawn = false
    dreyvidKey.IgnoreGuiInset = true
    dreyvidKey.DisplayOrder = 999
    dreyvidKey.Parent = playerGui

    local frame12 = Instance.new("Frame")
    frame12.Size = UDim2.new(1, 0, 1, 0)
    frame12.BackgroundColor3 = Color3.fromRGB(5, 7, 16)
    frame12.BackgroundTransparency = 0.35
    frame12.BorderSizePixel = 0
    frame12.ZIndex = 1
    frame12.Parent = dreyvidKey

    local frame13 = Instance.new("Frame")
    frame13.Size = UDim2.new(0, 260, 0, 130)
    frame13.Position = UDim2.new(0.5, -169, 0.5, -85)
    frame13.BackgroundColor3 = Color3.fromRGB(9, 11, 17)
    frame13.BackgroundTransparency = 0.05
    frame13.BorderSizePixel = 0
    frame13.Active = true
    frame13.Draggable = true
    frame13.ZIndex = 2
    frame13.Parent = dreyvidKey

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.3
    uiScale.Parent = frame13

    local uiCorner8 = Instance.new("UICorner")
    uiCorner8.CornerRadius = UDim.new(0, 14)
    uiCorner8.Parent = frame13

    local uiStroke4 = Instance.new("UIStroke")
    uiStroke4.Color = Color3.fromRGB(90, 140, 220)
    uiStroke4.Thickness = 1.4
    uiStroke4.Transparency = 0.15
    uiStroke4.Parent = frame13

    local uiGradient6 = Instance.new("UIGradient")
    uiGradient6.Color = ColorSequence.new(Color3.fromRGB(24, 30, 44), Color3.fromRGB(9, 11, 17))
    uiGradient6.Rotation = 135
    uiGradient6.Parent = frame13

    task.spawn(function()
      while dreyvidKey.Parent do
        tweenService:Create(uiStroke4, TweenInfo.new(
          1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Color = Color3.fromRGB(140, 200, 255),
          Transparency = 0.05,
          Thickness = 1.8,
        }):Play()

        task.wait(1.6)

        tweenService:Create(uiStroke4, TweenInfo.new(
          1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Color = Color3.fromRGB(90, 140, 220),
          Transparency = 0.15,
          Thickness = 1.4,
        }):Play()

        task.wait(1.6)
      end
    end)

    local textLabel7 = Instance.new("TextLabel")
    textLabel7.Size = UDim2.new(1, 0, 0, 22)
    textLabel7.Position = UDim2.new(0, 0, 0, 10)
    textLabel7.BackgroundTransparency = 1
    textLabel7.RichText = true
    textLabel7.Text = "Dreyvid Hub <font color='#96CDFF' size='13'> V3</font>"
    textLabel7.TextColor3 = Color3.fromRGB(240, 244, 255)
    textLabel7.Font = Enum.Font.GothamBold
    textLabel7.TextSize = 18
    textLabel7.ZIndex = 3
    textLabel7.Parent = frame13

    local uiGradient7 = Instance.new("UIGradient")

    uiGradient7.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
      ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 140, 255)),
    })

    uiGradient7.Parent = textLabel7

    local textLabel8 = Instance.new("TextLabel")
    textLabel8.Size = UDim2.new(1, 0, 0, 12)
    textLabel8.Position = UDim2.new(0, 0, 0, 30)
    textLabel8.BackgroundTransparency = 1
    textLabel8.Text = "SISTEMA DE VERIFICACIÓN"
    textLabel8.TextColor3 = Color3.fromRGB(130, 155, 190)
    textLabel8.Font = Enum.Font.GothamBold
    textLabel8.TextSize = 8
    textLabel8.ZIndex = 3
    textLabel8.Parent = frame13

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 200, 0, 20)
    textBox.Position = UDim2.new(0.5, -100, 0, 46)
    textBox.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    textBox.BackgroundTransparency = 0.1
    textBox.BorderSizePixel = 0
    textBox.Text = ""
    textBox.PlaceholderText = "Ingresa tu key…"
    textBox.PlaceholderColor3 = Color3.fromRGB(90, 105, 135)
    textBox.TextColor3 = Color3.fromRGB(240, 244, 255)
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 11
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 3
    textBox.Parent = frame13

    local uiCorner9 = Instance.new("UICorner")
    uiCorner9.CornerRadius = UDim.new(0, 6)
    uiCorner9.Parent = textBox

    local uiStroke5 = Instance.new("UIStroke")
    uiStroke5.Color = Color3.fromRGB(70, 100, 150)
    uiStroke5.Thickness = 1
    uiStroke5.Transparency = 0.3
    uiStroke5.Parent = textBox

    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingLeft = UDim.new(0, 8)
    uiPadding.PaddingRight = UDim.new(0, 8)
    uiPadding.Parent = textBox

    local textLabel9 = Instance.new("TextLabel")
    textLabel9.Size = UDim2.new(1, -30, 0, 12)
    textLabel9.Position = UDim2.new(0, 15, 0, 70)
    textLabel9.BackgroundTransparency = 1
    textLabel9.Text = ""
    textLabel9.TextColor3 = Color3.fromRGB(150, 165, 195)
    textLabel9.Font = Enum.Font.GothamMedium
    textLabel9.TextSize = 9
    textLabel9.TextXAlignment = Enum.TextXAlignment.Left
    textLabel9.ZIndex = 3
    textLabel9.Parent = frame13

    local imageButton = Instance.new("ImageButton")
    imageButton.Size = UDim2.new(0, 22, 0, 22)
    imageButton.Position = UDim2.new(0, 18, 1, -30)
    imageButton.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
    imageButton.Image = "rbxassetid://93628638506572"
    imageButton.ImageColor3 = Color3.fromRGB(120, 180, 255)
    imageButton.ScaleType = Enum.ScaleType.Fit
    imageButton.AutoButtonColor = false
    imageButton.ZIndex = 3
    imageButton.Parent = frame13

    local uiCorner10 = Instance.new("UICorner")
    uiCorner10.CornerRadius = UDim.new(0, 6)
    uiCorner10.Parent = imageButton

    local uiStroke6 = Instance.new("UIStroke")
    uiStroke6.Color = Color3.fromRGB(70, 90, 130)
    uiStroke6.Transparency = 0.5
    uiStroke6.Parent = imageButton

    local textButton = Instance.new("TextButton")
    textButton.Size = UDim2.new(0, 80, 0, 22)
    textButton.Position = UDim2.new(0, 46, 1, -30)
    textButton.BackgroundTransparency = 1
    textButton.Text = "Sacar Key"
    textButton.TextColor3 = Color3.fromRGB(140, 190, 255)
    textButton.Font = Enum.Font.GothamBold
    textButton.TextSize = 10
    textButton.TextXAlignment = Enum.TextXAlignment.Left
    textButton.AutoButtonColor = false
    textButton.ZIndex = 3
    textButton.Parent = frame13

    local textButton2 = Instance.new("TextButton")
    textButton2.Size = UDim2.new(0, 82, 0, 22)
    textButton2.Position = UDim2.new(1, -100, 1, -30)
    textButton2.BackgroundColor3 = Color3.fromRGB(26, 46, 74)
    textButton2.Text = "Verificar"
    textButton2.TextColor3 = Color3.fromRGB(150, 205, 255)
    textButton2.Font = Enum.Font.GothamBold
    textButton2.TextSize = 10
    textButton2.AutoButtonColor = false
    textButton2.ZIndex = 3
    textButton2.Parent = frame13

    local uiCorner11 = Instance.new("UICorner")
    uiCorner11.CornerRadius = UDim.new(0, 6)
    uiCorner11.Parent = textButton2

    local uiStroke7 = Instance.new("UIStroke")
    uiStroke7.Color = Color3.fromRGB(70, 130, 210)
    uiStroke7.Transparency = 0.3
    uiStroke7.Parent = textButton2

    local v41 = f23()

    if v41 and v41 ~= "" then
      textBox.Text = v41
      textLabel9.Text = "Key detectada · apretá Verificar"
      textLabel9.TextColor3 = Color3.fromRGB(120, 200, 255)
    end

    local function f24()
      local text2 = textBox.Text

      if text2 == "1111" then
        textLabel9.Text = "Key correcta · accediendo…"
        textLabel9.TextColor3 = Color3.fromRGB(120, 235, 175)

        tweenService:Create(uiStroke7, TweenInfo.new(0.2), {
          Color = Color3.fromRGB(80, 220, 140),
        }):Play()

        tweenService:Create(textButton2, TweenInfo.new(0.2), {
          BackgroundColor3 = Color3.fromRGB(24, 62, 46),
          TextColor3 = Color3.fromRGB(120, 235, 175),
        }):Play()

        f22(text2)
        task.wait(0.5)
        dreyvidKey:Destroy()

        if p21 then
          p21()
        end
      else
        textLabel9.Text = "Key incorrecta. Intentá de nuevo."
        textLabel9.TextColor3 = Color3.fromRGB(255, 130, 130)

        tweenService:Create(uiStroke7, TweenInfo.new(0.2), {
          Color = Color3.fromRGB(220, 90, 90),
        }):Play()

        tweenService:Create(textButton2, TweenInfo.new(0.2), {
          BackgroundColor3 = Color3.fromRGB(44, 24, 30),
          TextColor3 = Color3.fromRGB(230, 120, 120),
        }):Play()

        local position3 = textBox.Position
        local count3 = 0

        while true do
          count3 = 1 + count3

          if not (count3 <= 6) then
            break
          end

          tweenService:Create(textBox, TweenInfo.new(0.05), {
            Position = position3 + UDim2.new(0, count3 % 2 == 0 and 5 or -5, 0, 0),
          }):Play()

          task.wait(0.05)
        end

        tweenService:Create(textBox, TweenInfo.new(0.08), { Position = position3 }):Play()

        task.delay(1.2, function()
          tweenService:Create(uiStroke7, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(70, 130, 210),
          }):Play()

          tweenService:Create(textButton2, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(26, 46, 74),
            TextColor3 = Color3.fromRGB(150, 205, 255),
          }):Play()
        end)
      end
    end

    textButton2.MouseButton1Click:Connect(f24)

    textBox.FocusLost:Connect(function(p22)
      if p22 then
        f24()
      end
    end)

    local frame14 = Instance.new("Frame")
    frame14.Size = UDim2.new(0, 230, 0, 178)
    frame14.Position = UDim2.new(0.5, -150, 0.5, -116)
    frame14.BackgroundColor3 = Color3.fromRGB(9, 11, 17)
    frame14.BackgroundTransparency = 0.05
    frame14.BorderSizePixel = 0
    frame14.Active = true
    frame14.Draggable = true
    frame14.Visible = false
    frame14.ZIndex = 10
    frame14.Parent = dreyvidKey

    local uiScale2 = Instance.new("UIScale")
    uiScale2.Scale = 1.3
    uiScale2.Parent = frame14

    local uiCorner12 = Instance.new("UICorner")
    uiCorner12.CornerRadius = UDim.new(0, 12)
    uiCorner12.Parent = frame14

    local uiStroke8 = Instance.new("UIStroke")
    uiStroke8.Color = Color3.fromRGB(140, 200, 255)
    uiStroke8.Thickness = 1.4
    uiStroke8.Transparency = 0.15
    uiStroke8.Parent = frame14

    local uiGradient8 = Instance.new("UIGradient")
    uiGradient8.Color = ColorSequence.new(Color3.fromRGB(24, 30, 44), Color3.fromRGB(9, 11, 17))
    uiGradient8.Rotation = 135
    uiGradient8.Parent = frame14

    local textLabel10 = Instance.new("TextLabel")
    textLabel10.Size = UDim2.new(1, -50, 0, 18)
    textLabel10.Position = UDim2.new(0, 12, 0, 8)
    textLabel10.BackgroundTransparency = 1
    textLabel10.Text = "Links de la comunidad"
    textLabel10.TextColor3 = Color3.fromRGB(240, 244, 255)
    textLabel10.Font = Enum.Font.GothamBold
    textLabel10.TextSize = 12
    textLabel10.TextXAlignment = Enum.TextXAlignment.Left
    textLabel10.ZIndex = 11
    textLabel10.Parent = frame14

    local textButton3 = Instance.new("TextButton")
    textButton3.Size = UDim2.new(0, 20, 0, 20)
    textButton3.Position = UDim2.new(1, -28, 0, 8)
    textButton3.BackgroundColor3 = Color3.fromRGB(48, 30, 36)
    textButton3.Text = "X"
    textButton3.TextColor3 = Color3.fromRGB(240, 140, 140)
    textButton3.Font = Enum.Font.GothamBold
    textButton3.TextSize = 10
    textButton3.AutoButtonColor = false
    textButton3.ZIndex = 11
    textButton3.Parent = frame14

    local uiCorner13 = Instance.new("UICorner")
    uiCorner13.CornerRadius = UDim.new(1, 0)
    uiCorner13.Parent = textButton3

    local frame15 = Instance.new("Frame")
    frame15.Size = UDim2.new(1, -24, 0, 1)
    frame15.Position = UDim2.new(0, 12, 0, 30)
    frame15.BackgroundColor3 = Color3.fromRGB(60, 80, 115)
    frame15.BackgroundTransparency = 0.5
    frame15.BorderSizePixel = 0
    frame15.ZIndex = 11
    frame15.Parent = frame14

    local textButton4 = Instance.new("TextButton")
    textButton4.Size = UDim2.new(1, -24, 0, 36)
    textButton4.Position = UDim2.new(0, 12, 0, 40)
    textButton4.BackgroundColor3 = Color3.fromRGB(30, 35, 60)
    textButton4.BackgroundTransparency = 0.15
    textButton4.Text = ""
    textButton4.AutoButtonColor = false
    textButton4.ZIndex = 11
    textButton4.Parent = frame14

    local uiCorner14 = Instance.new("UICorner")
    uiCorner14.CornerRadius = UDim.new(0, 8)
    uiCorner14.Parent = textButton4

    local uiStroke9 = Instance.new("UIStroke")
    uiStroke9.Color = Color3.fromRGB(88, 101, 242)
    uiStroke9.Transparency = 0.2
    uiStroke9.Parent = textButton4

    local imageLabel2 = Instance.new("ImageLabel")
    imageLabel2.Size = UDim2.new(0, 24, 0, 24)
    imageLabel2.Position = UDim2.new(0, 8, 0.5, -12)
    imageLabel2.BackgroundTransparency = 1
    imageLabel2.Image = "rbxassetid://93628638506572"
    imageLabel2.ImageColor3 = Color3.fromRGB(140, 170, 255)
    imageLabel2.ScaleType = Enum.ScaleType.Fit
    imageLabel2.ZIndex = 12
    imageLabel2.Parent = textButton4

    local textLabel11 = Instance.new("TextLabel")
    textLabel11.Size = UDim2.new(1, -50, 1, 0)
    textLabel11.Position = UDim2.new(0, 40, 0, 0)
    textLabel11.BackgroundTransparency = 1
    textLabel11.Text = "Discord"
    textLabel11.TextColor3 = Color3.fromRGB(240, 244, 255)
    textLabel11.Font = Enum.Font.GothamBold
    textLabel11.TextSize = 12
    textLabel11.TextXAlignment = Enum.TextXAlignment.Left
    textLabel11.ZIndex = 12
    textLabel11.Parent = textButton4

    local textButton5 = Instance.new("TextButton")
    textButton5.Size = UDim2.new(1, -24, 0, 36)
    textButton5.Position = UDim2.new(0, 12, 0, 84)
    textButton5.BackgroundColor3 = Color3.fromRGB(22, 55, 35)
    textButton5.BackgroundTransparency = 0.15
    textButton5.Text = ""
    textButton5.AutoButtonColor = false
    textButton5.ZIndex = 11
    textButton5.Parent = frame14

    local uiCorner15 = Instance.new("UICorner")
    uiCorner15.CornerRadius = UDim.new(0, 8)
    uiCorner15.Parent = textButton5

    local uiStroke10 = Instance.new("UIStroke")
    uiStroke10.Color = Color3.fromRGB(37, 211, 102)
    uiStroke10.Transparency = 0.2
    uiStroke10.Parent = textButton5

    local frame16 = Instance.new("Frame")
    frame16.Size = UDim2.new(0, 24, 0, 24)
    frame16.Position = UDim2.new(0, 8, 0.5, -12)
    frame16.BackgroundColor3 = Color3.fromRGB(37, 211, 102)
    frame16.BorderSizePixel = 0
    frame16.ZIndex = 12
    frame16.Parent = textButton5

    local uiCorner16 = Instance.new("UICorner")
    uiCorner16.CornerRadius = UDim.new(1, 0)
    uiCorner16.Parent = frame16

    local frame17 = Instance.new("Frame")
    frame17.Size = UDim2.new(0, 11, 0, 3)
    frame17.Position = UDim2.new(0.5, -5.5, 0.5, -1.5)
    frame17.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame17.BorderSizePixel = 0
    frame17.Rotation = -45
    frame17.ZIndex = 13
    frame17.Parent = frame16

    local uiCorner17 = Instance.new("UICorner")
    uiCorner17.CornerRadius = UDim.new(1, 0)
    uiCorner17.Parent = frame17

    local frame18 = Instance.new("Frame")
    frame18.Size = UDim2.new(0, 3, 0, 8)
    frame18.Position = UDim2.new(0.5, -7, 0.5, -1.5)
    frame18.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame18.BorderSizePixel = 0
    frame18.Rotation = -45
    frame18.ZIndex = 13
    frame18.Parent = frame16

    local uiCorner18 = Instance.new("UICorner")
    uiCorner18.CornerRadius = UDim.new(1, 0)
    uiCorner18.Parent = frame18

    local textLabel12 = Instance.new("TextLabel")
    textLabel12.Size = UDim2.new(1, -50, 1, 0)
    textLabel12.Position = UDim2.new(0, 40, 0, 0)
    textLabel12.BackgroundTransparency = 1
    textLabel12.Text = "WhatsApp"
    textLabel12.TextColor3 = Color3.fromRGB(240, 244, 255)
    textLabel12.Font = Enum.Font.GothamBold
    textLabel12.TextSize = 12
    textLabel12.TextXAlignment = Enum.TextXAlignment.Left
    textLabel12.ZIndex = 12
    textLabel12.Parent = textButton5

    local textLabel13 = Instance.new("TextLabel")
    textLabel13.Size = UDim2.new(1, -24, 0, 16)
    textLabel13.Position = UDim2.new(0, 12, 1, -24)
    textLabel13.BackgroundTransparency = 1
    textLabel13.Text = ""
    textLabel13.TextColor3 = Color3.fromRGB(150, 165, 195)
    textLabel13.Font = Enum.Font.GothamBold
    textLabel13.TextSize = 10
    textLabel13.TextXAlignment = Enum.TextXAlignment.Center
    textLabel13.ZIndex = 12
    textLabel13.Parent = frame14

    local function f25()
      frame14.Visible = true
      textLabel13.Text = ""
      frame14.Size = UDim2.new(0, 180, 0, 140)

      tweenService:Create(frame14, TweenInfo.new(
        0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out
      ), { Size = UDim2.new(0, 230, 0, 178) }):Play()
    end

    textButton3.MouseButton1Click:Connect(function() frame14.Visible = false end)

    local function f26(p23, p24)
      textLabel13.Text = "✗ No se pudo copiar el link"
      textLabel13.TextColor3 = Color3.fromRGB(255, 130, 130)

      task.delay(2.5, function()
        if textLabel13.Text ~= "" then
          textLabel13.Text = ""
        end
      end)
    end

    textButton4.MouseButton1Click:Connect(function()
      f26("https://discord.gg/MbQWs6SAgK", "Discord")
    end)

    textButton5.MouseButton1Click:Connect(function()
      f26("https://whatsapp.com/channel/0029VbDGdwi4IBhHMtl68X1R", "WhatsApp")
    end)

    textButton4.MouseEnter:Connect(function()
      tweenService:Create(textButton4, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(45, 52, 90),
      }):Play()
    end)

    textButton4.MouseLeave:Connect(function()
      tweenService:Create(textButton4, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(30, 35, 60),
      }):Play()
    end)

    textButton5.MouseEnter:Connect(function()
      tweenService:Create(textButton5, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(32, 75, 48),
      }):Play()
    end)

    textButton5.MouseLeave:Connect(function()
      tweenService:Create(textButton5, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(22, 55, 35),
      }):Play()
    end)

    imageButton.MouseButton1Click:Connect(f25)
    textButton.MouseButton1Click:Connect(f25)

    imageButton.MouseEnter:Connect(function()
      tweenService:Create(imageButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(45, 55, 75),
      }):Play()
    end)

    imageButton.MouseLeave:Connect(function()
      tweenService:Create(imageButton, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(30, 35, 48),
      }):Play()
    end)

    textButton.MouseEnter:Connect(function()
      tweenService:Create(textButton, TweenInfo.new(0.15), {
        TextColor3 = Color3.fromRGB(180, 220, 255),
      }):Play()
    end)

    textButton.MouseLeave:Connect(function()
      tweenService:Create(textButton, TweenInfo.new(0.15), {
        TextColor3 = Color3.fromRGB(140, 190, 255),
      }):Play()
    end)

    textButton2.MouseEnter:Connect(function()
      tweenService:Create(textButton2, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(34, 60, 96),
      }):Play()
    end)

    textButton2.MouseLeave:Connect(function()
      tweenService:Create(textButton2, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(26, 46, 74),
      }):Play()
    end)
  end

  local connect3

  local function makeTextButton2()
    local dreyvidHub, v42, frame19, frame21, frame22, uiStroke11, uiStroke12, frame23,
      textButton6, textButton7, uiStroke15, uiScale3, frame24, frame25, uiStroke16,
      uiGradient11, frame26, textButton8, uiStroke17, uiScale4, frame27, frame28, textButton9,
      btn, stroke, btn2, stroke2, btn3, stroke3, btn4, stroke4, btn5, stroke5, frame32, frame33,
      frame34, textButton11, uiStroke23, frame36, frame37, frame38, frame39, uiScale5, frame42,
      uiScale6, frame45, frame46, frame47, frame48, textButton13, textButton14, textBox2,
      textButton15, frame50, textButton17, frame52, frame54, textLabel44

    if playerGui:FindFirstChild("DreyvidHub") then
      playerGui.DreyvidHub:Destroy()
    end

    dreyvidHub = Instance.new("ScreenGui")
    dreyvidHub.Name = "DreyvidHub"
    dreyvidHub.ResetOnSpawn = false
    dreyvidHub.Parent = playerGui

    v42 = f2()

    frame19 = Instance.new("Frame")
    frame19.Size = UDim2.new(0, 145, 0, 26)
    frame19.Position = UDim2.new(0.5, -72, 0, 4)
    frame19.BackgroundTransparency = 1
    frame19.ZIndex = 5
    frame19.Parent = dreyvidHub

    do
      local frame20 = Instance.new("Frame")
      frame20.Size = UDim2.new(1, 20, 1, 10)
      frame20.Position = UDim2.new(0.5, -10, 0.5, -5)
      frame20.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
      frame20.BackgroundTransparency = 0.85
      frame20.BorderSizePixel = 0
      frame20.ZIndex = 4
      frame20.Parent = frame19

      local uiCorner19 = Instance.new("UICorner")
      uiCorner19.CornerRadius = UDim.new(1, 0)
      uiCorner19.Parent = frame20

      local textLabel14 = Instance.new("TextLabel")
      textLabel14.Size = UDim2.new(1, 0, 1, 0)
      textLabel14.BackgroundTransparency = 1
      textLabel14.Text = "Dreyvid Hub"
      textLabel14.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel14.Font = Enum.Font.GothamBold
      textLabel14.TextSize = 18
      textLabel14.TextStrokeTransparency = 0.5
      textLabel14.TextStrokeColor3 = Color3.fromRGB(60, 140, 255)
      textLabel14.ZIndex = 5
      textLabel14.Parent = frame19
    end

    do
      frame21 = Instance.new("Frame")
      frame21.Size = UDim2.fromOffset(280, 125)
      frame21.Position = UDim2.new(0, 5, 0, 37)
      frame21.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
      frame21.BackgroundTransparency = 0.5
      frame21.BorderSizePixel = 0
      frame21.ZIndex = 1
      frame21.Parent = dreyvidHub

      local uiCorner20 = Instance.new("UICorner")
      uiCorner20.CornerRadius = UDim.new(0, 16)
      uiCorner20.Parent = frame21

      frame22 = Instance.new("Frame")
    end

    do
      frame22.Size = UDim2.fromOffset(270, 115)
      frame22.Position = UDim2.new(0, 10, 0, 42)
      frame22.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
      frame22.BorderSizePixel = 0
      frame22.ClipsDescendants = true
      frame22.Active = true
      frame22.Draggable = true
      frame22.ZIndex = 2
      frame22.Parent = dreyvidHub

      local uiCorner21 = Instance.new("UICorner")
      uiCorner21.CornerRadius = UDim.new(0, 14)
      uiCorner21.Parent = frame22
    end

    do
      local uiGradient9 = Instance.new("UIGradient")

      uiGradient9.Color = ColorSequence.new(
        Color3.fromRGB(24, 28, 40), Color3.fromRGB(12, 14, 20)
      )

      uiGradient9.Rotation = 135
      uiGradient9.Parent = frame22

      uiStroke11 = Instance.new("UIStroke")
      uiStroke11.Color = Color3.fromRGB(90, 120, 160)
      uiStroke11.Thickness = 1.2
      uiStroke11.Transparency = 0.4
      uiStroke11.Parent = frame22

      frame22:GetPropertyChangedSignal("Position"):Connect(function()
        frame21.Position = UDim2.new(
          frame22.Position.X.Scale, frame22.Position.X.Offset - 5, frame22.Position.Y.Scale,
          frame22.Position.Y.Offset - 5
        )
      end)

      local imageLabel3 = Instance.new("ImageLabel")
      imageLabel3.Size = UDim2.fromOffset(42, 42)
      imageLabel3.Position = UDim2.new(0, 14, 0, 12)
      imageLabel3.BackgroundTransparency = 1
      imageLabel3.Image = getUserThumbnailAsync
      imageLabel3.ScaleType = Enum.ScaleType.Crop
      imageLabel3.ZIndex = 3
      imageLabel3.Parent = frame22

      local uiCorner22 = Instance.new("UICorner")
      uiCorner22.CornerRadius = UDim.new(1, 0)
      uiCorner22.Parent = imageLabel3

      uiStroke12 = Instance.new("UIStroke")
      uiStroke12.Color = Color3.fromRGB(120, 180, 255)
      uiStroke12.Thickness = 1.5
      uiStroke12.Transparency = 0.2
      uiStroke12.Parent = imageLabel3
    end

    do
      local textLabel15 = Instance.new("TextLabel")
      textLabel15.Size = UDim2.new(1, -110, 0, 20)
      textLabel15.Position = UDim2.new(0, 64, 0, 14)
      textLabel15.BackgroundTransparency = 1
      textLabel15.Text = "Drey"
      textLabel15.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel15.Font = Enum.Font.GothamBold
      textLabel15.TextSize = 17
      textLabel15.TextXAlignment = Enum.TextXAlignment.Left
      textLabel15.ZIndex = 3
      textLabel15.Parent = frame22

      local textLabel16 = Instance.new("TextLabel")
      textLabel16.Size = UDim2.new(1, -110, 0, 14)
      textLabel16.Position = UDim2.new(0, 64, 0, 36)
      textLabel16.BackgroundTransparency = 1
      textLabel16.Text = "ANTI-HIT"
      textLabel16.TextColor3 = Color3.fromRGB(140, 150, 170)
      textLabel16.Font = Enum.Font.GothamMedium
      textLabel16.TextSize = 10
      textLabel16.TextXAlignment = Enum.TextXAlignment.Left
      textLabel16.ZIndex = 3
      textLabel16.Parent = frame22
    end

    do
      frame23 = Instance.new("Frame")
      frame23.Size = UDim2.fromOffset(6, 6)
      frame23.Position = UDim2.new(0, 118, 0, 39)
      frame23.BackgroundColor3 = Color3.fromRGB(230, 70, 80)
      frame23.BorderSizePixel = 0
      frame23.ZIndex = 3
      frame23.Parent = frame22

      local uiCorner23 = Instance.new("UICorner")
      uiCorner23.CornerRadius = UDim.new(1, 0)
      uiCorner23.Parent = frame23

      textButton6 = Instance.new("TextButton")
      textButton6.Size = UDim2.fromOffset(28, 28)
    end

    do
      textButton6.Position = UDim2.new(1, -72, 0, 10)
      textButton6.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
      textButton6.Text = "⚙"
      textButton6.TextColor3 = Color3.fromRGB(120, 180, 255)
      textButton6.Font = Enum.Font.GothamBold
      textButton6.TextSize = 16
      textButton6.AutoButtonColor = false
      textButton6.ZIndex = 3
      textButton6.Parent = frame22

      local uiCorner24 = Instance.new("UICorner")
      uiCorner24.CornerRadius = UDim.new(0, 8)
      uiCorner24.Parent = textButton6
    end

    do
      local uiStroke13 = Instance.new("UIStroke")
      uiStroke13.Color = Color3.fromRGB(70, 90, 130)
      uiStroke13.Thickness = 1
      uiStroke13.Transparency = 0.6
      uiStroke13.Parent = textButton6

      local imageButton2 = Instance.new("ImageButton")
      imageButton2.Size = UDim2.fromOffset(28, 28)
      imageButton2.Position = UDim2.new(1, -40, 0, 10)
      imageButton2.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
      imageButton2.Image = "rbxassetid://93628638506572"
      imageButton2.ImageColor3 = Color3.fromRGB(120, 180, 255)
      imageButton2.ScaleType = Enum.ScaleType.Fit
      imageButton2.ZIndex = 3
      imageButton2.Parent = frame22

      local uiCorner25 = Instance.new("UICorner")
      uiCorner25.CornerRadius = UDim.new(0, 8)
      uiCorner25.Parent = imageButton2

      local uiStroke14 = Instance.new("UIStroke")
      uiStroke14.Color = Color3.fromRGB(70, 90, 130)
      uiStroke14.Thickness = 1
      uiStroke14.Transparency = 0.6
      uiStroke14.Parent = imageButton2

      imageButton2.MouseButton1Click:Connect(function() f1("https://discord.gg/MbQWs6SAgK") end)
    end

    do
      textButton7 = Instance.new("TextButton")
      textButton7.Size = UDim2.new(1, -28, 0, 34)
      textButton7.Position = UDim2.new(0, 14, 1, -48)
      textButton7.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
      textButton7.Text = "OFF"
      textButton7.TextColor3 = Color3.fromRGB(230, 120, 120)
      textButton7.Font = Enum.Font.GothamBold
      textButton7.TextSize = 14
      textButton7.AutoButtonColor = false
      textButton7.ZIndex = 3
      textButton7.Parent = frame22

      local uiCorner26 = Instance.new("UICorner")
      uiCorner26.CornerRadius = UDim.new(0, 8)
      uiCorner26.Parent = textButton7
    end

    uiStroke15 = Instance.new("UIStroke")
    uiStroke15.Color = Color3.fromRGB(120, 50, 60)
    uiStroke15.Thickness = 1
    uiStroke15.Transparency = 0.4
    uiStroke15.Parent = textButton7

    task.spawn(function()
      while dreyvidHub.Parent do
        tweenService:Create(uiStroke11, TweenInfo.new(
          1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Color = Color3.fromRGB(120, 180, 255),
          Transparency = 0.1,
          Thickness = 1.8,
        }):Play()

        task.wait(1.8)

        tweenService:Create(uiStroke11, TweenInfo.new(
          1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Color = Color3.fromRGB(90, 120, 160),
          Transparency = 0.4,
          Thickness = 1.2,
        }):Play()

        task.wait(1.8)
      end
    end)

    task.spawn(function()
      while dreyvidHub.Parent do
        tweenService:Create(uiStroke12, TweenInfo.new(
          1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Transparency = 0,
          Thickness = 2,
          Color = Color3.fromRGB(180, 120, 255),
        }):Play()

        task.wait(1.5)

        tweenService:Create(uiStroke12, TweenInfo.new(
          1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Transparency = 0.2,
          Thickness = 1.5,
          Color = Color3.fromRGB(120, 180, 255),
        }):Play()

        task.wait(1.5)
      end
    end)

    task.spawn(function()
      while dreyvidHub.Parent do
        tweenService:Create(frame23, TweenInfo.new(
          0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.fromOffset(8, 8),
          Position = UDim2.new(0, 117, 0, 38),
        }):Play()

        task.wait(0.6)

        tweenService:Create(frame23, TweenInfo.new(
          0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Size = UDim2.fromOffset(6, 6),
          Position = UDim2.new(0, 118, 0, 39),
        }):Play()

        task.wait(0.6)
      end
    end)

    uiScale3 = Instance.new("UIScale")
    uiScale3.Scale = v42
    uiScale3.Parent = frame22

    frame24 = Instance.new("Frame")

    do
      frame24.Size = UDim2.fromOffset(250, 105)
      frame24.Position = UDim2.new(0, 5, 0, 167)
      frame24.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
      frame24.BackgroundTransparency = 0.5
      frame24.BorderSizePixel = 0
      frame24.ZIndex = 1
      frame24.Visible = false
      frame24.Parent = dreyvidHub

      local uiCorner27 = Instance.new("UICorner")
      uiCorner27.CornerRadius = UDim.new(0, 16)
      uiCorner27.Parent = frame24

      frame25 = Instance.new("Frame")
    end

    do
      frame25.Size = UDim2.fromOffset(240, 95)
      frame25.Position = UDim2.new(0, 10, 0, 172)
      frame25.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
      frame25.BorderSizePixel = 0
      frame25.ClipsDescendants = true
      frame25.Active = true
      frame25.Draggable = true
      frame25.ZIndex = 2
      frame25.Visible = false
      frame25.Parent = dreyvidHub

      local uiCorner28 = Instance.new("UICorner")
      uiCorner28.CornerRadius = UDim.new(0, 14)
      uiCorner28.Parent = frame25
    end

    do
      local uiGradient10 = Instance.new("UIGradient")

      uiGradient10.Color = ColorSequence.new(
        Color3.fromRGB(24, 28, 40), Color3.fromRGB(12, 14, 20)
      )

      uiGradient10.Rotation = 135
      uiGradient10.Parent = frame25

      uiStroke16 = Instance.new("UIStroke")
      uiStroke16.Color = Color3.fromRGB(90, 120, 160)
      uiStroke16.Thickness = 1.2
      uiStroke16.Transparency = 0.4
      uiStroke16.Parent = frame25

      frame25:GetPropertyChangedSignal("Position"):Connect(function()
        frame24.Position = UDim2.new(
          frame25.Position.X.Scale, frame25.Position.X.Offset - 5, frame25.Position.Y.Scale,
          frame25.Position.Y.Offset - 5
        )
      end)

      local textLabel17 = Instance.new("TextLabel")
      textLabel17.Size = UDim2.new(1, -28, 0, 24)
      textLabel17.Position = UDim2.new(0, 14, 0, 12)
      textLabel17.BackgroundTransparency = 1
      textLabel17.Text = "Agarra el huevo más tiempo"
      textLabel17.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel17.Font = Enum.Font.GothamBold
      textLabel17.TextSize = 15
      textLabel17.TextXAlignment = Enum.TextXAlignment.Left
      textLabel17.ZIndex = 3
      textLabel17.Parent = frame25

      uiGradient11 = Instance.new("UIGradient")

      uiGradient11.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 140, 255)),
      })

      uiGradient11.Rotation = 0
      uiGradient11.Parent = textLabel17
    end

    do
      local textLabel18 = Instance.new("TextLabel")
      textLabel18.Size = UDim2.new(1, -28, 0, 14)
      textLabel18.Position = UDim2.new(0, 14, 0, 36)
      textLabel18.BackgroundTransparency = 1
      textLabel18.Text = "Se queda arriba automáticamente"
      textLabel18.TextColor3 = Color3.fromRGB(140, 150, 170)
      textLabel18.Font = Enum.Font.GothamMedium
      textLabel18.TextSize = 10
      textLabel18.TextXAlignment = Enum.TextXAlignment.Left
      textLabel18.ZIndex = 3
      textLabel18.Parent = frame25

      frame26 = Instance.new("Frame")
    end

    do
      frame26.Size = UDim2.fromOffset(6, 6)
      frame26.Position = UDim2.new(1, -28, 0, 18)
      frame26.BackgroundColor3 = Color3.fromRGB(230, 70, 80)
      frame26.BorderSizePixel = 0
      frame26.ZIndex = 3
      frame26.Parent = frame25

      local uiCorner29 = Instance.new("UICorner")
      uiCorner29.CornerRadius = UDim.new(1, 0)
      uiCorner29.Parent = frame26

      textButton8 = Instance.new("TextButton")
      textButton8.Size = UDim2.new(1, -28, 0, 28)
      textButton8.Position = UDim2.new(0, 14, 1, -38)
    end

    do
      textButton8.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
      textButton8.Text = "OFF"
      textButton8.TextColor3 = Color3.fromRGB(230, 120, 120)
      textButton8.Font = Enum.Font.GothamBold
      textButton8.TextSize = 12
      textButton8.AutoButtonColor = false
      textButton8.ZIndex = 3
      textButton8.Parent = frame25

      local uiCorner30 = Instance.new("UICorner")
      uiCorner30.CornerRadius = UDim.new(0, 8)
      uiCorner30.Parent = textButton8

      uiStroke17 = Instance.new("UIStroke")
    end

    uiStroke17.Color = Color3.fromRGB(120, 50, 60)
    uiStroke17.Thickness = 1
    uiStroke17.Transparency = 0.4
    uiStroke17.Parent = textButton8

    task.spawn(function()
      while dreyvidHub.Parent do
        tweenService:Create(uiStroke16, TweenInfo.new(
          1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Color = Color3.fromRGB(120, 180, 255),
          Transparency = 0.1,
          Thickness = 1.8,
        }):Play()

        task.wait(1.8)

        tweenService:Create(uiStroke16, TweenInfo.new(
          1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
        ), {
          Color = Color3.fromRGB(90, 120, 160),
          Transparency = 0.4,
          Thickness = 1.2,
        }):Play()

        task.wait(1.8)
      end
    end)

    task.spawn(function()
      local v43 = 0

      while dreyvidHub.Parent do
        v43 = v43 + 1

        tweenService:Create(uiGradient11, TweenInfo.new(2, Enum.EasingStyle.Linear), {
          Rotation = v43 * 45,
        }):Play()

        task.wait(2)

        if v43 > 8 then
          v43 = 0
        end
      end
    end)

    uiScale4 = Instance.new("UIScale")
    uiScale4.Scale = v42
    uiScale4.Parent = frame25

    frame27 = Instance.new("Frame")
    frame27.Size = UDim2.fromOffset(320, 380)
    frame27.Position = UDim2.new(0.5, -160, 0.5, -190)

    do
      frame27.BackgroundColor3 = Color3.fromRGB(13, 15, 21)
      frame27.BorderSizePixel = 0
      frame27.Visible = false
      frame27.ZIndex = 100
      frame27.Parent = dreyvidHub

      local uiCorner31 = Instance.new("UICorner")
      uiCorner31.CornerRadius = UDim.new(0, 14)
      uiCorner31.Parent = frame27

      local uiGradient12 = Instance.new("UIGradient")

      uiGradient12.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 32, 46)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 17, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 24, 34)),
      })

      uiGradient12.Rotation = 135
      uiGradient12.Parent = frame27
    end

    do
      local uiStroke18 = Instance.new("UIStroke")
      uiStroke18.Color = Color3.fromRGB(60, 140, 255)
      uiStroke18.Thickness = 1.5
      uiStroke18.Transparency = 0.15
      uiStroke18.Parent = frame27

      local uiGradient13 = Instance.new("UIGradient")

      uiGradient13.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 220, 255)),
      })

      uiGradient13.Parent = uiStroke18

      frame28 = Instance.new("Frame")
      frame28.Size = UDim2.new(1, 0, 0, 46)
      frame28.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
      frame28.BackgroundTransparency = 0.3
    end

    do
      frame28.BorderSizePixel = 0
      frame28.ZIndex = 101
      frame28.Parent = frame27

      local uiCorner32 = Instance.new("UICorner")
      uiCorner32.CornerRadius = UDim.new(0, 14)
      uiCorner32.Parent = frame28

      local frame29 = Instance.new("Frame")
      frame29.Size = UDim2.new(1, 0, 0, 16)
      frame29.Position = UDim2.new(0, 0, 1, -16)
      frame29.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
      frame29.BackgroundTransparency = 0.3
      frame29.BorderSizePixel = 0
      frame29.ZIndex = 101
      frame29.Parent = frame28
    end

    do
      local frame30 = Instance.new("Frame")
      frame30.Size = UDim2.fromOffset(30, 30)
      frame30.Position = UDim2.new(0, 12, 0.5, -15)
      frame30.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
      frame30.BorderSizePixel = 0
      frame30.ZIndex = 102
      frame30.Parent = frame28

      local uiCorner33 = Instance.new("UICorner")
      uiCorner33.CornerRadius = UDim.new(0, 8)
      uiCorner33.Parent = frame30

      local textLabel19 = Instance.new("TextLabel")
      textLabel19.Size = UDim2.fromScale(1, 1)
      textLabel19.BackgroundTransparency = 1
      textLabel19.Text = "⚙"
      textLabel19.TextColor3 = Color3.fromRGB(120, 180, 255)
      textLabel19.Font = Enum.Font.GothamBold
      textLabel19.TextSize = 16
      textLabel19.ZIndex = 103
      textLabel19.Parent = frame30
    end

    do
      local textLabel20 = Instance.new("TextLabel")
      textLabel20.Size = UDim2.new(1, -100, 0, 18)
      textLabel20.Position = UDim2.new(0, 50, 0, 8)
      textLabel20.BackgroundTransparency = 1
      textLabel20.Text = "Configuración"
      textLabel20.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel20.Font = Enum.Font.GothamBold
      textLabel20.TextSize = 14
      textLabel20.TextXAlignment = Enum.TextXAlignment.Left
      textLabel20.ZIndex = 102
      textLabel20.Parent = frame28

      local textLabel21 = Instance.new("TextLabel")
      textLabel21.Size = UDim2.new(1, -100, 0, 12)
      textLabel21.Position = UDim2.new(0, 50, 0, 25)
      textLabel21.BackgroundTransparency = 1
      textLabel21.Text = "DREYVID · v3"
      textLabel21.TextColor3 = Color3.fromRGB(110, 120, 150)
      textLabel21.Font = Enum.Font.GothamMedium
      textLabel21.TextSize = 9
      textLabel21.TextXAlignment = Enum.TextXAlignment.Left
      textLabel21.ZIndex = 102
      textLabel21.Parent = frame28
    end

    do
      textButton9 = Instance.new("TextButton")
      textButton9.Size = UDim2.fromOffset(26, 26)
      textButton9.Position = UDim2.new(1, -36, 0, 10)
      textButton9.BackgroundColor3 = Color3.fromRGB(60, 25, 30)
      textButton9.Text = "×"
      textButton9.TextColor3 = Color3.fromRGB(255, 140, 140)
      textButton9.Font = Enum.Font.GothamBold
      textButton9.TextSize = 18
      textButton9.AutoButtonColor = false
      textButton9.ZIndex = 102
      textButton9.Parent = frame28

      local uiCorner34 = Instance.new("UICorner")
      uiCorner34.CornerRadius = UDim.new(0, 8)
      uiCorner34.Parent = textButton9
    end

    do
      local uiStroke19 = Instance.new("UIStroke")
      uiStroke19.Color = Color3.fromRGB(120, 50, 60)
      uiStroke19.Thickness = 1
      uiStroke19.Transparency = 0.4
      uiStroke19.Parent = textButton9

      local frame31 = Instance.new("Frame")
      frame31.Size = UDim2.new(1, -20, 0, 34)
      frame31.Position = UDim2.new(0, 10, 0, 56)
      frame31.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
      frame31.BackgroundTransparency = 0.5
      frame31.BorderSizePixel = 0
      frame31.ZIndex = 101
      frame31.Parent = frame27

      local uiCorner35 = Instance.new("UICorner")
      uiCorner35.CornerRadius = UDim.new(0, 9)
      uiCorner35.Parent = frame31

      local uiPadding2 = Instance.new("UIPadding")
      uiPadding2.PaddingLeft = UDim.new(0, 3)
      uiPadding2.PaddingRight = UDim.new(0, 3)
      uiPadding2.PaddingTop = UDim.new(0, 3)
      uiPadding2.PaddingBottom = UDim.new(0, 3)
      uiPadding2.Parent = frame31

      local uiListLayout = Instance.new("UIListLayout")
      uiListLayout.FillDirection = Enum.FillDirection.Horizontal
      uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
      uiListLayout.Padding = UDim.new(0, 3)
      uiListLayout.Parent = frame31

      local function makeTextButton3(text3, layoutOrder)
        local textButton10 = Instance.new("TextButton")
        textButton10.Size = UDim2.new(0.2, -3, 1, 0)
        textButton10.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
        textButton10.BackgroundTransparency = 0.5
        textButton10.Text = text3
        textButton10.TextColor3 = Color3.fromRGB(180, 180, 200)
        textButton10.Font = Enum.Font.GothamBold
        textButton10.TextSize = 9
        textButton10.AutoButtonColor = false
        textButton10.ZIndex = 102
        textButton10.LayoutOrder = layoutOrder
        textButton10.Parent = frame31

        local uiCorner36 = Instance.new("UICorner")
        uiCorner36.CornerRadius = UDim.new(0, 7)
        uiCorner36.Parent = textButton10

        local uiStroke20 = Instance.new("UIStroke")
        uiStroke20.Color = Color3.fromRGB(70, 90, 130)
        uiStroke20.Thickness = 1
        uiStroke20.Transparency = 0.6
        uiStroke20.Parent = textButton10

        return textButton10, uiStroke20
      end

      btn, stroke = makeTextButton3("Funciones", 1)
      btn2, stroke2 = makeTextButton3("Tamaño", 2)
      btn3, stroke3 = makeTextButton3("Servers", 3)
      btn4, stroke4 = makeTextButton3("Soporte", 4)
      btn5, stroke5 = makeTextButton3("Info", 5)
    end

    frame32 = Instance.new("Frame")
    frame32.Size = UDim2.new(1, -20, 1, -104)
    frame32.Position = UDim2.new(0, 10, 0, 100)
    frame32.BackgroundTransparency = 1
    frame32.ZIndex = 101
    frame32.Parent = frame27

    frame33 = Instance.new("Frame")
    frame33.Size = UDim2.new(1, 0, 1, 0)
    frame33.BackgroundTransparency = 1
    frame33.Visible = true
    frame33.ZIndex = 102
    frame33.Parent = frame32

    do
      local textLabel22 = Instance.new("TextLabel")
      textLabel22.Size = UDim2.new(1, 0, 0, 16)
      textLabel22.Position = UDim2.new(0, 0, 0, 0)
      textLabel22.BackgroundTransparency = 1
      textLabel22.Text = "FUNCIONES DISPONIBLES"
      textLabel22.TextColor3 = Color3.fromRGB(120, 180, 255)
      textLabel22.Font = Enum.Font.GothamBold
      textLabel22.TextSize = 10
      textLabel22.TextXAlignment = Enum.TextXAlignment.Left
      textLabel22.ZIndex = 103
      textLabel22.Parent = frame33

      frame34 = Instance.new("Frame")
    end

    do
      frame34.Size = UDim2.new(1, 0, 0, 78)
      frame34.Position = UDim2.new(0, 0, 0, 26)
      frame34.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
      frame34.BackgroundTransparency = 0.2
      frame34.BorderSizePixel = 0
      frame34.ZIndex = 102
      frame34.Parent = frame33

      local uiCorner37 = Instance.new("UICorner")
      uiCorner37.CornerRadius = UDim.new(0, 12)
      uiCorner37.Parent = frame34

      local uiStroke21 = Instance.new("UIStroke")
      uiStroke21.Color = Color3.fromRGB(70, 90, 130)
      uiStroke21.Thickness = 1
      uiStroke21.Transparency = 0.4
      uiStroke21.Parent = frame34
    end

    do
      local frame35 = Instance.new("Frame")
      frame35.Size = UDim2.fromOffset(50, 50)
      frame35.Position = UDim2.new(0, 14, 0.5, -25)
      frame35.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
      frame35.BorderSizePixel = 0
      frame35.ZIndex = 103
      frame35.Parent = frame34

      local uiCorner38 = Instance.new("UICorner")
      uiCorner38.CornerRadius = UDim.new(0, 10)
      uiCorner38.Parent = frame35

      local uiStroke22 = Instance.new("UIStroke")
      uiStroke22.Color = Color3.fromRGB(120, 180, 255)
      uiStroke22.Thickness = 1
      uiStroke22.Transparency = 0.4
      uiStroke22.Parent = frame35

      local textLabel23 = Instance.new("TextLabel")
      textLabel23.Size = UDim2.fromScale(1, 1)
      textLabel23.BackgroundTransparency = 1
      textLabel23.Text = "↑"
      textLabel23.TextColor3 = Color3.fromRGB(120, 200, 255)
      textLabel23.Font = Enum.Font.GothamBlack
      textLabel23.TextSize = 28
      textLabel23.ZIndex = 104
      textLabel23.Parent = frame35
    end

    do
      local textLabel24 = Instance.new("TextLabel")
      textLabel24.Size = UDim2.new(1, -110, 0, 18)
      textLabel24.Position = UDim2.new(0, 76, 0, 16)
      textLabel24.BackgroundTransparency = 1
      textLabel24.Text = "Agarra el huevo más tiempo"
      textLabel24.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel24.Font = Enum.Font.GothamBold
      textLabel24.TextSize = 12
      textLabel24.TextXAlignment = Enum.TextXAlignment.Left
      textLabel24.ZIndex = 103
      textLabel24.Parent = frame34

      local textLabel25 = Instance.new("TextLabel")
      textLabel25.Size = UDim2.new(1, -110, 0, 14)
      textLabel25.Position = UDim2.new(0, 76, 0, 36)
      textLabel25.BackgroundTransparency = 1
      textLabel25.Text = "Sube y se queda arriba"
      textLabel25.TextColor3 = Color3.fromRGB(140, 150, 170)
      textLabel25.Font = Enum.Font.GothamMedium
      textLabel25.TextSize = 10
      textLabel25.TextXAlignment = Enum.TextXAlignment.Left
      textLabel25.ZIndex = 103
      textLabel25.Parent = frame34
    end

    do
      textButton11 = Instance.new("TextButton")
      textButton11.Size = UDim2.fromOffset(60, 26)
      textButton11.Position = UDim2.new(1, -75, 0.5, -13)
      textButton11.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
      textButton11.BorderSizePixel = 0
      textButton11.Text = ""
      textButton11.AutoButtonColor = false
      textButton11.ZIndex = 103
      textButton11.Parent = frame34

      local uiCorner39 = Instance.new("UICorner")
      uiCorner39.CornerRadius = UDim.new(1, 0)
      uiCorner39.Parent = textButton11
    end

    uiStroke23 = Instance.new("UIStroke")
    uiStroke23.Color = Color3.fromRGB(90, 90, 110)
    uiStroke23.Thickness = 1
    uiStroke23.Transparency = 0.3
    uiStroke23.Parent = textButton11

    frame36 = Instance.new("Frame")
    frame36.Size = UDim2.fromOffset(20, 20)
    frame36.Position = UDim2.new(0, 3, 0.5, -10)
    frame36.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
    frame36.BorderSizePixel = 0
    frame36.ZIndex = 104
    frame36.Parent = textButton11

    do
      local uiCorner40 = Instance.new("UICorner")
      uiCorner40.CornerRadius = UDim.new(1, 0)
      uiCorner40.Parent = frame36

      frame37 = Instance.new("Frame")
      frame37.Size = UDim2.new(1, 0, 1, 0)
      frame37.BackgroundTransparency = 1
      frame37.Visible = false
      frame37.ZIndex = 102
      frame37.Parent = frame32

      local textLabel26 = Instance.new("TextLabel")
      textLabel26.Size = UDim2.new(1, 0, 0, 16)
      textLabel26.Position = UDim2.new(0, 0, 0, 0)
      textLabel26.BackgroundTransparency = 1
      textLabel26.Text = "TAMAÑO POR PANEL"
      textLabel26.TextColor3 = Color3.fromRGB(120, 180, 255)
      textLabel26.Font = Enum.Font.GothamBold
      textLabel26.TextSize = 10
      textLabel26.TextXAlignment = Enum.TextXAlignment.Left
      textLabel26.ZIndex = 103
      textLabel26.Parent = frame37
    end

    do
      local textLabel27 = Instance.new("TextLabel")
      textLabel27.Size = UDim2.new(1, 0, 0, 24)
      textLabel27.Position = UDim2.new(0, 0, 0, 20)
      textLabel27.BackgroundTransparency = 1
      textLabel27.Text = "Cambia el tamaño de cada panel sin moverlo de su posición"
      textLabel27.TextColor3 = Color3.fromRGB(140, 150, 170)
      textLabel27.Font = Enum.Font.GothamMedium
      textLabel27.TextSize = 10
      textLabel27.TextWrapped = true
      textLabel27.TextXAlignment = Enum.TextXAlignment.Left
      textLabel27.TextYAlignment = Enum.TextYAlignment.Top
      textLabel27.ZIndex = 103
      textLabel27.Parent = frame37
    end

    do
      frame38 = Instance.new("Frame")
      frame38.Size = UDim2.new(1, 0, 0, 84)
      frame38.Position = UDim2.new(0, 0, 0, 50)
      frame38.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
      frame38.BackgroundTransparency = 0.4
      frame38.BorderSizePixel = 0
      frame38.ZIndex = 102
      frame38.Parent = frame37

      local uiCorner41 = Instance.new("UICorner")
      uiCorner41.CornerRadius = UDim.new(0, 10)
      uiCorner41.Parent = frame38

      local textLabel28 = Instance.new("TextLabel")
      textLabel28.Size = UDim2.new(1, -20, 0, 14)
      textLabel28.Position = UDim2.new(0, 10, 0, 6)
      textLabel28.BackgroundTransparency = 1
      textLabel28.Text = "PREVIEW"
      textLabel28.TextColor3 = Color3.fromRGB(120, 130, 160)
      textLabel28.Font = Enum.Font.GothamBold
      textLabel28.TextSize = 9
      textLabel28.TextXAlignment = Enum.TextXAlignment.Left
      textLabel28.ZIndex = 103
      textLabel28.Parent = frame38
    end

    do
      frame39 = Instance.new("Frame")
      frame39.Size = UDim2.fromOffset(120, 46)
      frame39.Position = UDim2.new(0, 15, 0.5, -14)
      frame39.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
      frame39.BorderSizePixel = 0
      frame39.ZIndex = 103
      frame39.Parent = frame38

      local uiCorner42 = Instance.new("UICorner")
      uiCorner42.CornerRadius = UDim.new(0, 8)
      uiCorner42.Parent = frame39

      local uiStroke24 = Instance.new("UIStroke")
      uiStroke24.Color = Color3.fromRGB(60, 140, 255)
      uiStroke24.Thickness = 1
      uiStroke24.Transparency = 0.3
      uiStroke24.Parent = frame39
    end

    do
      local frame40 = Instance.new("Frame")
      frame40.Size = UDim2.fromOffset(4, 4)
      frame40.Position = UDim2.new(0, 8, 0, 8)
      frame40.BackgroundColor3 = Color3.fromRGB(50, 220, 130)
      frame40.BorderSizePixel = 0
      frame40.ZIndex = 104
      frame40.Parent = frame39

      local uiCorner43 = Instance.new("UICorner")
      uiCorner43.CornerRadius = UDim.new(1, 0)
      uiCorner43.Parent = frame40

      local textLabel29 = Instance.new("TextLabel")
      textLabel29.Size = UDim2.new(1, -20, 0, 10)
      textLabel29.Position = UDim2.new(0, 16, 0, 5)
      textLabel29.BackgroundTransparency = 1
      textLabel29.Text = "Anti-Hit"
      textLabel29.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel29.Font = Enum.Font.GothamBold
      textLabel29.TextSize = 8
      textLabel29.TextXAlignment = Enum.TextXAlignment.Left
      textLabel29.ZIndex = 104
      textLabel29.Parent = frame39
    end

    do
      local frame41 = Instance.new("Frame")
      frame41.Size = UDim2.new(1, -16, 0, 14)
      frame41.Position = UDim2.new(0, 8, 1, -20)
      frame41.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
      frame41.BorderSizePixel = 0
      frame41.ZIndex = 104
      frame41.Parent = frame39

      local uiCorner44 = Instance.new("UICorner")
      uiCorner44.CornerRadius = UDim.new(0, 4)
      uiCorner44.Parent = frame41

      uiScale5 = Instance.new("UIScale")
      uiScale5.Scale = 1
    end

-- https://discord.gg/AwGHNh7Z7T
    do
      uiScale5.Parent = frame39

      frame42 = Instance.new("Frame")
      frame42.Size = UDim2.fromOffset(100, 46)
      frame42.Position = UDim2.new(1, -115, 0.5, -14)
      frame42.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
      frame42.BorderSizePixel = 0
      frame42.ZIndex = 103
      frame42.Parent = frame38

      local uiCorner45 = Instance.new("UICorner")
      uiCorner45.CornerRadius = UDim.new(0, 8)
      uiCorner45.Parent = frame42

      local uiStroke25 = Instance.new("UIStroke")
      uiStroke25.Color = Color3.fromRGB(120, 180, 255)
      uiStroke25.Thickness = 1
      uiStroke25.Transparency = 0.3
      uiStroke25.Parent = frame42
    end

    do
      local frame43 = Instance.new("Frame")
      frame43.Size = UDim2.fromOffset(4, 4)
      frame43.Position = UDim2.new(0, 8, 0, 8)
      frame43.BackgroundColor3 = Color3.fromRGB(50, 220, 130)
      frame43.BorderSizePixel = 0
      frame43.ZIndex = 104
      frame43.Parent = frame42

      local uiCorner46 = Instance.new("UICorner")
      uiCorner46.CornerRadius = UDim.new(1, 0)
      uiCorner46.Parent = frame43

      local textLabel30 = Instance.new("TextLabel")
      textLabel30.Size = UDim2.new(1, -20, 0, 10)
      textLabel30.Position = UDim2.new(0, 16, 0, 5)
      textLabel30.BackgroundTransparency = 1
      textLabel30.Text = "Huevo"
      textLabel30.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel30.Font = Enum.Font.GothamBold
      textLabel30.TextSize = 8
      textLabel30.TextXAlignment = Enum.TextXAlignment.Left
      textLabel30.ZIndex = 104
      textLabel30.Parent = frame42
    end

    do
      local frame44 = Instance.new("Frame")
      frame44.Size = UDim2.new(1, -16, 0, 14)
      frame44.Position = UDim2.new(0, 8, 1, -20)
      frame44.BackgroundColor3 = Color3.fromRGB(20, 45, 35)
      frame44.BorderSizePixel = 0
      frame44.ZIndex = 104
      frame44.Parent = frame42

      local uiCorner47 = Instance.new("UICorner")
      uiCorner47.CornerRadius = UDim.new(0, 4)
      uiCorner47.Parent = frame44

      uiScale6 = Instance.new("UIScale")
      uiScale6.Scale = 1
    end

    do
      uiScale6.Parent = frame42

      local textLabel31 = Instance.new("TextLabel")
      textLabel31.Size = UDim2.new(1, 0, 0, 16)
      textLabel31.Position = UDim2.new(0, 0, 0, 142)
      textLabel31.BackgroundTransparency = 1
      textLabel31.Text = "AJUSTA EL TAMAÑO"
      textLabel31.TextColor3 = Color3.fromRGB(140, 150, 170)
      textLabel31.Font = Enum.Font.GothamBold
      textLabel31.TextSize = 10
      textLabel31.TextXAlignment = Enum.TextXAlignment.Left
      textLabel31.ZIndex = 103
      textLabel31.Parent = frame37
    end

    do
      frame45 = Instance.new("Frame")
      frame45.Size = UDim2.new(1, 0, 0, 8)
      frame45.Position = UDim2.new(0, 0, 0, 162)
      frame45.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
      frame45.BorderSizePixel = 0
      frame45.ZIndex = 103
      frame45.Parent = frame37

      local uiCorner48 = Instance.new("UICorner")
      uiCorner48.CornerRadius = UDim.new(1, 0)
      uiCorner48.Parent = frame45

      frame46 = Instance.new("Frame")
      frame46.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
    end

    do
      frame46.BorderSizePixel = 0
      frame46.ZIndex = 104
      frame46.Parent = frame45

      local uiCorner49 = Instance.new("UICorner")
      uiCorner49.CornerRadius = UDim.new(1, 0)
      uiCorner49.Parent = frame46

      frame47 = Instance.new("Frame")
      frame47.Size = UDim2.fromOffset(18, 18)
      frame47.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
      frame47.BorderSizePixel = 0
      frame47.ZIndex = 105
      frame47.Parent = frame45
    end

    do
      local uiCorner50 = Instance.new("UICorner")
      uiCorner50.CornerRadius = UDim.new(1, 0)
      uiCorner50.Parent = frame47

      local uiStroke26 = Instance.new("UIStroke")
      uiStroke26.Color = Color3.fromRGB(60, 140, 255)
      uiStroke26.Thickness = 2
      uiStroke26.Transparency = 0.3
      uiStroke26.Parent = frame47

      local textLabel32 = Instance.new("TextLabel")
      textLabel32.Size = UDim2.new(1, 0, 0, 18)
      textLabel32.Position = UDim2.new(0, 0, 0, 182)
      textLabel32.BackgroundTransparency = 1
      textLabel32.Text = "100%"
      textLabel32.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel32.Font = Enum.Font.GothamBold
      textLabel32.TextSize = 14
      textLabel32.TextXAlignment = Enum.TextXAlignment.Center
      textLabel32.ZIndex = 103
      textLabel32.Parent = frame37

      local function f27(text4, p25)
        uiScale3.Scale = text4
        uiScale4.Scale = text4
        uiScale5.Scale = text4
        uiScale6.Scale = text4
        local v44 = math.clamp((text4 - 0.7) / 0.44999999999999996, 0, 1)
        frame46.Size = UDim2.new(v44, 0, 1, 0)
        frame47.Position = UDim2.new(v44, -9, 0.5, -9)
        textLabel32.Text = tostring(math.floor(text4 * 100 + 0.5)) .. "%"

        if p25 then
          f3(text4)
        end
      end

      local v45 = (v42 - 0.7) / 0.44999999999999996
      frame46.Size = UDim2.new(math.clamp(v45, 0, 1), 0, 1, 0)
      frame47.Position = UDim2.new(math.clamp(v45, 0, 1), -9, 0.5, -9)
      textLabel32.Text = tostring(math.floor(v42 * 100 + 0.5)) .. "%"
      uiScale5.Scale = v42
      uiScale6.Scale = v42

      frame45.InputBegan:Connect(function(input)
        local v46 = input.UserInputType == Enum.UserInputType.MouseButton1
          or input.UserInputType == Enum.UserInputType.Touch

        local f28, connect4

        if v46 then
          function f28(p26)
            f27(0.7 + 0.44999999999999996 * math.clamp(
              (userInputService:GetMouseLocation().X - frame45.AbsolutePosition.X) / frame45.AbsoluteSize.X,
              0, 1
            ), p26)
          end

          f28(false)

          connect4 = userInputService.InputChanged:Connect(function(input2)
            if input2.UserInputType == Enum.UserInputType.MouseMovement
              or input2.UserInputType == Enum.UserInputType.Touch then
              f28(false)
            end
          end)

          userInputService.InputEnded:Connect(function(input3)
            if input3 == input then
              f28(true)
              connect4:Disconnect()
              endConn:Disconnect()
            end
          end)
        end
      end)

      local textButton12 = Instance.new("TextButton")
      textButton12.Size = UDim2.new(1, 0, 0, 26)
      textButton12.Position = UDim2.new(0, 0, 0, 208)
      textButton12.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
      textButton12.Text = "Restablecer (100%)"
      textButton12.TextColor3 = Color3.fromRGB(180, 200, 230)
      textButton12.Font = Enum.Font.GothamBold
      textButton12.TextSize = 11
      textButton12.AutoButtonColor = false
      textButton12.ZIndex = 103
      textButton12.Parent = frame37

      local uiCorner51 = Instance.new("UICorner")
      uiCorner51.CornerRadius = UDim.new(0, 8)
      uiCorner51.Parent = textButton12

      textButton12.MouseButton1Click:Connect(function() f27(1, true) end)
    end

    do
      frame48 = Instance.new("Frame")
      frame48.Size = UDim2.new(1, 0, 1, 0)
      frame48.BackgroundTransparency = 1
      frame48.Visible = false
      frame48.ZIndex = 102
      frame48.Parent = frame32

      local textLabel33 = Instance.new("TextLabel")
      textLabel33.Size = UDim2.new(1, 0, 0, 16)
      textLabel33.Position = UDim2.new(0, 0, 0, 0)
      textLabel33.BackgroundTransparency = 1
      textLabel33.Text = "SERVER HOP"
      textLabel33.TextColor3 = Color3.fromRGB(120, 180, 255)
      textLabel33.Font = Enum.Font.GothamBold
      textLabel33.TextSize = 10
      textLabel33.TextXAlignment = Enum.TextXAlignment.Left
      textLabel33.ZIndex = 103
      textLabel33.Parent = frame48
    end

    do
      local textLabel34 = Instance.new("TextLabel")
      textLabel34.Size = UDim2.new(1, 0, 0, 24)
      textLabel34.Position = UDim2.new(0, 0, 0, 20)
      textLabel34.BackgroundTransparency = 1
      textLabel34.Text = "Elige el máximo de jugadores y salta a otro servidor"
      textLabel34.TextColor3 = Color3.fromRGB(140, 150, 170)
      textLabel34.Font = Enum.Font.GothamMedium
      textLabel34.TextSize = 10
      textLabel34.TextWrapped = true
      textLabel34.TextXAlignment = Enum.TextXAlignment.Left
      textLabel34.TextYAlignment = Enum.TextYAlignment.Top
      textLabel34.ZIndex = 103
      textLabel34.Parent = frame48
    end

    do
      textButton13 = Instance.new("TextButton")
      textButton13.Size = UDim2.fromOffset(36, 28)
      textButton13.Position = UDim2.new(0, 0, 0, 50)
      textButton13.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
      textButton13.Text = "1"
      textButton13.TextColor3 = Color3.fromRGB(240, 244, 255)
      textButton13.Font = Enum.Font.GothamBold
      textButton13.TextSize = 13
      textButton13.AutoButtonColor = false
      textButton13.ZIndex = 103
      textButton13.Parent = frame48

      local uiCorner52 = Instance.new("UICorner")
      uiCorner52.CornerRadius = UDim.new(0, 6)
      uiCorner52.Parent = textButton13
    end

    do
      local uiStroke27 = Instance.new("UIStroke")
      uiStroke27.Color = Color3.fromRGB(60, 90, 140)
      uiStroke27.Thickness = 1
      uiStroke27.Transparency = 0.3
      uiStroke27.Parent = textButton13

      local textLabel35 = Instance.new("TextLabel")
      textLabel35.Size = UDim2.new(0, 100, 0, 28)
      textLabel35.Position = UDim2.new(0, 44, 0, 50)
      textLabel35.BackgroundTransparency = 1
      textLabel35.Text = "Máx. jugadores"
      textLabel35.TextColor3 = Color3.fromRGB(160, 170, 200)
      textLabel35.Font = Enum.Font.GothamMedium
      textLabel35.TextSize = 10
      textLabel35.TextXAlignment = Enum.TextXAlignment.Left
      textLabel35.ZIndex = 103
      textLabel35.Parent = frame48
    end

    do
      textButton14 = Instance.new("TextButton")
      textButton14.Size = UDim2.new(1, 0, 0, 30)
      textButton14.Position = UDim2.new(0, 0, 0, 84)
      textButton14.BackgroundColor3 = Color3.fromRGB(30, 60, 100)
      textButton14.Text = "HOP"
      textButton14.TextColor3 = Color3.fromRGB(120, 200, 255)
      textButton14.Font = Enum.Font.GothamBold
      textButton14.TextSize = 12
      textButton14.AutoButtonColor = false
      textButton14.ZIndex = 103
      textButton14.Parent = frame48

      local uiCorner53 = Instance.new("UICorner")
      uiCorner53.CornerRadius = UDim.new(0, 8)
      uiCorner53.Parent = textButton14
    end

    do
      local uiStroke28 = Instance.new("UIStroke")
      uiStroke28.Color = Color3.fromRGB(60, 140, 255)
      uiStroke28.Thickness = 1
      uiStroke28.Transparency = 0.2
      uiStroke28.Parent = textButton14

      local frame49 = Instance.new("Frame")
      frame49.Size = UDim2.new(1, 0, 0, 1)
      frame49.Position = UDim2.new(0, 0, 0, 122)
      frame49.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
      frame49.BackgroundTransparency = 0.5
      frame49.BorderSizePixel = 0
      frame49.ZIndex = 103
      frame49.Parent = frame48
    end

    do
      local textLabel36 = Instance.new("TextLabel")
      textLabel36.Size = UDim2.new(1, 0, 0, 16)
      textLabel36.Position = UDim2.new(0, 0, 0, 132)
      textLabel36.BackgroundTransparency = 1
      textLabel36.Text = "JOIN BY JOB ID"
      textLabel36.TextColor3 = Color3.fromRGB(120, 180, 255)
      textLabel36.Font = Enum.Font.GothamBold
      textLabel36.TextSize = 10
      textLabel36.TextXAlignment = Enum.TextXAlignment.Left
      textLabel36.ZIndex = 103
      textLabel36.Parent = frame48

      textBox2 = Instance.new("TextBox")
    end

    textBox2.Size = UDim2.new(1, 0, 0, 26)
    textBox2.Position = UDim2.new(0, 0, 0, 154)
    textBox2.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    textBox2.BorderSizePixel = 0
    textBox2.Text = ""
    textBox2.PlaceholderText = "Pega aquí el Job ID..."
    textBox2.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    textBox2.TextColor3 = Color3.fromRGB(240, 244, 255)
    textBox2.Font = Enum.Font.GothamMedium
    textBox2.TextSize = 11
    textBox2.ClearTextOnFocus = false
    textBox2.ZIndex = 103

    do
      textBox2.Parent = frame48

      local uiCorner54 = Instance.new("UICorner")
      uiCorner54.CornerRadius = UDim.new(0, 6)
      uiCorner54.Parent = textBox2

      local uiStroke29 = Instance.new("UIStroke")
      uiStroke29.Color = Color3.fromRGB(60, 90, 140)
      uiStroke29.Thickness = 1
      uiStroke29.Transparency = 0.3
      uiStroke29.Parent = textBox2

      textButton15 = Instance.new("TextButton")
      textButton15.Size = UDim2.new(0.5, -3, 0, 28)
      textButton15.Position = UDim2.new(0, 0, 0, 188)
    end

    do
      textButton15.BackgroundColor3 = Color3.fromRGB(30, 60, 100)
      textButton15.Text = "JOIN"
      textButton15.TextColor3 = Color3.fromRGB(120, 200, 255)
      textButton15.Font = Enum.Font.GothamBold
      textButton15.TextSize = 11
      textButton15.AutoButtonColor = false
      textButton15.ZIndex = 103
      textButton15.Parent = frame48

      local uiCorner55 = Instance.new("UICorner")
      uiCorner55.CornerRadius = UDim.new(0, 8)
      uiCorner55.Parent = textButton15

      local uiStroke30 = Instance.new("UIStroke")
      uiStroke30.Color = Color3.fromRGB(60, 140, 255)
      uiStroke30.Thickness = 1
      uiStroke30.Transparency = 0.2
      uiStroke30.Parent = textButton15
    end

    do
      local textButton16 = Instance.new("TextButton")
      textButton16.Size = UDim2.new(0.5, -3, 0, 28)
      textButton16.Position = UDim2.new(0.5, 3, 0, 188)
      textButton16.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
      textButton16.Text = "REJOIN"
      textButton16.TextColor3 = Color3.fromRGB(180, 160, 255)
      textButton16.Font = Enum.Font.GothamBold
      textButton16.TextSize = 11
      textButton16.AutoButtonColor = false
      textButton16.ZIndex = 103
      textButton16.Parent = frame48

      local uiCorner56 = Instance.new("UICorner")
      uiCorner56.CornerRadius = UDim.new(0, 8)
      uiCorner56.Parent = textButton16

      local uiStroke31 = Instance.new("UIStroke")
      uiStroke31.Color = Color3.fromRGB(120, 100, 200)
      uiStroke31.Thickness = 1
      uiStroke31.Transparency = 0.2
      uiStroke31.Parent = textButton16

      local v47 = 1

      textButton13.MouseButton1Click:Connect(function()
        v47 = v47 + 1

        if v47 > 5 then
          v47 = 1
        end

        textButton13.Text = tostring(v47)
      end)

      local function f29(p27)
        local v48 = "https://games.roblox.com/v1/games/" .. placeId
          .. "/servers/Public?sortOrder=Asc&limit=100"

        local v49, v50 = pcall(function() return game:HttpGet(v48) end)

        if not v49 or not v50 then
          return nil
        else
          local v51, v52 = pcall(httpService.JSONDecode, httpService, v50)

          if not v51 or not v52 or not v52.data then
            return nil
          else
            local v53 = tostring(game.JobId)
            local v54 = {}

            for index16, value21 in ipairs(v52.data) do
              if value21.id and tostring(value21.id) ~= v53 and value21.playing
                and value21.playing <= p27 and value21.playing > 0 then
                table.insert(v54, tostring(value21.id))
              end
            end

            if #v54 == 0 then
              return nil
            end

            return v54[math.random(1, #v54)]
          end
        end
      end

      textButton14.MouseButton1Click:Connect(function()
        textButton14.Active = false
        textButton14.Text = "..."

        local v55 = f29(v47)

        if not v55 then
          textButton14.Text = "NONE"
          task.wait(2)

          textButton14.Text = "HOP"
          textButton14.Active = true

          return
        end

        textButton14.Text = "OK"
        task.wait(0.3)
        pcall(function() teleportService:TeleportToPlaceInstance(placeId, v55, localPlayer) end)
        textButton14.Active = true
      end)

      textButton15.MouseButton1Click:Connect(function()
        local text5 = textBox2.Text

        if not text5 or text5 == "" then
          return
        end

        local v56 = string.match(
          tostring(text5),
          "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
        ) or tostring(text5)

        textButton15.Text = "..."
        task.wait(0.2)
        pcall(function() teleportService:TeleportToPlaceInstance(placeId, v56, localPlayer) end)
        textButton15.Text = "JOIN"
      end)

      textButton16.MouseButton1Click:Connect(function()
        pcall(function()
          if game.JobId ~= "" then
            teleportService:TeleportToPlaceInstance(placeId, game.JobId, localPlayer)
          else
            teleportService:Teleport(placeId, localPlayer)
          end
        end)
      end)
    end

    do
      frame50 = Instance.new("Frame")
      frame50.Size = UDim2.new(1, 0, 1, 0)
      frame50.BackgroundTransparency = 1
      frame50.Visible = false
      frame50.ZIndex = 102
      frame50.Parent = frame32

      local frame51 = Instance.new("Frame")
      frame51.Size = UDim2.fromOffset(50, 50)
      frame51.Position = UDim2.new(0.5, -25, 0, 0)
      frame51.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
      frame51.BorderSizePixel = 0
      frame51.ZIndex = 103
      frame51.Parent = frame50

      local uiCorner57 = Instance.new("UICorner")
      uiCorner57.CornerRadius = UDim.new(0, 12)
      uiCorner57.Parent = frame51

      local textLabel37 = Instance.new("TextLabel")
      textLabel37.Size = UDim2.fromScale(1, 1)
      textLabel37.BackgroundTransparency = 1
      textLabel37.Text = "💡"
      textLabel37.Font = Enum.Font.GothamBold
      textLabel37.TextSize = 28
      textLabel37.ZIndex = 104
      textLabel37.Parent = frame51
    end

    do
      local textLabel38 = Instance.new("TextLabel")
      textLabel38.Size = UDim2.new(1, 0, 0, 22)
      textLabel38.Position = UDim2.new(0, 0, 0, 60)
      textLabel38.BackgroundTransparency = 1
      textLabel38.Text = "Danos tus sugerencias"
      textLabel38.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel38.Font = Enum.Font.GothamBold
      textLabel38.TextSize = 15
      textLabel38.ZIndex = 103
      textLabel38.Parent = frame50

      local textLabel39 = Instance.new("TextLabel")
      textLabel39.Size = UDim2.new(1, 0, 0, 40)
      textLabel39.Position = UDim2.new(0, 0, 0, 88)
      textLabel39.BackgroundTransparency = 1
      textLabel39.Text = "¿Qué te gustaría que añadamos en la próxima actualización v3?"
      textLabel39.TextColor3 = Color3.fromRGB(160, 170, 200)
      textLabel39.Font = Enum.Font.GothamMedium
      textLabel39.TextSize = 12
      textLabel39.TextWrapped = true
      textLabel39.ZIndex = 103
      textLabel39.Parent = frame50
    end

    do
      textButton17 = Instance.new("TextButton")
      textButton17.Size = UDim2.new(1, 0, 0, 54)
      textButton17.Position = UDim2.new(0, 0, 0, 140)
      textButton17.BackgroundColor3 = Color3.fromRGB(45, 60, 90)
      textButton17.Text = "Únete aquí"
      textButton17.TextColor3 = Color3.fromRGB(180, 210, 255)
      textButton17.Font = Enum.Font.GothamBold
      textButton17.TextSize = 15
      textButton17.AutoButtonColor = false
      textButton17.ZIndex = 103
      textButton17.Parent = frame50

      local uiCorner58 = Instance.new("UICorner")
      uiCorner58.CornerRadius = UDim.new(0, 12)
      uiCorner58.Parent = textButton17
    end

    do
      local uiStroke32 = Instance.new("UIStroke")
      uiStroke32.Color = Color3.fromRGB(90, 130, 200)
      uiStroke32.Thickness = 1
      uiStroke32.Transparency = 0.2
      uiStroke32.Parent = textButton17

      local imageLabel4 = Instance.new("ImageLabel")
      imageLabel4.Size = UDim2.fromOffset(32, 32)
      imageLabel4.Position = UDim2.new(0, 16, 0.5, -16)
      imageLabel4.BackgroundTransparency = 1
      imageLabel4.Image = "rbxassetid://93628638506572"
      imageLabel4.ImageColor3 = Color3.fromRGB(180, 210, 255)
      imageLabel4.ScaleType = Enum.ScaleType.Fit
      imageLabel4.ZIndex = 104
      imageLabel4.Parent = textButton17
    end

    do
      textButton17.MouseButton1Click:Connect(function()
        if not pcall(function() guiService:OpenBrowserWindow("https://discord.gg/MbQWs6SAgK") end) then
          f1("https://discord.gg/MbQWs6SAgK")
        end
      end)

      textButton17.MouseEnter:Connect(function()
        tweenService:Create(textButton17, TweenInfo.new(0.2), {
          BackgroundColor3 = Color3.fromRGB(60, 80, 120),
        }):Play()
      end)

      textButton17.MouseLeave:Connect(function()
        tweenService:Create(textButton17, TweenInfo.new(0.2), {
          BackgroundColor3 = Color3.fromRGB(45, 60, 90),
        }):Play()
      end)

      frame52 = Instance.new("Frame")
      frame52.Size = UDim2.new(1, 0, 1, 0)
      frame52.BackgroundTransparency = 1
      frame52.Visible = false
      frame52.ZIndex = 102
      frame52.Parent = frame32

      local frame53 = Instance.new("Frame")
      frame53.Size = UDim2.fromOffset(50, 50)
      frame53.Position = UDim2.new(0.5, -25, 0, 0)
      frame53.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
      frame53.BorderSizePixel = 0
      frame53.ZIndex = 103
      frame53.Parent = frame52

      local uiCorner59 = Instance.new("UICorner")
      uiCorner59.CornerRadius = UDim.new(0, 12)
      uiCorner59.Parent = frame53

      local textLabel40 = Instance.new("TextLabel")
      textLabel40.Size = UDim2.fromScale(1, 1)
      textLabel40.BackgroundTransparency = 1
      textLabel40.Text = "ℹ"
      textLabel40.TextColor3 = Color3.fromRGB(120, 180, 255)
      textLabel40.Font = Enum.Font.GothamBold
      textLabel40.TextSize = 28
      textLabel40.ZIndex = 104
      textLabel40.Parent = frame53
    end

    do
      local textLabel41 = Instance.new("TextLabel")
      textLabel41.Size = UDim2.new(1, 0, 0, 22)
      textLabel41.Position = UDim2.new(0, 0, 0, 60)
      textLabel41.BackgroundTransparency = 1
      textLabel41.Text = "Dreyvid Hub"
      textLabel41.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel41.Font = Enum.Font.GothamBold
      textLabel41.TextSize = 16
      textLabel41.ZIndex = 103
      textLabel41.Parent = frame52

      local textLabel42 = Instance.new("TextLabel")
      textLabel42.Size = UDim2.new(1, 0, 0, 16)
      textLabel42.Position = UDim2.new(0, 0, 0, 88)
      textLabel42.BackgroundTransparency = 1
      textLabel42.Text = "Versión v3"
      textLabel42.TextColor3 = Color3.fromRGB(160, 170, 200)
      textLabel42.Font = Enum.Font.GothamMedium
      textLabel42.TextSize = 12
      textLabel42.ZIndex = 103
      textLabel42.Parent = frame52
    end

    do
      local textLabel43 = Instance.new("TextLabel")
      textLabel43.Size = UDim2.new(1, 0, 0, 80)
      textLabel43.Position = UDim2.new(0, 0, 0, 116)
      textLabel43.BackgroundTransparency = 1
      textLabel43.Text = "Hub con Anti-Hit, Huevo Más Tiempo, Anti-Trap, Server Hop, FPS/Ping y más."
      textLabel43.TextColor3 = Color3.fromRGB(180, 190, 220)
      textLabel43.Font = Enum.Font.GothamMedium
      textLabel43.TextSize = 11
      textLabel43.TextWrapped = true
      textLabel43.ZIndex = 103
      textLabel43.Parent = frame52

      local v57 = {
        { btn = btn, stroke = stroke, panel = frame33 },
        { btn = btn2, stroke = stroke2, panel = frame37 },
        { btn = btn3, stroke = stroke3, panel = frame48 },
        { btn = btn4, stroke = stroke4, panel = frame50 },
        { btn = btn5, stroke = stroke5, panel = frame52 },
      }

      local function f30(p28)
        for index17, value22 in ipairs(v57) do
          local v58 = value22 == p28
          value22.panel.Visible = v58

          if v58 then
            tweenService:Create(value22.btn, TweenInfo.new(0.2), {
              BackgroundColor3 = Color3.fromRGB(30, 60, 100),
              BackgroundTransparency = 0.2,
              TextColor3 = Color3.fromRGB(120, 200, 255),
            }):Play()

            tweenService:Create(value22.stroke, TweenInfo.new(0.2), {
              Color = Color3.fromRGB(60, 140, 255),
              Transparency = 0.2,
            }):Play()
          else
            tweenService:Create(value22.btn, TweenInfo.new(0.2), {
              BackgroundColor3 = Color3.fromRGB(30, 35, 48),
              BackgroundTransparency = 0.5,
              TextColor3 = Color3.fromRGB(180, 180, 200),
            }):Play()

            tweenService:Create(value22.stroke, TweenInfo.new(0.2), {
              Color = Color3.fromRGB(70, 90, 130),
              Transparency = 0.6,
            }):Play()
          end
        end
      end

      for index18, value23 in ipairs(v57) do
        local v59 = value23
        v59.btn.MouseButton1Click:Connect(function() f30(v59) end)
      end

      f30(v57[1])
    end

    do
      local v60 = false

      local function f31()
        if v60 then
          tweenService:Create(textButton11, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(30, 60, 100),
          }):Play()

          tweenService:Create(uiStroke23, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(60, 140, 255),
            Transparency = 0.1,
          }):Play()

          tweenService:Create(frame36, TweenInfo.new(0.25), {
            Position = UDim2.new(1, -23, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(100, 200, 255),
          }):Play()
        else
          tweenService:Create(textButton11, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
          }):Play()

          tweenService:Create(uiStroke23, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(90, 90, 110),
            Transparency = 0.3,
          }):Play()

          tweenService:Create(frame36, TweenInfo.new(0.25), {
            Position = UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(200, 200, 210),
          }):Play()
        end
      end

      textButton11.MouseButton1Click:Connect(function()
        v60 = not v60

        if v60 then
          frame25.Visible = true
          frame24.Visible = true
          f20()
        else
          frame25.Visible = false
          frame24.Visible = false
          f19()
        end

        f31()
      end)

      textButton6.MouseButton1Click:Connect(function() frame27.Visible = not frame27.Visible end)
      textButton9.MouseButton1Click:Connect(function() frame27.Visible = false end)

      local function f32(p29)
        if p29 then
          tweenService:Create(textButton7, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(20, 45, 35),
            TextColor3 = Color3.fromRGB(100, 230, 160),
          }):Play()

          tweenService:Create(uiStroke15, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(50, 150, 100),
          }):Play()

          tweenService:Create(frame23, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(50, 220, 130),
          }):Play()

          textButton7.Text = "ON"
        else
          tweenService:Create(textButton7, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(40, 25, 30),
            TextColor3 = Color3.fromRGB(230, 120, 120),
          }):Play()

          tweenService:Create(uiStroke15, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(120, 50, 60),
          }):Play()

          tweenService:Create(frame23, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(230, 70, 80),
          }):Play()

          textButton7.Text = "OFF"
        end
      end

      textButton7.MouseButton1Click:Connect(function()
        v7 = not v7

        if v7 then
          if frame25.Visible then
            frame25.Visible = false
            frame24.Visible = false
            f19()
            v60 = false
            f31()
          end

          f32(true)
          f6(true)

          if not connect3 then
            connect3 = proximityPromptService.PromptTriggered:Connect(function(p30, p31)
              if p31 == localPlayer then
                f4()
              end
            end)
          end
        else
          f32(false)
          f6(false)

          if connect3 then
            connect3:Disconnect()
            connect3 = nil
          end
        end
      end)

      local function f33(p32)
        if p32 then
          tweenService:Create(textButton8, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(20, 45, 35),
            TextColor3 = Color3.fromRGB(100, 230, 160),
          }):Play()

          tweenService:Create(uiStroke17, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(50, 150, 100),
          }):Play()

          tweenService:Create(frame26, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(50, 220, 130),
          }):Play()

          textButton8.Text = "ON"
        else
          tweenService:Create(textButton8, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(40, 25, 30),
            TextColor3 = Color3.fromRGB(230, 120, 120),
          }):Play()

          tweenService:Create(uiStroke17, TweenInfo.new(0.25), {
            Color = Color3.fromRGB(120, 50, 60),
          }):Play()

          tweenService:Create(frame26, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(230, 70, 80),
          }):Play()

          textButton8.Text = "OFF"
        end
      end

      textButton8.MouseButton1Click:Connect(function()
        v11 = not v11

        if v11 then
          if v7 then
            v7 = false
            f32(false)
            f6(false)

            if connect3 then
              connect3:Disconnect()
              connect3 = nil
            end
          end

          f20()
          f33(true)
        else
          f19()
          f33(false)
        end
      end)

      frame54 = Instance.new("Frame")
      frame54.Size = UDim2.new(0, 170, 0, 30)
      frame54.Position = UDim2.new(0.5, -85, 0, 34)
    end

    do
      frame54.BackgroundTransparency = 1
      frame54.Parent = dreyvidHub

      local uiListLayout2 = Instance.new("UIListLayout")
      uiListLayout2.FillDirection = Enum.FillDirection.Horizontal
      uiListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
      uiListLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
      uiListLayout2.Padding = UDim.new(0, 10)
      uiListLayout2.Parent = frame54

      local frame55 = Instance.new("Frame")
      frame55.Size = UDim2.new(0, 75, 0, 24)
      frame55.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
      frame55.BackgroundTransparency = 0.5
      frame55.BorderSizePixel = 0
      frame55.LayoutOrder = 1
      frame55.Parent = frame54

      local uiCorner60 = Instance.new("UICorner")
      uiCorner60.CornerRadius = UDim.new(0, 12)
      uiCorner60.Parent = frame55

      textLabel44 = Instance.new("TextLabel")
      textLabel44.Size = UDim2.new(1, -8, 1, 0)
      textLabel44.Position = UDim2.new(0, 4, 0, 0)
      textLabel44.BackgroundTransparency = 1
      textLabel44.Text = "FPS: --"
      textLabel44.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel44.Font = Enum.Font.GothamBold
      textLabel44.TextSize = 12
      textLabel44.Parent = frame55
    end

    do
      local frame56 = Instance.new("Frame")
      frame56.Size = UDim2.new(0, 75, 0, 24)
      frame56.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
      frame56.BackgroundTransparency = 0.5
      frame56.BorderSizePixel = 0
      frame56.LayoutOrder = 2
      frame56.Parent = frame54

      local uiCorner61 = Instance.new("UICorner")
      uiCorner61.CornerRadius = UDim.new(0, 12)
      uiCorner61.Parent = frame56

      local textLabel45 = Instance.new("TextLabel")
      textLabel45.Size = UDim2.new(1, -8, 1, 0)
      textLabel45.Position = UDim2.new(0, 4, 0, 0)
      textLabel45.BackgroundTransparency = 1
      textLabel45.Text = "PING: --"
      textLabel45.TextColor3 = Color3.fromRGB(240, 244, 255)
      textLabel45.Font = Enum.Font.GothamBold
      textLabel45.TextSize = 12
      textLabel45.Parent = frame56

      local v61 = 0
      local v62 = 0

      task.spawn(function()
        while dreyvidHub.Parent do
          task.wait(1)
          local v63 = math.floor(v61 / v62 + 0.5)
          v61 = 0
          v62 = 0
          textLabel44.Text = "FPS: " .. tostring(v63)

          if v63 >= 50 then
            textLabel44.TextColor3 = Color3.fromRGB(80, 230, 130)
          elseif v63 >= 30 then
            textLabel44.TextColor3 = Color3.fromRGB(255, 210, 80)
          else
            textLabel44.TextColor3 = Color3.fromRGB(255, 80, 80)
          end
        end
      end)

      runService.RenderStepped:Connect(function(delta)
        if not dreyvidHub.Parent then
          return
        end

        v61 = v61 + 1
        v62 = v62 + delta
      end)

      task.spawn(function()
        while dreyvidHub.Parent do
          task.wait(1)

          local v64, v65 = pcall(function()
            return statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
          end)

          if v64 and v65 then
            local v66 = math.floor(v65 + 0.5)
            textLabel45.Text = "PING: " .. v66

            if v66 <= 80 then
              textLabel45.TextColor3 = Color3.fromRGB(80, 230, 130)
            elseif v66 <= 150 then
              textLabel45.TextColor3 = Color3.fromRGB(255, 210, 80)
            else
              textLabel45.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
          end
        end
      end)
    end
  end

  makeTextLabel(function() makeTextButton(function() makeTextButton2() end) end)
end

localPlayer2 = players.LocalPlayer

v67 = {
  BgMain = Color3.fromRGB(11, 28, 38),
  BgHeader = Color3.fromRGB(15, 42, 58),
  BgRow = Color3.fromRGB(13, 36, 50),
  BgDark = Color3.fromRGB(8, 22, 32),
  Stroke = Color3.fromRGB(35, 90, 115),
  StrokeTrack = Color3.fromRGB(40, 95, 118),
  Green = Color3.fromRGB(34, 200, 34),
  GreenDim = Color3.fromRGB(28, 160, 28),
  Grey = Color3.fromRGB(60, 60, 66),
  White = Color3.fromRGB(245, 245, 250),
  TextMain = Color3.fromRGB(235, 244, 250),
  TextHeader = Color3.fromRGB(232, 242, 248),
  TextArrow = Color3.fromRGB(180, 205, 215),
}

local function f34(parent)
  local uiCorner62 = Instance.new("UICorner")
  uiCorner62.CornerRadius = UDim.new(1, 0)
  uiCorner62.Parent = parent

  return uiCorner62
end

local function f35(parent2, color2, p33, p34)
  local uiStroke33 = Instance.new("UIStroke")
  uiStroke33.Color = color2
  uiStroke33.Thickness = p33 or 1
  uiStroke33.Transparency = p34 or 0
  uiStroke33.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  uiStroke33.Parent = parent2

  return uiStroke33
end

local function f36(parent3, p35)
  local uiCorner63 = Instance.new("UICorner")
  uiCorner63.CornerRadius = UDim.new(0, p35 or 6)
  uiCorner63.Parent = parent3

  return uiCorner63
end

v68 = 900
v69 = false

v70 = {
  Original = nil,
  Clone = nil,
  Links = {},
  Disabled = {},
}

local function f37()
  local character4 = localPlayer2.Character
  local humanoidRootPart2 = character4 and character4:FindFirstChild("HumanoidRootPart")
  local humanoid2 = character4 and character4:FindFirstChildOfClass("Humanoid")

  if humanoidRootPart2 and humanoid2 and humanoid2.Health > 0 then
    return humanoidRootPart2, humanoid2
  end

  return nil, nil
end

local function f38()
  local character5 = localPlayer2.Character
  local original = v70.Original
  local clone = v70.Clone

  v70.Original = nil
  v70.Clone = nil

  local v71 = original and clone and character5 and original.Parent == nil
    and clone.Parent == character5

  local animate

  if v71 then
    original.Parent = character5
    workspace.CurrentCamera.CameraSubject = original

    pcall(function() clone:Destroy() end)

    pcall(function()
      local playerScripts = localPlayer2:FindFirstChild("PlayerScripts")
      local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")

      if playerModule then
        local getControls = require(playerModule):GetControls()

        if type(getControls) == "table" then
          getControls.humanoid = original
        end
      end
    end)

    animate = character5:FindFirstChild("Animate")

    if animate and animate:IsA("LocalScript") then
      task.spawn(function()
        animate.Enabled = false
        task.wait()
        animate.Enabled = true
      end)
    end
  end
end

local function f39(humanoid3)
  local humanoid4 = humanoid3

  if not humanoid4 then
    local character6 = localPlayer2.Character
    humanoid4 = character6 and character6:FindFirstChildOfClass("Humanoid")
  end

  if not humanoid4 or humanoid4.Health <= 0 or humanoid4.FloorMaterial == Enum.Material.Air then
    return false
  else
    local getState = humanoid4:GetState()

    return getState == Enum.HumanoidStateType.Running
      or getState == Enum.HumanoidStateType.RunningNoPhysics
      or getState == Enum.HumanoidStateType.Landed
  end
end

local function f40()
  local character7 = localPlayer2.Character
  local humanoid5 = character7 and character7:FindFirstChildOfClass("Humanoid")

  if not humanoid5 or humanoid5.Health <= 0 then
    return
  end

  local clone2, animate2, animator

  if v70.Clone and v70.Clone.Parent == character7 then
    return
  elseif not f39(humanoid5) then
    return
  else
    clone2 = humanoid5:Clone()
    humanoid5.Parent = nil
    clone2.Parent = character7
    workspace.CurrentCamera.CameraSubject = clone2

    pcall(function()
      local playerScripts2 = localPlayer2:FindFirstChild("PlayerScripts")
      local playerModule2 = playerScripts2 and playerScripts2:FindFirstChild("PlayerModule")

      if playerModule2 then
        local getControls2 = require(playerModule2):GetControls()

        if type(getControls2) == "table" then
          getControls2.humanoid = clone2
        end
      end
    end)

    animate2 = character7:FindFirstChild("Animate")

    if animate2 and animate2:IsA("LocalScript") then
      task.spawn(function()
        animate2.Enabled = false
        task.wait()
        animate2.Enabled = true
      end)
    end

    v70.Original = humanoid5
    v70.Clone = clone2

    local animator2 = humanoid5:FindFirstChildOfClass("Animator")
    animator = clone2:FindFirstChildOfClass("Animator")

    if animator2 and animator then
      local animationPlayed = animator2.AnimationPlayed

      table.insert(v70.Links, animationPlayed:Connect(function(p36)
        local animation = p36.Animation
        local v72 = not animation or clone2.Parent == nil
        local v73, connect5

        if v72 then
          return
        else
          local v74
          v74, v73 = pcall(function() return animator:LoadAnimation(animation) end)

          if not v74 or not v73 then
            return
          end

          pcall(function()
            v73.Priority = p36.Priority
            v73.Looped = p36.Looped
            v73:Play(0.05, math.max(p36.WeightTarget, 0.01), p36.Speed)
          end)

          connect5 = nil
          connect5 = p36.Stopped:Connect(function() connect5:Disconnect() end)

          return
        end
      end))
    end

    local died = clone2.Died

    table.insert(v70.Links, died:Connect(function()
      local original2 = v70.Original

      v70.Original = nil
      v70.Clone = nil

      local character8 = localPlayer2.Character

      if character8 and original2 and original2.Parent == nil then
        original2.Parent = character8
        workspace.CurrentCamera.CameraSubject = original2

        pcall(function()
          local playerScripts3 = localPlayer2:FindFirstChild("PlayerScripts")
          local playerModule3 = playerScripts3 and playerScripts3:FindFirstChild("PlayerModule")

          if playerModule3 then
            local getControls3 = require(playerModule3):GetControls()

            if type(getControls3) == "table" then
              getControls3.humanoid = original2
            end
          end
        end)
      end

      pcall(function() clone2:Destroy() end)

      if original2 then
        original2.Health = 0
      end
    end))

    return
  end
end

local function f41()
  if not v69 then
    return
  else
    local v75 = tonumber(localPlayer2:GetAttribute("RagdollEndTime"))

    if v75 and v75 > workspace:GetServerTimeNow() then
      return
    else
      local v76, v77 = f37()

      if not v76 or not v77 then
        return
      end

      if v77.Sit or v77.PlatformStand then
        return
      else
        local moveDirection = v77.MoveDirection

        if Vector3.new(moveDirection.X, 0, moveDirection.Z).Magnitude <= 0.001 then
          return
        end

        return
      end
    end
  end
end

do
  local screenGui = Instance.new("ScreenGui")
  screenGui.Name = "SpeedP
