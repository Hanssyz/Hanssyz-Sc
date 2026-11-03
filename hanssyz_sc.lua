-- ============================================
-- PART 3: FARM, HATCH, EQUIP, SELL, FUSE, FAVORITE, RIFT, SCRAMBLE
-- ============================================

-- ============================================
-- FARM STATE
-- ============================================
local FarmState = {
    TreadmillRiding = false,
    TreadmillNextCheck = 0,
    HatchTask = nil,
    SellTask = nil,
    FuseTask = nil,
    FavTask = nil,
    RiftTask = nil,
    ScrambleTask = nil,
    RiftState = nil,
    ScrambleState = nil,
    ScrambleDrones = {},
    ScrambleDrops = {},
    SellCooldown = 0,
    HatchCooldown = 0,
    FuseCooldown = 0,
    FavCooldown = 0,
    EquipTask = nil,
}

-- ============================================
-- TAB: FARM (TREADMILL) — tab baru
-- ============================================
local tabFarm = GUI.CreateTab(window, "Farm", 3.5)

GUI.CreateSection(tabFarm.Page, "AUTO TREADMILL", 1)
GUI.CreateText(tabFarm.Page, {
    Text = "Duduk di treadmill base lo buat dapet income pasif.",
    Color = Color3.fromRGB(180, 180, 200),
    Size = 10,
    Height = 30,
    Order = 2,
})

local function findMyTreadmill()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil, nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        sign = sign and sign:FindFirstChild("PlayerPlotSign")
        sign = sign and sign:FindFirstChild("Frame")
        sign = sign and sign:FindFirstChild("PlayerName")
        if sign and sign:IsA("TextLabel") and (sign.Text == lp.Name or sign.Text == lp.DisplayName) then
            local tread = plot:FindFirstChild("TreadmillBottom")
            return plot, tread
        end
    end
    return nil, nil
end

local function runTreadmillCycle()
    if not claimMovement("treadmill") then return false end
    local plot, tread = findMyTreadmill()
    if not tread then
        releaseMovement("treadmill")
        return false
    end
    local pos = tread.Position + Vector3.new(0, tread.Size.Y/2 + 1, 0)

    -- teleport ke treadmill
    if distTo(pos) > 5 then
        local arrived = false
        flyTo(pos, CONFIG.StealSpeed, nil, function(a) arrived = a end)
        local t = 0
        while not arrived and t < 8 do
            task.wait(0.1)
            t = t + 0.1
        end
    end

    -- wear still
    local rf = networking:FindFirstChild("RF/Treadmill/AskWearStill")
    if rf and rf:IsA("RemoteFunction") then
        local ok, result = pcall(rf.InvokeServer, rf)
        FarmState.TreadmillRiding = ok and result ~= false and result ~= nil
    end
    releaseMovement("treadmill")
    return FarmState.TreadmillRiding
end

local function treadmillLoop()
    if not CONFIG.AutoTreadmill then return end
    task.spawn(function()
        while CONFIG.AutoTreadmill do
            if not FarmState.TreadmillRiding and os.clock() >= FarmState.TreadmillNextCheck then
                pcall(runTreadmillCycle)
                FarmState.TreadmillNextCheck = os.clock() + 3
            elseif CONFIG.StayOnTreadmill and FarmState.TreadmillRiding and os.clock() >= FarmState.TreadmillNextCheck then
                local rf = networking:FindFirstChild("RF/Treadmill/AskWearStill")
                if rf and rf:IsA("RemoteFunction") then
                    pcall(function() rf:InvokeServer() end)
                end
                FarmState.TreadmillNextCheck = os.clock() + 8
            end
            task.wait(1)
        end
    end)
end

local treadmillToggle = GUI.CreateToggle(tabFarm.Page, {
    Name = "Auto Treadmill",
    Note = "Duduk di treadmill base lo",
    Default = false,
    Order = 3,
    Callback = function(on)
        CONFIG.AutoTreadmill = on
        if on then
            treadmillLoop()
        else
            FarmState.TreadmillRiding = false
            if claimMovement("treadmill") then
                local rf = networking:FindFirstChild("RF/Treadmill/AskDoff")
                if rf and rf:IsA("RemoteFunction") then
                    pcall(function() rf:InvokeServer() end)
                end
                releaseMovement("treadmill")
            end
        end
    end,
})

GUI.CreateToggle(tabFarm.Page, {
    Name = "Stay On Treadmill",
    Note = "Auto re-wear kalau kelepas",
    Default = true,
    Order = 4,
    Callback = function(on)
        CONFIG.StayOnTreadmill = on
    end,
})

-- ============================================
-- HATCH & EQUIP
-- ============================================
GUI.CreateSection(tabHatch.Page, "AUTO HATCH", 1)

local function isEggReady(uid)
    if Modules.EggState and type(Modules.EggState.IsReadyToHatch) == "function" then
        local ok, r = pcall(Modules.EggState.IsReadyToHatch, uid)
        if ok then return r == true end
    end
    return false
end

local function runHatchCycle()
    if not claimMovement("hatch") then return false end
    local ownerEggs = readOwnerEggs()
    if not ownerEggs then
        releaseMovement("hatch")
        return false
    end

    local ready = {}
    for uid, record in pairs(ownerEggs) do
        if type(record) == "table" and record.Placement ~= nil and isEggReady(uid) then
            local rarity = getEggRarity(record)
            local value = getEggValue(record)
            local ok = rarity >= (CONFIG.HatchMinRarity or 0)
            if ok and (CONFIG.HatchMinValue or 0) > 0 then
                ok = value >= CONFIG.HatchMinValue
            end
            if ok then
                table.insert(ready, { Uid = uid, Record = record, Value = value })
            end
        end
    end

    if #ready == 0 then
        releaseMovement("hatch")
        return false
    end

    table.sort(ready, function(a, b) return a.Value > b.Value end)

    local RF = networking:FindFirstChild("RF/EggWorld/AskHatch")
    local Finish = networking:FindFirstChild("RF/EggWorld/AskFinishHatch")
    local count = 0

    for _, item in ipairs(ready) do
        if count >= 8 then break end
        if not RF or not RF:IsA("RemoteFunction") then break end
        local ok, result = pcall(RF.InvokeServer, RF, item.Uid)
        if ok and result ~= false then
            task.wait(0.35)
            if Finish and Finish:IsA("RemoteFunction") then
                pcall(Finish.InvokeServer, Finish, item.Uid)
            end
            count = count + 1
            task.wait(0.15)
        end
    end

    releaseMovement("hatch")
    return count > 0
end

local function hatchLoop()
    if not CONFIG.AutoHatch then return end
    if FarmState.HatchTask then return end
    FarmState.HatchTask = task.spawn(function()
        while CONFIG.AutoHatch do
            pcall(runHatchCycle)
            task.wait(2)
        end
        FarmState.HatchTask = nil
    end)
end

GUI.CreateToggle(tabHatch.Page, {
    Name = "Auto Hatch",
    Note = "Hatch egg yang udah siap",
    Default = false,
    Order = 2,
    Callback = function(on)
        CONFIG.AutoHatch = on
        if on then hatchLoop() end
    end,
})

GUI.CreateSlider(tabHatch.Page, {
    Name = "Hatch Min Value (K/s)",
    Min = 0,
    Max = 5000,
    Default = 0,
    Increment = 10,
    Order = 3,
    Callback = function(v) CONFIG.HatchMinValue = v * 1000 end,
})

GUI.CreateSection(tabHatch.Page, "AUTO EQUIP", 10)

local function runEquipCycle()
    local fetch = networking:FindFirstChild("RF/Haul/FetchWearBestStatus")
    local wear = networking:FindFirstChild("RF/Haul/WearBest")
    if not wear or not wear:IsA("RemoteFunction") then return false end
    if fetch and fetch:IsA("RemoteFunction") then
        local ok, result = pcall(fetch.InvokeServer, fetch)
        if not ok or result == false or result == nil then return false end
    end
    local ok, result = pcall(wear.InvokeServer, wear)
    return ok and result ~= false
end

local function equipLoop()
    if not CONFIG.AutoEquipBest then return end
    if FarmState.EquipTask then return end
    FarmState.EquipTask = task.spawn(function()
        while CONFIG.AutoEquipBest do
            pcall(runEquipCycle)
            task.wait(15)
        end
        FarmState.EquipTask = nil
    end)
