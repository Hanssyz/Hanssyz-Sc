--[[
    SAE Steal+Teleport - Delta Compatible
    Combine dari ScriptVerse + Hanssyz + Dreyvid
    
    Tested executors: Delta, Wave, Codex, Fluxus
    NOT: Solara, Xeno, Micro
]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- ═══════════════════════════════════════════════════════
-- EXECUTOR DETECTION + GUARD
-- ═══════════════════════════════════════════════════════
local execName = "unknown"
if identifyexecutor then
    local ok, n = pcall(identifyexecutor)
    if ok and n then execName = tostring(n):lower() end
elseif getexecutorname then
    local ok, n = pcall(getexecutorname)
    if ok and n then execName = tostring(n):lower() end
end

if execName:find("solara") or execName:find("xeno") or execName:find("micro") then
    return warn("[SAE] " .. execName .. " not supported (missing required functions)")
end

-- capability probe (Delta-friendly)
local CAP = {
    filtergc = (typeof(filtergc) == "function"),
    getgc = (typeof(getgc) == "function"),
    setrawmeta = (typeof(setrawmetatable) == "function"),
    setmeta = (typeof(setmetatable) == "function"),
    hookmm = (typeof(hookmetamethod) == "function"),
    getupvalue = (typeof(getupvalue) == "function"),
    setupvalue = (typeof(setupvalue) == "function"),
    fireprompt = (typeof(fireproximityprompt) == "function"),
    gethui = (typeof(gethui) == "function"),
    request = (typeof(request) == "function") or (typeof(http_request) == "function"),
    protectgui = (typeof(protect_gui) == "function"),
}

print("[SAE] Executor: " .. execName)
print("[SAE] Caps: " .. (function()
    local t = {}
    for k, v in pairs(CAP) do if v then t[#t+1] = k end end
    return table.concat(t, ", ")
end)())

-- Delta: filtergc biasanya butuh argumen lain, atau ga ada Constants support
-- jadi AC bypass kita bikin soft — pake getgc scan sederhana
local function bypassAC()
    local blocked = 0
    
    -- metode 1: getgc scan (Delta-friendly)
    if CAP.getgc then
        pcall(function()
            local fns = getgc(true)
            for _, obj in ipairs(fns) do
                if type(obj) == "function" then
                    -- cari fungsi AC yang pake gmatch + GetFullName
                    local ok, info = pcall(debug.getinfo, obj)
                    if ok and info and info.source and info.source:find("AntiCheat", 1, true) then
                        blocked = blocked + 1
                    end
                end
            end
        end)
    end
    
    -- metode 2: filtergc (kalau ada)
    if blocked == 0 and CAP.filtergc then
        local ok, fn = pcall(function()
            return filtergc("function", { Constants = {"gmatch", "GetFullName"} }, true)
        end)
        if ok and type(fn) == "function" then
            local setMeta = CAP.setrawmeta and setrawmetatable or setmetatable
            if setMeta then
                local okUv, ups = pcall(debug.getupvalues, fn)
                if okUv and type(ups) == "table" then
                    for _, tbl in pairs(ups) do
                        if typeof(tbl) == "table" then
                            if pcall(setMeta, tbl, { __newindex = function() end }) then
                                blocked = blocked + 1
                            end
                        end
                    end
                end
            end
        end
    end
    
    return blocked > 0, blocked
end

local acOk, acInfo = bypassAC()
print("[SAE] AC bypass:", acOk and ("OK (" .. acInfo .. " tables)") or "skip")

-- ═══════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════
local genv = (getgenv and getgenv()) or _G
if genv.SAE_RUNNING then
    local last = genv.SAE_HEARTBEAT
    if type(last) == "number" and (tick() - last) > 8 then
        genv.SAE_RUNNING = nil
    else
        return warn("[SAE] Already running. getgenv().SAE_SHUTDOWN() first")
    end
end
genv.SAE_RUNNING = true
genv.SAE_HEARTBEAT = tick()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ═══════════════════════════════════════════════════════
-- MODULE DISCOVERY
-- ═══════════════════════════════════════════════════════
local function softRequire(inst)
    if typeof(inst) ~= "Instance" then return nil end
    local ok, mod = pcall(require, inst)
    return ok and mod or nil
end

local Lib, Client, Util, Globals
local EggCmds, PlotCmds, Network, Guard, Lookup, Save, SpeedPowerProjection, Constants

for i = 1, 6 do
    pcall(function()
        Lib = ReplicatedStorage:WaitForChild("Library", 25)
        if not Lib then return end
        Client  = Lib:WaitForChild("Client", 15)
        Util    = Lib:WaitForChild("Util", 15)
        Globals = Lib:WaitForChild("Globals", 15)
        if not Client then return end
        EggCmds   = softRequire(Client:WaitForChild("EggCmds", 15))
        PlotCmds  = softRequire(Client:WaitForChild("PlotCmds", 15))
        Network   = softRequire(Client:WaitForChild("Network", 15))
        Guard     = softRequire(Client:WaitForChild("ToolGameplayGuard", 15))
        Lookup    = softRequire(Util and Util:WaitForChild("GuardAreaLookupUtil", 15))
        Save      = softRequire(Client:WaitForChild("Save", 15))
        Constants = softRequire(Globals and Globals:WaitForChild("Constants", 15))
        SpeedPowerProjection = softRequire(Client:FindFirstChild("SpeedPowerProjection"))
    end)
    if EggCmds and PlotCmds and Guard and Lookup then break end
    if i < 6 then task.wait(2) end
end

if not (EggCmds and PlotCmds and Guard and Lookup) then
    genv.SAE_RUNNING = nil
    return warn("[SAE] Modules unavailable. Are you in Steal An Egg?")
end
print("[SAE] Modules loaded")

-- ═══════════════════════════════════════════════════════
-- NETWORK
-- ═══════════════════════════════════════════════════════
local NetMap = (Constants and Constants.NETWORK_MAP) or (Network and Network.NET_MAP) or {}
local PivotKey = (NetMap.ClientCharacter and NetMap.ClientCharacter.SET_PIVOT)
    or "ClientCharacter: SetPivot"

local function netFire(key, ...)
    if not Network or not key then return end
    local args = table.pack(...)
    pcall(Network.Fire, key, table.unpack(args, 1, args.n))
end

local function netInvoke(key, ...)
    if not Network or not key then return false end
    local args = table.pack(...)
    local ok, r = pcall(Network.Invoke, key, table.unpack(args, 1, args.n))
    return ok and r == true
end

-- ═══════════════════════════════════════════════════════
-- SNAPSHOT REMOTE (Dreyvid path)
-- ═══════════════════════════════════════════════════════
local SnapshotRF

local function findSnapshotRF()
    if SnapshotRF and SnapshotRF.Parent then return SnapshotRF end
    local cur = ReplicatedStorage
    for part in string.gmatch("Packages.Networking.RF/EggWorld/AskFieldEggSnapshot", "[^%./]+") do
        cur = cur and cur:FindFirstChild(part)
    end
    if cur and cur:IsA("RemoteFunction") then
        SnapshotRF = cur
        return cur
    end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteFunction") then
            local n = string.lower(d.Name):gsub("[^%w]", "")
            if n == "askfieldeggsnapshot" then
                SnapshotRF = d
                return d
            end
        end
    end
    return nil
end

local function getEggSnapshot()
    local rf = findSnapshotRF()
    if not rf then return nil, "snapshot RF not found" end
    local ok, data = pcall(rf.InvokeServer, rf)
    if not ok or type(data) ~= "table" then
        return nil, "invoke failed: " .. tostring(data)
    end
    return data
end

-- ═══════════════════════════════════════════════════════
-- CHARACTER HELPERS
-- ═══════════════════════════════════════════════════════
local function root()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function zeroVel(p)
    if p then
        p.AssemblyLinearVelocity = Vector3.zero
        p.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ═══════════════════════════════════════════════════════
-- TELEPORT
-- ═══════════════════════════════════════════════════════
local function burstPivot(cf, fires)
    local r = root()
    if not r or not cf then return end
    fires = fires or 2
    for _ = 1, fires do
        netFire(PivotKey, cf)
        r.CFrame = cf
        zeroVel(r)
        task.wait(0.014)
    end
end

local function smoothPath(goal, steps)
    local r = root()
    if not r or not goal then return false end
    steps = steps or 16
    local from = r.Position
    for i = 1, steps do
        if not genv.SAE_RUNNING then return false end
        r = root()
        if not r then return false end
        local p = from:Lerp(goal, i / steps)
        burstPivot(CFrame.new(p.X, math.max(p.Y, r.Position.Y), p.Z), 2)
    end
    return true
end

local function fastPath(goal, steps)
    local r = root()
    if not r or not goal then return false end
    steps = steps or 8
    local from = r.Position
    for i = 1, steps do
        if not genv.SAE_RUNNING then return false end
        r = root()
        if not r then return false end
        local p = from:Lerp(goal, i / steps)
        local cf = CFrame.new(p.X, math.max(p.Y, r.Position.Y), p.Z)
        netFire(PivotKey, cf)
        r.CFrame = cf
        zeroVel(r)
        task.wait(0.01)
    end
    return true
end

local function tpTo(pos, fires)
    burstPivot(CFrame.new(pos), fires or 3)
end

local function teleportToEgg(eggPos)
    if not eggPos then return false end
    fastPath(eggPos + Vector3.new(0, 6, 0), 8)
    task.wait(0.05)
    tpTo(eggPos + Vector3.new(0, 2, 0), 3)
    return true
end

-- ═══════════════════════════════════════════════════════
-- INSTANT PROMPT (Delta: fireproximityprompt support)
-- ═══════════════════════════════════════════════════════
local ProximityPromptService = game:GetService("ProximityPromptService")
local savedHold = setmetatable({}, { __mode = "k" })
local promptConns = {}

local function instantPrompt(p)
    if not p or not p:IsA("ProximityPrompt") then return end
    if savedHold[p] == nil then
        savedHold[p] = p.HoldDuration
    end
    p.HoldDuration = 0
    p.RequiresLineOfSight = false
end

local function hookPrompts()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then instantPrompt(d) end
    end
    table.insert(promptConns, Workspace.DescendantAdded:Connect(function(d)
        if d:IsA("ProximityPrompt") then instantPrompt(d) end
    end))
    table.insert(promptConns, ProximityPromptService.PromptShown:Connect(function(p)
        instantPrompt(p)
    end))
end

local function unhookPrompts()
    for _, c in ipairs(promptConns) do pcall(function() c:Disconnect() end) end
    promptConns = {}
    for p, orig in pairs(savedHold) do
        if p.Parent then pcall(function() p.HoldDuration = orig end) end
    end
    savedHold = setmetatable({}, { __mode = "k" })
end

local function firePrompt(p)
    if not p or not p.Enabled then return false end
    local hold = math.max(p.HoldDuration or 0.5, 0.4) + 0.15
    -- Delta: fireproximityprompt support
    if CAP.fireprompt then
        local ok = pcall(fireproximityprompt, p, hold)
        if ok then task.wait(0.1); return true end
    end
    -- fallback: InputHoldBegin/End
    return pcall(function()
        p:InputHoldBegin()
        task.wait(hold)
        p:InputHoldEnd()
    end)
end

local function findPromptNear(pos, radius)
    radius = radius or 15
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local part = d.Parent
            if part and part:IsA("BasePart") then
                if (part.Position - pos).Magnitude <= radius then
                    return d
                end
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════
-- FREEZE SPEED POWER (Delta: getupvalue/setupvalue support)
-- ═══════════════════════════════════════════════════════
local function freezeSpeedPower()
    if not (CAP.getupvalue and CAP.setupvalue) then return end
    local fn = SpeedPowerProjection and SpeedPowerProjection.GetSpeedPower
    if type(fn) ~= "function" then return end
    pcall(function()
        for i = 1, 12 do
            local v = getupvalue(fn, i)
            if type(v) == "number" then
                setupvalue(fn, i, 1e7)
                break
            end
        end
    end)
    pcall(function()
        local d = Save and Save.Get and Save.Get()
        if type(d) == "table" and type(d.SpeedPower) == "number" and d.SpeedPower < 1e6 then
            d.SpeedPower = 1e7
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- ARENA DETECT
-- ═══════════════════════════════════════════════════════
local function inGameplay()
    if type(Guard.IsLocalPlayerInGameplayArea) == "function" then
        return Guard.IsLocalPlayerInGameplayArea() == true
    end
    return false
end

local function onGameplaySide(pos)
    local objs = Workspace:FindFirstChild("__OBJECTS")
    local areas = objs and objs:FindFirstChild("Areas")
    local line = areas and areas:FindFirstChild("SeparationLine")
    if not line or not pos then return false end
    if type(Lookup.IsInGameplaySide) == "function" then
        return Lookup.IsInGameplaySide(line, pos) == true
    end
    return line.CFrame:PointToObjectSpace(pos).Z > 0
end

-- ═══════════════════════════════════════════════════════
-- EGG VALUE
-- ═══════════════════════════════════════════════════════
local AssetsDir
pcall(function()
    local A = require(ReplicatedStorage.Directory.Assets)
    AssetsDir = A and A.Directory
end)

local function eggValue(rec)
    local score = 0
    local cat = rec.AssetCategory
    if cat and AssetsDir then
        local e = AssetsDir[cat]
        if e and e.Rarity and type(e.Rarity.RarityNumber) == "number" then
            score = e.Rarity.RarityNumber
        end
    end
    if type(rec.Mutations) == "table" then score = score + #rec.Mutations * 50 end
    if rec.IsRare or rec.Rare then score = score + 200 end
    return score
end

-- ═══════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════
local State = {
    running = true,
    busy = false,
    carrying = false,
    busySince = nil,
}

-- ═══════════════════════════════════════════════════════
-- LIST EGGS
-- ═══════════════════════════════════════════════════════
local function listEggs()
    local snap, err = getEggSnapshot()
    if not snap then return {}, err end
    local list = {}
    local r = root()
    for uid, rec in pairs(snap.Records or snap) do
        if type(rec) == "table"
            and rec.State == "Slot"
            and rec.BottomCFrame then
            local pos = rec.BottomCFrame.Position or (typeof(rec.BottomCFrame) == "Vector3" and rec.BottomCFrame)
            if pos and onGameplaySide(pos) then
                list[#list + 1] = {
                    uid = uid,
                    rec = rec,
                    pos = pos,
                    dist = r and (pos - r.Position).Magnitude or math.huge,
                    value = eggValue(rec),
                }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.dist < b.dist
    end)
    return list
end

-- ═══════════════════════════════════════════════════════
-- STEAL
-- ═══════════════════════════════════════════════════════
local function stealEgg(target)
    if not target then return false, "no target" end
    local r = root()
    if not r then return false, "no character" end
    if not inGameplay() then
        local objs = Workspace:FindFirstChild("__OBJECTS")
        local line = objs and objs.Areas and objs.Areas:FindFirstChild("SeparationLine")
        if line then
            fastPath(line.Position + Vector3.new(55, 4, 0), 12)
            task.wait(0.3)
        end
        if not inGameplay() then return false, "not in arena" end
    end
    teleportToEgg(target.pos)
    task.wait(0.1)
    local prompt = findPromptNear(target.pos, 15)
    if not prompt then
        if EggCmds.RequestCarryAreaEgg then
            local slot = tostring(target.uid):match(":(.+)$")
            pcall(EggCmds.RequestCarryAreaEgg, target.uid, slot or target.uid)
        end
        task.wait(0.3)
        State.carrying = true
        return true
    end
    firePrompt(prompt)
    task.wait(0.15)
    State.carrying = true
    return true
end

local function returnHome()
    if not PlotCmds.GetRespawnPointCFrame then return false end
    local home = PlotCmds.GetRespawnPointCFrame(LP)
    if not home then return false end
    fastPath(home.Position + Vector3.new(0, 3, 0), 10)
    task.wait(0.3)
    State.carrying = false
    return true
end

local function stealCycle(opts)
    opts = opts or {}
    if State.busy then return false end
    State.busy = true
    State.busySince = os.clock()
    local ok, err = pcall(function()
        freezeSpeedPower()
        local eggs, snapErr = listEggs()
        if #eggs == 0 then return false, snapErr or "no eggs" end
        local target = eggs[1]
        print(("[SAE] Target: %s (val=%d, dist=%.0f)"):format(
            tostring(target.rec.AssetCategory or "?"),
            target.value,
            target.dist
        ))
        local grabbed, gErr = stealEgg(target)
        if not grabbed then return false, gErr end
        if opts.returnHome ~= false then returnHome() end
        return true
    end)
    State.busy = false
    State.busySince = nil
    return ok, err
end

genv.SAE_STEAL = stealCycle

-- ═══════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════
genv.SAE = {
    Steal = stealCycle,
    ListEggs = listEggs,
    GetSnapshot = getEggSnapshot,
    Teleport = tpTo,
    FastPath = fastPath,
    SmoothPath = smoothPath,
    FreezeSpeed = freezeSpeedPower,
    State = State,
}

genv.SAE_SHUTDOWN = function()
    genv.SAE_RUNNING = nil
    State.running = false
    unhookPrompts()
end

-- ═══════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════
hookPrompts()

RunService.Heartbeat:Connect(function()
    genv.SAE_HEARTBEAT = tick()
    if State.busy and State.busySince and os.clock() - State.busySince > 60 then
        State.busy = false
        State.busySince = nil
    end
end)

print("[SAE] Ready on " .. execName)
print("[SAE] API: getgenv().SAE.Steal() | .ListEggs() | .Teleport(pos)")
print("[SAE] Stop: getgenv().SAE_SHUTDOWN()")