end

GUI.CreateToggle(tabHatch.Page, {
    Name = "Auto Equip Best",
    Note = "Equip pet terbaik tiap 15 detik",
    Default = false,
    Order = 11,
    Callback = function(on)
        CONFIG.AutoEquipBest = on
        if on then equipLoop() end
    end,
})

GUI.CreateButton(tabHatch.Page, {
    Name = "Equip Best Now",
    ButtonText = "Equip Best Now",
    Order = 12,
    Callback = function()
        pcall(runEquipCycle)
    end,
})

GUI.CreateButton(tabHatch.Page, {
    Name = "Hatch Now",
    ButtonText = "Hatch Now",
    Order = 13,
    Callback = function()
        task.spawn(function() pcall(runHatchCycle) end)
    end,
})

-- ============================================
-- SELL
-- ============================================
GUI.CreateSection(tabSell.Page, "AUTO SELL PET", 1)

local function getInventory()
    if Modules.Save and type(Modules.Save.Get) == "function" then
        local ok, r = pcall(Modules.Save.Get)
        if ok and type(r) == "table" then return r end
    end
    return nil
end

local function matchesSellRule(item, mode)
    local rule = mode == "pet" and CONFIG.SellPetRule or CONFIG.SellEggRule
    local maxRarity = mode == "pet" and CONFIG.SellPetMaxRarity or CONFIG.SellEggMaxRarity
    local minValue = mode == "pet" and CONFIG.SellPetMinValue or CONFIG.SellEggMinValue
    local keepMut = mode == "pet" and CONFIG.KeepMutatedPets or CONFIG.KeepMutatedEggs

    local mutations = type(item.Mutations) == "table" and item.Mutations or {}
    if keepMut and #mutations > 0 then return false end

    local cat = mode == "pet" and item.Category or item.AssetCategory
    local info = getAssetInfo(cat)
    local scale = tonumber(item.AssetScale or item.Scale) or 1
    local value = getIncome(cat, scale, mutations)

    local rarityOk = info.RarityNumber <= maxRarity
    local valueOk = minValue <= 0 or value < minValue

    if rule == "Value Only" then return valueOk end
    if rule == "Rarity And Value" then return rarityOk and valueOk end
    if rule == "Rarity Or Value" then return rarityOk or valueOk end
    return rarityOk
end

local function sellPets()
    local data = getInventory()
    if not data then return 0 end
    local inventory = type(data.Inventory) == "table" and data.Inventory or {}
    local equipped = type(data.EquippedAssets) == "table" and data.EquippedAssets or {}
    local equippedSet = {}
    for _, uid in pairs(equipped) do equippedSet[uid] = true end

    local uids = {}
    for uid, item in pairs(inventory) do
        if type(item) == "table" and item.InFuse ~= true and item.IsFavorite ~= true
            and not equippedSet[uid] and matchesSellRule(item, "pet") then
            table.insert(uids, uid)
        end
    end
    if #uids == 0 then return 0 end

    local re = networking:FindFirstChild("RE/PetSatchel/SellSelection")
    if not re or not re:IsA("RemoteEvent") then return 0 end

    -- batch 50
    for i = 1, #uids, 50 do
        local batch = {}
        for j = i, math.min(i + 49, #uids) do
            table.insert(batch, uids[j])
        end
        pcall(re.FireServer, re, { Eggs = {}, Assets = batch })
        task.wait(0.3)
    end
    return #uids
end

local function sellEggs()
    local ownerEggs = readOwnerEggs()
    if not ownerEggs then return 0 end
    local uids = {}
    for uid, record in pairs(ownerEggs) do
        if type(record) == "table" and record.Placement == nil and matchesSellRule(record, "egg") then
            table.insert(uids, uid)
        end
    end
    if #uids == 0 then return 0 end

    local re = networking:FindFirstChild("RE/PetSatchel/SellSelection")
    if not re or not re:IsA("RemoteEvent") then return 0 end

    for i = 1, #uids, 50 do
        local batch = {}
        for j = i, math.min(i + 49, #uids) do
            table.insert(batch, uids[j])
        end
        pcall(re.FireServer, re, { Eggs = batch, Assets = {} })
        task.wait(0.3)
    end
    return #uids
end

local function sellLoop()
    if not (CONFIG.AutoSellPet or CONFIG.AutoSellEgg) then return end
    if FarmState.SellTask then return end
    FarmState.SellTask = task.spawn(function()
        while CONFIG.AutoSellPet or CONFIG.AutoSellEgg do
            if CONFIG.AutoSellPet then pcall(sellPets) end
            if CONFIG.AutoSellEgg then pcall(sellEggs) end
            task.wait(3)
        end
        FarmState.SellTask = nil
    end)
end

GUI.CreateToggle(tabSell.Page, {
    Name = "Auto Sell Pet",
    Default = false,
    Order = 2,
    Callback = function(on)
        CONFIG.AutoSellPet = on
        if on then sellLoop() end
    end,
})

GUI.CreateDropdown(tabSell.Page, {
    Name = "Sell Pet Rule",
    Options = { "Rarity Only", "Value Only", "Rarity And Value", "Rarity Or Value" },
    Default = "Rarity Only",
    Order = 3,
    Callback = function(v) CONFIG.SellPetRule = v end,
})

GUI.CreateSlider(tabSell.Page, {
    Name = "Sell Pet Max Rarity (num)",
    Min = 0,
    Max = 15,
    Default = 3,
    Order = 4,
    Callback = function(v) CONFIG.SellPetMaxRarity = v end,
})

GUI.CreateToggle(tabSell.Page, {
    Name = "Keep Mutated Pets",
    Default = true,
    Order = 5,
    Callback = function(on) CONFIG.KeepMutatedPets = on end,
})

GUI.CreateSection(tabSell.Page, "AUTO SELL EGG", 10)

GUI.CreateToggle(tabSell.Page, {
    Name = "Auto Sell Egg",
    Default = false,
    Order = 11,
    Callback = function(on)
        CONFIG.AutoSellEgg = on
        if on then sellLoop() end
    end,
})

GUI.CreateDropdown(tabSell.Page, {
    Name = "Sell Egg Rule",
    Options = { "Rarity Only", "Value Only", "Rarity And Value", "Rarity Or Value" },
    Default = "Rarity Only",
    Order = 12,
    Callback = function(v) CONFIG.SellEggRule = v end,
})

GUI.CreateSlider(tabSell.Page, {
    Name = "Sell Egg Max Rarity (num)",
    Min = 0,
    Max = 15,
    Default = 3,
    Order = 13,
    Callback = function(v) CONFIG.SellEggMaxRarity = v end,
})

GUI.CreateToggle(tabSell.Page, {
    Name = "Keep Mutated Eggs",
    Default = true,
    Order = 14,
    Callback = function(on) CONFIG.KeepMutatedEggs = on end,
})

GUI.CreateButton(tabSell.Page, {
    Name = "Sell Pets Now",
    ButtonText = "Sell Pets Now",
    Order = 20,
    Callback = function()
        task.spawn(function()
            local n = sellPets()
            statusText.Set("Sold " .. n .. " pets")
        end)
    end,
})

GUI.CreateButton(tabSell.Page, {
    Name = "Sell Eggs Now",
    ButtonText = "Sell Eggs Now",
    Order = 21,
    Callback = function()
        task.spawn(function()
            local n = sellEggs()
            statusText.Set("Sold " .. n .. " eggs")
        end)
    end,
})

-- ============================================
-- FUSE
-- ============================================
GUI.CreateSection(tabFuse.Page, "AUTO FUSE MACHINE", 1)

local function runFuseCycle()
    if not claimMovement("fuse") then return false end
    local data = getInventory()
    if not data then
        releaseMovement("fuse")
        return false
    end

    if data.FusionLocked == true then
        if type(data.FusionEggReward) == "table" then
            local finish = networking:FindFirstChild("RF/Fusery/FinishReveal")
            if finish and finish:IsA("RemoteFunction") then
                pcall(finish.InvokeServer, finish)
            end
        end
        releaseMovement("fuse")
        return false
    end

    local inventory = type(data.Inventory) == "table" and data.Inventory or {}
    local slots = type(data.FusionSlots) == "table" and data.FusionSlots or {}
    local inSlot = {}
    for i = 1, 3 do
        if slots[i] then inSlot[slots[i]] = true end
    end

    -- cari 3 pet sama species
    local groups = {}
    for uid, item in pairs(inventory) do
        if type(item) == "table" and item.InFuse ~= true and item.IsFavorite ~= true and not inSlot[uid] then
            local cat = tostring(item.Category)
            local info = getAssetInfo(cat)
            if info.RarityNumber <= CONFIG.FuseMaxRarity then
                local mut = type(item.Mutations) == "table" and #item.Mutations > 0
                if not (CONFIG.FuseSkipMutated and mut) then
                    groups[cat] = groups[cat] or {}
                    table.insert(groups[cat], { Uid = uid, Item = item })
                end
            end
        end
    end

    local chosen = nil
    for cat, list in pairs(groups) do
        if #list >= 3 - (slots[1] and 1 or 0) - (slots[2] and 1 or 0) - (slots[3] and 1 or 0) then
            if not chosen then chosen = { Cat = cat, Items = list } end
        end
    end

    if not chosen then
        releaseMovement("fuse")
        return false
    end

    local load = networking:FindFirstChild("RF/Fusery/LoadPet")
    if load and load:IsA("RemoteFunction") then
        local need = 3
        for i = 1, 3 do if slots[i] then need = need - 1 end end
        for i = 1, math.min(need, #chosen.Items) do
            pcall(load.InvokeServer, load, chosen.Items[i].Uid)
            task.wait(0.35)
        end
    end

    local begin = networking:FindFirstChild("RF/Fusery/BeginFuse")
    if begin and begin:IsA("RemoteFunction") then
        pcall(begin.InvokeServer, begin)
    end

    releaseMovement("fuse")
    return true
end

local function fuseLoop()
    if not CONFIG.AutoFuse then return end
    if FarmState.FuseTask then return end
    FarmState.FuseTask = task.spawn(function()
        while CONFIG.AutoFuse do
            pcall(runFuseCycle)
            task.wait(3)
        end
        FarmState.FuseTask = nil
    end)
end

GUI.CreateToggle(tabFuse.Page, {
    Name = "Auto Fuse Machine",
    Note = "Fuse 3 pet sama species jadi egg",
    Default = false,
    Order = 2,
    Callback = function(on)
        CONFIG.AutoFuse = on
        if on then fuseLoop() end
    end,
})

GUI.CreateSlider(tabFuse.Page, {
    Name = "Fuse Max Rarity (num)",
    Min = 0,
    Max = 15,
    Default = 6,
    Order = 3,
    Callback = function(v) CONFIG.FuseMaxRarity = v end,
})

GUI.CreateToggle(tabFuse.Page, {
    Name = "Skip Mutated Pets",
    Default = true,
    Order = 4,
    Callback = function(on) CONFIG.FuseSkipMutated = on end,
})

GUI.CreateButton(tabFuse.Page, {
    Name = "Fuse Now",
    ButtonText = "Fuse Now",
    Order = 5,
    Callback = function()
        task.spawn(function() pcall(runFuseCycle) end)
    end,
})

-- ============================================
-- FAVORITE
-- ============================================
GUI.CreateSection(tabSell.Page, "AUTO FAVORITE", 30)

local function matchesFavRule(item)
    if not item then return false end
    local muts = type(item.Mutations) == "table" and item.Mutations or {}
    local info = getAssetInfo(item.Category)
    local scale = tonumber(item.AssetScale or item.Scale) or 1
    local value = getIncome(item.Category, scale, muts)

    local rarityOk = info.RarityNumber >= CONFIG.FavoriteMinRarity
    local valueOk = CONFIG.FavoriteMinValue <= 0 or value >= CONFIG.FavoriteMinValue
    local mutOk = true
    if next(CONFIG.FavoriteMutations) ~= nil then
        mutOk = false
        for _, m in ipairs(muts) do
            if CONFIG.FavoriteMutations[tostring(m)] then mutOk = true break end
        end
    end

    local rule = CONFIG.FavoriteRule
    if rule == "Match Any" then return rarityOk or valueOk or mutOk end
    return rarityOk and valueOk and mutOk
end

local function runFavoriteCycle()
    local data = getInventory()
    if not data then return 0 end
    local inventory = type(data.Inventory) == "table" and data.Inventory or {}
    local toFav = {}
    for uid, item in pairs(inventory) do
        if type(item) == "table" and item.IsFavorite ~= true and matchesFavRule(item) then
            table.insert(toFav, uid)
        end
    end
    if #toFav == 0 then return 0 end

    local re = networking:FindFirstChild("RE/PetSatchel/WriteFavourite")
    if not re or not re:IsA("RemoteEvent") then return 0 end

    for i = 1, math.min(#toFav, 25) do
        pcall(re.FireServer, re, toFav[i], true)
        task.wait(0.12)
    end
    return math.min(#toFav, 25)
end

local function favLoop()
    if not CONFIG.AutoFavorite then return end
    if FarmState.FavTask then return end
    FarmState.FavTask = task.spawn(function()
        while CONFIG.AutoFavorite do
            pcall(runFavoriteCycle)
            task.wait(5)
        end
        FarmState.FavTask = nil
    end)
end

GUI.CreateToggle(tabSell.Page, {
    Name = "Auto Favorite",
    Default = false,
    Order = 31,
    Callback = function(on)
        CONFIG.AutoFavorite = on
        if on then favLoop() end
    end,
})

GUI.CreateDropdown(tabSell.Page, {
    Name = "Favorite Rule",
    Options = { "Match All", "Match Any" },
    Default = "Match All",
    Order = 32,
    Callback = function(v) CONFIG.FavoriteRule = v end,
})

GUI.CreateSlider(tabSell.Page, {
    Name = "Favorite Min Rarity (num)",
    Min = 0,
    Max = 15,
    Default = 0,
    Order = 33,
    Callback = function(v) CONFIG.FavoriteMinRarity = v end,
})

GUI.CreateButton(tabSell.Page, {
    Name = "Favorite Now",
    ButtonText = "Favorite Now",
    Order = 34,
    Callback = function()
        task.spawn(function()
            local n = runFavoriteCycle()
            statusText.Set("Favorited " .. n .. " pets")
        end)
    end,
})

-- ============================================
-- RIFT & SCRAMBLE
-- ============================================
GUI.CreateSection(tabRift.Page, "RIFT MACHINE", 1)

local function readRiftState()
    local rf = networking:FindFirstChild("RF/Rift/AskState")
    if not rf or not rf:IsA("RemoteFunction") then return nil end
    local ok, result = pcall(rf.InvokeServer, rf)
    if ok and type(result) == "table" then return result end
    return nil
end

local function runRiftSacrifice()
    if not claimMovement("rift") then return false end
    local state = readRiftState()
    if not state or state.Unlocked ~= true or type(state.Requirements) ~= "table" then
        releaseMovement("rift")
        return false
    end

    local data = getInventory()
    if not data then
        releaseMovement("rift")
        return false
    end

    local inventory = type(data.Inventory) == "table" and data.Inventory or {}
    local equipped = type(data.EquippedAssets) == "table" and data.EquippedAssets or {}
    local equippedSet = {}
    for _, uid in pairs(equipped) do equippedSet[uid] = true end

    local requirements = state.Requirements
    local needByCat = {}
    for _, cat in ipairs(requirements) do
        needByCat[tostring(cat)] = (needByCat[tostring(cat)] or 0) + 1
    end

    local pick = {}
    for uid, item in pairs(inventory) do
        if type(item) == "table" and item.InFuse ~= true and item.IsFavorite ~= true
            and not equippedSet[uid] then
            local cat = tostring(item.Category)
            if (needByCat[cat] or 0) > 0 then
                table.insert(pick, { Uid = uid, Cat = cat })
                needByCat[cat] = needByCat[cat] - 1
            end
        end
    end

    for _, count in pairs(needByCat) do
        if count > 0 then
            releaseMovement("rift")
            return false
        end
    end

    if #pick < #requirements then
        releaseMovement("rift")
        return false
    end

    local trade = networking:FindFirstChild("RF/Rift/AskTradeIn")
    if trade and trade:IsA("RemoteFunction") then
        local uids = {}
        for _, p in ipairs(pick) do table.insert(uids, p.Uid) end
        pcall(trade.InvokeServer, trade, uids)
    end
    releaseMovement("rift")
    return true
end

local function runRiftReroll()
    local rf = networking:FindFirstChild("RF/Rift/AskRefresh")
    if rf and rf:IsA("RemoteFunction") then
        pcall(rf.InvokeServer, rf)
        return true
    end
    return false
end

local function riftLoop()
    if not (CONFIG.AutoRiftSacrifice or CONFIG.AutoRiftReroll) then return end
    if FarmState.RiftTask then return end
    FarmState.RiftTask = task.spawn(function()
        while CONFIG.AutoRiftSacrifice or CONFIG.AutoRiftReroll do
            local state = readRiftState()
            if state then
                if CONFIG.AutoRiftSacrifice then pcall(runRiftSacrifice) end
                if CONFIG.AutoRiftReroll and state.PendingReward == false and (state.FreeRefreshesRemaining or 0) > 0 then
                    pcall(runRiftReroll)
                end
            end
            task.wait(5)
        end
        FarmState.RiftTask = nil
    end)
end

GUI.CreateToggle(tabRift.Page, {
    Name = "Auto Rift Sacrifice",
    Note = "Trade 3 pet yang requirement Rift",
    Default = false,
    Order = 2,
    Callback = function(on)
        CONFIG.AutoRiftSacrifice = on
        if on then riftLoop() end
    end,
})

GUI.CreateToggle(tabRift.Page, {
    Name = "Auto Rift Reroll",
    Note = "Reroll recipe kalau free reroll tersedia",
    Default = false,
    Order = 3,
    Callback = function(on)
        CONFIG.AutoRiftReroll = on
        if on then riftLoop() end
    end,
})

-- ============================================
-- SCRAMBLE EVENT
-- ============================================
GUI.CreateSection(tabRift.Page, "DR SCRAMBLE EVENT", 10)

local function readScrambleSnapshot()
    local rf = networking:FindFirstChild("RF/Scramble/Request")
    if not rf or not rf:IsA("RemoteFunction") then return nil end
    local ok, result = pcall(rf.InvokeServer, rf, "Snapshot")
    if ok and type(result) == "table" then
        return result.Snapshot or result
    end
    return nil
end

local function isScrambleActive()
    local snap = readScrambleSnapshot()
    if not snap then return false end
    if snap.Enabled == false then return false end
    if type(snap.EventEndsAt) == "number" and workspace:GetServerTimeNow() >= snap.EventEndsAt then
        return false
    end
    return true
end

local function runScrambleHunt()
    if not claimMovement("scramble") then return false end
    if not isScrambleActive() then
        releaseMovement("scramble")
        return false
    end

    local snap = readScrambleSnapshot()
    if not snap then
        releaseMovement("scramble")
        return false
    end

    -- cari drone di workspace
    local container = Workspace:FindFirstChild("ScrambleLocalVisuals")
    local droneCount = 0
    if container then
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") and string.sub(child.Name, 1, 14) == "PersonalDrone_" then
                local hitbox = child:FindFirstChild("Hitbox")
                if hitbox and hitbox:IsA("BasePart") then
                    droneCount = droneCount + 1
                    -- teleport ke drone
                    local pos = hitbox.Position
                    if distTo(pos) > 20 then
                        local arrived = false
                        flyTo(pos + Vector3.new(0, -1, 4), CONFIG.StealSpeed, nil, function(a) arrived = a end)
                        local t = 0
                        while not arrived and t < 8 do
                            task.wait(0.1)
                            t = t + 0.1
                        end
                    end
                    -- swing bat
                    local re = networking:FindFirstChild("RE/BatSwing/Trigger")
                    if re and re:IsA("RemoteEvent") then
                        local trace = tostring(lp.UserId) .. ":" .. tostring(math.random(1e6)) .. ":" .. tostring(math.floor(workspace:GetServerTimeNow() * 1000))
                        pcall(re.FireServer, re, child, trace)
                        task.wait(0.1)
                    end
                end
            end
        end
    end

    releaseMovement("scramble")
    return droneCount > 0
end

local function runScrambleLostParts()
    if not claimMovement("scramble") then return false end
    local container = Workspace:FindFirstChild("DrScrambleEvent")
    if not container then
        releaseMovement("scramble")
        return false
    end
    local claimed = 0
    for _, partName in ipairs({ "LostPart1", "LostPart2" }) do
        local part = container:FindFirstChild(partName)
        if part then
            local hitbox = part:FindFirstChild("Hitbox", true) or part.PrimaryPart
            if hitbox then
                local pos = hitbox.Position or getPos(part)
                if pos and distTo(pos) > 10 then
                    local arrived = false
                    flyTo(pos + Vector3.new(0, 3, 0), CONFIG.StealSpeed, nil, function(a) arrived = a end)
                    local t = 0
                    while not arrived and t < 8 do
                        task.wait(0.1)
                        t = t + 0.1
                    end
                end
                for _, d in ipairs(part:GetDescendants()) do
                    if d:IsA("ProximityPrompt") and d.Name == "ClaimLostPart" then
                        pcall(function() d.HoldDuration = 0 end)
                        if typeof(fireproximityprompt) == "function" then
                            pcall(fireproximityprompt, d)
                        end
                        claimed = claimed + 1
                        task.wait(0.5)
                    end
                end
            end
        end
    end
    releaseMovement("scramble")
    return claimed > 0
end

local function runScrambleVault()
    if not claimMovement("scramble") then return false end
    local container = Workspace:FindFirstChild("DrScrambleEvent")
    if not container then
        releaseMovement("scramble")
        return false
    end
    local vault = container:FindFirstChild("ExperimentVault")
    if not vault then
        releaseMovement("scramble")
        return false
    end
    local pos = getPos(vault)
    if not pos then
        releaseMovement("scramble")
        return false
    end
    if distTo(pos) > 10 then
        local arrived = false
        flyTo(pos + Vector3.new(0, 3, 0), CONFIG.StealSpeed, nil, function(a) arrived = a end)
        local t = 0
        while not arrived and t < 8 do
            task.wait(0.1)
            t = t + 0.1
        end
    end
    local rf = networking:FindFirstChild("RF/Scramble/Request")
    if rf and rf:IsA("RemoteFunction") then
        pcall(rf.InvokeServer, rf, "Vault")
    end
    releaseMovement("scramble")
    return true
end

local function scrambleLoop()
    if not (CONFIG.AutoHuntDrones or CONFIG.AutoCollectLostParts or CONFIG.AutoOpenVault or CONFIG.AutoBuyScrambleShop) then return end
    if FarmState.ScrambleTask then return end
    FarmState.ScrambleTask = task.spawn(function()
        while CONFIG.AutoHuntDrones or CONFIG.AutoCollectLostParts or CONFIG.AutoOpenVault or CONFIG.AutoBuyScrambleShop do
            if isScrambleActive() then
                if CONFIG.AutoCollectLostParts then pcall(runScrambleLostParts) end
                if CONFIG.AutoHuntDrones then pcall(runScrambleHunt) end
                if CONFIG.AutoOpenVault then pcall(runScrambleVault) end
            end
            task.wait(3)
        end
        FarmState.ScrambleTask = nil
    end)
end

GUI.CreateToggle(tabRift.Page, {
    Name = "Auto Hunt Drones",
    Default = false,
    Order = 11,
    Callback = function(on) CONFIG.AutoHuntDrones = on if on then scrambleLoop() end end,
})

GUI.CreateToggle(tabRift.Page, {
    Name = "Auto Collect Lost Parts",
    Default = false,
    Order = 12,
    Callback = function(on) CONFIG.AutoCollectLostParts = on if on then scrambleLoop() end end,
})

GUI.CreateToggle(tabRift.Page, {
    Name = "Auto Open Vault",
    Default = false,
    Order = 13,
    Callback = function(on) CONFIG.AutoOpenVault = on if on then scrambleLoop() end end,
})

GUI.CreateButton(tabRift.Page, {
    Name = "Open Vault Now",
    ButtonText = "Open Vault Now",
    Order = 14,
    Callback = function()
        task.spawn(function() pcall(runScrambleVault) end)
    end,
})

GUI.CreateButton(tabRift.Page, {
    Name = "Sacrifice Rift Now",
    ButtonText = "Sacrifice Rift Now",
    Order = 20,
    Callback = function()
        task.spawn(function() pcall(runRiftSacrifice) end)
    end,
})

GUI.CreateButton(tabRift.Page, {
    Name = "Reroll Rift Now",
    ButtonText = "Reroll Rift Now",
    Order = 21,
    Callback = function()
        pcall(runRiftReroll)
    end,
})

print("[Kyriel] Part 3 loaded: treadmill, hatch, equip, sell, fuse, favorite, rift, scramble.")

-- ============================================
-- END PART 3
-- Tempel Part 4 di bawah baris ini
-- ============================================

-- ============================================
-- PART 4: COMBAT, MISC, SERVER, INFO, WEBHOOK, FINALIZE
-- ============================================

-- ============================================
-- COMBAT STATE
-- ============================================
local CombatState = {
    RagdollTask = nil,
    TrapConnection = nil,
    TrapOriginal = {},
    InvisibleActive = false,
    InvisibleOriginal = nil,
    InvisibleClone = nil,
    SpeedConnection = nil,
    JumpConnection = nil,
    AntiGuardTask = nil,
    AntiGuardBusy = false,
    AntiGuardLastHit = 0,
}

-- ============================================
-- TAB: COMBAT
-- ============================================
GUI.CreateSection(tabCombat.Page, "ANTI RAGDOLL", 1)

local function ragdollForceUp()
    local hum = getHum()
    local root = getRoot()
    if not hum or not root then return end
    pcall(function()
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum.PlatformStand = false
        hum.Sit = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        hum.BreakJointsOnDeath = false
        hum.RequiresNeck = false
    end)
end

local function startRagdollBypass()
    if CombatState.RagdollTask then return end
    CombatState.RagdollTask = task.spawn(function()
        while CONFIG.AutoRagdoll do
            ragdollForceUp()
            task.wait(0.15)
        end
        CombatState.RagdollTask = nil
    end)
end

GUI.CreateToggle(tabCombat.Page, {
    Name = "Anti Ragdoll",
    Note = "Force up kalau kena ragdoll dari guard/trap",
    Default = true,
    Order = 2,
    Callback = function(on)
        CONFIG.AutoRagdoll = on
        if on then startRagdollBypass()
        else ragdollForceUp() end
    end,
})

-- ============================================
-- ANTI TRAP
-- ============================================
GUI.CreateSection(tabCombat.Page, "ANTI TRAP", 10)

local function disableTrap(instance)
    if not instance or not instance.Parent then return end
    local function disablePart(part)
        if part:IsA("BasePart") and CombatState.TrapOriginal[part] == nil then
            CombatState.TrapOriginal[part] = part.CanTouch
            pcall(function() part.CanTouch = false end)
        end
    end
    disablePart(instance)
    for _, d in ipairs(instance:GetDescendants()) do
        disablePart(d)
    end
end

local function scanTraps()
    for _, trap in ipairs(CollectionService:GetTagged("PlacedTrap")) do
        if trap:GetAttribute("Owner") ~= lp.Name then
            disableTrap(trap)
        end
    end
end

local function restoreTraps()
    for part, original in pairs(CombatState.TrapOriginal) do
        if part and part.Parent then
            pcall(function() part.CanTouch = original end)
        end
    end
    CombatState.TrapOriginal = {}
end

local function startAntiTrap()
    if CombatState.TrapConnection then return end
    scanTraps()
    CombatState.TrapConnection = CollectionService:GetInstanceAddedSignal("PlacedTrap"):Connect(function(trap)
        task.defer(function()
            if CONFIG.AutoTrap and trap:GetAttribute("Owner") ~= lp.Name then
                disableTrap(trap)
            end
        end)
    end)
end

GUI.CreateToggle(tabCombat.Page, {
    Name = "Anti Trap",
    Note = "Trap dari player lain gak bisa nangkep lo",
    Default = true,
    Order = 11,
    Callback = function(on)
        CONFIG.AutoTrap = on
        if on then startAntiTrap()
        else
            if CombatState.TrapConnection then
                CombatState.TrapConnection:Disconnect()
                CombatState.TrapConnection = nil
            end
            restoreTraps()
        end
    end,
})

-- ============================================
-- INVISIBILITY
-- ============================================
GUI.CreateSection(tabCombat.Page, "INVISIBILITY", 20)

local function toggleInvisibility(on)
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")

    if on then
        if CombatState.InvisibleActive then return end
        if not hum then return end
        if hum:GetState() ~= Enum.HumanoidStateType.Running
            and hum:GetState() ~= Enum.HumanoidStateType.RunningNoPhysics
            and hum:GetState() ~= Enum.HumanoidStateType.Landed then
            return
        end

        -- clone humanoid swap
        local clone = hum:Clone()
        hum.Parent = nil
        clone.Parent = char
        workspace.CurrentCamera.CameraSubject = clone
        pcall(function()
            local ps = lp:FindFirstChild("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then
                local ctl = require(pm):GetControls()
                if type(ctl) == "table" then ctl.humanoid = clone end
            end
        end)

        local animate = char:FindFirstChild("Animate")
        if animate and animate:IsA("LocalScript") then
            task.spawn(function()
                animate.Enabled = false
                task.wait()
                animate.Enabled = true
            end)
        end

        local animator = hum:FindFirstChildOfClass("Animator")
        local cloneAnim = clone:FindFirstChildOfClass("Animator")
        if animator and cloneAnim then
            animator.AnimationPlayed:Connect(function(track)
                local anim = track.Animation
                if not anim or not cloneAnim.Parent then return end
                local ok, cloned = pcall(function() return cloneAnim:LoadAnimation(anim) end)
                if not ok or not cloned then return end
                pcall(function()
                    cloned.Priority = track.Priority
                    cloned.Looped = track.Looped
                    cloned:Play(0.05, math.max(track.WeightTarget, 0.01), track.Speed)
                end)
            end)
        end

        CombatState.InvisibleOriginal = hum
        CombatState.InvisibleClone = clone
        CombatState.InvisibleActive = true
    else
        if not CombatState.InvisibleActive then return end
        local original = CombatState.InvisibleOriginal
        local clone = CombatState.InvisibleClone
        CombatState.InvisibleActive = false
        CombatState.InvisibleOriginal = nil
        CombatState.InvisibleClone = nil

        if original and clone and char and original.Parent == nil and clone.Parent == char then
            original.Parent = char
            workspace.CurrentCamera.CameraSubject = original
            pcall(function()
                local ps = lp:FindFirstChild("PlayerScripts")
                local pm = ps and ps:FindFirstChild("PlayerModule")
                if pm then
                    local ctl = require(pm):GetControls()
                    if type(ctl) == "table" then ctl.humanoid = original end
                end
            end)
            pcall(function() clone:Destroy() end)
        end
    end
end

GUI.CreateToggle(tabCombat.Page, {
    Name = "Invisibility",
    Note = "Bikin lo invisible ke player lain",
    Default = false,
    Order = 21,
    Callback = function(on)
        CONFIG.Invisibility = on
        toggleInvisibility(on)
    end,
})

-- ============================================
-- SPEED BOOST
-- ============================================
GUI.CreateSection(tabCombat.Page, "MOVEMENT", 30)

local function startSpeedBoost()
    if CombatState.SpeedConnection then return end
    CombatState.SpeedConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.SpeedBoost then return end
        local hum = getHum()
        local root = getRoot()
        if not hum or not root then return end
        if hum.Sit or hum.PlatformStand then return end
        local num = tonumber(lp:GetAttribute("RagdollEndTime"))
        if num and num > workspace:GetServerTimeNow() then return end
        local moveDir = hum.MoveDirection
        local flat = Vector3.new(moveDir.X, 0, moveDir.Z)
        if flat.Magnitude <= 0.001 then return end
        local target = flat.Unit * CONFIG.BoostSpeed
        local vel = root.AssemblyLinearVelocity
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(target.X, vel.Y, target.Z)
        end)
    end)
end

GUI.CreateToggle(tabCombat.Page, {
    Name = "Speed Boost",
    Default = false,
    Order = 31,
    Callback = function(on)
        CONFIG.SpeedBoost = on
        if on then startSpeedBoost() end
    end,
})

GUI.CreateSlider(tabCombat.Page, {
    Name = "Boost Speed (studs/s)",
    Min = 20,
    Max = 1000,
    Default = 350,
    Increment = 5,
    Order = 32,
    Callback = function(v) CONFIG.BoostSpeed = v end,
})

GUI.CreateToggle(tabCombat.Page, {
    Name = "Infinite Jump",
    Default = false,
    Order = 33,
    Callback = function(on)
        CONFIG.InfiniteJump = on
        if on then
            if CombatState.JumpConnection then return end
            CombatState.JumpConnection = UserInputService.JumpRequest:Connect(function()
                if not CONFIG.InfiniteJump then return end
                local hum = getHum()
                if hum then
                    pcall(function()
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end)
                end
            end)
        else
            if CombatState.JumpConnection then
                CombatState.JumpConnection:Disconnect()
                CombatState.JumpConnection = nil
            end
        end
    end,
})

-- ============================================
-- ANTI GUARD (SIMPLE)
-- ============================================
GUI.CreateSection(tabCombat.Page, "ANTI GUARD", 40)

local AntiGuardHome = Vector3.new(528.7, 70.57, -364.1)

local function getGuardHome()
    local world = Workspace:FindFirstChild("World") or Workspace:FindFirstChild("__OBJECTS")
    world = world and world:FindFirstChild("Machines")
    world = world and world:FindFirstChild("RiftMachine")
    world = world and world:FindFirstChild("Rift")
    world = world and world:FindFirstChild("Meshes/VoidPortal_Cube.003")
    if world and world:IsA("BasePart") then
        local cf = world.CFrame
        return cf:PointToWorldSpace(Vector3.new(-26.776, 1.75, 18.665))
    end
    return AntiGuardHome
end

local function dodgeGuard()
    if CombatState.AntiGuardBusy then return end
    if not CONFIG.AntiGuard then return end
    if not isCarrying() then return end
    if os.clock() - CombatState.AntiGuardLastHit < 20 then return end

    CombatState.AntiGuardBusy = true
    CombatState.AntiGuardLastHit = os.clock()

    task.spawn(function()
        local char = lp.Character
        local hum = getHum()
        local root = getRoot()
        if not char or not hum or not root then
            CombatState.AntiGuardBusy = false
            return
        end

        local home = getGuardHome()
        hum.PlatformStand = true
        local target = home + Vector3.new(0, 3, 0)
        local startPos = root.Position

        for i = 1, 25 do
            local t = i / 25
            local lerp = startPos:Lerp(target, t)
            pcall(function()
                root.CFrame = CFrame.new(lerp)
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            if i == 12 then
                -- fire ForestStrike mid-flight kalau ada
                local strike = networking:FindFirstChild("RE/GuardPatrol/ForestStrike")
                if strike and strike:IsA("RemoteEvent") then
                    pcall(function()
                        strike:FireServer({ EggUid = StealState.CarryUid, GuardCFrame = CFrame.new(home) })
                    end)
                end
            end
            RunService.Heartbeat:Wait()
        end

        hum.PlatformStand = false
        CombatState.AntiGuardBusy = false
    end)
end

GUI.CreateToggle(tabCombat.Page, {
    Name = "Anti Guard V1",
    Note = "Auto dodge kalau guard ngejar lo pas carry egg",
    Default = false,
    Order = 41,
    Callback = function(on)
        CONFIG.AntiGuard = on
        if on then
            if CombatState.AntiGuardTask then return end
            CombatState.AntiGuardTask = task.spawn(function()
                while CONFIG.AntiGuard do
                    pcall(dodgeGuard)
                    task.wait(0.5)
                end
                CombatState.AntiGuardTask = nil
            end)
        end
    end,
})

-- ============================================
-- TAB: MISC
-- ============================================
GUI.CreateSection(tabMisc.Page, "PERFORMANCE", 1)

GUI.CreateSlider(tabMisc.Page, {
    Name = "FPS Cap",
    Min = 30,
    Max = 1000,
    Default = 240,
    Increment = 1,
    Order = 2,
    Callback = function(v)
        CONFIG.FpsCap = v
        if typeof(setfpscap) == "function" then
            pcall(setfpscap, v)
        end
    end,
})

GUI.CreateToggle(tabMisc.Page, {
    Name = "Optimizer",
    Note = "Strip shadows, texture, particle biar FPS naik",
    Default = false,
    Order = 3,
    Callback = function(on)
        CONFIG.Optimizer = on
        if on then
            local Lighting = game:GetService("Lighting")
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.ShadowSoftness = 0
                Lighting.FogEnd = 9000000000
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
            end)
            pcall(function()
                local terrain = Workspace.Terrain
                terrain.Decoration = false
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end)
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
                    pcall(function() d.Enabled = false end)
                elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                    pcall(function() d.Enabled = false end)
                elseif d:IsA("BasePart") then
                    pcall(function()
                        d.CastShadow = false
                        d.Material = Enum.Material.SmoothPlastic
                    end)
                end
            end
        end
    end,
})

GUI.CreateToggle(tabMisc.Page, {
    Name = "Show FPS & Ping",
    Default = true,
    Order = 4,
    Callback = function(on)
        CONFIG.ShowFpsPing = on
        if guiRefs.FpsGui then guiRefs.FpsGui.Enabled = on end
    end,
})

-- FPS/Ping overlay
local function makeFpsOverlay()
    local sg = Instance.new("ScreenGui")
    sg.Name = "KyrielFpsPing"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 50
    sg.Parent = CoreGui
    guiRefs.FpsGui = sg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(132, 34)
    frame.Position = UDim2.fromOffset(16, 16)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    frame.BackgroundTransparency = 0.28
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    makeCorner(frame, 10)

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.fromOffset(34, 16)
    fpsLabel.Position = UDim2.fromOffset(12, 9)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "--"
    fpsLabel.TextColor3 = Color3.fromRGB(58, 255, 55)
    fpsLabel.TextSize = 14
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame

    local fpsTag = Instance.new("TextLabel")
    fpsTag.Size = UDim2.fromOffset(22, 16)
    fpsTag.Position = UDim2.fromOffset(48, 9)
    fpsTag.BackgroundTransparency = 1
    fpsTag.Text = "FPS"
    fpsTag.TextColor3 = Color3.fromRGB(150, 150, 158)
    fpsTag.TextSize = 10
    fpsTag.Font = Enum.Font.GothamBold
    fpsTag.Parent = frame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.fromOffset(30, 16)
    pingLabel.Position = UDim2.fromOffset(82, 9)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "--"
    pingLabel.TextColor3 = Color3.fromRGB(58, 255, 55)
    pingLabel.TextSize = 14
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = frame

    local pingTag = Instance.new("TextLabel")
    pingTag.Size = UDim2.fromOffset(14, 16)
    pingTag.Position = UDim2.fromOffset(113, 9)
    pingTag.BackgroundTransparency = 1
    pingTag.Text = "ms"
    pingTag.TextColor3 = Color3.fromRGB(150, 150, 158)
    pingTag.TextSize = 10
    pingTag.Font = Enum.Font.GothamBold
    pingTag.Parent = frame

    local frames = 0
    local lastCheck = os.clock()

    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if os.clock() - lastCheck >= 0.5 then
            local fps = math.floor(frames / (os.clock() - lastCheck) + 0.5)
            frames = 0
            lastCheck = os.clock()
            fpsLabel.Text = tostring(fps)
            fpsLabel.TextColor3 = fps >= 100 and Color3.fromRGB(58, 255, 55)
                or fps >= 50 and Color3.fromRGB(255, 214, 84)
                or Color3.fromRGB(255, 96, 96)
        end
    end)

    task.spawn(function()
        while guiRefs.FpsGui do
            local ok, ping = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if ok and ping then
                local p = math.floor(ping + 0.5)
                pingLabel.Text = tostring(p)
                pingLabel.TextColor3 = p <= 90 and Color3.fromRGB(58, 255, 55)
                    or p <= 180 and Color3.fromRGB(255, 214, 84)
                    or Color3.fromRGB(255, 96, 96)
            end
            task.wait(1)
        end
    end)

    sg.Enabled = CONFIG.ShowFpsPing
end

makeFpsOverlay()

-- ============================================
-- ANTI AFK
-- ============================================
GUI.CreateSection(tabMisc.Page, "ANTI AFK", 20)

local function startAntiAfk()
    task.spawn(function()
        while CONFIG.AntiAFK do
            local ok, connections = pcall(function()
                if typeof(getconnections) ~= "function" then return nil end
                return getconnections(lp.Idled)
            end)
            if ok and connections then
                for _, c in ipairs(connections) do
                    pcall(function() c:Disable() end)
                end
            end
            task.wait(60)
        end
    end)
end

GUI.CreateToggle(tabMisc.Page, {
    Name = "Anti AFK",
    Default = true,
    Order = 21,
    Callback = function(on)
        CONFIG.AntiAFK = on
    end,
})

-- ============================================
-- PROGRESSION
-- ============================================
GUI.CreateSection(tabMisc.Page, "AUTO PROGRESSION", 30)

local function getSaveData()
    if Modules.Save and type(Modules.Save.Get) == "function" then
        local ok, r = pcall(Modules.Save.Get)
        if ok and type(r) == "table" then return r end
    end
    return nil
end

local function buyTrail()
    if not CONFIG.AutoBuyTrail then return end
    local data = getSaveData()
    if not data then return end
    local trails = Modules.Trails
    local directory = trails and trails.Directory
    if type(directory) ~= "table" then return end
    local list = {}
    for id, info in pairs(directory) do
        if type(info) == "table" then
            table.insert(list, { Id = tostring(info._id or id), Price = tonumber(info.Price) or math.huge })
        end
    end
    table.sort(list, function(a, b) return a.Price < b.Price end)
    local inv = type(data.TrailInventory) == "table" and data.TrailInventory or {}
    local money = tonumber(data.Money) or 0
    for _, trail in ipairs(list) do
        if inv[trail.Id] ~= true and trail.Price <= money then
            local rf = networking:FindFirstChild("RF/Trailwear/AskPurchase")
            if rf and rf:IsA("RemoteFunction") then
                pcall(rf.InvokeServer, rf, trail.Id)
                return
            end
        end
    end
end

local function upgradeBase()
    if not CONFIG.AutoUpgradeBase then return end
    local data = getSaveData()
    if not data then return end
    local bases = Modules.Bases
    local baseList = bases and bases.BASES
    if type(baseList) ~= "table" then return end
    local level = tonumber(data.BaseUpgradeLevel) or 0
    local nextTier = baseList[level + 1]
    if not nextTier then return end
    local cost = tonumber(nextTier.Cost) or math.huge
    if (tonumber(data.Money) or 0) >= cost then
        local re = networking:FindFirstChild("RE/Homestead/AskBaseTierRaise")
        if re and re:IsA("RemoteEvent") then
            pcall(re.FireServer, re)
        end
    end
end

local function upgradeTreadmill()
    if not CONFIG.AutoUpgradeTreadmill then return end
    local data = getSaveData()
    if not data then return end
    local mod = Modules.Treadmills
    if not mod or type(mod.GetByUpgradeLevel) ~= "function" then return end
    local level = tonumber(data.TreadmillUpgradeLevel) or 0
    local ok, nextTier = pcall(mod.GetByUpgradeLevel, level + 1)
    if not ok or type(nextTier) ~= "table" then return end
    local price = tonumber(nextTier.Price) or math.huge
    if (tonumber(data.Money) or 0) >= price then
        local rf = networking:FindFirstChild("RF/Treadmill/AskTierRaise")
        if rf and rf:IsA("RemoteFunction") then
            pcall(rf.InvokeServer, rf, nextTier._id)
        end
    end
end

local function claimAll()
    if not CONFIG.AutoClaim then return end
    local rf = networking:FindFirstChild("RF/AwayEarnings/AskCollect")
    if rf and rf:IsA("RemoteFunction") then
        local ok, has = pcall(rf.InvokeServer, rf)
        if ok and has then return end
    end
    local collect = networking:FindFirstChild("RF/AwayEarnings/AskCollect")
    if collect and collect:IsA("RemoteFunction") then
        pcall(collect.InvokeServer, collect)
    end
    local redeem = networking:FindFirstChild("RF/Codex/AskRedeemAll")
    if redeem and redeem:IsA("RemoteFunction") then
        pcall(redeem.InvokeServer, redeem)
    end
end

task.spawn(function()
    while true do
        task.wait(20)
        pcall(buyTrail)
        pcall(upgradeBase)
        pcall(upgradeTreadmill)
        pcall(claimAll)
    end
end)

GUI.CreateToggle(tabMisc.Page, {
    Name = "Auto Buy Trail",
    Default = false,
    Order = 31,
    Callback = function(on) CONFIG.AutoBuyTrail = on end,
})

GUI.CreateToggle(tabMisc.Page, {
    Name = "Auto Upgrade Base",
    Default = false,
    Order = 32,
    Callback = function(on) CONFIG.AutoUpgradeBase = on end,
})

GUI.CreateToggle(tabMisc.Page, {
    Name = "Auto Upgrade Treadmill",
    Default = false,
    Order = 33,
    Callback = function(on) CONFIG.AutoUpgradeTreadmill = on end,
})

GUI.CreateToggle(tabMisc.Page, {
    Name = "Auto Claim",
    Note = "Klaim offline money & index reward",
    Default = false,
    Order = 34,
    Callback = function(on) CONFIG.AutoClaim = on end,
})

-- ============================================
-- TAB: SERVER
-- ============================================
GUI.CreateSection(tabServer.Page, "SERVER HOP", 1)

local function fetchServers(sortOrder)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100",
        game.PlaceId, sortOrder or "Asc"
    )
    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or type(result) ~= "table" or type(result.data) ~= "table" then return {} end
    local servers = {}
    for _, s in ipairs(result.data) do
        if s.id and tostring(s.id) ~= game.JobId and tonumber(s.playing) and tonumber(s.maxPlayers)
            and tonumber(s.playing) < tonumber(s.maxPlayers) then
            table.insert(servers, {
                Id = tostring(s.id),
                Playing = tonumber(s.playing),
                Room = tonumber(s.maxPlayers) - tonumber(s.playing),
            })
        end
    end
    return servers
end

local function hopServer(mode)
    local servers = fetchServers(mode == "Most Players" and "Desc" or "Asc")
    if #servers == 0 then
        statusText.Set("Hop: no server found")
        return
    end
    local pick
    if mode == "Random" then
        pick = servers[math.random(1, #servers)]
    elseif mode == "Most Players" then
        table.sort(servers, function(a, b) return a.Playing > b.Playing end)
        pick = servers[1]
    else
        table.sort(servers, function(a, b) return a.Playing < b.Playing end)
        pick = servers[1]
    end
    if pick then
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.Id, lp)
        end)
    end
end

GUI.CreateDropdown(tabServer.Page, {
    Name = "Hop Mode",
    Options = { "Least Players", "Most Players", "Random" },
    Default = "Least Players",
    Order = 2,
    Callback = function(v)
        tabServer._HopMode = v
    end,
})

GUI.CreateButton(tabServer.Page, {
    Name = "Server Hop",
    ButtonText = "Hop",
    Order = 3,
    Callback = function()
        hopServer(tabServer._HopMode or "Least Players")
    end,
})

local jobInput = ""
GUI.CreateText(tabServer.Page, {
    Text = "Job ID Input (tempel di kotak di bawah):",
    Color = Color3.fromRGB(180, 180, 200),
    Size = 10,
    Order = 4,
})

-- Simple job id input
do
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundColor3 = Color3.fromRGB(30, 31, 45)
    holder.BorderSizePixel = 0
    holder.LayoutOrder = 5
    holder.Parent = tabServer.Page
    makeCorner(holder, 6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, -8)
    box.Position = UDim2.new(0, 8, 0, 4)
    box.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "Tempel Job ID di sini..."
    box.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
    box.TextColor3 = Color3.fromRGB(240, 240, 250)
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = holder
    makeCorner(box, 4)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        jobInput = box.Text
    end)
end

GUI.CreateButton(tabServer.Page, {
    Name = "Join Job ID",
    ButtonText = "Join Job ID",
    Order = 6,
    Callback = function()
        local match = jobInput:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x")
            or jobInput
        if match and match ~= "" then
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, match, lp)
            end)
        end
    end,
})

GUI.CreateButton(tabServer.Page, {
    Name = "Rejoin",
    ButtonText = "Rejoin",
    Order = 7,
    Callback = function()
        pcall(function()
            if game.JobId ~= "" then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
            else
                TeleportService:Teleport(game.PlaceId, lp)
            end
        end)
    end,
})

GUI.CreateButton(tabServer.Page, {
    Name = "Copy Job ID",
    ButtonText = "Copy Job ID",
    Order = 8,
    Callback = function()
        if typeof(setclipboard) == "function" then
            pcall(setclipboard, game.JobId)
        end
        statusText.Set("Job ID: " .. game.JobId)
    end,
})

-- ============================================
-- WEBHOOK
-- ============================================
GUI.CreateSection(tabServer.Page, "WEBHOOK", 20)

do
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundColor3 = Color3.fromRGB(30, 31, 45)
    holder.BorderSizePixel = 0
    holder.LayoutOrder = 21
    holder.Parent = tabServer.Page
    makeCorner(holder, 6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, -8)
    box.Position = UDim2.new(0, 8, 0, 4)
    box.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    box.BorderSizePixel = 0
    box.Text = CONFIG.WebhookUrl
    box.PlaceholderText = "https://discord.com/api/webhooks/..."
    box.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
    box.TextColor3 = Color3.fromRGB(240, 240, 250)
    box.TextSize = 10
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = holder
    makeCorner(box, 4)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        CONFIG.WebhookUrl = box.Text
    end)
end

GUI.CreateToggle(tabServer.Page, {
    Name = "Notify Stolen Eggs",
    Default = false,
    Order = 22,
    Callback = function(on) CONFIG.WebhookNotifyStolen = on end,
})

GUI.CreateToggle(tabServer.Page, {
    Name = "Ping @everyone",
    Default = false,
    Order = 23,
    Callback = function(on) CONFIG.WebhookPingEveryone = on end,
})

local function sendWebhook(title, description, color)
    if CONFIG.WebhookUrl == "" then return end
    if not string.match(CONFIG.WebhookUrl, "^https://discord%.com/api/webhooks/") then return end

    local request = (typeof(request) == "function" and request)
        or (syn and syn.request)
        or (http and http.request)
        or http_request
    if not request then return end

    local payload = {
        username = "Kyriel Hub",
        embeds = {{
            title = title,
            description = description,
            color = color or 5793266,
            footer = { text = "Kyriel Hub | Steal An Egg" },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }
    if CONFIG.WebhookPingEveryone then
        payload.content = "@everyone"
        payload.allowed_mentions = { parse = { "everyone" } }
    end

    pcall(request, {
        Url = CONFIG.WebhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
end

-- Hook stolen egg notification ke StealState
task.spawn(function()
    local lastDelivered = nil
    while true do
        task.wait(1)
        if CONFIG.WebhookNotifyStolen and StealState.LastFinishedAt > 0
            and StealState.LastFinishedAt ~= lastDelivered then
            lastDelivered = StealState.LastFinishedAt
            local cat = StealState.CurrentTarget and StealState.CurrentTarget.Category or "Egg"
            local info = getAssetInfo(cat)
            local value = StealState.CurrentTarget and StealState.CurrentTarget.Value or 0
            sendWebhook(
                "Egg Stolen!",
                string.format("**%s**\nRarity: **%s**\nValue: **$%s/s**",
                    info.Name, info.Rarity, formatNum(value)),
                16762960
            )
        end
    end
end)

-- ============================================
-- TAB: INFO
-- ============================================
GUI.CreateSection(tabInfo.Page, "KYRIEL HUB v3", 1)
GUI.CreateText(tabInfo.Page, {
    Text = "Steal An Egg custom script. No key, no nonsense.",
    Color = Color3.fromRGB(180, 180, 200),
    Size = 11,
    Height = 30,
    Order = 2,
})

GUI.CreateText(tabInfo.Page, {
    Text = "Minimize: tombol '—' kanan atas. Balik: tombol H.",
    Color = Color3.fromRGB(180, 180, 200),
    Size = 10,
    Height = 24,
    Order = 3,
})

GUI.CreateSection(tabInfo.Page, "STATS", 10)

local statsLabel = GUI.CreateText(tabInfo.Page, {
    Text = "Loading...",
    Color = Color3.fromRGB(120, 200, 255),
    Size = 11,
    Height = 60,
    Order = 11,
})

task.spawn(function()
    while true do
        task.wait(2)
        local parts = #Workspace:GetDescendants()
        local plrs = #Players:GetPlayers()
        local ok, mem = pcall(function()
            return Stats:GetTotalMemoryUsageMb()
        end)
        statsLabel.Set(string.format(
            "Players: %d | Workspace descendants: %d | Mem: %.0f MB",
            plrs, parts, ok and mem or 0
        ))
    end
end)

GUI.CreateSection(tabInfo.Page, "RESET / DEBUG", 20)

GUI.CreateButton(tabInfo.Page, {
    Name = "Clear Failed Steal",
    ButtonText = "Clear Failed Steal",
    Order = 21,
    Callback = function()
        StealState.FailedUids = {}
        statusText.Set("Failed UIDs cleared")
    end,
})

GUI.CreateButton(tabInfo.Page, {
    Name = "Force Cancel All",
    ButtonText = "Force Cancel All",
    Order = 22,
    Callback = function()
        cleanupMovers()
        StealState.Running = false
        StealState.MovementOwner = nil
        FarmState.TreadmillRiding = false
        statusText.Set("All movement canceled")
    end,
})

GUI.CreateButton(tabInfo.Page, {
    Name = "Rescan Modules",
    ButtonText = "Rescan Modules",
    Order = 23,
    Callback = function()
        Modules.EggState = tryRequire(function() return require(ReplicatedStorage.Client.EggState) end)
        Modules.Save = tryRequire(function() return require(ReplicatedStorage.Shared.Save) end)
        Modules.Assets = tryRequire(function() return require(ReplicatedStorage.Data.Assets) end)
        Modules.Mutations = tryRequire(function() return require(ReplicatedStorage.Shared.Modules.Mutations) end)
        statusText.Set("Modules rescan done")
    end,
})

-- ============================================
-- HANDLE RESPAWN
-- ============================================
lp.CharacterAdded:Connect(function()
    task.wait(2)
    cleanupMovers()
    if CONFIG.AutoRagdoll then startRagdollBypass() end
    if CONFIG.AutoTrap then startAntiTrap() end
    if CONFIG.AutoTreadmill and CONFIG.StayOnTreadmill then
        FarmState.TreadmillRiding = false
    end
end)

-- ============================================
-- INITIAL START
-- ============================================
task.spawn(function()
    task.wait(1)
    if CONFIG.AutoRagdoll then startRagdollBypass() end
    if CONFIG.AutoTrap then startAntiTrap() end
    if CONFIG.AntiAFK then startAntiAfk() end
    statusText.Set("Kyriel Hub siap. Aktifin fitur di tab kiri.")
end)

-- ============================================
-- CLEANUP ON UNLOAD
-- ============================================
_G.KyrielHubCleanup = function()
    CONFIG.AutoSteal = false
    CONFIG.AutoPlace = false
    CONFIG.AutoTreadmill = false
    CONFIG.AutoHatch = false
    CONFIG.AutoEquipBest = false
    CONFIG.AutoSellPet = false
    CONFIG.AutoSellEgg = false
    CONFIG.AutoFuse = false
    CONFIG.AutoFavorite = false
    CONFIG.AutoRiftSacrifice = false
    CONFIG.AutoRiftReroll = false
    CONFIG.AutoHuntDrones = false
    CONFIG.AutoCollectLostParts = false
    CONFIG.AutoOpenVault = false
    CONFIG.AutoRagdoll = false
    CONFIG.AutoTrap = false
    CONFIG.SpeedBoost = false
    CONFIG.InfiniteJump = false
    CONFIG.AntiGuard = false

    cleanupMovers()
    restoreTraps()

    if CombatState.RagdollTask then pcall(task.cancel, CombatState.RagdollTask) end
    if CombatState.AntiGuardTask then pcall(task.cancel, CombatState.AntiGuardTask) end
    if CombatState.SpeedConnection then CombatState.SpeedConnection:Disconnect() end
    if CombatState.JumpConnection then CombatState.JumpConnection:Disconnect() end
    if CombatState.TrapConnection then CombatState.TrapConnection:Disconnect() end

    if guiRefs.ScreenGui then
        guiRefs.ScreenGui:Destroy()
        guiRefs.ScreenGui = nil
    end
    if guiRefs.FpsGui then
        guiRefs.FpsGui:Destroy()
        guiRefs.FpsGui = nil
    end
end

print("[Kyriel] Part 4 loaded: combat, misc, server, info, webhook, finalize.")
print("[Kyriel] Kyriel Hub v3 FULLY LOADED. Gas, boss.")

-- ============================================
-- END PART 4 — FULL SCRIPT COMPLETE
-- ============================================
