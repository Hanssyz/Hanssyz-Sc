-- =============================================================================
-- Hanssyz 4.7.0 (build 8dc2057f)
-- Steal An Egg
--
-- v4.7:
--   * Egg panel click: stops when the target egg is stolen or gone.
--     No more endless "waiting" loop.
--   * Config: Auto-Save toggle. Saves your settings automatically.
--   * Discord invite updated.
-- =============================================================================

local BLYXO_VERSION = "4.7.0"
local BLYXO_BUILD = "8dc2057f"
local DISCORD_INVITE = "https://discord.gg/G5ySYb9xMS"

local env = (type(getgenv) == "function" and getgenv()) or _G
env.BlyxoGeneration = (env.BlyxoGeneration or 0) + 1

local BX = {
	generation = env.BlyxoGeneration,
	version = BLYXO_VERSION,
	build = BLYXO_BUILD,
	_factories = {},
	_loaded = {},
	_loading = {},
	_conns = {},
}
env.BX = BX

function BX.alive()
	return env.BlyxoGeneration == BX.generation
end
function BX.module(name, factory)
	if BX._factories[name] then
		error(("duplicate module %q"):format(name), 2)
	end
	BX._factories[name] = factory
end
function BX.require(name)
	local cached = BX._loaded[name]
	if cached ~= nil then
		return cached
	end
	if BX._loading[name] then
		error(("circular dependency: %s"):format(name), 2)
	end
	local factory = BX._factories[name]
	if not factory then
		error(("no such module: %s"):format(name), 2)
	end
	BX._loading[name] = true
	local ok, result = pcall(factory, BX)
	BX._loading[name] = nil
	if not ok then
		error(("module %q failed to load: %s"):format(name, tostring(result)), 2)
	end
	if result == nil then
		error(("module %q returned nil"):format(name), 2)
	end
	BX._loaded[name] = result
	return result
end
function BX.connect(signal, fn)
	local c = signal:Connect(fn)
	BX._conns[#BX._conns + 1] = c
	return c
end
function BX.offthread(fn, timeout)
	local done, result = false, nil
	task.spawn(function()
		local ok, r = pcall(fn)
		if ok then
			result = r
		end
		done = true
	end)
	local t = os.clock()
	timeout = timeout or 5
	while not done and (os.clock() - t) < timeout do
		task.wait(0.03)
	end
	return result, done
end
function BX.teardown()
	pcall(function()
		local lg = BX._loaded["boot.log"]
		if lg and lg.flushNow then
			lg.flushNow()
		end
	end)
	if BX.destroyAllScopes then
		pcall(BX.destroyAllScopes)
	end
	for _, c in ipairs(BX._conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	BX._conns = {}
	BX._loaded = {}
end
if type(env.BlyxoTeardown) == "function" then
	pcall(env.BlyxoTeardown)
end
env.BlyxoTeardown = BX.teardown

-- =============================================================================
-- boot/01_log.lua
-- =============================================================================

BX.module("boot.log", function(BX)
	local M = {}
	local TRACE_FILE = "Hanssyz_trace.txt"
	local FLUSH_GAP, RING, SEEN_MAX = 1.0, 500, 400
	local canWrite = (type(writefile) == "function")
	local debugOn = function()
		local e = (type(getgenv) == "function" and getgenv()) or _G
		return e.BlyxoDebug == true
	end
	local ring, ringN, ringHead = {}, 0, 0
	local seen, seenN = {}, 0
	M.LEVELS = { TRACE = 1, INFO = 2, WARN = 3, ERROR = 4 }
	M.level = M.LEVELS.INFO
	local dirty = false
	local function writeNow()
		if not canWrite then
			return
		end
		dirty = false
		local out, n = {}, 0
		local start = (ringN < RING) and 1 or (ringHead % RING) + 1
		for i = 0, ringN - 1 do
			n = n + 1
			out[n] = ring[((start - 1 + i) % RING) + 1]
		end
		pcall(writefile, TRACE_FILE, table.concat(out, "\n", 1, n))
	end
	local function flush(force)
		if not canWrite then
			return
		end
		if force then
			return writeNow()
		end
		dirty = true
	end
	if canWrite then
		task.spawn(function()
			while BX.alive() do
				task.wait(FLUSH_GAP)
				if dirty then
					pcall(writeNow)
				end
			end
			if dirty then
				pcall(writeNow)
			end
		end)
	end
	function M.flushNow()
		pcall(writeNow)
	end
	local TAGS = { "TRACE", "INFO", "WARN", "ERROR" }
	local function emit(level, mod, msg)
		if level < M.level then
			return
		end
		local line = ("[%7.2f] %-5s %-16s %s"):format(os.clock(), TAGS[level], mod, msg)
		ringHead = (ringHead % RING) + 1
		ring[ringHead] = line
		if ringN < RING then
			ringN = ringN + 1
		end
		if debugOn() or level >= M.LEVELS.WARN then
			print("[HANSSYZ] " .. line)
		end
		flush(level >= M.LEVELS.ERROR)
	end
	function M.for_module(name)
		return {
			trace = function(m, ...)
				emit(1, name, select("#", ...) > 0 and m:format(...) or m)
			end,
			info = function(m, ...)
				emit(2, name, select("#", ...) > 0 and m:format(...) or m)
			end,
			warn = function(m, ...)
				emit(3, name, select("#", ...) > 0 and m:format(...) or m)
			end,
			error = function(m, ...)
				emit(4, name, select("#", ...) > 0 and m:format(...) or m)
			end,
		}
	end
	function M.session(msg)
		emit(2, "session", "=== " .. msg .. " ===")
		flush(true)
	end
	function M.repeats()
		local out = {}
		for label, n in pairs(seen) do
			if n > 1 then
				out[#out + 1] = ("%s x%d"):format(label, n)
			end
		end
		table.sort(out)
		return out
	end
	function BX.try(label, fn, ...)
		local ok, result = pcall(fn, ...)
		if not ok then
			if seen[label] == nil then
				if seenN >= SEEN_MAX then
					label = "(other)"
				else
					seenN = seenN + 1
				end
			end
			local n = (seen[label] or 0) + 1
			seen[label] = n
			if n == 1 then
				emit(4, "try", ("%s: %s"):format(label, tostring(result)))
			elseif n == 10 or n == 100 then
				emit(3, "try", ("%s: still failing (x%d)"):format(label, n))
			end
		end
		return ok, result
	end
	function BX.guard(label, fn)
		return function(...)
			return select(2, BX.try(label, fn, ...))
		end
	end
	M._emit = emit
	M._seen = seen
	return M
end)

-- =============================================================================
-- boot/02_scope.lua
-- =============================================================================

BX._scopes = {}
function BX.scope(name)
	local existing = BX._scopes[name]
	if existing and not existing.dead then
		existing:destroy()
	end
	local sc = { name = name, dead = false, conns = {}, insts = {}, threads = {}, tweens = {}, gen = BX.generation }
	function sc:alive()
		return (not self.dead) and BX.alive()
	end
	function sc:connect(signal, fn)
		if self.dead then
			return nil
		end
		local c = signal:Connect(fn)
		self.conns[#self.conns + 1] = c
		return c
	end
	function sc:own(inst)
		if self.dead then
			pcall(function()
				inst:Destroy()
			end)
			return inst
		end
		self.insts[#self.insts + 1] = inst
		return inst
	end
	function sc:spawn(label, fn, ...)
		if self.dead then
			return nil
		end
		local th
		th = task.spawn(function(...)
			BX.try(self.name .. "/" .. label, fn, ...)
			for i, t in ipairs(self.threads) do
				if t == th then
					table.remove(self.threads, i)
					break
				end
			end
		end, ...)
		self.threads[#self.threads + 1] = th
		return th
	end
	function sc:loop(label, interval, fn)
		return self:spawn(label .. "/loop", function()
			while self:alive() do
				BX.try(self.name .. "/" .. label, fn)
				if not self:alive() then
					return
				end
				task.wait(interval)
			end
		end)
	end
	function sc:onFrame(label, signal, fn)
		local tag = self.name .. "/" .. label
		local guarded = BX.guard(tag, fn)
		local timed = BX.profile and BX.profile.wrap(tag, guarded) or guarded
		return self:connect(signal, timed)
	end
	function sc:delay(label, seconds, fn)
		if self.dead then
			return
		end
		task.delay(seconds, function()
			if not self:alive() then
				return
			end
			BX.try(self.name .. "/" .. label, fn)
		end)
	end
	function sc:destroy()
		if self.dead then
			return
		end
		self.dead = true
		for _, c in ipairs(self.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		for _, t in ipairs(self.tweens) do
			pcall(function()
				t:Cancel()
			end)
		end
		for _, i in ipairs(self.insts) do
			pcall(function()
				i:Destroy()
			end)
		end
		local me = coroutine.running()
		for _, th in ipairs(self.threads) do
			if th ~= me then
				pcall(task.cancel, th)
			end
		end
		self.conns, self.insts, self.threads, self.tweens = {}, {}, {}, {}
		if BX._scopes[self.name] == self then
			BX._scopes[self.name] = nil
		end
	end
	function sc:counts()
		return { conns = #self.conns, insts = #self.insts, threads = #self.threads, tweens = #self.tweens }
	end
	BX._scopes[name] = sc
	return sc
end
function BX.scopeReport()
	local out = {}
	for name, sc in pairs(BX._scopes) do
		if not sc.dead then
			local c = sc:counts()
			out[#out + 1] = ("%-24s conns=%-3d insts=%-4d threads=%-3d tweens=%d"):format(
				name,
				c.conns,
				c.insts,
				c.threads,
				c.tweens
			)
		end
	end
	table.sort(out)
	return out
end
function BX.destroyAllScopes()
	for _, sc in pairs(BX._scopes) do
		pcall(function()
			sc:destroy()
		end)
	end
	BX._scopes = {}
end

-- =============================================================================
-- boot/03_profile.lua
-- =============================================================================

BX.profile = { enabled = true, _stats = {}, _mem0 = nil, _t0 = os.clock() }
local P = BX.profile
P._watch = {}
function P.watch(name, fn)
	P._watch[name] = fn
end
function P.watched()
	local out = {}
	for name, fn in pairs(P._watch) do
		local ok, n = pcall(fn)
		out[#out + 1] = ("%s=%s"):format(name, ok and tostring(n) or "?")
	end
	table.sort(out)
	return out
end
P._marks = {}
function P.mark(name)
	local ok, health, state, swapped = pcall(function()
		local plr = game:GetService("Players").LocalPlayer
		local char = plr and plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return -1, "no-humanoid", false
		end
		return hum.Health,
			tostring(hum:GetState()):gsub("Enum.HumanoidStateType.", ""),
			hum:GetAttribute("BlyxoStealHum") == true
	end)
	local row = {
		name = name,
		at = os.clock(),
		health = ok and health or -1,
		state = ok and state or "?",
		swapped = ok and swapped or false,
	}
	P._marks[#P._marks + 1] = row
	if #P._marks > 200 then
		table.remove(P._marks, 1)
	end
	return row
end
function P.marksSince(t)
	local out = {}
	for _, r in ipairs(P._marks) do
		if r.at >= (t or 0) then
			out[#out + 1] = ("%s@%.2f hp=%.0f %s%s"):format(
				r.name,
				r.at - (t or 0),
				r.health,
				r.state,
				r.swapped and " swapped" or ""
			)
		end
	end
	return out
end
function P.wrap(label, fn)
	local s = P._stats[label]
	if not s then
		s = { n = 0, total = 0, max = 0, last = 0 }
		P._stats[label] = s
	end
	return function(...)
		if not P.enabled then
			return fn(...)
		end
		local t0 = os.clock()
		fn(...)
		local dt = os.clock() - t0
		s.n = s.n + 1
		s.total = s.total + dt
		s.last = dt
		if dt > s.max then
			s.max = dt
		end
	end
end
function P.report()
	local rows = {}
	for label, s in pairs(P._stats) do
		if s.n > 0 then
			rows[#rows + 1] =
				{ label = label, avg = (s.total / s.n) * 1000, max = s.max * 1000, total = s.total, n = s.n }
		end
	end
	table.sort(rows, function(a, b)
		return a.total > b.total
	end)
	local out = { ("%-34s %8s %8s %9s %8s"):format("per-frame job", "avg ms", "max ms", "total s", "calls") }
	for _, r in ipairs(rows) do
		out[#out + 1] = ("%-34s %8.3f %8.3f %9.2f %8d"):format(r.label, r.avg, r.max, r.total, r.n)
	end
	return out
end
local function memMb()
	local ok, v = pcall(function()
		return game:GetService("Stats"):GetTotalMemoryUsageMb()
	end)
	if ok and type(v) == "number" then
		return v
	end
	ok, v = pcall(gcinfo)
	return (ok and type(v) == "number") and (v / 1024) or 0
end
function P.health()
	local conns, threads, scopes, insts = 0, 0, 0, 0
	for _, sc in pairs(BX._scopes or {}) do
		if not sc.dead then
			scopes = scopes + 1
			local c = sc:counts()
			conns = conns + c.conns
			insts = insts + c.insts
			threads = threads + c.threads
		end
	end
	local mem = memMb()
	P._mem0 = P._mem0 or mem
	return {
		uptime = os.clock() - P._t0,
		mem = mem,
		memGrow = mem - P._mem0,
		scopes = scopes,
		conns = conns,
		insts = insts,
		threads = threads,
		loaded = (function()
			local n = 0
			for _ in pairs(BX._loaded) do
				n = n + 1
			end
			return n
		end)(),
	}
end
function P.start()
	local sc = BX.scope("boot.profile")
	local log = BX.require("boot.log").for_module("profile")
	local frames = 0
	sc:connect(BX.require("core.services").RunService.Heartbeat, function()
		frames = frames + 1
	end)
	sc:loop("health", 60, function()
		local h = P.health()
		log.info(
			"health up=%.0fs fps=%.0f mem=%.0fMB scopes=%d conns=%d insts=%d threads=%d",
			h.uptime,
			frames / 60,
			h.mem,
			h.scopes,
			h.conns,
			h.insts,
			h.threads
		)
		frames = 0
	end)
	return sc
end

-- =============================================================================
-- core/services.lua
-- =============================================================================

BX.module("core.services", function(BX)
	local log = BX.require("boot.log").for_module("services")
	local M = {}
	local WANTED = {
		"Players",
		"ReplicatedStorage",
		"RunService",
		"TweenService",
		"UserInputService",
		"Lighting",
		"Workspace",
		"HttpService",
		"CoreGui",
		"TextService",
		"Stats",
		"TeleportService",
	}
	for _, name in ipairs(WANTED) do
		local ok, svc = pcall(game.GetService, game, name)
		if ok and svc then
			M[name] = svc
		else
			log.error("service unavailable: %s", name)
		end
	end
	if M.Players and not M.Players.LocalPlayer then
		local deadline = os.clock() + 10
		while not M.Players.LocalPlayer and os.clock() < deadline do
			task.wait(0.1)
		end
	end
	M.LocalPlayer = M.Players and M.Players.LocalPlayer
	return M
end)

-- =============================================================================
-- core/net.lua
-- =============================================================================

BX.module("core.net", function(BX)
	local svc = BX.require("core.services")
	local M = {}
	local container, containerAt = nil, 0
	local CONTAINER_TTL = 30
	local function networking()
		local now = os.clock()
		if container and container.Parent and (now - containerAt) < CONTAINER_TTL then
			return container
		end
		local pkgs = svc.ReplicatedStorage:FindFirstChild("Packages")
		local net = pkgs and pkgs:FindFirstChild("Networking")
		container, containerAt = net, now
		return net
	end
	function M.find(name)
		local net = networking()
		return net and net:FindFirstChild(name) or nil
	end
	function M.call(name, ...)
		local rf = M.find(name)
		if not rf then
			return false, "remote not found: " .. tostring(name)
		end
		local ok, a, b = pcall(function(...)
			return rf:InvokeServer(...)
		end, ...)
		if not ok then
			return false, tostring(a)
		end
		return a, b
	end
	function M.fire(name, ...)
		local re = M.find(name)
		if not re then
			return false, "remote not found: " .. tostring(name)
		end
		local ok, err = pcall(function(...)
			re:FireServer(...)
		end, ...)
		if not ok then
			return false, tostring(err)
		end
		return true
	end
	return M
end)

-- =============================================================================
-- core/data.lua
-- =============================================================================

BX.module("core.data", function(BX)
	local svc = BX.require("core.services")
	local exec = BX.require("core.exec")
	local M = {}
	local cache = {}
	local function atPath(...)
		local node = svc.ReplicatedStorage
		for _, part in ipairs({ ... }) do
			if not node then
				return nil
			end
			node = node:FindFirstChild(part)
		end
		return node
	end
	local function searchModule(name)
		for _, d in ipairs(svc.ReplicatedStorage:GetDescendants()) do
			if d:IsA("ModuleScript") and d.Name == name then
				return d
			end
		end
		return nil
	end
	local function resolve(key, path)
		local held = cache[key]
		if held then
			return held.mod
		end
		if not exec.can.gameRequire then
			cache[key] = { missing = true }
			return nil
		end
		local name = path[#path]
		local inst = atPath(table.unpack(path))
		if not (inst and inst:IsA("ModuleScript")) then
			inst = searchModule(name)
		end
		if not inst then
			cache[key] = { missing = true }
			return nil
		end
		local mod
		local ok = BX.try("data.require." .. key, function()
			mod = require(inst)
		end)
		if not ok or type(mod) ~= "table" then
			cache[key] = { missing = true }
			return nil
		end
		cache[key] = { mod = mod }
		return mod
	end
	function M.assets()
		return resolve("assets", { "Data", "Assets" })
	end
	function M.areas()
		return resolve("areas", { "Data", "Areas" })
	end
	function M.eggState()
		return resolve("eggState", { "Client", "EggState" })
	end
	function M.assetEarnings()
		return resolve("assetEarnings", { "Shared", "Util", "AssetEarnings" })
	end
	function M.plotState()
		return resolve("plotState", { "Client", "PlotState" })
	end
	function M.slotIdentity()
		return resolve("slotIdentity", { "Shared", "Util", "AreaEggSlotIdentity" })
	end
	function M.assetsDir()
		local a = M.assets()
		return a and a.Directory or nil
	end
	function M.areasDir()
		local a = M.areas()
		return a and a.Directory or nil
	end
	return M
end)

-- =============================================================================
-- core/profiles.lua - now with Auto-Save
-- =============================================================================

BX.module("core.profiles", function(BX)
	local svc = BX.require("core.services")
	local exec = BX.require("core.exec")
	local M = {}
	local FORMAT = 1
	local DIR = "Hanssyz/profiles"
	local SETTINGS = "Hanssyz/settings.json"
	local AUTOSAVE_NAME = "__autosave"
	M.FORMAT = FORMAT

	local SKIP_KEYS = { "url", "token", "secret", "key", "password" }
	local ALLOW = {
		AntiTreadmill = true,
		FarmAreas = true,
		FarmRarities = true,
		FarmTargetBy = true,
		WebhookOn = true,
		Theme = true,
		Background = true,
		AutoTreadmillWait = true,
		StatusHUD = true,
		EggPanel = true,
	}
	M.ALLOW = ALLOW

	local function skipped(name)
		if not ALLOW[name] then
			return true
		end
		local n = tostring(name):lower()
		for _, bad in ipairs(SKIP_KEYS) do
			if n:find(bad, 1, true) then
				return true
			end
		end
		return false
	end
	function M.available()
		return exec.can.files and exec.can.folders and true or false
	end
	local listing, listingOk = {}, false
	local function safeName(name)
		return tostring(name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	end
	local function pathFor(name)
		return DIR .. "/" .. name .. ".json"
	end

	function M.refresh()
		listing, listingOk = {}, false
		if not M.available() then
			return listing
		end
		BX.try("profiles.refresh", function()
			exec.ensureFolder("Hanssyz")
			exec.ensureFolder(DIR)
			local files = exec.listFiles(DIR)
			if not files then
				return
			end
			for _, f in ipairs(files) do
				local name = tostring(f):match("([^/\\]+)%.json$")
				-- Skip the internal autosave slot from the user list.
				if name and name ~= AUTOSAVE_NAME then
					listing[#listing + 1] = name
				end
			end
			table.sort(listing)
			listingOk = true
		end)
		return listing
	end
	function M.list()
		if not listingOk then
			M.refresh()
		end
		return listing
	end

	local flagSource, appearanceSource, appearanceApply = nil, nil, nil
	function M.setFlagSource(fn)
		flagSource = fn
	end
	function M.setAppearanceHooks(read, apply)
		appearanceSource, appearanceApply = read, apply
	end

	local function collectFlags()
		local out = {}
		if type(flagSource) ~= "function" then
			return out
		end
		local ok, flags = pcall(flagSource)
		if not ok or type(flags) ~= "table" then
			return out
		end
		for name, el in pairs(flags) do
			if not skipped(name) then
				local v
				if type(el) == "table" then
					v = el.CurrentValue
					if v == nil then
						v = el.Value
					end
					if v == nil then
						v = el.value
					end
				else
					v = el
				end
				local t = type(v)
				if t == "boolean" or t == "number" or t == "string" then
					out[tostring(name)] = v
				elseif t == "table" then
					local copy = {}
					for i, item in ipairs(v) do
						if type(item) == "string" or type(item) == "number" then
							copy[i] = item
						end
					end
					out[tostring(name)] = copy
				end
			end
		end
		return out
	end

	local function buildPayload()
		return {
			version = FORMAT,
			saved = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			build = tostring(BX.build),
			flags = collectFlags(),
			appearance = (type(appearanceSource) == "function") and select(2, pcall(appearanceSource)) or nil,
		}
	end

	local function writeProfile(name, payload)
		local body
		if not pcall(function()
			body = svc.HttpService:JSONEncode(payload)
		end) then
			return false, "encode failed"
		end
		local path = pathFor(name)
		local ok = BX.try("profiles.write." .. name, function()
			exec.ensureFolder("Hanssyz")
			exec.ensureFolder(DIR)
			exec.writeFile(path, body)
		end)
		if not ok then
			return false, "write failed"
		end
		return true
	end

	function M.save(name)
		if not M.available() then
			return false, "This executor cannot save files"
		end
		name = safeName(name)
		if name == "" then
			return false, "Give the profile a name"
		end
		local ok, why = writeProfile(name, buildPayload())
		if not ok then
			return false, "Could not write the profile"
		end
		M.refresh()
		return true, "Saved " .. name
	end

	-- Silent save to the internal autosave slot.
	function M.saveAuto()
		if not M.available() then
			return false
		end
		local ok = writeProfile(AUTOSAVE_NAME, buildPayload())
		return ok
	end

	local function readAuto()
		if not M.available() then
			return nil
		end
		local path = pathFor(AUTOSAVE_NAME)
		if not exec.isFile(path) then
			return nil
		end
		local body = exec.readFile(path)
		if type(body) ~= "string" or body == "" then
			return nil
		end
		local data
		pcall(function()
			data = svc.HttpService:JSONDecode(body)
		end)
		return type(data) == "table" and data or nil
	end

	-- Apply the autosave silently at startup if it exists.
	function M.loadAuto()
		local data = readAuto()
		if not data then
			return false, "no autosave"
		end
		local applied = 0
		if type(data.flags) == "table" and type(flagSource) == "function" then
			local ok, flags = pcall(flagSource)
			if ok and type(flags) == "table" then
				for key, value in pairs(data.flags) do
					local el = (not skipped(key)) and flags[key] or nil
					if type(el) == "table" and type(el.Set) == "function" then
						if BX.try("profiles.autoSet." .. tostring(key), function()
							el:Set(value)
						end) then
							applied = applied + 1
						end
					end
				end
			end
		end
		if type(data.appearance) == "table" and type(appearanceApply) == "function" then
			BX.try("profiles.autoAppearance", function()
				appearanceApply(data.appearance)
			end)
		end
		return true, applied
	end

	function M.load(name)
		if not M.available() then
			return false, "This executor cannot read files"
		end
		name = safeName(name)
		if name == "" then
			return false, "Pick a profile"
		end
		local path = pathFor(name)
		if not exec.isFile(path) then
			return false, "No profile called " .. name
		end
		local body = exec.readFile(path)
		if type(body) ~= "string" or body == "" then
			return false, name .. " is empty"
		end
		local data
		if not pcall(function()
			data = svc.HttpService:JSONDecode(body)
		end) then
			return false, name .. " is corrupt"
		end
		if type(data) ~= "table" then
			return false, name .. " is corrupt"
		end
		local applied = 0
		if type(data.flags) == "table" and type(flagSource) == "function" then
			local ok, flags = pcall(flagSource)
			if ok and type(flags) == "table" then
				for key, value in pairs(data.flags) do
					local el = (not skipped(key)) and flags[key] or nil
					if type(el) == "table" and type(el.Set) == "function" then
						if BX.try("profiles.set." .. tostring(key), function()
							el:Set(value)
						end) then
							applied = applied + 1
						end
					end
				end
			end
		end
		if type(data.appearance) == "table" and type(appearanceApply) == "function" then
			BX.try("profiles.appearance", function()
				appearanceApply(data.appearance)
			end)
		end
		return true, ("Loaded %s (%d settings)"):format(name, applied)
	end

	function M.delete(name)
		if not M.available() then
			return false, "This executor cannot delete files"
		end
		name = safeName(name)
		local path = pathFor(name)
		if name == "" or not exec.isFile(path) then
			return false, "No such profile"
		end
		BX.try("profiles.delete", function()
			exec.deleteFile(path)
		end)
		M.refresh()
		return true, "Deleted " .. name
	end

	local function readSettings()
		if not M.available() or not exec.isFile(SETTINGS) then
			return {}
		end
		local body = exec.readFile(SETTINGS)
		local data
		pcall(function()
			data = svc.HttpService:JSONDecode(body)
		end)
		return type(data) == "table" and data or {}
	end
	local function writeSettings(s)
		s.version = FORMAT
		local body
		if not pcall(function()
			body = svc.HttpService:JSONEncode(s)
		end) then
			return false
		end
		BX.try("profiles.settings", function()
			exec.ensureFolder("Hanssyz")
			exec.writeFile(SETTINGS, body)
		end)
		return true
	end

	function M.autoLoadName()
		local s = readSettings()
		local n = s.autoLoad
		return type(n) == "string" and n ~= "" and n or nil
	end
	function M.setAutoLoad(name)
		if not M.available() then
			return false, "This executor cannot save files"
		end
		name = safeName(name)
		local s = readSettings()
		s.autoLoad = (name ~= "" and name) or nil
		writeSettings(s)
		return true, name ~= "" and ("Auto-loading " .. name) or "Auto-load off"
	end

	-- NEW: Auto-save toggle.
	function M.autoSaveOn()
		return readSettings().autoSave == true
	end
	function M.setAutoSave(on)
		if not M.available() then
			return false, "This executor cannot save files"
		end
		local s = readSettings()
		s.autoSave = on and true or false
		writeSettings(s)
		return true, on and "Auto-save ON" or "Auto-save OFF"
	end

	local autoLoadRan = false
	function M.runAutoLoad()
		if autoLoadRan then
			return false, "already ran"
		end
		autoLoadRan = true
		local name = M.autoLoadName()
		if not name then
			return false, "no auto-load profile set"
		end
		return M.load(name)
	end
	return M
end)

-- =============================================================================
-- core/exec.lua
-- =============================================================================

BX.module("core.exec", function(BX)
	local log = BX.require("boot.log").for_module("exec")
	local M = {}
	local env = (type(getgenv) == "function" and getgenv()) or _G
	local deny = type(env.BLYXO_CAPS_DENY) == "table" and env.BLYXO_CAPS_DENY or {}
	local function fn(name)
		if deny[name] then
			return nil
		end
		local ok, v
		ok, v = pcall(function()
			return type(getgenv) == "function" and getgenv()[name] or nil
		end)
		if not ok or type(v) ~= "function" then
			ok, v = pcall(function()
				return getfenv and getfenv()[name] or nil
			end)
		end
		if not ok or type(v) ~= "function" then
			ok, v = pcall(function()
				return (_G and _G[name])
			end)
		end
		if not ok or type(v) ~= "function" then
			ok, v = pcall(function()
				local chunk = loadstring and loadstring("return " .. name)
				return chunk and chunk() or nil
			end)
		end
		return (ok and type(v) == "function") and v or nil
	end
	local function first(...)
		for _, name in ipairs({ ... }) do
			local f = fn(name)
			if f then
				return f, name
			end
		end
		return nil, nil
	end
	local f_writefile = first("writefile")
	local f_readfile = first("readfile")
	local f_isfile = first("isfile")
	local f_delfile = first("delfile")
	local f_isfolder = first("isfolder")
	local f_makefolder = first("makefolder")
	local f_listfiles = first("listfiles")
	local f_gethui = first("gethui")
	local f_identify = first("identifyexecutor", "getexecutorname")
	local f_fireprompt = first("fireproximityprompt")
	local f_clip = first("setclipboard", "toclipboard", "set_clipboard", "setrbxclipboard")
	local canRequire, requireWhy = false, "no probe"
	do
		local ok, err = pcall(function()
			local RS = game:GetService("ReplicatedStorage")
			local probe = RS:FindFirstChildWhichIsA("ModuleScript", true)
			if not probe then
				return
			end
			require(probe)
			canRequire, requireWhy = true, probe:GetFullName()
		end)
		if not ok then
			requireWhy = tostring(err)
		end
	end
	local f_request
	do
		local ok, v = pcall(function()
			return syn and syn.request
		end)
		if ok and type(v) == "function" then
			f_request = v
		else
			ok, v = pcall(function()
				return http and http.request
			end)
			if ok and type(v) == "function" then
				f_request = v
			else
				f_request = first("request", "http_request", "httprequest")
			end
		end
	end
	M.can = {
		files = (f_writefile and f_readfile and f_isfile) and true or false,
		folders = (f_isfolder and f_makefolder) and true or false,
		listFiles = f_listfiles and true or false,
		hiddenUi = f_gethui and true or false,
		clipboard = f_clip and true or false,
		request = f_request and true or false,
		prompts = true,
		gameRequire = canRequire,
	}
	M.promptVia = f_fireprompt and "fireproximityprompt" or "InputHoldBegin"
	M.gameRequireWhy = requireWhy
	M.name = "unknown"
	if f_identify then
		local ok, n = pcall(f_identify)
		if ok and type(n) == "string" and #n > 0 then
			M.name = n
		end
	end
	function M.hiddenParent()
		if f_gethui then
			local ok, ui = pcall(f_gethui)
			if ok and ui then
				return ui
			end
		end
		return BX.require("core.services").CoreGui
	end
	function M.writeFile(path, data)
		if not f_writefile then
			return false
		end
		return (BX.try("exec.writeFile", f_writefile, path, data))
	end
	function M.readFile(path)
		if not f_readfile then
			return nil
		end
		local ok, data = BX.try("exec.readFile", f_readfile, path)
		return ok and data or nil
	end
	function M.isFile(path)
		if not f_isfile then
			return false
		end
		local ok, yes = pcall(f_isfile, path)
		return ok and yes or false
	end
	function M.listFiles(path)
		if not f_listfiles then
			return nil
		end
		local ok, files = BX.try("exec.listFiles", f_listfiles, path)
		if not ok or type(files) ~= "table" then
			return nil
		end
		return files
	end
	function M.deleteFile(path)
		if not f_delfile then
			return false
		end
		return (BX.try("exec.deleteFile", f_delfile, path))
	end
	function M.ensureFolder(path)
		if not M.can.folders then
			return false
		end
		local built = ""
		for part in tostring(path):gmatch("[^/]+") do
			built = (built == "") and part or (built .. "/" .. part)
			local ok, exists = pcall(f_isfolder, built)
			if ok and not exists then
				if not BX.try("exec.makeFolder", f_makefolder, built) then
					return false
				end
			end
		end
		return true
	end
	function M.clipboard(text)
		for _, name in ipairs({ "setclipboard", "toclipboard", "set_clipboard", "setrbxclipboard" }) do
			local f = fn(name)
			if f and pcall(f, text) then
				return true
			end
		end
		return false
	end
	function M.httpRequest(opts)
		if not f_request then
			return nil
		end
		local ok, res = BX.try("exec.httpRequest", f_request, opts)
		return ok and res or nil
	end
	function M.firePrompt(prompt, holdDuration)
		if f_fireprompt then
			return (BX.try("exec.firePrompt", f_fireprompt, prompt, holdDuration or 0))
		end
		return (
			BX.try("exec.firePrompt.hold", function()
				prompt:InputHoldBegin()
				local hold = tonumber(holdDuration) or tonumber(prompt.HoldDuration) or 0
				if hold > 0 then
					task.wait(hold + 0.05)
				end
				prompt:InputHoldEnd()
			end)
		)
	end
	function M.report()
		local have, missing = {}, {}
		for k, v in pairs(M.can) do
			table.insert(v and have or missing, k)
		end
		table.sort(have)
		table.sort(missing)
		return {
			executor = M.name,
			have = have,
			missing = missing,
			promptVia = M.promptVia,
			gameRequireWhy = requireWhy,
		}
	end
	log.info("executor=%s gameRequire=%s", M.name, tostring(canRequire))
	return M
end)

-- =============================================================================
-- core/device.lua
-- =============================================================================

BX.module("core.device", function(BX)
	local svc = BX.require("core.services")
	local M = {}
	M.isTouch = svc.UserInputService.TouchEnabled and not svc.UserInputService.KeyboardEnabled
	local function shortSide()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize
		if not vp or vp.Y < 10 then
			return 1080
		end
		return math.min(vp.X, vp.Y)
	end
	M.smallScreen = shortSide() < 500
	M.tier = (M.isTouch and M.smallScreen) and "low" or "mid"
	M.fps = nil
	local MULT = { low = 2.2, mid = 1.35, high = 1.0 }
	function M.scale(s)
		return s * (MULT[M.tier] or 1.35)
	end
	function M.budget(n)
		local share = (M.tier == "low" and 0.35) or (M.tier == "mid" and 0.7) or 1
		return math.max(1, math.floor(n * share + 0.5))
	end
	function M.lite()
		return M.tier == "low"
	end
	local sc = BX.scope("core.device")
	local frames = 0
	sc:connect(svc.RunService.Heartbeat, function()
		frames = frames + 1
	end)
	sc:loop("measure", 5, function()
		local fps = frames / 5
		frames = 0
		M.fps = M.fps and (M.fps + (fps - M.fps) * 0.4) or fps
		local want = M.tier
		if M.tier == "high" then
			if M.fps < 45 then
				want = "mid"
			end
		elseif M.tier == "mid" then
			if M.fps < 25 then
				want = "low"
			elseif M.fps > 75 then
				want = "high"
			end
		else
			if M.fps > 40 then
				want = "mid"
			end
		end
		if want == "high" and M.isTouch and M.smallScreen then
			want = "mid"
		end
		M.tier = want
	end)
	return M
end)

-- =============================================================================
-- core/character.lua
-- =============================================================================

BX.module("core.character", function(BX)
	local svc = BX.require("core.services")
	local M = {}
	local plr = svc.LocalPlayer
	local current = setmetatable({}, { __mode = "v" })
	local listeners = {}
	function M.get()
		local c = current.char
		if c and c.Parent then
			return c
		end
		return plr and plr.Character
	end
	function M.root()
		local c = M.get()
		return c and c:FindFirstChild("HumanoidRootPart")
	end
	function M.humanoid()
		local c = M.get()
		return c and c:FindFirstChildOfClass("Humanoid")
	end
	local function fire(char)
		current.char = char
		for i = #listeners, 1, -1 do
			local L = listeners[i]
			if not L.scope or L.scope.dead then
				table.remove(listeners, i)
			else
				BX.try(("character/%s"):format(L.label), L.fn, char)
			end
		end
	end
	function M.onSpawn(sc, label, fn)
		listeners[#listeners + 1] = { scope = sc, label = label, fn = fn }
		local c = M.get()
		if c then
			BX.try(("character/%s"):format(label), fn, c)
		end
	end
	local sc = BX.scope("core.character")
	if plr then
		sc:connect(plr.CharacterAdded, function(char)
			task.spawn(function()
				BX.try("character/wait", function()
					char:WaitForChild("HumanoidRootPart", 10)
				end)
				if BX.alive() then
					fire(char)
				end
			end)
		end)
		sc:connect(plr.CharacterRemoving, function()
			current.char = nil
		end)
		current.char = plr.Character
	end
	return M
end)

-- =============================================================================
-- core/restore.lua
-- =============================================================================

BX.module("core.restore", function(BX)
	local ch = BX.require("core.character")
	local M = {}
	local entries = {}
	local order = {}
	function M.remember(key, read, write)
		if entries[key] then
			return false
		end
		local ok, value = pcall(read)
		if not ok then
			return false
		end
		entries[key] = { read = read, write = write, original = value, char = ch.get() }
		order[#order + 1] = key
		return true
	end
	function M.onRestore(key, undo)
		if entries[key] then
			return false
		end
		entries[key] = { undo = undo, char = ch.get() }
		order[#order + 1] = key
		return true
	end
	function M.permanent(key, why)
		if entries[key] then
			return false
		end
		entries[key] = { permanent = why or "not reversible", char = ch.get() }
		order[#order + 1] = key
		return true
	end
	function M.restoreAll()
		local restored, skipped, failed = 0, 0, 0
		local liveChar = ch.get()
		for i = #order, 1, -1 do
			local key = order[i]
			local e = entries[key]
			if e then
				if e.permanent then
					skipped = skipped + 1
				elseif e.char and e.char ~= liveChar then
					skipped = skipped + 1
				else
					local ok = pcall(function()
						if e.undo then
							e.undo()
						else
							e.write(e.original)
						end
					end)
					if ok then
						restored = restored + 1
					else
						failed = failed + 1
					end
				end
				entries[key] = nil
			end
			table.remove(order, i)
		end
		return restored, skipped, failed
	end
	local sc = BX.scope("core.restore")
	ch.onSpawn(sc, "restore.respawn", function(char)
		for i = #order, 1, -1 do
			local key = order[i]
			local e = entries[key]
			if e and e.char and e.char ~= char then
				entries[key] = nil
				table.remove(order, i)
			end
		end
	end)
	return M
end)

-- =============================================================================
-- core/config.lua
-- =============================================================================

BX.module("core.config", function(BX)
	return {
		CARRY_SPEED = 500,
		OUTBOUND_SPEED_MIN = 500,
		OUTBOUND_SPEED_MAX = 1200,
		LITE_FPS = 25,
		STATS_HZ = 4,
		LOG_LEVEL = 2,
		DEFAULT_BACKGROUND = "108858454360177",
		AUTOSAVE_INTERVAL = 30,
	}
end)

-- =============================================================================
-- core/state.lua
-- =============================================================================

BX.module("core.state", function(BX)
	return { heldEggUid = nil, autoStealOn = false, stayOnTreadmill = false, lastFps = 0, startedAt = os.clock() }
end)

-- =============================================================================
-- core/util.lua
-- =============================================================================

BX.module("core.util", function(BX)
	local M = {}
	function M.clamp(v, lo, hi)
		return math.max(lo, math.min(hi, v))
	end
	function M.short(n)
		if n >= 1e6 then
			return ("%.1fM"):format(n / 1e6)
		end
		if n >= 1e3 then
			return ("%.1fk"):format(n / 1e3)
		end
		return tostring(math.floor(n))
	end
	return M
end)

-- =============================================================================
-- ui/splash.lua
-- =============================================================================

BX.module("ui.splash", function(BX)
	return {
		step = function() end,
		discord = function() end,
		fail = function() end,
		done = function() end,
		isWaitingForUser = function()
			return false
		end,
		whenClosed = function(fn)
			pcall(fn)
		end,
	}
end)

-- =============================================================================
-- ui/notify.lua
-- =============================================================================

BX.module("ui.notify", function(BX)
	local svc = BX.require("core.services")
	local TS = svc.TweenService
	local M = {}
	local W, PAD, MAX_ACTIVE = 340, 8, 4
	local BG, BORD, TEXT, DIM =
		Color3.fromRGB(22, 22, 26),
		Color3.fromRGB(48, 48, 56),
		Color3.fromRGB(240, 240, 246),
		Color3.fromRGB(160, 160, 168)
	local KIND = {
		success = Color3.fromRGB(87, 242, 135),
		warn = Color3.fromRGB(240, 190, 90),
		error = Color3.fromRGB(240, 110, 110),
		info = Color3.fromRGB(140, 200, 255),
	}
	local sc, gui, container
	local active = {}
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end
	local function ensure()
		if sc then
			return
		end
		sc = BX.scope("ui.notify")
		local parent = (gethui and gethui()) or svc.CoreGui
		local old = parent:FindFirstChild("HanssyzNotify")
		if old then
			old:Destroy()
		end
		gui = mk(
			"ScreenGui",
			{
				Name = "HanssyzNotify",
				DisplayOrder = 999999,
				IgnoreGuiInset = true,
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			},
			parent
		)
		sc:own(gui)
		container = mk(
			"Frame",
			{
				Name = "Stack",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 12),
				Size = UDim2.new(0, W, 0, 0),
				BackgroundTransparency = 1,
			},
			gui
		)
		sc:own(container)
		mk(
			"UIListLayout",
			{
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, PAD),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			container
		)
	end
	local function removeNotif(n)
		if not n or n.removed then
			return
		end
		n.removed = true
		for i, x in ipairs(active) do
			if x == n then
				table.remove(active, i)
				break
			end
		end
		local frame = n.frame
		if not frame or not frame.Parent then
			return
		end
		TS:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(0, 40, 0, frame.Position.Y.Offset),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.32, function()
			if frame and frame.Parent then
				frame:Destroy()
			end
		end)
	end
	function M.show(title, body, kind, duration)
		ensure()
		while #active >= MAX_ACTIVE do
			removeNotif(active[1])
			task.wait(0.05)
		end
		local accentColor = KIND[kind] or KIND.info
		local frame = mk(
			"Frame",
			{ Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = BG, BackgroundTransparency = 1, BorderSizePixel = 0 },
			container
		)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
		local stroke = mk(
			"UIStroke",
			{ Color = BORD, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			frame
		)
		local accent = mk(
			"Frame",
			{
				Size = UDim2.new(0, 3, 1, 0),
				BackgroundColor3 = accentColor,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			},
			frame
		)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, accent)
		mk(
			"UIPadding",
			{
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 12),
			},
			frame
		)
		local titleL = mk(
			"TextLabel",
			{
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = TEXT,
				TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(title or "Hanssyz"),
			},
			frame
		)
		local bodyL = mk(
			"TextLabel",
			{
				Position = UDim2.fromOffset(0, 20),
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = DIM,
				TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = tostring(body or ""),
			},
			frame
		)
		local n = { frame = frame, removed = false }
		active[#active + 1] = n
		frame.Position = UDim2.new(0, 0, 0, -20)
		TS:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08,
			Position = UDim2.new(0, 0, 0, 0),
		}):Play()
		TS:Create(stroke, TweenInfo.new(0.35), { Transparency = 0.55 }):Play()
		TS:Create(accent, TweenInfo.new(0.35), { BackgroundTransparency = 0 }):Play()
		TS:Create(titleL, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
		TS:Create(bodyL, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
		task.delay(duration or 3, function()
			removeNotif(n)
		end)
		return n
	end
	function M.success(t, b, d)
		return M.show(t, b, "success", d)
	end
	function M.warn(t, b, d)
		return M.show(t, b, "warn", d)
	end
	function M.error(t, b, d)
		return M.show(t, b, "error", d)
	end
	function M.info(t, b, d)
		return M.show(t, b, "info", d)
	end
	return M
end)

-- =============================================================================
-- ui/stats.lua - removed
-- =============================================================================

BX.module("ui.stats", function(BX)
	return { show = function() end }
end)

-- =============================================================================
-- ui/eggpanel.lua - click = steal, stops when target gone
-- =============================================================================

BX.module("ui.eggpanel", function(BX)
	local svc = BX.require("core.services")
	local eggs = BX.require("features.eggs")
	local auto = BX.require("features.autosteal")
	local data = BX.require("core.data")
	local notify = BX.require("ui.notify")
	local log = BX.require("boot.log").for_module("eggpanel")
	local M = {}

	local BG_TOP = Color3.fromRGB(26, 26, 30)
	local BG_BOT = Color3.fromRGB(14, 14, 17)
	local ELEMENT = Color3.fromRGB(41, 41, 48)
	local ACCENT = Color3.fromRGB(206, 206, 212)
	local TEXT = Color3.fromRGB(220, 220, 220)
	local DIM = Color3.fromRGB(150, 150, 158)
	local GREEN = Color3.fromRGB(87, 242, 135)
	local AMBER = Color3.fromRGB(240, 190, 90)

	local BUTTON_POS = Vector2.new(12, 12)
	local PANEL_W, PANEL_H = 340, 460
	local ROW_H = 48
	local MAX_ROWS = 9
	local TICK = 1.0

	local gui, btn, panel, listFrame, listScroll, hintLbl
	local rowPool = {}
	local sc, enabled, open = nil, false, false
	-- Track which egg the current uid-run is on, so the panel highlights it.
	local activeUid = nil

	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end
	local function hexOf(c)
		return ("%02X%02X%02X"):format(
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5)
		)
	end
	local function iconFor(egg)
		local dir = data.assetsDir()
		local entry = egg.assetCategory and dir and dir[egg.assetCategory] or nil
		local raw = entry and entry.Icon or nil
		if type(raw) == "number" then
			return "rbxassetid://" .. raw
		end
		if type(raw) == "string" and raw ~= "" then
			if raw:match("^%d+$") then
				return "rbxassetid://" .. raw
			end
			return raw
		end
		return nil
	end

	-- Click = steal that egg.
	local function stealEgg(uid)
		if not uid then
			return
		end
		local rec = eggs.get(uid)
		if not rec then
			notify.warn("Egg gone", "That egg is no longer on the field", 3)
			return
		end
		activeUid = uid
		local ok, why = auto.pickNow(uid)
		if ok then
			notify.success(
				"Targeting " .. tostring(rec.name or "egg"),
				("%s/s  \u{B7}  %s"):format(eggs.formatRate(rec.value or 0), tostring(rec.rarity or "?")),
				3
			)
		else
			notify.error("Could not start", tostring(why or "unknown"), 3)
			activeUid = nil
		end
	end

	local function makeRow(i)
		local row = rowPool[i]
		if row then
			return row
		end
		local f = mk("TextButton", {
			Size = UDim2.new(1, -8, 0, ROW_H - 4),
			BackgroundColor3 = ELEMENT,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
		}, listFrame)
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
		local accent = mk("Frame", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = ACCENT,
			BorderSizePixel = 0,
		}, f)
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, accent)
		local icon = mk("ImageLabel", {
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			Image = "",
			ScaleType = Enum.ScaleType.Fit,
		}, f)
		local title = mk("TextLabel", {
			Position = UDim2.fromOffset(46, 5),
			Size = UDim2.new(1, -56, 0, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "",
		}, f)
		local sub = mk("TextLabel", {
			Position = UDim2.fromOffset(46, 22),
			Size = UDim2.new(1, -56, 0, 14),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = DIM,
			TextXAlignment = Enum.TextXAlignment.Left,
			RichText = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "",
		}, f)
		row = { frame = f, title = title, sub = sub, accent = accent, icon = icon, uid = nil }
		rowPool[i] = row
		f.MouseButton1Click:Connect(function()
			if row.uid then
				stealEgg(row.uid)
			end
		end)
		f.MouseEnter:Connect(function()
			f.BackgroundTransparency = 0.1
		end)
		f.MouseLeave:Connect(function()
			f.BackgroundTransparency = 0.35
		end)
		return row
	end

	local function paintList()
		if not listFrame then
			return
		end
		local list = eggs.list() or {}
		local n = math.min(#list, MAX_ROWS)
		for i = 1, n do
			local egg = list[i]
			local row = makeRow(i)
			row.frame.Visible = true
			row.frame.LayoutOrder = i
			row.uid = egg.uid
			row.title.Text = tostring(egg.name or "?")
			local colour = ACCENT
			local dir = data.assetsDir()
			local entry = egg.assetCategory and dir and dir[egg.assetCategory] or nil
			if entry and entry.Rarity and typeof(entry.Rarity.Color) == "Color3" then
				colour = entry.Rarity.Color
			end
			row.accent.BackgroundColor3 = colour
			local icon = iconFor(egg)
			row.icon.Image = icon or ""
			row.icon.Visible = icon ~= nil
			row.sub.Text = ('<font color="#%s">%s/s</font>  \u{B7}  %s%s%s'):format(
				hexOf(GREEN),
				eggs.formatRate(egg.value or 0),
				tostring(egg.rarity or "?"),
				egg.kg and egg.kg > 0 and ("  \u{B7}  %.1fkg"):format(egg.kg) or "",
				egg.areaId and ("  \u{B7}  " .. tostring(egg.areaId)) or ""
			)
			-- Highlight the currently-targeted egg.
			if activeUid and egg.uid == activeUid then
				row.frame.BackgroundColor3 = Color3.fromRGB(60, 80, 40)
				row.title.Text = "\u{25B8} " .. row.title.Text
			else
				row.frame.BackgroundColor3 = ELEMENT
			end
		end
		for i = n + 1, #rowPool do
			if rowPool[i] then
				rowPool[i].frame.Visible = false
				rowPool[i].uid = nil
			end
		end
		if n == 0 and hintLbl then
			hintLbl.Visible = true
			hintLbl.Text = "No eggs on the field"
		elseif hintLbl then
			hintLbl.Visible = false
		end
	end

	local function build()
		sc = BX.scope("ui.eggpanel")
		local parent = (gethui and gethui()) or svc.CoreGui
		local old = parent:FindFirstChild("HanssyzEggPanel")
		if old then
			old:Destroy()
		end
		gui = mk(
			"ScreenGui",
			{
				Name = "HanssyzEggPanel",
				DisplayOrder = 999997,
				IgnoreGuiInset = true,
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			},
			parent
		)
		sc:own(gui)
		btn = mk("TextButton", {
			Position = UDim2.fromOffset(BUTTON_POS.X, BUTTON_POS.Y),
			Size = UDim2.fromOffset(56, 32),
			BackgroundColor3 = BG_TOP,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "EGGS",
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextColor3 = TEXT,
		}, gui)
		mk("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
		mk(
			"UIStroke",
			{ Color = ACCENT, Transparency = 0.55, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			btn
		)
		panel = mk("Frame", {
			Position = UDim2.fromOffset(BUTTON_POS.X, BUTTON_POS.Y + 40),
			Size = UDim2.fromOffset(PANEL_W, PANEL_H),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Visible = false,
		}, gui)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
		mk("UIGradient", { Color = ColorSequence.new(BG_TOP, BG_BOT), Rotation = 90 }, panel)
		mk(
			"UIStroke",
			{ Color = ACCENT, Transparency = 0.55, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
			panel
		)
		mk(
			"UIPadding",
			{
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			},
			panel
		)
		mk("TextLabel", {
			Size = UDim2.new(1, -24, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Click an egg to steal it",
		}, panel)
		local close = mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = ELEMENT,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "\u{2715}",
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextColor3 = TEXT,
		}, panel)
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
		listScroll = mk("ScrollingFrame", {
			Position = UDim2.fromOffset(0, 28),
			Size = UDim2.new(1, 0, 1, -28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = ACCENT,
			ScrollBarImageTransparency = 0.5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, panel)
		listFrame = mk(
			"Frame",
			{ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 },
			listScroll
		)
		mk(
			"UIListLayout",
			{
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			},
			listFrame
		)
		hintLbl = mk("TextLabel", {
			Position = UDim2.fromOffset(0, 4),
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = DIM,
			Text = "No eggs on the field",
			Visible = false,
		}, listFrame)
		btn.MouseButton1Click:Connect(function()
			open = not open
			panel.Visible = open
			if open then
				paintList()
			end
		end)
		close.MouseButton1Click:Connect(function()
			open = false
			panel.Visible = false
		end)
		sc:loop("paint", TICK, function()
			if not open then
				return
			end
			paintList()
		end)
	end

	function M.show(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		enabled = on
		if not on then
			open = false
			if sc then
				sc:destroy()
				sc = nil
			end
			if gui then
				pcall(function()
					gui:Destroy()
				end)
			end
			gui, btn, panel, listFrame, listScroll, hintLbl = nil, nil, nil, nil, nil, nil
			rowPool = {}
			activeUid = nil
			return true
		end
		local ok, err = pcall(build)
		if not ok then
			log.error("could not build egg panel: %s", tostring(err))
			enabled = false
			return false
		end
		return true
	end
	function M.isOn()
		return enabled
	end
	function M.isOpen()
		return open
	end
	function M.clearActive()
		activeUid = nil
	end
	return M
end)

-- =============================================================================
-- ui/status.lua
-- =============================================================================

BX.module("ui.status", function(BX)
	local svc = BX.require("core.services")
	local auto = BX.require("features.autosteal")
	local hold = BX.require("features.farm.treadmill_on")
	local boss = BX.require("features.boss")
	local rift = BX.require("features.rift")
	local st = BX.require("core.state")
	local log = BX.require("boot.log").for_module("status")
	local M = {}
	local BG_TOP, BG_BOT = Color3.fromRGB(26, 26, 30), Color3.fromRGB(14, 14, 17)
	local ELEMENT, ACCENT = Color3.fromRGB(41, 41, 48), Color3.fromRGB(206, 206, 212)
	local TEXT, DIM = Color3.fromRGB(220, 220, 220), Color3.fromRGB(140, 140, 148)
	local GREEN, AMBER = Color3.fromRGB(87, 242, 135), Color3.fromRGB(240, 190, 90)
	local FONT = Enum.Font.GothamMedium
	local TICK = 0.5
	local gui, panel, body
	local sc, enabled = nil, false
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do
			o[k] = v
		end
		o.Parent = parent
		return o
	end
	local function hexOf(c)
		return ("%02X%02X%02X"):format(
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5)
		)
	end
	local function fmtDur(sec)
		sec = math.max(0, math.floor(sec or 0))
		local h, m = math.floor(sec / 3600), math.floor(sec / 60) % 60
		if h > 0 then
			return ("%dh %02dm"):format(h, m)
		end
		if m > 0 then
			return ("%dm %02ds"):format(m, sec % 60)
		end
		return ("%ds"):format(sec)
	end
	local function actionLine()
		if not auto.isRunning() then
			return "Idle", DIM
		end
		local owner = auto.owner() or "?"
		local act = auto.activity() or "running"
		if hold.isOn() and st.stayOnTreadmill then
			return "On Treadmill  \u{B7}  waiting (" .. owner .. ")", AMBER
		end
		if act == "waiting" then
			return "Waiting for target (" .. owner .. ")", AMBER
		end
		if act:find("^baiting") then
			return "Baiting in Forest (" .. owner .. ")", GREEN
		end
		if act:find("^target") then
			return "Going to target (" .. owner .. ")", GREEN
		end
		if act:find("^stealing") then
			return "Stealing (" .. owner .. ")", GREEN
		end
		if act:find("^carrying") then
			return "Carrying home (" .. owner .. ")", GREEN
		end
		if act:find("^delivering") then
			return "Delivering (" .. owner .. ")", GREEN
		end
		return act .. " (" .. owner .. ")", TEXT
	end
	local function bossLine()
		local s = boss.held()
		if not s then
			return "Boss:  reading...", DIM
		end
		local now = workspace:GetServerTimeNow()
		if s.Open == true then
			local left = math.max(0, (tonumber(s.ClosesAt) or 0) - now)
			return ("Boss:  OPEN  \u{B7}  closes in %s"):format(fmtDur(left)), GREEN
		end
		local open = math.max(0, (tonumber(s.OpensAt) or 0) - now)
		if open > 0 then
			return ("Boss:  opens in %s"):format(fmtDur(open)), DIM
		end
		return "Boss:  closed", DIM
	end
	local function riftLine()
		if not rift.isOn() then
			return "Rift:  off", DIM
		end
		local s = rift.status()
		if not s then
			return "Rift:  reading...", DIM
		end
		local bodyText = tostring(s.body or "")
		local have = rift.owned()
		local reqs = rift.requirements()
		local pct = (have and #reqs > 0) and ("%d/%d"):format(have, #reqs) or ""
		local out = rift.onField()
		local colour = DIM
		if #out > 0 then
			colour = GREEN
		elseif pct == (#reqs .. "/" .. #reqs) then
			colour = GREEN
		elseif pct ~= "" then
			colour = AMBER
		end
		if pct ~= "" then
			return ("Rift:  %s  \u{B7}  %s"):format(pct, bodyText), colour
		end
		return "Rift:  " .. bodyText, colour
	end
	local function refresh()
		if not body then
			return
		end
		local l1, c1 = actionLine()
		local l2, c2 = bossLine()
		local l3, c3 = riftLine()
		body.Text = ('<font color="#%s">%s</font>\n<font color="#%s">%s</font>\n<font color="#%s">%s</font>'):format(
			hexOf(c1),
			l1,
			hexOf(c2),
			l2,
			hexOf(c3),
			l3
		)
	end
	local function build()
		sc = BX.scope("ui.status")
		local parent = (gethui and gethui()) or svc.CoreGui
		local old = parent:FindFirstChild("HanssyzStatus")
		if old then
			old:Destroy()
		end
		gui = mk(
			"ScreenGui",
			{
				Name = "HanssyzStatus",
				DisplayOrder = 999995,
				IgnoreGuiInset = true,
				ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			},
			parent
		)
		panel = mk(
			"Frame",
			{
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromOffset(80, 40),
				Size = UDim2.fromOffset(360, 98),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
			},
			gui
		)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
		mk("UIGradient", { Color = ColorSequence.new(BG_TOP, BG_BOT), Rotation = 90 }, panel)
		local stroke = mk(
			"UIStroke",
			{
				Color = Color3.new(1, 1, 1),
				Transparency = 0.55,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			},
			panel
		)
		mk("UIGradient", { Color = ColorSequence.new(ACCENT, ELEMENT), Rotation = 90 }, stroke)
		mk(
			"UIPadding",
			{
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			},
			panel
		)
		mk(
			"TextLabel",
			{
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "Hanssyz  \u{B7}  Status",
			},
			panel
		)
		body = mk(
			"TextLabel",
			{
				Position = UDim2.fromOffset(0, 22),
				Size = UDim2.new(1, 0, 1, -22),
				BackgroundTransparency = 1,
				Font = FONT,
				TextSize = 12,
				TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				RichText = true,
				TextWrapped = true,
				Text = "",
			},
			panel
		)
		sc:loop("tick", TICK, refresh)
	end
	function M.show(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		enabled = on
		if not on then
			if sc then
				sc:destroy()
				sc = nil
			end
			if gui then
				pcall(function()
					gui:Destroy()
				end)
			end
			gui, panel, body = nil, nil, nil
			return true
		end
		local ok, err = pcall(build)
		if not ok then
			log.error("could not build status HUD: %s", tostring(err))
			enabled = false
			return false
		end
		refresh()
		return true
	end
	function M.isOn()
		return enabled
	end
	return M
end)

-- =============================================================================
-- ui/window.lua
-- =============================================================================

BX.module("ui.window", function(BX)
	local exec = BX.require("core.exec")
	local M = { ok = false }
	local URLS = {
		"https://sirius.menu/gen2",
		"https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
	}
	local Rayfield, lastErr
	for attempt = 1, 4 do
		for _, url in ipairs(URLS) do
			local ok, res = pcall(function()
				return game:HttpGet(url)
			end)
			if ok and type(res) == "string" and #res > 1000 then
				local okLoad, lib = pcall(function()
					return loadstring(res)()
				end)
				if okLoad and type(lib) == "table" then
					Rayfield = lib
					break
				end
				lastErr = "loadstring failed: " .. tostring(lib)
			else
				lastErr = tostring(res)
			end
		end
		if Rayfield then
			break
		end
		task.wait(attempt * 1.5)
	end
	if not Rayfield then
		M.error = "Menu host is down"
		return M
	end
	local env = (type(getgenv) == "function" and getgenv()) or _G
	pcall(function()
		if env.__HANSSYZ_WINDOW and not env.__HANSSYZ_WINDOW.unloaded then
			env.__HANSSYZ_WINDOW:Unload()
		end
	end)
	local okWin, window = pcall(function()
		return Rayfield:CreateWindow({
			name = "Hanssyz",
			subtitle = "Steal An Egg",
			showName = "Hanssyz",
			sidebarLayout = true,
			profile = "Premium",
			theme = {
				AccentColor = Color3.fromRGB(255, 255, 255),
				AccentStroke = Color3.fromRGB(40, 40, 40),
				AccentGlow = 0.1,
				TextColor = Color3.fromRGB(220, 220, 220),
				BackgroundColor = Color3.fromRGB(12, 12, 12),
				ElementColor = Color3.fromRGB(20, 20, 20),
			},
			configuration = { autoSave = false, autoLoad = false, fileName = "Hanssyz_StealAnEgg" },
		})
	end)
	if not okWin or not window then
		M.error = "Could not build the menu"
		return M
	end
	env.__HANSSYZ_WINDOW = window
	M.ok, M.window, M.lib = true, window, Rayfield
	BX.try("window.versionTag", function()
		local shown = tostring(BX.version or ""):match("^(%d+%.%d+)")
		if not shown then
			return
		end
		window:CreateTag({ title = "V" .. shown, color = Color3.fromRGB(206, 206, 212) })
	end)
	local sc = BX.scope("ui.window")
	local screen = nil
	BX.try("window.resolveGui", function()
		if typeof(window.screenGui) == "Instance" and window.screenGui:IsA("ScreenGui") then
			screen = window.screenGui
		end
	end)
	if not screen then
		BX.try("window.findGui", function()
			local root = exec.hiddenParent()
			for _ = 1, 20 do
				for _, g in ipairs(root:GetChildren()) do
					if
						g:IsA("ScreenGui")
						and g.Name ~= "HanssyzStatus"
						and g.Name ~= "HanssyzNotify"
						and g.Name ~= "HanssyzEggPanel"
						and g:FindFirstChild("Main")
					then
						screen = g
						break
					end
				end
				if screen then
					break
				end
				task.wait(0.05)
			end
		end)
	end
	M.screen = screen
	function M.hide()
		if not screen then
			return false
		end
		screen.Enabled = false
		return true
	end
	function M.reveal()
		if not screen or not screen.Parent then
			return false
		end
		screen.Enabled = true
		return true
	end
	function M.tab(name)
		local ok, t = BX.try("window.tab." .. name, function()
			return window:CreateTab({ name = name })
		end)
		return ok and t or nil
	end
	local hasNotify = type(Rayfield.Notify) == "function"
	function M.notify(title, content, duration)
		if not hasNotify then
			return false
		end
		return (
			BX.try("window.notify", function()
				Rayfield:Notify({ title = title or "Hanssyz", content = content or "", duration = duration or 4 })
			end)
		)
	end
	M.hasNotify = hasNotify
	function M.unload()
		BX.try("window.unload", function()
			if window and not window.unloaded then
				window:Unload()
			end
		end)
		sc:destroy()
	end
	return M
end)

-- =============================================================================
-- ui/tabs/home.lua - new Discord invite
-- =============================================================================

BX.module("ui.tabs.home", function(BX)
	local exec = BX.require("core.exec")
	local win = BX.require("ui.window")
	local M = {}
	local INVITE = DISCORD_INVITE
	local UPDATES = "V4.7 - Hanssyz\n"
		.. "- Egg panel: stops when the target is stolen or gone.\n"
		.. "- Config: Auto-Save toggle.\n"
		.. "- Discord invite updated.\n"

	function M.build(tab)
		if not tab then
			return M
		end
		tab:CreateSection({ name = "Discord" })
		tab:CreateButton({
			name = "Join Discord",
			description = INVITE,
			callback = function()
				local copied = exec.clipboard(INVITE)
				BX.try("home.openBrowser", function()
					game:GetService("GuiService"):OpenBrowserWindow(INVITE)
				end)
				win.notify("Hanssyz", copied and "Invite copied to clipboard" or ("Join at " .. INVITE))
			end,
		})
		tab:CreateSection({ name = "Updates" })
		tab:CreateText({ name = "Latest", text = UPDATES })
		return M
	end
	return M
end)

-- =============================================================================
-- ui/tabs/farm.lua
-- =============================================================================

BX.module("ui.tabs.farm", function(BX)
	local auto = BX.require("features.autosteal")
	local eggs = BX.require("features.eggs")
	local filter = BX.require("features.farm.filter")
	local hold = BX.require("features.farm.treadmill_on")
	local pets = BX.require("features.farm.pets")
	local tread = BX.require("features.treadmill")
	local panel = BX.require("ui.eggpanel")
	local win = BX.require("ui.window")
	local log = BX.require("boot.log").for_module("farm.tab")
	local M = {}
	local autoToggle, autoTmToggle, holdToggle, statusLine
	local statusSc, lastStatus = nil, nil
	local selfAuto, selfHold, selfAutoTm = 0, 0, 0
	local areaIds, rarityIds = {}, {}
	local function paintStatus(text)
		if not statusLine or text == lastStatus then
			return
		end
		if BX.try("farm.status", function()
			statusLine:Set(text)
		end) then
			lastStatus = text
		end
	end
	local function statusText()
		local st = filter.status()
		if not auto.isRunning() or auto.owner() ~= "farm" then
			return "off"
		end
		return "ON  \u{B7}  " .. tostring(st.text)
	end
	local function watchStatus(on)
		if statusSc then
			statusSc:destroy()
			statusSc = nil
		end
		if not on then
			paintStatus("off")
			return
		end
		statusSc = BX.scope("ui.tabs.farm.status")
		statusSc:loop("paint", 1.0, function()
			paintStatus(statusText())
		end)
	end
	local function labelsAndMap(r)
		local labels, map = {}, {}
		for _, x in ipairs(r) do
			labels[#labels + 1] = x.label
			map[x.label] = x.id
		end
		return labels, map
	end
	local function idsFor(picked, map)
		local out = {}
		if type(picked) == "table" then
			for _, label in pairs(picked) do
				local id = map[tostring(label)]
				if id then
					out[#out + 1] = id
				end
			end
		elseif type(picked) == "string" and picked ~= "" then
			local id = map[picked]
			if id then
				out[#out + 1] = id
			end
		end
		return out
	end
	local function farmOptions()
		return { pick = filter.pick, continuous = true }
	end

	function M.build(tab)
		if not tab then
			return M
		end
		tab:CreateSection({ name = "How It Works" })
		tab:CreateText({
			name = "How It Works",
			text = "Set filters, press Auto Steal. While nothing matches, you sit "
				.. "on the treadmill. The moment an egg matches, the belt releases "
				.. "and the steal runs immediately.",
		})
		tab:CreateSection({ name = "Auto Farm" })
		statusLine = tab:CreateText({ name = "Status", text = "off" })
		autoToggle = tab:CreateToggle({
			name = "Auto Steal",
			value = false,
			flag = "FarmAutoSteal",
			callback = function(on)
				BX.try("farm.autoToggle", function()
					if on then
						selfAuto = 0
						auto.setOptions("farm", farmOptions())
						local okStart, why = auto.setEnabled(true, "farm")
						if okStart == false then
							paintStatus(tostring(why))
							win.notify("Farm", tostring(why), 6)
							task.spawn(function()
								if autoToggle and autoToggle.Set then
									selfAuto = selfAuto + 1
									autoToggle:Set(false)
								end
							end)
							return
						end
						watchStatus(true)
						return
					end
					watchStatus(false)
					if selfAuto > 0 then
						selfAuto = selfAuto - 1
						return
					end
					auto.setEnabled(false, "farm")
				end)
			end,
		})
		autoTmToggle = tab:CreateToggle({
			name = "Auto Treadmill While Waiting",
			description = "Park on the belt while Auto Steal waits for a match",
			value = true,
			flag = "AutoTreadmillWait",
			callback = function(on)
				if selfAutoTm > 0 then
					selfAutoTm = selfAutoTm - 1
					return
				end
				auto.setAutoTreadmill(on and true or false)
				win.notify("Farm", "Auto Treadmill " .. (on and "ON" or "OFF"), 3)
			end,
		})
		holdToggle = tab:CreateToggle({
			name = "Stay On Treadmill (manual)",
			value = false,
			flag = "StayOnTreadmill",
			callback = function(on)
				if selfHold > 0 then
					selfHold = selfHold - 1
					return
				end
				local ok, why = hold.setEnabled(on and true or false)
				if on and not ok then
					task.spawn(function()
						if holdToggle and holdToggle.Set then
							selfHold = selfHold + 1
							holdToggle:Set(false)
						end
					end)
					win.notify("Farm", tostring(why or "Could not stay on the belt"), 4)
				end
			end,
		})
		tab:CreateSection({ name = "Egg List Panel" })
		tab:CreateText({
			name = "Egg List Panel",
			text = "Floating button (top-left). Click an egg to steal it. Works "
				.. "even while Auto Steal is on. The row is highlighted while "
				.. "being stolen.",
		})
		tab:CreateToggle({
			name = "Show Egg Panel",
			value = true,
			flag = "EggPanel",
			callback = function(on)
				BX.try("farm.eggPanel", function()
					panel.show(on and true or false)
				end)
			end,
		})
		tab:CreateSection({ name = "Egg Filters" })
		local areaRows = filter.areaOptions()
		local areaLabels
		areaLabels, areaIds = labelsAndMap(areaRows)
		tab:CreateDropdown({
			name = "Areas",
			options = #areaLabels > 0 and areaLabels or { "No areas found" },
			multiSelect = true,
			flag = "FarmAreas",
			callback = function(picked)
				filter.setAreas(idsFor(picked, areaIds))
			end,
		})
		local rarityRows = filter.rarityOptions()
		local rarityLabels
		rarityLabels, rarityIds = labelsAndMap(rarityRows)
		tab:CreateDropdown({
			name = "Rarities",
			options = #rarityLabels > 0 and rarityLabels or { "No rarities found" },
			multiSelect = true,
			flag = "FarmRarities",
			callback = function(picked)
				filter.setRarities(idsFor(picked, rarityIds))
			end,
		})
		tab:CreateDropdown({
			name = "Target By",
			options = filter.targetByOptions(),
			currentOption = "Income",
			flag = "FarmTargetBy",
			callback = function(v)
				filter.setTargetBy(type(v) == "table" and v[1] or v)
			end,
		})
		tab:CreateButton({
			name = "Refresh Eggs",
			callback = function()
				eggs.invalidate("farm refresh")
				eggs.list({}, true)
				local n = filter.matchCount()
				win.notify("Farm", n .. " eggs match your filters", 3)
				if not statusSc then
					paintStatus(("%d eggs match your filters"):format(n))
				end
			end,
		})
		tab:CreateSection({ name = "ESP" })
		tab:CreateToggle({
			name = "Egg ESP",
			value = false,
			callback = function(on)
				BX.try("farm.eggEsp", function()
					BX.require("features.esp.eggs").setEnabled(on)
				end)
			end,
		})
		tab:CreateToggle({
			name = "Plot ESP",
			value = false,
			callback = function(on)
				BX.try("farm.plotEsp", function()
					BX.require("features.esp.plot").setEnabled(on)
				end)
			end,
		})
		tab:CreateSection({ name = "Anti Treadmill" })
		tab:CreateToggle({
			name = "Anti Treadmill",
			description = "Keeps you OFF the belt during a run",
			value = true,
			flag = "AntiTreadmill",
			callback = function(on)
				tread.setEnabled(on and true or false)
			end,
		})
		tab:CreateSection({ name = "Pets" })
		tab:CreateButton({
			name = "Equip Best Pets",
			callback = function()
				local ok, msg = pets.equipBest()
				win.notify("Pets", tostring(msg), ok and 3 or 4)
			end,
		})
		auto.onStart(function(_, whose)
			if whose and whose ~= "farm" then
				return
			end
			task.spawn(function()
				BX.try("farm.toggleOn", function()
					watchStatus(true)
					if autoToggle and autoToggle.Set then
						selfAuto = selfAuto + 1
						autoToggle:Set(true)
					end
				end)
			end)
		end)
		auto.onStop(function(_, whose)
			if whose and whose ~= "farm" then
				return
			end
			task.spawn(function()
				BX.try("farm.toggleOff", function()
					watchStatus(false)
					-- Clear the egg panel highlight when the run ends.
					BX.try("farm.clearPanelActive", function()
						BX.require("ui.eggpanel").clearActive()
					end)
					if autoToggle and autoToggle.Set then
						selfAuto = selfAuto + 1
						autoToggle:Set(false)
					end
				end)
			end)
		end)
		log.info("farm tab built")
		return M
	end
	return M
end)

-- =============================================================================
-- ui/tabs/event.lua
-- =============================================================================

BX.module("ui.tabs.event", function(BX)
	local boss = BX.require("features.boss")
	local fight = BX.require("features.bossfight")
	local rift = BX.require("features.rift")
	local auto = BX.require("features.autosteal")
	local win = BX.require("ui.window")
	local M = {}
	local K = { PAINT = 1.0 }
	local sc = nil
	local bossLine, fightLine, riftLine, petDrop, autoRiftToggle, fightToggle
	local suppressDrop, selfAuto = 0, 0
	local lastOptSig = nil
	local painted = {}
	local function say(msg, secs)
		win.notify("Event", tostring(msg), secs or 3)
	end
	local function paint(el, st)
		if not el then
			return
		end
		local last = painted[el]
		if not last then
			last = {}
			painted[el] = last
		end
		if st.title and st.title ~= last.title then
			if BX.try("event.setTitle", function()
				el:SetTitle(st.title)
			end) then
				last.title = st.title
			end
		end
		if st.body ~= last.body then
			if BX.try("event.setBody", function()
				el:Set(st.body)
			end) then
				last.body = st.body
			end
		end
	end
	local function repaintBoss()
		paint(bossLine, boss.status())
		paint(fightLine, fight.status())
	end
	local function repaintRift()
		paint(riftLine, rift.status())
		if not petDrop then
			return
		end
		local opts = rift.options()
		local sig = table.concat(opts, "\1")
		if sig == lastOptSig then
			return
		end
		lastOptSig = sig
		BX.try("event.refreshDrop", function()
			suppressDrop = suppressDrop + 1
			petDrop:Refresh(opts)
		end)
	end
	function M.build(tab)
		if not tab then
			return M
		end
		tab:CreateSection({ name = "Boss" })
		bossLine = tab:CreateText({ name = "Abyss Overlord", text = "Reading..." })
		tab:CreateButton({
			name = "Enter the boss world",
			callback = function()
				if not boss.isOn() then
					boss.setEnabled(true)
				end
				task.spawn(function()
					BX.try("event.enter", function()
						local ok, why = boss.enter()
						say(why, ok and 3 or 4)
					end)
				end)
			end,
		})
		tab:CreateToggle({
			name = "Auto enter",
			value = false,
			callback = function(v)
				v = v and true or false
				if v and not boss.isOn() then
					boss.setEnabled(true)
				end
				boss.setAutoEnter(v)
				say("Auto enter " .. (v and "ON" or "OFF"))
			end,
		})
		fightToggle = tab:CreateToggle({
			name = "Auto fight",
			value = false,
			callback = function(v)
				v = v and true or false
				fight.setEnabled(v)
				say("Auto fight " .. (v and "ON" or "OFF"))
			end,
		})
		fightLine = tab:CreateText({ name = "Auto fight", text = "off" })
		tab:CreateButton({
			name = "Claim mastery rewards",
			callback = function()
				task.spawn(function()
					BX.try("event.claim", function()
						local n, msg = boss.claimMilestones()
						say(msg, n > 0 and 3 or 4)
					end)
				end)
			end,
		})
		tab:CreateSection({ name = "Rift" })
		riftLine = tab:CreateText({ name = "Rift", text = "reading..." })
		petDrop = tab:CreateDropdown({
			name = "Rift pet",
			options = { rift.K.NONE_LABEL },
			currentOption = rift.K.NONE_LABEL,
			callback = function(v)
				if suppressDrop > 0 then
					suppressDrop = suppressDrop - 1
					return
				end
				if not rift.isOn() then
					rift.setEnabled(true)
				end
				local picked = type(v) == "table" and v[1] or v
				local id = rift.idForLabel(picked)
				rift.setPick(id)
				if id then
					say("Rift pet: " .. rift.petName(id))
				end
			end,
		})
		tab:CreateButton({
			name = "Refresh",
			callback = function()
				if not rift.isOn() then
					rift.setEnabled(true)
				end
				if not boss.isOn() then
					boss.setEnabled(true)
				end
				boss.refresh()
				task.spawn(function()
					BX.try("event.riftRefresh", function()
						rift.refresh("refresh button")
						local out = rift.onField()
						if #out > 0 then
							local names = {}
							for _, id in ipairs(out) do
								names[#names + 1] = rift.petName(id)
							end
							say("Rift: " .. table.concat(names, ", "), 4)
						else
							say("Rift: none out", 3)
						end
					end)
				end)
			end,
		})
		autoRiftToggle = tab:CreateToggle({
			name = "Auto steal rift pets",
			value = false,
			callback = function(v)
				if not v then
					if selfAuto > 0 then
						selfAuto = selfAuto - 1
						return
					end
					if auto.isRunning() and auto.owner() == "rift" then
						auto.setEnabled(false, "rift")
					end
					say("Rift auto OFF")
					return
				end
				if not rift.isOn() then
					rift.setEnabled(true)
				end
				auto.setOptions("rift", { pick = rift.pickTarget, continuous = true })
				auto.setEnabled(true, "rift")
				say("Rift auto ON")
			end,
		})
		tab:CreateToggle({
			name = "Auto trade-in",
			value = false,
			callback = function(v)
				v = v and true or false
				rift.setAutoTrade(v)
				say("Auto trade-in " .. (v and "ON" or "OFF"))
			end,
		})
		rift.onTrade(function(r)
			if r == "traded" then
				say("Rift: traded in", 5)
			elseif r ~= "revealed" then
				say("Rift trade-in " .. tostring(r), 6)
			end
		end)
		sc = BX.scope("ui.tabs.event")
		sc:loop("paint", K.PAINT, function()
			repaintBoss()
			repaintRift()
		end)
		boss.setEnabled(true)
		rift.setEnabled(true)
		auto.onStop(function(_, whose)
			if whose and whose ~= "rift" then
				return
			end
			task.spawn(function()
				BX.try("event.riftAutoOff", function()
					if autoRiftToggle and autoRiftToggle.Set then
						selfAuto = selfAuto + 1
						autoRiftToggle:Set(false)
					end
				end)
			end)
		end)
		return M
	end
	return M
end)

-- =============================================================================
-- ui/tabs/misc.lua
-- =============================================================================

BX.module("ui.tabs.misc", function(BX)
	local servers = BX.require("features.misc.servers")
	local hook = BX.require("features.misc.webhook")
	local fps = BX.require("features.fps")
	local win = BX.require("ui.window")
	local M = {}
	local function say(title, ok, msg)
		win.notify(title, tostring(msg), ok and 3 or 4)
	end
	function M.build(tab)
		if not tab then
			return M
		end
		tab:CreateSection({ name = "Performance" })
		tab:CreateToggle({
			name = "FPS Boost",
			value = true,
			callback = function(on)
				on = on and true or false
				if not on then
					fps.userTurnedOff = true
				end
				BX.try("misc.fpsToggle", function()
					fps.setEnabled(on)
				end)
			end,
		})
		tab:CreateSection({ name = "Servers" })
		tab:CreateButton({
			name = "Lowest Server",
			callback = function()
				local ok, msg = servers.lowestServer()
				say("Servers", ok, msg)
			end,
		})
		tab:CreateButton({
			name = "Server Hop",
			callback = function()
				local ok, msg = servers.hop()
				say("Servers", ok, msg)
			end,
		})
		tab:CreateSection({ name = "Webhooks" })
		local exec = BX.require("core.exec")
		tab:CreateToggle({
			name = "Enable Webhook",
			value = false,
			flag = "WebhookOn",
			callback = function(on)
				BX.try("misc.webhookToggle", function()
					hook.setEnabled(on)
				end)
				if on and not exec.can.request then
					win.notify("Webhook", "Not supported by this executor", 6)
				end
			end,
		})
		tab:CreateInput({
			name = "Webhook URL",
			placeholder = "https://discord.com/api/webhooks/...",
			callback = function(v)
				local ok, msg = hook.setUrl(v)
				if not ok then
					say("Webhooks", false, msg)
				end
			end,
		})
		tab:CreateButton({
			name = "Test Webhook",
			callback = function()
				local ok, msg = hook.test()
				say("Webhooks", ok, msg)
			end,
		})
		return M
	end
	return M
end)

-- =============================================================================
-- ui/tabs/config.lua - now with Auto-Save toggle
-- =============================================================================

BX.module("ui.tabs.config", function(BX)
	local prof = BX.require("core.profiles")
	local look = BX.require("features.misc.appearance")
	local status = BX.require("ui.status")
	local win = BX.require("ui.window")
	local M = {}
	local nameBox, loadDrop, autoDrop, bgInput, statusLine
	local NONE = "None"
	local function say(ok, msg)
		win.notify("Config", tostring(msg), ok and 3 or 4)
		BX.try("config.status", function()
			if statusLine then
				statusLine:Set(tostring(msg))
			end
		end)
	end
	local function options()
		local list = prof.list()
		local out = { NONE }
		for _, n in ipairs(list) do
			out[#out + 1] = n
		end
		return out
	end
	local function refreshLists()
		local opts = options()
		BX.try("config.refreshLists", function()
			if loadDrop and loadDrop.Refresh then
				loadDrop:Refresh(opts)
			end
			if autoDrop and autoDrop.Refresh then
				autoDrop:Refresh(opts)
			end
		end)
		return opts
	end
	local function boxValue(box)
		if not box then
			return ""
		end
		local v = box.CurrentValue
		if v == nil or v == "" then
			v = box.Value
		end
		if v == nil or v == "" then
			v = box.value
		end
		if (v == nil or v == "") and typeof(box.input) == "Instance" then
			pcall(function()
				v = box.input.Text
			end)
		end
		return tostring(v or "")
	end
	local function pick(v)
		local s = type(v) == "table" and v[1] or v
		s = tostring(s or "")
		if s == NONE then
			return ""
		end
		return s
	end
	function M.build(tab)
		if not tab then
			return M
		end
		tab:CreateSection({ name = "Auto-Save" })
		tab:CreateText({
			name = "Auto-Save",
			text = "Saves your settings automatically every 30 seconds and loads "
				.. "them when you re-execute. Use the buttons below to save or "
				.. "clear the auto-save slot.",
		})
		tab:CreateToggle({
			name = "Enable Auto-Save",
			value = prof.autoSaveOn(),
			flag = "AutoSaveCfg",
			callback = function(on)
				local ok, msg = prof.setAutoSave(on and true or false)
				say(ok, msg)
				-- If enabled now, save once immediately so a restart is
				-- guaranteed to restore something.
				if on then
					BX.try("config.autoSaveNow", function()
						prof.saveAuto()
					end)
				end
			end,
		})
		tab:CreateButton({
			name = "Save Now",
			callback = function()
				if not prof.available() then
					say(false, "Executor cannot save files")
					return
				end
				local ok = prof.saveAuto()
				say(ok, ok and "Auto-save updated" or "Could not save")
			end,
		})
		tab:CreateButton({
			name = "Clear Auto-Save",
			callback = function()
				if not prof.available() then
					say(false, "Executor cannot save files")
					return
				end
				local ok, msg = prof.delete("__autosave")
				say(ok, msg)
			end,
		})

		tab:CreateSection({ name = "On-screen Status" })
		tab:CreateText({
			name = "Status HUD",
			text = "Shows what Auto Steal is doing, when the boss opens, " .. "and the rift rotation.",
		})
		tab:CreateToggle({
			name = "Show Status HUD",
			value = false,
			flag = "StatusHUD",
			callback = function(on)
				local ok = status.show(on and true or false)
				if not ok and on then
					say(false, "Could not build the status panel")
				end
			end,
		})
		tab:CreateSection({ name = "Appearance" })
		tab:CreateDropdown({
			name = "Theme",
			options = look.themes(),
			flag = "Theme",
			callback = function(v)
				local ok, msg = look.setTheme(pick(v))
				if not ok then
					say(false, msg)
				end
			end,
		})
		bgInput = tab:CreateInput({
			name = "Background Image ID",
			placeholder = "0000000000",
			flag = "Background",
			callback = function(v)
				local ok, msg = look.setBackground(v)
				say(ok, msg)
			end,
		})
		tab:CreateButton({
			name = "Clear Background",
			callback = function()
				local ok, msg = look.clearBackground()
				BX.try("config.clearInput", function()
					if bgInput and bgInput.Set then
						bgInput:Set("")
					end
				end)
				say(ok, msg)
			end,
		})

		tab:CreateSection({ name = "Profiles" })
		if not prof.available() then
			tab:CreateText({
				name = "Profiles",
				text = "Config saving is not supported by this executor.",
			})
			return M
		end
		nameBox = tab:CreateInput({ name = "Profile Name", placeholder = "my settings", callback = function() end })
		statusLine = tab:CreateText({ name = "Status", text = "Type a name and press Save Profile" })
		tab:CreateButton({
			name = "Save Profile",
			callback = function()
				local ok, msg = prof.save(boxValue(nameBox))
				if ok then
					refreshLists()
				end
				say(ok, msg)
			end,
		})
		loadDrop = tab:CreateDropdown({
			name = "Load Profile",
			options = options(),
			currentOption = NONE,
			callback = function(v)
				local name = pick(v)
				if name == "" then
					return
				end
				local ok, msg = prof.load(name)
				say(ok, msg)
			end,
		})
		tab:CreateButton({
			name = "Refresh Profiles",
			callback = function()
				prof.refresh()
				local opts = refreshLists()
				say(true, (#opts - 1) .. " profiles")
			end,
		})
		tab:CreateButton({
			name = "Delete Profile",
			callback = function()
				local ok, msg = prof.delete(boxValue(nameBox))
				if ok then
					refreshLists()
				end
				say(ok, msg)
			end,
		})
		autoDrop = tab:CreateDropdown({
			name = "Auto Load Profile",
			options = options(),
			currentOption = prof.autoLoadName() or NONE,
			callback = function(v)
				local ok, msg = prof.setAutoLoad(pick(v))
				say(ok, msg)
			end,
		})
		return M
	end
	return M
end)

-- =============================================================================
-- features/movement.lua
-- =============================================================================

BX.module("features.movement", function(BX)
	local svc = BX.require("core.services")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local rs = BX.require("core.restore")
	local M = {}
	local RunService, Players = svc.RunService, svc.Players
	local K = {
		GROUND_OFFSET = 3,
		CRUISE_UP = 18,
		RAMP_FRAC = 0.12,
		RAMP_MAX = 220,
		RAMP_MIN = 40,
		START_SPEED = 0.45,
		SPEED_RAMP_FRAC = 0.28,
		SLOW_RADIUS = 50,
		SLOW_SPEED = 260,
		ARRIVE = 5,
		MAX_DT = 0.05,
		MAX_FRAME = 0.25,
		MAX_DEBT = 2.0,
		MAX_STEP = 20,
		SPEED = 1200,
		SPEED_NOSPOOF = 500,
		NOSPOOF_FLOOR = 300,
		NOSPOOF_CONVERGE = 40,
		DROP_SPEED = 400,
		SPOOF_HEADROOM = 1.35,
		WS_MAX = 4000,
		WALKSPEED_SANE_MIN = 40,
		RELOC_CLAMP_FOR = 6,
		RELOC_CLAMP_RATIO = 1.04,
		TP_SETTLE = 0.35,
		TP_LANDED = 30,
	}
	local ac = nil
	function M.setAnticheat(adapter)
		ac = adapter
	end
	local function acGet(name)
		local f = ac and ac[name]
		return type(f) == "function" and f or nil
	end
	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	groundParams.IgnoreWater = true
	local filterDirty = true
	local scratchIgnore = {}
	local function rebuildFilter()
		local n = 0
		for i = #scratchIgnore, 1, -1 do
			scratchIgnore[i] = nil
		end
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then
				n = n + 1
				scratchIgnore[n] = pl.Character
			end
		end
		groundParams.FilterDescendantsInstances = scratchIgnore
		filterDirty = false
	end
	local function solidGroundY(pos)
		if filterDirty then
			rebuildFilter()
		end
		local origin = pos + Vector3.new(0, 80, 0)
		local dir = Vector3.new(0, -700, 0)
		local extra = nil
		for _ = 1, 15 do
			local r = workspace:Raycast(origin, dir, groundParams)
			if not r then
				break
			end
			if r.Instance.CanCollide then
				if extra then
					groundParams.FilterDescendantsInstances = scratchIgnore
				end
				return r.Position.Y + K.GROUND_OFFSET
			end
			extra = extra or table.clone(scratchIgnore)
			extra[#extra + 1] = r.Instance
			groundParams.FilterDescendantsInstances = extra
		end
		if extra then
			groundParams.FilterDescendantsInstances = scratchIgnore
		end
		return nil
	end
	local function groundOr(pos, fallback)
		return solidGroundY(pos) or fallback
	end
	M.groundY = solidGroundY
	local noclipSc, noclipWas, noclipParts, noclipFor = nil, nil, nil, nil
	local function noclipStep()
		local char = ch.get()
		if not char then
			return
		end
		if noclipFor ~= char or not noclipParts then
			noclipParts, noclipFor, noclipWas = {}, char, {}
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					noclipParts[#noclipParts + 1] = p
					noclipWas[p] = p.CanCollide
				end
			end
		end
		for i = 1, #noclipParts do
			local p = noclipParts[i]
			if p.Parent and p.CanCollide then
				p.CanCollide = false
			end
		end
	end
	function M.noclip(on)
		if on then
			if noclipSc then
				return
			end
			rs.onRestore("movement.noclip", function()
				M.noclip(false)
			end)
			noclipSc = BX.scope("features.movement.noclip")
			noclipSc:onFrame("noclip", RunService.Stepped, noclipStep)
		else
			if not noclipSc then
				return
			end
			noclipSc:destroy()
			noclipSc = nil
			if noclipWas then
				for part, was in pairs(noclipWas) do
					if part.Parent then
						pcall(function()
							part.CanCollide = was
						end)
					end
				end
			end
			noclipParts, noclipWas, noclipFor = nil, nil, nil
		end
	end
	local brk = { low = nil, high = nil, speed = nil, legSpeed = nil, legRelocs = nil }
	function M.outboundSpeed()
		return K.SPEED
	end
	local function writeStep(char, hum, hrp, dest, look)
		if hum then
			hum:Move(Vector3.zero, false)
		end
		char:PivotTo(CFrame.lookAt(dest, dest + look))
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	function M.travel(opts)
		local pos = opts.to
		local tag = opts.tag or "leg"
		local arrive = opts.arrive or K.ARRIVE
		local carrying = opts.carrying and true or false
		local cancel = opts.cancel
		local char = ch.get()
		local hrp = ch.root()
		local hum = ch.humanoid()
		if not char or not hrp then
			return false, { reason = "no-character" }
		end
		local speed = math.max(opts.speed or K.SPEED_NOSPOOF, 40)
		local start = hrp.Position
		local flatTotal = Vector3.new(pos.X - start.X, 0, pos.Z - start.Z).Magnitude
		if flatTotal < 1 then
			return true, { reason = "already-there", distance = 0 }
		end
		local startGround = groundOr(start, start.Y)
		local endGround = groundOr(pos, pos.Y)
		local landY = endGround
		local cruiseY = math.max(startGround, endGround, start.Y, pos.Y) + K.CRUISE_UP
		local ramp = math.clamp(flatTotal * K.RAMP_FRAC, K.RAMP_MIN, K.RAMP_MAX)
		if ramp * 2 > flatTotal * 0.9 then
			ramp = flatTotal * 0.45
		end
		if flatTotal < K.RAMP_MIN * 2 then
			cruiseY = math.max(start.Y, pos.Y)
		end
		local wasPS = hum and hum.PlatformStand or false
		if hum then
			rs.remember("movement.platformStand", function()
				return hum.PlatformStand
			end, function(v)
				hum.PlatformStand = v
			end)
			hum.PlatformStand = true
		end
		local spoof = (not carrying) and hum and true or false
		local claimWS, savedWS = nil, nil
		if spoof then
			rs.remember("movement.walkSpeed", function()
				return hum.WalkSpeed
			end, function(v)
				hum.WalkSpeed = v
			end)
			savedWS = hum.WalkSpeed
			claimWS = math.clamp(speed * K.SPOOF_HEADROOM, 16, K.WS_MAX)
			hum.WalkSpeed = claimWS
		end
		if not carrying and not spoof then
			brk.legSpeed = speed
			local count = acGet("relocateCount")
			brk.legRelocs = count and count() or 0
		end
		local t0 = os.clock()
		local deadline = t0 + math.max(flatTotal / speed, 0.3) * 3 + 6
		local lastT = t0
		local arcDebt = 0
		local ok, reason = false, "timeout"
		while os.clock() < deadline do
			if cancel and cancel() then
				reason = "cancelled"
				break
			end
			local liveChar = ch.get()
			if liveChar ~= char then
				reason = "respawned"
				break
			end
			local hh = ch.root()
			if not hh then
				reason = "lost-root"
				break
			end
			local now = os.clock()
			local raw = now - lastT
			lastT = now
			arcDebt = math.min(arcDebt + raw, K.MAX_DEBT)
			local frameDt = math.min(arcDebt, K.MAX_FRAME)
			arcDebt = arcDebt - frameDt
			local subSteps = math.max(1, math.ceil(frameDt / K.MAX_DT))
			local dt = frameDt / subSteps
			local flat = Vector3.new(pos.X - hh.Position.X, 0, pos.Z - hh.Position.Z)
			local rem = flat.Magnitude
			if rem <= arrive then
				ok, reason = true, "arrived"
				break
			end
			local done = math.max(flatTotal - rem, 0)
			local want
			local speedRamp = math.max(ramp * K.SPEED_RAMP_FRAC, 1)
			if rem <= K.SLOW_RADIUS then
				want = math.min(K.SLOW_SPEED, speed)
			elseif rem < ramp then
				local f = rem / ramp
				want = math.max(speed * f, math.min(K.SLOW_SPEED, speed))
			elseif done < speedRamp then
				want = speed * (K.START_SPEED + (1 - K.START_SPEED) * (done / speedRamp))
			else
				want = speed
			end
			local lastReloc = acGet("lastRelocateAt")
			local relocAt = lastReloc and lastReloc() or nil
			if relocAt and (os.clock() - relocAt) < K.RELOC_CLAMP_FOR then
				local allowFn = acGet("allowance")
				local allow = allowFn and allowFn() or nil
				if not allow and hum and hum.WalkSpeed > K.WALKSPEED_SANE_MIN then
					allow = hum.WalkSpeed * K.RELOC_CLAMP_RATIO
				end
				if allow and allow > 0 and want > allow then
					want = allow
				end
			end
			local wantY
			if done < ramp then
				wantY = start.Y + (cruiseY - start.Y) * (done / ramp)
			elseif rem < ramp then
				wantY = landY + (cruiseY - landY) * (rem / ramp)
			else
				wantY = cruiseY
			end
			local arrived = false
			for _ = 1, subSteps do
				local hp = hh.Position
				local f2 = Vector3.new(pos.X - hp.X, 0, pos.Z - hp.Z)
				local rem2 = f2.Magnitude
				if rem2 <= arrive then
					arrived = true
					break
				end
				local step = math.min(rem2, want * dt, K.MAX_STEP)
				local unit = f2.Unit
				local nxt = hp + unit * step
				pcall(writeStep, char, hum, hh, Vector3.new(nxt.X, wantY, nxt.Z), unit)
			end
			if arrived then
				ok, reason = true, "arrived"
				break
			end
			if spoof then
				if hum.WalkSpeed < claimWS - 1 then
					hum.WalkSpeed = claimWS
				end
				pcall(function()
					hh.AssemblyLinearVelocity = Vector3.zero
				end)
			end
			RunService.Heartbeat:Wait()
		end
		local hz = ch.root()
		if hz and ch.get() == char then
			local gy = solidGroundY(hz.Position)
			if gy and math.abs(hz.Position.Y - gy) > 1 then
				pcall(function()
					char:PivotTo(CFrame.new(hz.Position.X, gy, hz.Position.Z))
				end)
			end
		end
		if spoof and hum and hum.Parent then
			local legalFn = acGet("legalWalkSpeed")
			local legal = legalFn and legalFn() or savedWS or 16
			pcall(function()
				hum.WalkSpeed = math.max(legal, 16)
			end)
		end
		if hum and hum.Parent then
			hum.PlatformStand = wasPS
			local hstate = hum:GetState()
			if
				hstate == Enum.HumanoidStateType.Freefall
				or hstate == Enum.HumanoidStateType.PlatformStanding
				or hstate == Enum.HumanoidStateType.Physics
			then
				pcall(function()
					hum:ChangeState(Enum.HumanoidStateType.Landed)
				end)
			end
		end
		if hz then
			hz.AssemblyLinearVelocity = Vector3.zero
			hz.AssemblyAngularVelocity = Vector3.zero
		end
		local gap = hz and Vector3.new(pos.X - hz.Position.X, 0, pos.Z - hz.Position.Z).Magnitude or math.huge
		return (ok or gap <= arrive + 4),
			{ reason = reason, distance = flatTotal, elapsed = os.clock() - t0, gap = gap }
	end
	function M.descend(tag)
		local char, h = ch.get(), ch.root()
		if not char or not h then
			return false
		end
		local hum = ch.humanoid()
		local gy = solidGroundY(h.Position)
		if not gy then
			if hum then
				hum.PlatformStand = false
			end
			return false
		end
		local x, z = h.Position.X, h.Position.Z
		local from = h.Position.Y
		if from - gy <= 2 then
			if hum then
				hum.PlatformStand = false
			end
			return true
		end
		if hum then
			hum.PlatformStand = true
		end
		local t0 = os.clock()
		local dur = math.clamp((from - gy) / math.max(K.DROP_SPEED, 50), 0.05, 1.2)
		while os.clock() - t0 < dur do
			if ch.get() ~= char then
				break
			end
			local hh = ch.root()
			if not hh then
				break
			end
			local f = (os.clock() - t0) / dur
			local y = from + (gy - from) * f
			pcall(function()
				char:PivotTo(CFrame.new(x, y, z) * (hh.CFrame - hh.CFrame.Position))
				hh.AssemblyLinearVelocity = Vector3.zero
			end)
			RunService.Heartbeat:Wait()
		end
		if ch.get() == char then
			pcall(function()
				char:PivotTo(CFrame.new(x, gy, z))
			end)
		end
		if hum and hum.Parent then
			hum.PlatformStand = false
			pcall(function()
				hum:ChangeState(Enum.HumanoidStateType.Landed)
			end)
		end
		return true
	end
	local sc = BX.scope("features.movement")
	sc:connect(Players.PlayerAdded, function()
		filterDirty = true
	end)
	sc:connect(Players.PlayerRemoving, function()
		filterDirty = true
	end)
	ch.onSpawn(sc, "movement.respawn", function()
		filterDirty = true
		noclipParts, noclipWas, noclipFor = nil, nil, nil
	end)
	function M.reset()
		M.noclip(false)
	end
	return M
end)

-- =============================================================================
-- features/humanoid.lua
-- =============================================================================

BX.module("features.humanoid", function(BX)
	local ch = BX.require("core.character")
	local rs = BX.require("core.restore")
	local M = {}
	local SWAP_ATTR = "BlyxoStealHum"
	M.SWAP_ATTR = SWAP_ATTR
	local sc = nil
	local swapPrior = nil
	local function applyStates(prior)
		local hum = ch.humanoid()
		if not hum or hum:GetAttribute(SWAP_ATTR) ~= true then
			return
		end
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, prior.dead)
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, prior.fallingDown)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, prior.ragdoll)
		hum.BreakJointsOnDeath = prior.breakJoints
	end
	function M.swap(char)
		char = char or ch.get()
		if not char then
			return false
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return false
		end
		if hum:GetAttribute(SWAP_ATTR) == true then
			return true
		end
		local prior = {
			dead = hum:GetStateEnabled(Enum.HumanoidStateType.Dead),
			fallingDown = hum:GetStateEnabled(Enum.HumanoidStateType.FallingDown),
			ragdoll = hum:GetStateEnabled(Enum.HumanoidStateType.Ragdoll),
			breakJoints = hum.BreakJointsOnDeath,
		}
		local ok = BX.try("humanoid.swap", function()
			local hs = char:FindFirstChild("Health")
			if hs then
				hs:Destroy()
			end
			hum.BreakJointsOnDeath = false
			hum.Archivable = true
			local clone = hum:Clone()
			if not clone then
				error("clone failed")
			end
			clone.Name = "Humanoid"
			clone:SetAttribute(SWAP_ATTR, true)
			clone:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			clone:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			clone:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			clone.Health = hum.MaxHealth
			if not clone:FindFirstChildOfClass("Animator") then
				Instance.new("Animator").Parent = clone
			end
			hum:Destroy()
			clone.Parent = char
			if workspace.CurrentCamera then
				workspace.CurrentCamera.CameraSubject = clone
			end
			local animate = char:FindFirstChild("Animate")
			if animate then
				local ac = animate:Clone()
				animate:Destroy()
				ac.Parent = char
				ac.Disabled = false
			end
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("Motor6D") then
					d.Enabled = true
				end
			end
		end)
		if ok then
			rs.permanent("humanoid.swap", "Humanoid replaced")
			swapPrior = prior
			rs.remember("humanoid.states", function()
				return prior
			end, function(v)
				applyStates(v)
			end)
		end
		return ok and true or false
	end
	function M.arm()
		if sc then
			return true
		end
		sc = BX.scope("features.humanoid")
		M.swap()
		ch.onSpawn(sc, "humanoid.reswap", function(char)
			swapPrior = nil
			M.swap(char)
		end)
		return true
	end
	function M.disarm()
		if swapPrior then
			BX.try("humanoid.restoreStates", function()
				applyStates(swapPrior)
			end)
		end
		if not sc then
			return
		end
		sc:destroy()
		sc = nil
	end
	return M
end)

-- =============================================================================
-- features/jump.lua
-- =============================================================================

BX.module("features.jump", function(BX)
	local svc = BX.require("core.services")
	local ch = BX.require("core.character")
	local st = BX.require("core.state")
	local hsw = BX.require("features.humanoid")
	local M = {}
	local sc = nil
	function M.arm()
		if sc then
			return true
		end
		sc = BX.scope("features.jump")
		sc:connect(svc.UserInputService.JumpRequest, function()
			if st.autoStealOn then
				return
			end
			local hum = ch.humanoid()
			if not hum then
				return
			end
			if hum:GetAttribute(hsw.SWAP_ATTR) ~= true then
				return
			end
			if hum.Health <= 0 then
				return
			end
			local state = hum:GetState()
			if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
				return
			end
			hum.Jump = true
		end)
		return true
	end
	function M.disarm()
		if not sc then
			return
		end
		sc:destroy()
		sc = nil
	end
	return M
end)

-- =============================================================================
-- features/antideath.lua
-- =============================================================================

BX.module("features.antideath", function(BX)
	local ch = BX.require("core.character")
	local rs = BX.require("core.restore")
	local M = {}
	local sc, saved, armedFor = nil, nil, nil
	local function applyTo(char)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return false
		end
		if armedFor == hum then
			return true
		end
		saved = {
			humanoid = hum,
			breakJoints = hum.BreakJointsOnDeath,
			deadEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Dead),
		}
		armedFor = hum
		BX.try("antideath.apply", function()
			rs.remember("antideath.breakJoints", function()
				return hum.BreakJointsOnDeath
			end, function(v)
				hum.BreakJointsOnDeath = v
			end)
			rs.remember("antideath.state.Dead", function()
				return hum:GetStateEnabled(Enum.HumanoidStateType.Dead)
			end, function(v)
				hum:SetStateEnabled(Enum.HumanoidStateType.Dead, v)
			end)
			hum.BreakJointsOnDeath = false
			hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		end)
		sc:connect(hum.HealthChanged, function(hp)
			if hp <= 0 and hum.Parent then
				hum.Health = hum.MaxHealth
			end
		end)
		sc:connect(hum.StateChanged, function(_, new)
			if new == Enum.HumanoidStateType.Dead and hum.Parent then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				hum.Health = hum.MaxHealth
			end
		end)
		if hum.Health <= 0 then
			hum.Health = hum.MaxHealth
		end
		return true
	end
	local function restore()
		local s = saved
		saved, armedFor = nil, nil
		if not s or not s.humanoid or not s.humanoid.Parent then
			return
		end
		BX.try("antideath.restore", function()
			s.humanoid.BreakJointsOnDeath = s.breakJoints
			s.humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, s.deadEnabled)
		end)
	end
	function M.arm()
		if sc then
			return true
		end
		sc = BX.scope("features.antideath")
		applyTo(ch.get())
		ch.onSpawn(sc, "antideath.rearm", function(char)
			saved, armedFor = nil, nil
			applyTo(char)
		end)
		return true
	end
	function M.disarm()
		if not sc then
			return
		end
		sc:destroy()
		sc = nil
		BX.try("antideath.reviveOnDisarm", function()
			local hum = ch.humanoid()
			if hum and hum.Parent and hum.Health <= 0 then
				hum.Health = hum.MaxHealth
			end
		end)
		restore()
	end
	return M
end)

-- =============================================================================
-- features/guard.lua
-- =============================================================================

BX.module("features.guard", function(BX)
	local svc = BX.require("core.services")
	local data = BX.require("core.data")
	local ch = BX.require("core.character")
	local rs = BX.require("core.restore")
	local M = {}
	local RunService = svc.RunService
	local K = { RISE = 150, FLAT_MULT = 2.5, FLAT_MIN = 150, JOINT_GAP = 0.25, HOLD_MAX = 2.75, HOLD_GRACE = 0.25 }
	local sc = nil
	function M.isRagdolled()
		local hum = ch.humanoid()
		if not hum then
			return false
		end
		if hum.PlatformStand then
			return true
		end
		local s = hum:GetState()
		return s == Enum.HumanoidStateType.Physics
			or s == Enum.HumanoidStateType.Ragdoll
			or s == Enum.HumanoidStateType.FallingDown
	end
	local function applyAntiRagdoll(char)
		char = char or ch.get()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return false
		end
		BX.try("guard.antiRagdoll", function()
			rs.remember("guard.state.Ragdoll", function()
				return hum:GetStateEnabled(Enum.HumanoidStateType.Ragdoll)
			end, function(v)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, v)
			end)
			rs.remember("guard.state.FallingDown", function()
				return hum:GetStateEnabled(Enum.HumanoidStateType.FallingDown)
			end, function(v)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, v)
			end)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("Motor6D") then
					d.Enabled = true
				end
			end
		end)
		return true
	end
	local dropOriginal, dropInstalled, eggStateRef = nil, false, nil
	local dropAllowed = false
	local function installDropBlock()
		if dropInstalled then
			return true
		end
		eggStateRef = eggStateRef or data.eggState()
		if not eggStateRef or type(eggStateRef.DropFieldEgg) ~= "function" then
			return false
		end
		dropOriginal = eggStateRef.DropFieldEgg
		eggStateRef.DropFieldEgg = function(reason, ...)
			if not dropAllowed then
				return
			end
			return dropOriginal(reason, ...)
		end
		dropInstalled = true
		return true
	end
	local function removeDropBlock()
		if not dropInstalled then
			return
		end
		BX.try("guard.restoreDrop", function()
			if eggStateRef and dropOriginal then
				eggStateRef.DropFieldEgg = dropOriginal
			end
		end)
		dropInstalled, dropOriginal = false, nil
	end
	function M.allowDrops(on)
		dropAllowed = on and true or false
	end
	local jointAt = 0
	local function antiHitStep()
		local hum, hrp = ch.humanoid(), ch.root()
		if not hum or not hrp then
			return
		end
		local st = hum:GetState()
		if st == Enum.HumanoidStateType.Jumping then
			return
		end
		local v = hrp.AssemblyLinearVelocity
		local flat = (v * Vector3.new(1, 0, 1)).Magnitude
		local flatCap = math.max((hum.WalkSpeed or 16) * K.FLAT_MULT, K.FLAT_MIN)
		if v.Y > K.RISE or flat > flatCap then
			local keep = Vector3.zero
			if flat > 0.001 then
				keep = (v * Vector3.new(1, 0, 1)).Unit * math.min(flat, hum.WalkSpeed or 16)
			end
			hrp.AssemblyLinearVelocity = Vector3.new(keep.X, math.min(v.Y, 0), keep.Z)
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		if
			hum.PlatformStand
			or hum.Sit
			or st == Enum.HumanoidStateType.Physics
			or st == Enum.HumanoidStateType.Ragdoll
			or st == Enum.HumanoidStateType.FallingDown
			or st == Enum.HumanoidStateType.PlatformStanding
		then
			pcall(function()
				hum.PlatformStand = false
				hum.Sit = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
			local now = os.clock()
			if now - jointAt > K.JOINT_GAP then
				jointAt = now
				local char = ch.get()
				if char then
					for _, d in ipairs(char:GetDescendants()) do
						if d:IsA("Motor6D") and not d.Enabled then
							d.Enabled = true
						end
					end
				end
			end
		end
	end
	function M.ragdollRemaining()
		local left = 0
		BX.try("guard.ragdollRemaining", function()
			local plr = svc.LocalPlayer
			local t = plr and plr:GetAttribute("RagdollEndTime")
			if type(t) == "number" then
				left = math.max(left, t - workspace:GetServerTimeNow())
			end
		end)
		return math.max(0, left)
	end
	function M.waitForServerRelease(cancel)
		local held = M.ragdollRemaining()
		if held <= 0 then
			return 0
		end
		local t0 = os.clock()
		local deadline = os.clock() + math.min(held, K.HOLD_MAX)
		while os.clock() < deadline do
			if cancel and cancel() then
				break
			end
			task.wait(0.05)
			if M.ragdollRemaining() <= 0 then
				break
			end
		end
		task.wait(K.HOLD_GRACE)
		return os.clock() - t0
	end
	function M.arm()
		if sc then
			return true
		end
		sc = BX.scope("features.guard")
		dropAllowed = false
		applyAntiRagdoll()
		installDropBlock()
		sc:onFrame("antihit", RunService.Heartbeat, antiHitStep)
		ch.onSpawn(sc, "guard.respawn", function(char)
			applyAntiRagdoll(char)
		end)
		return true
	end
	function M.disarm()
		if not sc then
			return
		end
		sc:destroy()
		sc = nil
		dropAllowed = true
		removeDropBlock()
	end
	return M
end)

-- =============================================================================
-- features/treadmill.lua
-- =============================================================================

BX.module("features.treadmill", function(BX)
	local data = BX.require("core.data")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local net = BX.require("core.net")
	local st = BX.require("core.state")
	local M = {}
	local K = { PAD = 6, Y_SLACK = 12, POLL = 1.5, AFTER_OFF = 2.0, PART_TTL = 30 }
	local PlotState = data.plotState()
	local partCache, partAt = nil, 0
	local function treadmillPart()
		local now = os.clock()
		if partCache and partCache.Parent and (now - partAt) < K.PART_TTL then
			return partCache
		end
		local found = nil
		BX.try("treadmill.resolvePart", function()
			local plot = PlotState and PlotState.ResolvePlot and PlotState.ResolvePlot()
			if type(plot) ~= "table" or not plot.PlotFolder then
				return
			end
			local p = plot.PlotFolder:FindFirstChild("TreadmillBottom", true)
			if p and p:IsA("BasePart") then
				found = p
			end
		end)
		partCache, partAt = found, now
		return found
	end
	function M.onBelt()
		local part = treadmillPart()
		local hrp = ch.root()
		if not part or not hrp then
			return false
		end
		local rel = part.CFrame:PointToObjectSpace(hrp.Position)
		local half = part.Size * 0.5
		return math.abs(rel.X) <= half.X + K.PAD and math.abs(rel.Z) <= half.Z + K.PAD and math.abs(rel.Y) <= K.Y_SLACK
	end
	local enabled = true
	local sc = nil
	local function step()
		if not enabled then
			return
		end
		if st.stayOnTreadmill then
			return
		end
		if not M.onBelt() then
			return
		end
		net.call("RF/Treadmill/AskDoff")
		task.wait(dev.scale(K.AFTER_OFF))
	end
	function M.arm()
		if sc then
			return true
		end
		sc = BX.scope("features.treadmill")
		sc:loop("watch", dev.scale(K.POLL), step)
		ch.onSpawn(sc, "treadmill.respawn", function()
			partCache, partAt = nil, 0
		end)
		return true
	end
	function M.disarm()
		if not sc then
			return
		end
		sc:destroy()
		sc = nil
		partCache, partAt = nil, 0
	end
	function M.setEnabled(on)
		enabled = on and true or false
		if enabled then
			M.arm()
		end
	end
	return M
end)

-- =============================================================================
-- features/farm/filter.lua
-- =============================================================================

BX.module("features.farm.filter", function(BX)
	local data = BX.require("core.data")
	local eggs = BX.require("features.eggs")
	local M = {}
	local areas, rarities, targetBy = {}, {}, "Income"
	local function count(set)
		local n = 0
		for _ in pairs(set) do
			n = n + 1
		end
		return n
	end
	local function toSet(list)
		local set = {}
		if type(list) == "table" then
			for _, v in pairs(list) do
				if v ~= nil and v ~= "" then
					set[tostring(v)] = true
				end
			end
		elseif type(list) == "string" and list ~= "" then
			set[list] = true
		end
		return set
	end
	function M.areaOptions()
		local out = {}
		for id, entry in pairs(data.areasDir() or {}) do
			out[#out + 1] = {
				id = tostring(id),
				label = tostring((type(entry) == "table" and entry.DisplayName) or id),
			}
		end
		table.sort(out, function(a, b)
			return a.label < b.label
		end)
		return out
	end
	function M.rarityOptions()
		local seen, rows = {}, {}
		for _, entry in pairs(data.assetsDir() or {}) do
			local r = type(entry) == "table" and entry.Rarity or nil
			if type(r) == "table" then
				local id = tostring(r._id or r.DisplayName or "")
				if id ~= "" and not seen[id] then
					seen[id] = true
					rows[#rows + 1] = {
						id = id,
						label = tostring(r.DisplayName or id),
						num = tonumber(r.RarityNumber) or 0,
					}
				end
			end
		end
		table.sort(rows, function(a, b)
			if a.num ~= b.num then
				return a.num < b.num
			end
			return a.label < b.label
		end)
		return rows
	end
	function M.targetByOptions()
		return { "Income", "Weight" }
	end
	function M.setAreas(list)
		areas = toSet(list)
	end
	function M.setRarities(list)
		rarities = toSet(list)
	end
	function M.setTargetBy(v)
		targetBy = (v == "Weight") and "Weight" or "Income"
	end
	function M.selection()
		return { areas = areas, rarities = rarities, targetBy = targetBy }
	end
	function M.describe()
		return ("%s areas, %s rarities, by %s"):format(
			count(areas) == 0 and "all" or tostring(count(areas)),
			count(rarities) == 0 and "any" or tostring(count(rarities)),
			targetBy
		)
	end
	local function rarityOk(e)
		if count(rarities) == 0 then
			return true
		end
		local id = tostring(e.rarityId or e.rarity or "")
		local label = tostring(e.rarity or "")
		return rarities[id] == true or rarities[label] == true
	end
	local function wanted(e)
		if count(areas) > 0 and not areas[tostring(e.areaId)] then
			return false
		end
		return rarityOk(e)
	end
	local last = { text = "waiting", n = 0, field = 0 }
	function M.status()
		return last
	end
	function M.pick()
		local list = eggs.list()
		local field = list and #list or 0
		if field == 0 then
			last = { text = "no takeable eggs on the field", n = 0, field = 0 }
			return nil, "field=0"
		end
		local afterArea, afterRarity = 0, 0
		local best, bestKey
		for _, e in ipairs(list) do
			local areaOk = (count(areas) == 0) or areas[tostring(e.areaId)] == true
			if areaOk then
				afterArea = afterArea + 1
				if rarityOk(e) then
					afterRarity = afterRarity + 1
					local key = (targetBy == "Weight") and (tonumber(e.kg) or 0) or (tonumber(e.value) or 0)
					if not best or key > bestKey then
						best, bestKey = e, key
					end
				end
			end
		end
		if best then
			last = {
				text = ("%d of %d eggs match  \u{B7}  next: %s"):format(afterRarity, field, tostring(best.name)),
				n = afterRarity,
				field = field,
			}
			return best
		end
		last = { text = ("0 of %d eggs match your filters"):format(field), n = 0, field = field }
		return nil, "nothing matches the filter"
	end
	function M.matchCount()
		local list = eggs.list()
		local n = 0
		for _, e in ipairs(list or {}) do
			if wanted(e) then
				n = n + 1
			end
		end
		return n
	end
	return M
end)

-- =============================================================================
-- features/farm/treadmill_on.lua
-- =============================================================================

BX.module("features.farm.treadmill_on", function(BX)
	local data = BX.require("core.data")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local net = BX.require("core.net")
	local st = BX.require("core.state")
	local M = {}
	local K = { POLL = 1.0, DRIFT = 6, STEP_OFF = 14 }
	local PlotState = data.plotState()
	local sc, enabled, autoHold = nil, false, false
	function M.isOn()
		return enabled
	end
	function M.spot()
		local slot
		BX.try("farm.treadmill.slot", function()
			slot = PlotState and PlotState.ResolveLocalSlot and PlotState.ResolveLocalSlot()
		end)
		if not slot then
			return nil
		end
		local pos
		BX.try("farm.treadmill.spot", function()
			local folder = workspace:FindFirstChild("__ClientTreadmillRenders")
			local render = folder and folder:FindFirstChild("TreadmillRender_" .. tostring(slot))
			local root = render and render:FindFirstChild("Root")
			if root and root:IsA("BasePart") then
				pos = root.Position
				return
			end
			local plots = workspace:FindFirstChild("Plots")
			local plot = plots and plots:FindFirstChild(tostring(slot))
			local bottom = plot and plot:FindFirstChild("TreadmillBottom")
			if bottom and bottom:IsA("BasePart") then
				pos = bottom.Position + Vector3.new(0, 4, 0)
			end
		end)
		return pos
	end
	local function place(pos)
		local hrp = ch.root()
		if not hrp or not pos then
			return false
		end
		local ok = BX.try("farm.treadmill.place", function()
			hrp.CFrame = CFrame.new(pos)
		end)
		return ok and true or false
	end
	local function step()
		if not enabled then
			return
		end
		if st.autoStealOn and not autoHold then
			return
		end
		local pos = M.spot()
		if not pos then
			return
		end
		local hrp = ch.root()
		if not hrp then
			return
		end
		if (hrp.Position - pos).Magnitude > K.DRIFT then
			place(pos)
		end
	end
	function M.setEnabled(on, opts)
		opts = opts or {}
		local fromAuto = opts.auto == true
		on = on and true or false
		if on == enabled then
			autoHold = fromAuto and on or autoHold
			return true
		end
		if on then
			if st.autoStealOn and not fromAuto then
				return false, "Turn Auto Steal off first"
			end
			local pos = M.spot()
			if not pos then
				return false, "Could not find your treadmill"
			end
			enabled = true
			autoHold = fromAuto
			st.stayOnTreadmill = true
			place(pos)
			sc = BX.scope("features.farm.treadmill_on")
			sc:loop("hold", dev.scale(K.POLL), step)
			ch.onSpawn(sc, "farm.treadmill.respawn", function()
				if enabled and (not st.autoStealOn or autoHold) then
					place(M.spot())
				end
			end)
			return true
		end
		enabled = false
		autoHold = false
		st.stayOnTreadmill = false
		if sc then
			sc:destroy()
			sc = nil
		end
		net.call("RF/Treadmill/AskDoff")
		local pos = M.spot()
		if pos then
			place(pos + Vector3.new(0, 3, K.STEP_OFF))
		end
		return true
	end
	return M
end)

-- =============================================================================
-- features/farm/pets.lua
-- =============================================================================

BX.module("features.farm.pets", function(BX)
	local net = BX.require("core.net")
	local M = {}
	function M.equipBest()
		local ok, msg = net.call("RF/Haul/WearBest")
		if ok == true then
			return true, "Equipped your best pets"
		end
		return false, "Refused: " .. tostring(msg or ok)
	end
	return M
end)

-- =============================================================================
-- features/esp/cards.lua
-- =============================================================================

BX.module("features.esp.cards", function(BX)
	local svc = BX.require("core.services")
	local dev = BX.require("core.device")
	local M = {}
	local K = {
		W = 190,
		H = 40,
		VIS_HZ = 12,
		MAX_DIST = 2200,
		FADE_BAND = 260,
		BASE_ALPHA = 0.42,
		BASE_STROKE = 0.55,
		BUILD_PER_FRAME = 3,
	}
	M.K = K
	local C = {
		bgTop = Color3.fromRGB(26, 26, 30),
		bgBot = Color3.fromRGB(14, 14, 17),
		accent = Color3.fromRGB(206, 206, 212),
		element = Color3.fromRGB(41, 41, 48),
		title = Color3.fromRGB(246, 242, 234),
		sub = Color3.fromRGB(168, 158, 144),
	}
	M.STYLE = { titleFont = Enum.Font.GothamBold, titleSize = 13, subFont = Enum.Font.Gotham, subSize = 10 }
	M.COL = { income = "57F287", neutral = "F0F0F6", mutation = "F0BE5A", dim = "8A8A92", ready = "57F287" }
	M.SEP = "  \u{B7}  "
	function M.tint(col, text)
		return ('<font color="#%s">%s</font>'):format(col, text)
	end
	function M.hex(c)
		return ("%02X%02X%02X"):format(
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5)
		)
	end
	local function scaleFor(dist)
		return math.clamp(1.25 - (tonumber(dist) or 0) / 800, 0.6, 1.25)
	end
	local sc, folder, handles = nil, nil, 0
	local pools = {}
	local build, apply
	local function ensure()
		if sc then
			return
		end
		sc = BX.scope("features.esp.cards")
		folder = Instance.new("Folder")
		folder.Name = "HanssyzESP"
		sc:own(folder)
		folder.Parent = workspace
		local acc, step = 0, 1 / K.VIS_HZ
		sc:onFrame("vis", svc.RunService.RenderStepped, function(dt)
			local budget = dev.budget(K.BUILD_PER_FRAME)
			for _, pool in pairs(pools) do
				if budget <= 0 then
					break
				end
				for i, d in pairs(pool.pending) do
					if budget <= 0 then
						break
					end
					local c = build()
					pool[i] = c
					pool.n = pool.n + 1
					if i > pool.high then
						pool.high = i
					end
					apply(c, d)
					pool.pending[i] = nil
					budget = budget - 1
				end
			end
			acc = acc + (dt or 0)
			if acc < step then
				return
			end
			acc = 0
			local cam = workspace.CurrentCamera
			if not cam then
				return
			end
			local eye = cam.CFrame.Position
			for _, pool in pairs(pools) do
				for i = 1, pool.shown do
					local c = pool[i]
					if c and c.anchor.Parent then
						local d = (c.pos - eye).Magnitude
						local show = d <= K.MAX_DIST
						if c.bb.Enabled ~= show then
							c.bb.Enabled = show
						end
						if show then
							local s = scaleFor(d)
							if math.abs(c.lastScale - s) > 0.01 or c.lastH ~= c.baseH then
								c.lastScale, c.lastH = s, c.baseH
								c.scale.Scale = s
								c.bb.Size = UDim2.fromOffset(K.W * s, c.baseH * s)
							end
							local fade = math.clamp((K.MAX_DIST - d) / K.FADE_BAND, 0, 1)
							if math.abs(c.lastFade - fade) > 0.02 then
								c.lastFade = fade
								c.frame.BackgroundTransparency = 1 - (1 - K.BASE_ALPHA) * fade
								c.title.TextTransparency = 1 - fade
								c.sub.TextTransparency = 1 - fade
								c.icon.ImageTransparency = 1 - fade
								c.stroke.Transparency = 1 - (1 - K.BASE_STROKE) * fade
							end
						end
					end
				end
			end
		end)
	end
	function build()
		local anchor = Instance.new("Part")
		anchor.Name = "EggAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.CastShadow = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.Parent = folder
		local bb = Instance.new("BillboardGui")
		bb.Name = "EggCard"
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.MaxDistance = 1e6
		bb.Size = UDim2.fromOffset(K.W, K.H)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.Active = false
		bb.Adornee = anchor
		bb.Enabled = false
		bb.Parent = anchor
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromOffset(K.W, K.H)
		frame.BackgroundColor3 = Color3.new(1, 1, 1)
		frame.BackgroundTransparency = K.BASE_ALPHA
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = true
		frame.Parent = bb
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
		local grad = Instance.new("UIGradient", frame)
		grad.Color = ColorSequence.new(C.bgTop, C.bgBot)
		grad.Rotation = 90
		local scaleObj = Instance.new("UIScale")
		scaleObj.Scale = 1
		scaleObj.Parent = frame
		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = Color3.new(1, 1, 1)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Thickness = 1
		stroke.Transparency = K.BASE_STROKE
		local sg = Instance.new("UIGradient", stroke)
		sg.Color = ColorSequence.new(C.accent, C.element)
		sg.Rotation = 90
		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.Position = UDim2.fromOffset(3, 4)
		accent.Size = UDim2.new(0, 2, 1, -8)
		accent.BorderSizePixel = 0
		accent.BackgroundColor3 = Color3.fromRGB(194, 142, 54)
		accent.Parent = frame
		Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Position = UDim2.fromOffset(9, 8)
		icon.Size = UDim2.fromOffset(24, 24)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = ""
		icon.Parent = frame
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Position = UDim2.fromOffset(38, 3)
		title.Size = UDim2.new(1, -44, 0, 15)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 12
		title.TextColor3 = C.title
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Text = ""
		title.Parent = frame
		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.Position = UDim2.fromOffset(38, 18)
		sub.Size = UDim2.new(1, -44, 0, 20)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 10
		sub.TextColor3 = C.sub
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextYAlignment = Enum.TextYAlignment.Top
		sub.RichText = true
		sub.Text = ""
		sub.Parent = frame
		return {
			anchor = anchor,
			bb = bb,
			frame = frame,
			stroke = stroke,
			accent = accent,
			icon = icon,
			title = title,
			sub = sub,
			scale = scaleObj,
			pos = Vector3.zero,
			baseH = K.H,
			lastScale = -1,
			lastFade = -1,
			lastH = -1,
			lastTitle = nil,
			lastSub = nil,
			lastIcon = nil,
			lastStyle = nil,
		}
	end
	function apply(c, d)
		if c.pos ~= d.pos then
			c.pos = d.pos
			c.anchor.CFrame = CFrame.new(d.pos)
		end
		local h = (d.lines and d.lines > 1) and (K.H + 12) or K.H
		if c.baseH ~= h then
			c.baseH = h
			c.frame.Size = UDim2.fromOffset(K.W, h)
			c.sub.Size = UDim2.new(1, -44, 0, h - 20)
		end
		local titleText = (d.target and "\u{25B8} " or "") .. tostring(d.title or "")
		if titleText ~= c.lastTitle then
			c.lastTitle = titleText
			c.title.Text = titleText
		end
		if d.sub ~= c.lastSub then
			c.lastSub = d.sub
			c.sub.Text = tostring(d.sub or "")
		end
		if d.icon ~= c.lastIcon then
			c.lastIcon = d.icon
			c.icon.Image = tostring(d.icon or "")
		end
		if d.accent then
			c.accent.BackgroundColor3 = d.accent
		end
		local st = d.style
		if st ~= c.lastStyle then
			c.lastStyle = st
			c.title.Font = (st and st.titleFont) or Enum.Font.GothamBold
			c.title.TextSize = (st and st.titleSize) or 12
			c.sub.Font = (st and st.subFont) or Enum.Font.Gotham
			c.sub.TextSize = (st and st.subSize) or 10
		end
	end
	local Handle = {}
	Handle.__index = Handle
	function Handle:show(i, d)
		local pool = pools[self.name]
		local c = pool[i]
		if not c then
			pool.pending[i] = d
			return
		end
		apply(c, d)
	end
	function Handle:shown(n)
		local pool = pools[self.name]
		pool.shown = n
		for i = n + 1, pool.high do
			local c = pool[i]
			if c and c.bb.Enabled then
				c.bb.Enabled = false
			end
		end
		for i in pairs(pool.pending) do
			if i > n then
				pool.pending[i] = nil
			end
		end
	end
	function Handle:close()
		local pool = pools[self.name]
		for i = 1, pool.high do
			local c = pool[i]
			if c then
				pcall(function()
					c.anchor:Destroy()
				end)
			end
		end
		pools[self.name] = nil
		handles = handles - 1
		if handles <= 0 then
			handles = 0
			if sc then
				sc:destroy()
				sc = nil
			end
			folder, pools = nil, {}
		end
	end
	function M.open(name)
		ensure()
		handles = handles + 1
		pools[name] = { shown = 0, pending = {}, n = 0, high = 0 }
		return setmetatable({ name = name }, Handle)
	end
	return M
end)

-- =============================================================================
-- features/esp/eggs.lua
-- =============================================================================

BX.module("features.esp.eggs", function(BX)
	local dev = BX.require("core.device")
	local eggs = BX.require("features.eggs")
	local data = BX.require("core.data")
	local cards = BX.require("features.esp.cards")
	local M = {}
	local K = { REFRESH = 0.5, MAX_CARDS = 40, LIFT_BASE = 2.2, LIFT_SCALE = 3.4 }
	local sc, handle, enabled = nil, nil, false
	local STYLE, COL, SEP, tint, hex = cards.STYLE, cards.COL, cards.SEP, cards.tint, cards.hex
	local function rate(n)
		n = tonumber(n) or 0
		for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
			if n >= u[1] then
				local v = n / u[1]
				local txt = (v < 10) and ("%.2f"):format(v) or ("%.1f"):format(v)
				return (txt:gsub("%.?0+$", "")) .. u[2]
			end
		end
		return tostring(math.floor(n))
	end
	local scratch = {}
	local function update()
		if not enabled or not handle then
			return
		end
		local cam = workspace.CurrentCamera
		local list = eggs.list()
		if not cam or not list then
			return
		end
		local dir = data.assetsDir()
		local eye = cam.CFrame.Position
		for i = #scratch, 1, -1 do
			scratch[i] = nil
		end
		for _, e in ipairs(list) do
			if e.pos and (e.pos - eye).Magnitude <= cards.K.MAX_DIST then
				scratch[#scratch + 1] = e
			end
		end
		table.sort(scratch, function(a, b)
			return (a.value or 0) > (b.value or 0)
		end)
		local n = math.min(#scratch, K.MAX_CARDS)
		for i = 1, n do
			local e = scratch[i]
			local d = e.assetCategory and dir and dir[e.assetCategory] or nil
			local colour = Color3.fromRGB(200, 200, 200)
			local rarityName = (e.rarity and e.rarity ~= "?") and e.rarity or nil
			if d and d.Rarity then
				if typeof(d.Rarity.Color) == "Color3" then
					colour = d.Rarity.Color
				end
				rarityName = rarityName or d.Rarity.DisplayName or d.Rarity._id
			end
			local bits = { tint(COL.income, "<b>" .. rate(e.value or 0) .. "/s</b>") }
			if rarityName then
				bits[#bits + 1] = tint(hex(colour), rarityName)
			end
			local kg = tonumber(e.kg) or 0
			if kg > 0 then
				bits[#bits + 1] = tint(COL.neutral, kg >= 100 and ("%.0fkg"):format(kg) or ("%.1fkg"):format(kg))
			end
			local sub = table.concat(bits, SEP)
			local lines = 1
			if type(e.mutations) == "table" and #e.mutations > 0 then
				local names = {}
				for _, mu in ipairs(e.mutations) do
					names[#names + 1] = tostring(type(mu) == "table" and (mu.DisplayName or mu._id or "?") or mu)
				end
				sub = sub .. "\n" .. tint(COL.mutation, table.concat(names, " \u{B7} "))
				lines = 2
			end
			local lift = K.LIFT_BASE + (tonumber(e.assetScale) or 1) * K.LIFT_SCALE
			handle:show(
				i,
				{
					pos = e.pos + Vector3.new(0, lift, 0),
					title = e.name,
					sub = sub,
					accent = colour,
					icon = d and d.Icon or nil,
					lines = lines,
					style = STYLE,
				}
			)
		end
		handle:shown(n)
	end
	function M.setEnabled(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		enabled = on
		if not on then
			if handle then
				handle:close()
				handle = nil
			end
			if sc then
				sc:destroy()
				sc = nil
			end
			return true
		end
		handle = cards.open("eggs")
		sc = BX.scope("features.esp.eggs")
		sc:loop("update", dev.scale(K.REFRESH), update)
		return true
	end
	return M
end)

-- =============================================================================
-- features/esp/plot.lua
-- =============================================================================

BX.module("features.esp.plot", function(BX)
	local svc = BX.require("core.services")
	local dev = BX.require("core.device")
	local ch = BX.require("core.character")
	local data = BX.require("core.data")
	local eggs = BX.require("features.eggs")
	local cards = BX.require("features.esp.cards")
	local M = {}
	local K = { RATE = 0.5, MAX_CARDS = 24 }
	local sc, handle, enabled = nil, nil, false
	local STYLE, COL, SEP, tint, hex = cards.STYLE, cards.COL, cards.SEP, cards.tint, cards.hex
	local function timeLeft(seconds)
		seconds = math.max(0, math.floor(seconds))
		local h, m = math.floor(seconds / 3600), math.floor(seconds / 60) % 60
		if h > 0 then
			return ("%dh %02dm"):format(h, m)
		end
		if m > 0 then
			return ("%dm %02ds"):format(m, seconds % 60)
		end
		return ("%ds"):format(seconds)
	end
	local function update()
		if not enabled or not handle then
			return
		end
		local rendered = workspace:FindFirstChild("PlacedEggRenders")
		if not rendered then
			handle:shown(0)
			return
		end
		local ES = data.eggState()
		local dir = data.assetsDir()
		local me = svc.Players.LocalPlayer and svc.Players.LocalPlayer.UserId
		if not me then
			return
		end
		local prefix = tostring(me) .. "_"
		local recs = {}
		BX.try("esp.plot.readOwner", function()
			recs = (ES and ES.ReadOwnerEggs and ES.ReadOwnerEggs(me)) or {}
		end)
		local n = 0
		for _, m in ipairs(rendered:GetChildren()) do
			if m:IsA("Model") and m.Name:sub(1, #prefix) == prefix then
				local uid = m.Name:sub(#prefix + 1)
				local pos
				BX.try("esp.plot.pivot", function()
					pos = m:GetPivot().Position
				end)
				if pos then
					n = n + 1
					local rec = recs[uid]
					local d = rec and dir and dir[rec.AssetCategory] or nil
					local title = (d and d.DisplayName ~= "" and d.DisplayName)
						or (rec and tostring(rec.AssetCategory))
						or "Egg"
					local rarity = d and d.Rarity and tostring(d.Rarity.DisplayName or d.Rarity._id or "") or ""
					local colour = (d and d.Rarity and typeof(d.Rarity.Color) == "Color3") and d.Rarity.Color
						or Color3.fromRGB(190, 190, 200)
					local muts = ""
					if rec and type(rec.Mutations) == "table" and #rec.Mutations > 0 then
						local names = {}
						for _, mu in ipairs(rec.Mutations) do
							names[#names + 1] =
								tostring(type(mu) == "table" and (mu.DisplayName or mu._id or "?") or mu)
						end
						muts = table.concat(names, " \u{B7} ")
					end
					local ready = false
					BX.try("esp.plot.ready", function()
						ready = (ES and ES.IsReadyToHatch and ES.IsReadyToHatch(uid)) == true
					end)
					local when = "growing"
					if ready then
						when = "READY"
					elseif rec then
						local grow = d and d.Egg and tonumber(d.Egg.GrowthTime)
						local placed = rec.Placement and tonumber(rec.Placement.PlacedAt)
						local mult = math.max(tonumber(rec.GrowthSpeedMultiplier) or 1, 0.01)
						if grow and placed then
							when = timeLeft(placed + grow / mult - os.time())
						end
					end
					local rate = nil
					if rec then
						BX.try("esp.plot.value", function()
							rate = eggs.value({
								Uid = uid,
								AssetCategory = rec.AssetCategory,
								AssetScale = rec.AssetScale,
								Mutations = rec.Mutations,
							})
						end)
					end
					local kg = d and d.Egg and tonumber(d.Egg.WeightKg)
					if kg then
						kg = kg * (tonumber(rec and rec.AssetScale) or 1)
					end
					if kg and kg <= 0 then
						kg = nil
					end
					local bits = {}
					if rate and rate > 0 then
						bits[#bits + 1] = tint(COL.income, "<b>" .. eggs.formatRate(rate) .. "/s</b>")
					end
					if rarity ~= "" then
						bits[#bits + 1] = tint(hex(colour), rarity)
					end
					if kg then
						bits[#bits + 1] =
							tint(COL.neutral, kg >= 100 and ("%.0fkg"):format(kg) or ("%.1fkg"):format(kg))
					end
					local line1 = table.concat(bits, SEP)
					local state = ready and tint(COL.ready, "<b>READY</b>") or tint(COL.dim, when)
					local line2 = (muts ~= "") and (tint(COL.mutation, muts) .. SEP .. state) or state
					local lift = 2.2 + (tonumber(rec and rec.AssetScale) or 1) * 3.4
					handle:show(
						n,
						{
							pos = pos + Vector3.new(0, lift, 0),
							title = title,
							sub = line1 .. "\n" .. line2,
							accent = colour,
							icon = d and d.Icon or nil,
							lines = 2,
							style = STYLE,
						}
					)
				end
			end
		end
		handle:shown(n)
	end
	function M.setEnabled(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		enabled = on
		if not on then
			if handle then
				handle:close()
				handle = nil
			end
			if sc then
				sc:destroy()
				sc = nil
			end
			return true
		end
		handle = cards.open("plot")
		sc = BX.scope("features.esp.plot")
		sc:loop("update", dev.scale(K.RATE), update)
		ch.onSpawn(sc, "esp.plot.respawn", function()
			if handle then
				handle:shown(0)
			end
		end)
		return true
	end
	return M
end)

-- =============================================================================
-- features/misc/servers.lua
-- =============================================================================

BX.module("features.misc.servers", function(BX)
	local svc = BX.require("core.services")
	local exec = BX.require("core.exec")
	local M = {}
	local K = { MAX_PAGES = 5, TRIES = 4, FAILED_FOR = 600, TP_SETTLE = 2.5 }
	local searching = false
	local failed = {}
	local function canFetch()
		if exec.can.request then
			return true
		end
		local ok, f = pcall(function()
			return game.HttpGet
		end)
		return ok and type(f) == "function"
	end
	local function fetchPage(cursor)
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
		if cursor then
			url = url .. "&cursor=" .. tostring(cursor)
		end
		local body
		if exec.can.request then
			local res
			BX.try("servers.fetch", function()
				res = exec.httpRequest({ Url = url, Method = "GET" })
			end)
			body = res and (res.Body or res.body)
		end
		if not body then
			local ok, got = pcall(function()
				return game:HttpGet(url)
			end)
			if ok and type(got) == "string" then
				body = got
			end
		end
		if not body then
			return nil
		end
		local decoded
		pcall(function()
			decoded = svc.HttpService:JSONDecode(body)
		end)
		if type(decoded) ~= "table" or type(decoded.data) ~= "table" then
			return nil
		end
		return decoded
	end
	local function teleport(sv)
		local failedWhy = nil
		local conn
		pcall(function()
			conn = svc.TeleportService.TeleportInitFailed:Connect(function(plr, result, msg)
				if plr == svc.Players.LocalPlayer then
					failedWhy = tostring(result) .. " " .. tostring(msg or "")
				end
			end)
		end)
		pcall(function()
			BX.require("boot.log").flushNow()
		end)
		local ok = pcall(function()
			svc.TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, svc.Players.LocalPlayer)
		end)
		if ok then
			local t0 = os.clock()
			while not failedWhy and (os.clock() - t0) < K.TP_SETTLE do
				task.wait(0.1)
			end
		end
		if conn then
			pcall(function()
				conn:Disconnect()
			end)
		end
		if not ok or failedWhy then
			failed[sv.id] = os.clock()
			return false
		end
		return true
	end
	local function go(order)
		if searching then
			return false, "Already searching"
		end
		if not canFetch() then
			return false, "Server search not supported"
		end
		searching = true
		local okRun, ok, msg = pcall(function()
			local out, cursor = {}, nil
			local here = tostring(game.JobId)
			local now = os.clock()
			for id, at in pairs(failed) do
				if (now - at) > K.FAILED_FOR then
					failed[id] = nil
				end
			end
			for _ = 1, K.MAX_PAGES do
				local page = fetchPage(cursor)
				if not page then
					break
				end
				for _, sv in ipairs(page.data) do
					local playing = tonumber(sv.playing) or 0
					local maxP = tonumber(sv.maxPlayers) or 0
					if sv.id and sv.id ~= here and not failed[sv.id] and maxP > 0 and playing < maxP then
						out[#out + 1] =
							{ id = sv.id, playing = playing, maxPlayers = maxP, ping = tonumber(sv.ping) or 0 }
					end
				end
				cursor = page.nextPageCursor
				if not cursor then
					break
				end
			end
			if #out == 0 then
				return false, "No suitable servers"
			end
			table.sort(out, order)
			for i = 1, math.min(#out, K.TRIES) do
				if teleport(out[i]) then
					return true, ("Joining a server with %d players"):format(out[i].playing)
				end
			end
			return false, "Teleport refused - try again"
		end)
		searching = false
		return ok, msg
	end
	function M.lowestServer()
		return go(function(a, b)
			if a.playing ~= b.playing then
				return a.playing < b.playing
			end
			return (a.ping > 0 and a.ping or math.huge) < (b.ping > 0 and b.ping or math.huge)
		end)
	end
	function M.hop()
		return go(function(a, b)
			return a.playing < b.playing
		end)
	end
	return M
end)

-- =============================================================================
-- features/misc/webhook.lua
-- =============================================================================

BX.module("features.misc.webhook", function(BX)
	local svc = BX.require("core.services")
	local exec = BX.require("core.exec")
	local util = BX.require("core.util")
	local M = {}
	local K = { MIN_GAP = 3.0 }
	local enabled, url, lastSend = false, nil, 0
	function M.isOn()
		return enabled
	end
	function M.hasUrl()
		return url ~= nil and url ~= ""
	end
	function M.setEnabled(on)
		enabled = on and true or false
		return true
	end
	function M.setUrl(v)
		v = tostring(v or ""):gsub("%s", "")
		if v == "" then
			url = nil
			return true, "URL cleared"
		end
		if not v:match("^https://") then
			return false, "Not a webhook URL"
		end
		url = v
		return true, "Webhook URL saved"
	end
	local function post(payload)
		if not exec.can.request or not url then
			return false
		end
		local body
		if not pcall(function()
			body = svc.HttpService:JSONEncode(payload)
		end) then
			return false
		end
		local res
		local ok = BX.try("webhook.post", function()
			res = exec.httpRequest({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = body,
			})
		end)
		local code = res and (res.StatusCode or res.status_code)
		return ok and code and code >= 200 and code < 300
	end
	function M.onDelivered(e)
		if not enabled or not M.hasUrl() or type(e) ~= "table" then
			return
		end
		local now = os.clock()
		if now - lastSend < K.MIN_GAP then
			return
		end
		lastSend = now
		task.spawn(function()
			BX.try("webhook.delivered", function()
				local fields = {}
				fields[#fields + 1] = { name = "Pet", value = tostring(e.name or "?"), inline = true }
				if e.value then
					fields[#fields + 1] = { name = "Income", value = util.short(e.value) .. "/s", inline = true }
				end
				if e.kg and e.kg > 0 then
					fields[#fields + 1] = { name = "Weight", value = ("%.2f kg"):format(e.kg), inline = true }
				end
				if e.rarity and e.rarity ~= "?" then
					fields[#fields + 1] = { name = "Rarity", value = tostring(e.rarity), inline = true }
				end
				if e.areaId then
					fields[#fields + 1] = { name = "Area", value = tostring(e.areaId), inline = true }
				end
				if type(e.mutations) == "table" and #e.mutations > 0 then
					local names = {}
					for _, mu in ipairs(e.mutations) do
						names[#names + 1] = tostring(type(mu) == "table" and (mu.DisplayName or mu._id or "?") or mu)
					end
					fields[#fields + 1] = { name = "Mutations", value = table.concat(names, ", "), inline = false }
				end
				local desc = ("**%s**"):format(tostring(e.name or "Egg"))
				if e.value then
					desc = desc .. "  \u{B7}  " .. util.short(e.value) .. "/s"
				end
				post({
					username = "Hanssyz",
					embeds = {
						{
							title = "Egg delivered",
							description = desc,
							color = 5814783,
							fields = fields,
							footer = { text = "Hanssyz " .. tostring(BX.version) },
							timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
						},
					},
				})
			end)
		end)
	end
	function M.test()
		if not M.hasUrl() then
			return false, "Set a webhook URL first"
		end
		task.spawn(function()
			BX.try("webhook.test", function()
				post({
					username = "Hanssyz",
					embeds = {
						{
							title = "Test",
							description = "Webhook is working.",
							color = 5814783,
							timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
						},
					},
				})
			end)
		end)
		return true, "Test sent"
	end
	return M
end)

-- =============================================================================
-- features/misc/appearance.lua
-- =============================================================================

BX.module("features.misc.appearance", function(BX)
	local win = BX.require("ui.window")
	local M = {}
	local K = { FADE = 0.35, CORNER = 12 }
	local sc = nil
	local current = { theme = nil, background = nil }
	local function themeApi()
		local lib = win.lib
		if type(lib) == "table" then
			for _, name in ipairs({ "SetTheme", "ChangeTheme", "ApplyTheme" }) do
				if type(lib[name]) == "function" then
					return function(v)
						lib[name](lib, v)
					end, name
				end
			end
		end
		return nil
	end
	function M.themes()
		local lib = win.lib
		local names = {}
		if type(lib) == "table" and type(lib.Theme) == "table" then
			for k in pairs(lib.Theme) do
				names[#names + 1] = tostring(k)
			end
		end
		if #names == 0 then
			names = { "Default", "Amethyst", "Green", "Bloom", "DarkBlue", "Light", "Serenity" }
		end
		table.sort(names)
		return names
	end
	function M.setTheme(name)
		name = tostring(name or "")
		if name == "" then
			return false, "Pick a theme"
		end
		local apply = themeApi()
		if not apply then
			return false, "No theme support"
		end
		if not BX.try("appearance.setTheme", function()
			apply(name)
		end) then
			return false, "Theme refused"
		end
		current.theme = name
		return true, "Theme: " .. name
	end
	local bgLabel, savedFill, guardConn = nil, nil, nil
	local request = 0
	local function restoreWindowFill()
		if guardConn then
			pcall(function()
				guardConn:Disconnect()
			end)
			guardConn = nil
		end
		if bgLabel and savedFill ~= nil then
			pcall(function()
				local host = bgLabel.Parent
				if host then
					host.BackgroundTransparency = savedFill
				end
			end)
		end
		savedFill = nil
	end
	local function findHost()
		local gui = win.screen
		if not gui or not gui.Parent then
			return nil
		end
		local best, bestArea
		for _, f in ipairs(gui:GetChildren()) do
			if f:IsA("Frame") and f.Visible then
				local a = f.AbsoluteSize.X * f.AbsoluteSize.Y
				if not bestArea or a > bestArea then
					best, bestArea = f, a
				end
			end
		end
		return best
	end
	local function applyBackground(id)
		restoreWindowFill()
		if bgLabel then
			pcall(function()
				bgLabel:Destroy()
			end)
		end
		bgLabel = nil
		id = tostring(id or ""):gsub("%s", "")
		if id == "" then
			current.background = nil
			local bgSc = BX._scopes["features.misc.appearance.background"]
			if bgSc and not bgSc.dead then
				bgSc:destroy()
			end
			return true, "cleared"
		end
		if not id:match("^%d+$") then
			id = id:match("(%d+)") or ""
			if id == "" then
				return false, "not an image id"
			end
		end
		local host = findHost()
		if not host then
			return false, "no hub window"
		end
		local bgSc = BX.scope("features.misc.appearance.background")
		local img = Instance.new("ImageLabel")
		img.Name = "HanssyzBackground"
		img.Size = UDim2.fromScale(1, 1)
		img.Image = "rbxassetid://" .. id
		img.ScaleType = Enum.ScaleType.Crop
		img.ImageTransparency = K.FADE
		img.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		img.BackgroundTransparency = 0
		img.BorderSizePixel = 0
		img.ZIndex = 0
		Instance.new("UICorner", img).CornerRadius = UDim.new(0, K.CORNER)
		bgSc:own(img)
		img.Parent = host
		savedFill = host.BackgroundTransparency
		host.BackgroundTransparency = 1
		bgLabel = img
		current.background = id
		guardConn = bgSc:connect(host:GetPropertyChangedSignal("BackgroundTransparency"), function()
			if bgLabel == img and img.Parent == host and host.BackgroundTransparency ~= 1 then
				savedFill = host.BackgroundTransparency
				host.BackgroundTransparency = 1
			end
		end)
		return true, "applied"
	end
	function M.setBackground(id)
		request = request + 1
		local mine = request
		local ok, why = applyBackground(id)
		if not ok and tostring(why):find("no hub window") then
			sc = sc or BX.scope("features.misc.appearance")
			sc:spawn("bgWait", function()
				for _ = 1, 60 do
					task.wait(0.5)
					if request ~= mine then
						return
					end
					if applyBackground(id) then
						return
					end
				end
			end)
			return true, "Waiting for the window"
		end
		return ok, ok and ("Background " .. why) or ("Background failed - " .. why)
	end
	function M.clearBackground()
		request = request + 1
		applyBackground("")
		return true, "Background cleared"
	end
	function M.read()
		return { theme = current.theme, background = current.background }
	end
	function M.apply(t)
		if type(t) ~= "table" then
			return
		end
		if t.theme then
			M.setTheme(t.theme)
		end
		if t.background and tostring(t.background) ~= "" then
			M.setBackground(t.background)
		end
	end
	return M
end)

-- =============================================================================
-- features/fps.lua
-- =============================================================================

BX.module("features.fps", function(BX)
	local svc = BX.require("core.services")
	local M = {}
	local K = { MAX_TRACKED = 4000, CHUNK = 1200, PRUNE_EVERY = 30, DEFER = 2.0 }
	local EFFECTS = { ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true }
	local POST = {
		BloomEffect = true,
		BlurEffect = true,
		ColorCorrectionEffect = true,
		SunRaysEffect = true,
		DepthOfFieldEffect = true,
	}
	local env = (type(getgenv) == "function" and getgenv()) or _G
	local ENV_KEY = "__HANSSYZ_FPS"
	local function newRecord()
		return { props = {}, n = 0 }
	end
	local function restoreRecord(rec)
		if type(rec) ~= "table" or type(rec.props) ~= "table" then
			return
		end
		for i = #rec.props, 1, -1 do
			local e = rec.props[i]
			if e and e.obj then
				pcall(function()
					e.obj[e.key] = e.was
				end)
			end
			rec.props[i] = nil
		end
		rec.n = 0
	end
	if type(env[ENV_KEY]) == "table" then
		local stale = env[ENV_KEY]
		env[ENV_KEY] = nil
		BX.try("fps.restoreStale", function()
			restoreRecord(stale)
		end)
	end
	local sc, rec, enabled, sweeping = nil, nil, false, false
	local function remember(obj, key, value)
		if not rec then
			return false
		end
		if rec.n >= K.MAX_TRACKED then
			return false
		end
		local was
		if not pcall(function()
			was = obj[key]
		end) then
			return false
		end
		if was == value then
			return false
		end
		if not pcall(function()
			obj[key] = value
		end) then
			return false
		end
		rec.n = rec.n + 1
		rec.props[rec.n] = { obj = obj, key = key, was = was }
		return true
	end
	local function offLimits(d)
		local espRoot = workspace:FindFirstChild("HanssyzESP")
		if espRoot and d:IsDescendantOf(espRoot) then
			return true
		end
		local char = svc.Players.LocalPlayer and svc.Players.LocalPlayer.Character
		if char and d:IsDescendantOf(char) then
			return true
		end
		return false
	end
	local function handle(d)
		local cls = d.ClassName
		if not (EFFECTS[cls] or POST[cls]) then
			return false
		end
		if EFFECTS[cls] and offLimits(d) then
			return false
		end
		remember(d, "Enabled", false)
		return true
	end
	local function sweep()
		if sweeping then
			return
		end
		sweeping = true
		for _, d in ipairs(svc.Lighting:GetDescendants()) do
			BX.try("fps.sweepPost", handle, d)
		end
		local desc = workspace:GetDescendants()
		local total = #desc
		local i = 1
		while i <= total do
			local stop = math.min(i + K.CHUNK - 1, total)
			for j = i, stop do
				local d = desc[j]
				if d then
					BX.try("fps.sweepOne", handle, d)
				end
			end
			i = stop + 1
			svc.RunService.Heartbeat:Wait()
			if not enabled or not (sc and sc:alive()) then
				break
			end
		end
		sweeping = false
	end
	function M.setEnabled(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		enabled = on
		if not on then
			if sc then
				sc:destroy()
				sc = nil
			end
			restoreRecord(rec)
			rec = nil
			env[ENV_KEY] = nil
			return true
		end
		rec = newRecord()
		env[ENV_KEY] = rec
		sc = BX.scope("features.fps")
		remember(svc.Lighting, "GlobalShadows", false)
		local ter = workspace:FindFirstChildOfClass("Terrain")
		if ter then
			remember(ter, "Decoration", false)
			remember(ter, "WaterWaveSize", 0)
			remember(ter, "WaterReflectance", 0)
		end
		sc:spawn("sweep", sweep)
		sc:connect(
			workspace.DescendantAdded,
			BX.guard("fps.added", function(d)
				if not enabled then
					return
				end
				handle(d)
			end)
		)
		return true
	end
	local armed = false
	function M.arm()
		if armed then
			return false
		end
		armed = true
		task.delay(K.DEFER, function()
			if not BX.alive() then
				return
			end
			if enabled or M.userTurnedOff then
				return
			end
			BX.try("fps.armApply", function()
				M.setEnabled(true)
			end)
		end)
		return true
	end
	return M
end)

-- =============================================================================
-- features/boss.lua
-- =============================================================================

BX.module("features.boss", function(BX)
	local dev = BX.require("core.device")
	local net = BX.require("core.net")
	local M = {}
	local K = { SNAP_TTL = 5, BACKSTOP = 30, ENTER_GAP = 1.0, RETRY = { 5, 10, 20 } }
	local sc, enabled = nil, false
	local snap, snapAt = nil, 0
	local retryN, retryArmed = 0, false
	local autoEnter = false
	function M.isOn()
		return enabled
	end
	function M.autoEnterOn()
		return autoEnter
	end
	local listeners = {}
	function M.onChange(fn)
		listeners[#listeners + 1] = fn
	end
	local function fireChange()
		for _, fn in ipairs(listeners) do
			task.spawn(function()
				BX.try("boss.onChange", fn)
			end)
		end
	end
	function M.snapshot(force)
		if not enabled then
			return nil
		end
		local now = os.clock()
		if not force and snap and (now - snapAt) < K.SNAP_TTL then
			return snap
		end
		local st = net.call("RF/BossEvent/AskSnapshot")
		snapAt = now
		if type(st) == "table" then
			snap = st
		end
		return snap
	end
	function M.held()
		return snap
	end
	local function clock(sec)
		sec = math.max(0, math.floor(sec or 0))
		local h, m = math.floor(sec / 3600), math.floor(sec / 60) % 60
		if h > 0 then
			return ("%dh %02dm"):format(h, m)
		end
		if m > 0 then
			return ("%dm %02ds"):format(m, sec % 60)
		end
		return ("%ds"):format(sec)
	end
	function M.status()
		if not enabled then
			return { title = "Abyss Overlord", body = "off" }
		end
		local s = snap
		if not s then
			return { title = "Abyss Overlord", body = "Reading..." }
		end
		local now = workspace:GetServerTimeNow()
		if s.Open == true then
			return {
				title = "Abyss Overlord",
				body = ("OPEN  \u{B7}  closes in %s"):format(clock((tonumber(s.ClosesAt) or 0) - now)),
			}
		end
		local until_ = (tonumber(s.OpensAt) or 0) - now
		if until_ > 0 then
			return { title = "Abyss Overlord", body = ("Closed  \u{B7}  opens in %s"):format(clock(until_)) }
		end
		return { title = "Abyss Overlord", body = "Closed" }
	end
	function M.refresh()
		if not enabled then
			return false
		end
		task.spawn(function()
			BX.try("boss.refresh", function()
				M.snapshot(true)
				fireChange()
			end)
		end)
		return true
	end
	local function readOrRetry()
		local st = M.snapshot(true)
		if st then
			retryN = 0
			return st
		end
		if retryArmed or not sc then
			return nil
		end
		local wait = K.RETRY[retryN + 1]
		if not wait then
			return nil
		end
		retryArmed = true
		sc:delay("retry", dev.scale(wait), function()
			retryArmed = false
			retryN = retryN + 1
			if readOrRetry() then
				fireChange()
			end
		end)
	end
	function M.enter()
		local accepted, msg = net.call("RF/BossEvent/AskEnter")
		if accepted == true then
			return true, "Entering the boss world"
		end
		if msg and tostring(msg):find("defeated") then
			return false, "Boss already defeated"
		end
		return false, tostring(msg or "Refused")
	end
	function M.setAutoEnter(on)
		autoEnter = on and true or false
		return true
	end
	function M.claimMilestones()
		local BM
		BX.try("boss.requireMastery", function()
			local mod = BX.require("core.services").ReplicatedStorage:FindFirstChild("Data")
			mod = mod and mod:FindFirstChild("BossMastery")
			if mod and mod:IsA("ModuleScript") then
				BM = require(mod)
			end
		end)
		if type(BM) ~= "table" then
			return 0, "Could not read mastery list"
		end
		local ids = {}
		for _, m in pairs(BM.Milestones or {}) do
			if type(m) == "table" and m.Id then
				ids[#ids + 1] = tostring(m.Id)
			end
		end
		if BM.InfiniteMilestoneId then
			ids[#ids + 1] = tostring(BM.InfiniteMilestoneId)
		end
		local claimed = 0
		for _, id in ipairs(ids) do
			if net.call("RF/BossMastery/AskClaimMilestone", id) == true then
				claimed = claimed + 1
			end
			task.wait(0.15)
		end
		return claimed, claimed > 0 and ("Claimed " .. claimed) or "Nothing to claim yet"
	end
	function M.setEnabled(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		if not on then
			enabled = false
			autoEnter = false
			if sc then
				sc:destroy()
				sc = nil
			end
			snap, snapAt = nil, 0
			retryN, retryArmed = 0, false
			fireChange()
			return true
		end
		sc = BX.scope("features.boss")
		enabled = true
		BX.try("boss.watchState", function()
			local re = net.find("RE/BossEvent/StateShifted")
			if not re then
				return
			end
			sc:connect(re.OnClientEvent, function()
				task.spawn(function()
					BX.try("boss.stateShifted", function()
						local was = snap and snap.Open
						M.snapshot(true)
						local isOpen = snap and snap.Open
						fireChange()
						if autoEnter and isOpen == true and was ~= true then
							task.wait(K.ENTER_GAP)
							M.enter()
						end
					end)
				end)
			end)
		end)
		sc:loop("backstop", dev.scale(K.BACKSTOP), function()
			local had, was = snap ~= nil, snap and snap.Open
			readOrRetry()
			if not had or (snap and snap.Open) ~= was then
				fireChange()
			end
		end)
		return true
	end
	return M
end)

-- =============================================================================
-- features/rift.lua
-- =============================================================================

BX.module("features.rift", function(BX)
	local svc = BX.require("core.services")
	local dev = BX.require("core.device")
	local data = BX.require("core.data")
	local net = BX.require("core.net")
	local eggs = BX.require("features.eggs")
	local M = {}
	local K = {
		BACKSTOP = 30,
		SNAP_TTL = 5,
		STALE_MAX = 8,
		DEBOUNCE = 0.35,
		RETRY = { 5, 10, 20 },
		NONE_LABEL = "No pets spawned",
	}
	local sc, enabled = nil, false
	local snap, snapAt, snapOkAt = nil, 0, 0
	local retryN, retryArmed = 0, false
	local fieldIds = nil
	local ownedHave, ownedMiss = nil, nil
	local pick = nil
	local labelToId = {}
	local dirty = false
	function M.isOn()
		return enabled
	end
	local listeners = {}
	function M.onChange(fn)
		listeners[#listeners + 1] = fn
	end
	local function fireChange()
		for _, fn in ipairs(listeners) do
			task.spawn(function()
				BX.try("rift.onChange", fn)
			end)
		end
	end
	function M.held()
		return snap
	end
	function M.petName(id)
		local dir = data.assetsDir()
		local cfg = dir and dir[id]
		return (cfg and cfg.DisplayName and tostring(cfg.DisplayName)) or tostring(id)
	end
	function M.state(force)
		if not enabled then
			return nil
		end
		local now = os.clock()
		if not force and snap and (now - snapAt) < K.SNAP_TTL then
			return snap
		end
		local st = net.call("RF/Rift/AskState")
		snapAt = now
		if type(st) == "table" then
			snap, snapOkAt = st, now
			return snap
		end
		if (now - snapOkAt) > K.STALE_MAX then
			snap = nil
		end
		return snap
	end
	function M.requirements()
		local st = M.state()
		return (st and type(st.Requirements) == "table") and st.Requirements or {}
	end
	local function computeOwned()
		local reqs = M.requirements()
		if #reqs == 0 then
			ownedHave, ownedMiss = nil, nil
			return
		end
		local counts = nil
		BX.try("rift.readInventory", function()
			local Save = svc.ReplicatedStorage:FindFirstChild("Save", true)
			if not (Save and Save:IsA("ModuleScript")) then
				return
			end
			local mod = require(Save)
			if type(mod) ~= "table" or type(mod.Get) ~= "function" then
				return
			end
			local profile = mod.Get(svc.LocalPlayer)
			local inv = profile and profile.Inventory
			if type(inv) ~= "table" then
				return
			end
			counts = {}
			for _, row in pairs(inv) do
				local cat = type(row) == "table" and row.Category or nil
				if cat then
					counts[cat] = (counts[cat] or 0) + 1
				end
			end
		end)
		if not counts then
			ownedHave, ownedMiss = nil, nil
			return
		end
		local have, missing = 0, {}
		for _, id in ipairs(reqs) do
			if (counts[id] or 0) > 0 then
				have = have + 1
			else
				missing[#missing + 1] = id
			end
		end
		ownedHave, ownedMiss = have, missing
	end
	function M.owned()
		if ownedHave == nil and ownedMiss == nil then
			computeOwned()
		end
		return ownedHave, ownedMiss
	end
	local function computeField()
		local reqs = M.requirements()
		if #reqs == 0 then
			fieldIds = nil
			return
		end
		local want = {}
		for _, id in ipairs(reqs) do
			want[id] = true
		end
		local list = eggs.list()
		if not list then
			fieldIds = nil
			return
		end
		local seen, out = {}, {}
		for _, e in ipairs(list) do
			local cat = e.assetCategory
			if cat and want[cat] and not seen[cat] then
				seen[cat] = true
				out[#out + 1] = cat
			end
		end
		fieldIds = out
	end
	function M.onField()
		if not enabled then
			return {}
		end
		if not fieldIds then
			computeField()
		end
		return fieldIds or {}
	end
	function M.petIsOut(id)
		if not id then
			return false
		end
		for _, out in ipairs(M.onField()) do
			if out == id then
				return true
			end
		end
		return false
	end
	function M.options()
		local out = {}
		labelToId = {}
		for _, id in ipairs(fieldIds or {}) do
			local label = M.petName(id)
			labelToId[label] = id
			out[#out + 1] = label
		end
		if #out == 0 then
			out[1] = K.NONE_LABEL
		end
		return out
	end
	function M.idForLabel(label)
		if type(label) ~= "string" or label == K.NONE_LABEL then
			return nil
		end
		return labelToId[label] or label
	end
	function M.setPick(id)
		pick = id
	end
	function M.status()
		if not enabled then
			return { title = "Rift", body = "off" }
		end
		local st = snap
		if not st then
			return { title = "Rift", body = "Reading..." }
		end
		if st.Unlocked == false then
			local need = tonumber(st.UnlockSpeedPower)
			return { title = "Rift", body = need and ("Unlocks at " .. eggs.formatRate(need)) or "Locked" }
		end
		local reqs = st.Requirements or {}
		local have, missing = ownedHave, ownedMiss
		local banner = tostring(st.BannerDisplayName or st.BannerId or "Rift")
		local secs = (tonumber(st.SecondsUntilRotation) or 0) - (os.clock() - snapOkAt)
		local mins = math.max(0, math.floor(secs / 60))
		local title = have and ("%s  %d/%d"):format(banner, have, #reqs) or banner
		local tail = ("%dm"):format(mins)
		if have and #reqs > 0 and have >= #reqs then
			return { title = title, body = ("All ready  \u{B7}  new rift in %s"):format(tail) }
		end
		local want = (missing and #missing > 0) and missing or reqs
		if #want == 0 then
			return { title = title, body = ("New rift in %s"):format(tail) }
		end
		local outSet = {}
		for _, id in ipairs(fieldIds or {}) do
			outSet[id] = true
		end
		local ready = {}
		for _, id in ipairs(want) do
			if outSet[id] then
				ready[#ready + 1] = M.petName(id)
			end
		end
		local body
		if #ready > 0 then
			body = ("Steal %s now"):format(table.concat(ready, ", "))
		elseif #want == 1 then
			body = ("Need %s"):format(M.petName(want[1]))
		else
			body = ("Need %d pets"):format(#want)
		end
		return { title = title, body = ("%s  \u{B7}  %s"):format(body, tail) }
	end
	function M.pickTarget()
		if not enabled then
			return nil, "rift is off"
		end
		local have, missing = M.owned()
		local reqs = M.requirements()
		if #reqs == 0 then
			return nil, "rift has no requirements"
		end
		if have and have >= #reqs then
			return nil, "all rift pets owned"
		end
		local need = {}
		for _, id in ipairs((missing and #missing > 0) and missing or reqs) do
			need[id] = true
		end
		local list = eggs.list()
		if not list then
			return nil, "no egg list"
		end
		for _, e in ipairs(list) do
			local cat = e.assetCategory
			if cat and need[cat] then
				if pick then
					if cat == pick then
						return e
					end
				else
					return e
				end
			end
		end
		return nil, "no required rift pet is on the field"
	end
	local tradeSc, tradeOn, trading = nil, false, false
	local tradeListeners = {}
	function M.onTrade(fn)
		tradeListeners[#tradeListeners + 1] = fn
	end
	function M.setAutoTrade(on)
		on = on and true or false
		if on == tradeOn then
			return true
		end
		tradeOn = on
		if not on then
			if tradeSc then
				tradeSc:destroy()
				tradeSc = nil
			end
			return true
		end
		if not enabled then
			M.setEnabled(true)
		end
		tradeSc = BX.scope("features.rift.trade")
		tradeSc:loop("trade", dev.scale(5), function()
			if trading then
				return
			end
			trading = true
			BX.try("rift.tryTrade", function()
				local st = M.state(true)
				if type(st) ~= "table" then
					return
				end
				if st.PendingReward then
					net.call("RF/Rift/AskFinishReveal")
					for _, fn in ipairs(tradeListeners) do
						task.spawn(function()
							BX.try("rift.onTrade", fn, "revealed")
						end)
					end
				end
			end)
			trading = false
		end)
		return true
	end
	local scheduleRetry
	local function recompute(why, full)
		dirty = false
		if full then
			snapAt = 0
			local st = M.state(true)
			if st then
				retryN = 0
			else
				scheduleRetry()
			end
		end
		if full or (ownedHave == nil and ownedMiss == nil) then
			computeOwned()
		end
		computeField()
		if pick and not M.petIsOut(pick) then
			pick = nil
		end
		fireChange()
	end
	scheduleRetry = function()
		if retryArmed or not sc then
			return
		end
		local wait = K.RETRY[retryN + 1]
		if not wait then
			return
		end
		retryArmed = true
		sc:delay("retry", dev.scale(wait), function()
			retryArmed = false
			retryN = retryN + 1
			recompute("retry " .. retryN, true)
		end)
	end
	M.refresh = function(why)
		if not enabled then
			return false
		end
		eggs.invalidate("rift refresh")
		recompute(why or "manual refresh", true)
		return true
	end
	function M.setEnabled(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		if not on then
			enabled = false
			if sc then
				sc:destroy()
				sc = nil
			end
			snap, snapAt, snapOkAt = nil, 0, 0
			fieldIds, ownedHave, ownedMiss = nil, nil, nil
			labelToId, dirty = {}, false
			retryN, retryArmed = 0, false
			pick = nil
			fireChange()
			return true
		end
		sc = BX.scope("features.rift")
		enabled = true
		BX.try("rift.watchRotation", function()
			local re = net.find("RE/Rift/BannerRotated")
			if not re then
				return
			end
			sc:connect(re.OnClientEvent, function()
				task.spawn(function()
					BX.try("rift.rotated", function()
						recompute("banner rotated", true)
					end)
				end)
			end)
		end)
		sc:loop("backstop", dev.scale(K.BACKSTOP), function()
			recompute(snap and "backstop" or "first read", true)
		end)
		return true
	end
	return M
end)

-- =============================================================================
-- features/eggs.lua
-- =============================================================================

BX.module("features.eggs", function(BX)
	local svc = BX.require("core.services")
	local dev = BX.require("core.device")
	local data = BX.require("core.data")
	local M = {}
	local K = {
		CACHE_TTL = 0.5,
		MIN_REBUILD = 0.1,
		RAW_TTL = 0.25,
		FALLBACK_TTL = 5.0,
		STOLEN_FOR = 120,
		UNREACHABLE_FOR = 45,
		PARTIAL_FLOOR = 8,
		FULL_FIELD_MIN = 10,
		VALUE_CACHE_MAX = 600,
	}
	local EggState, AssetEarnings, AssetsDir
	BX.try("eggs.resolveModules", function()
		EggState = data.eggState()
		AssetEarnings = data.assetEarnings()
		AssetsDir = data.assetsDir()
	end)
	M.ready = (EggState ~= nil)
	local rawSnap, rawSnapAt = nil, 0
	local dirty = false
	local list, listAt = nil, 0
	local fallbackAt = 0
	local sawFullField, saidPartial = false, false
	local stolen, unreachable = {}, {}
	local valueCache, valueCacheN = {}, 0
	function M.invalidate(reason)
		list, listAt = nil, 0
		rawSnap, rawSnapAt = nil, 0
		dirty = false
	end
	function M.markDirty(reason)
		dirty = true
	end
	function M.markStolen(uid)
		if uid then
			stolen[tostring(uid)] = os.clock()
		end
	end
	function M.markUnreachable(uid)
		if uid then
			unreachable[tostring(uid)] = os.clock()
		end
	end
	local function pruneStolen()
		local now = os.clock()
		for uid, at in pairs(stolen) do
			if (now - at) > K.STOLEN_FOR then
				stolen[uid] = nil
			end
		end
		for uid, at in pairs(unreachable) do
			if (now - at) > K.UNREACHABLE_FOR then
				unreachable[uid] = nil
			end
		end
	end
	local function calcValue(rec)
		local uid = rec.Uid
		local hit = valueCache[uid]
		if hit then
			return hit
		end
		local item =
			{ Category = rec.AssetCategory, Scale = tonumber(rec.AssetScale) or 1, Mutations = rec.Mutations or {} }
		local v = 0
		if AssetEarnings then
			local ok, rate = pcall(AssetEarnings.LiveRatePerSecond, item, nil, nil, svc.LocalPlayer)
			if ok and type(rate) == "number" then
				v = rate
			else
				ok, rate = pcall(AssetEarnings.MutationOnlyRatePerSecond, item)
				if ok and type(rate) == "number" then
					v = rate
				end
			end
		end
		if valueCacheN >= K.VALUE_CACHE_MAX then
			valueCache, valueCacheN = {}, 0
		end
		valueCache[uid] = v
		valueCacheN = valueCacheN + 1
		return v
	end
	M.value = calcValue
	local function displayName(rec)
		local dir = AssetsDir and AssetsDir[rec.AssetCategory]
		return (dir and dir.DisplayName) or rec.AssetCategory or ("Egg " .. tostring(rec.Uid or "?"):sub(1, 6))
	end
	local function rarityIdOf(rec)
		local dir = AssetsDir and AssetsDir[rec.AssetCategory]
		if dir and dir.Rarity then
			return dir.Rarity._id or dir.Rarity.DisplayName or "?"
		end
		return "?"
	end
	local function rarityOf(rec)
		local dir = AssetsDir and AssetsDir[rec.AssetCategory]
		if dir and dir.Rarity then
			return dir.Rarity.DisplayName or dir.Rarity._id or "?"
		end
		return "?"
	end
	local function weightOf(rec)
		local dir = AssetsDir and AssetsDir[rec.AssetCategory]
		local base = dir and dir.Egg and tonumber(dir.Egg.WeightKg)
		if not base then
			return 0
		end
		return base * (tonumber(rec.AssetScale) or 1)
	end
	function M.formatRate(n)
		n = tonumber(n) or 0
		for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
			if n >= u[1] then
				local v = n / u[1]
				local txt = (v < 10) and string.format("%.2f", v) or string.format("%.1f", v)
				return (txt:gsub("%.?0+$", "")) .. u[2]
			end
		end
		return tostring(math.floor(n))
	end
	local function readField()
		local records = nil
		BX.try("eggs.readField", function()
			local d = EggState and EggState.ReadFieldEggs and EggState.ReadFieldEggs()
			if type(d) == "table" and type(d.Records) == "table" then
				records = d.Records
			end
		end)
		return records
	end
	local function readFallback()
		local now = os.clock()
		if (now - fallbackAt) < K.FALLBACK_TTL then
			return nil
		end
		fallbackAt = now
		local records = {}
		BX.try("eggs.fallback", function()
			local slots = workspace:FindFirstChild("AreaEggSlotsClient")
			if not slots then
				return
			end
			for _, m in ipairs(slots:GetChildren()) do
				if m:IsA("Model") then
					local uid = m:GetAttribute("Uid") or m:GetAttribute("EggUid") or m.Name
					local cf
					local hit = m:FindFirstChild("Hitbox")
					if hit and hit:IsA("BasePart") then
						cf = hit.CFrame
					else
						cf = m:GetPivot()
					end
					if uid and cf then
						records[#records + 1] = { Uid = tostring(uid), BoundsCFrame = cf, State = "Slot" }
					end
				end
			end
		end)
		return #records > 0 and records or nil
	end
	local function snapshot(force)
		local now = os.clock()
		if not force and rawSnap and (now - rawSnapAt) < dev.scale(K.RAW_TTL) then
			return rawSnap
		end
		local records = readField()
		if not records or #records == 0 then
			records = readFallback() or records
		end
		if records then
			rawSnap, rawSnapAt = records, now
		end
		return rawSnap
	end
	function M.list(opts, force)
		opts = opts or {}
		local now = os.clock()
		local fresh = (now - listAt) < dev.scale(K.CACHE_TTL)
		local mayRebuild = (now - listAt) >= K.MIN_REBUILD
		if not force and list and fresh and not (dirty and mayRebuild) then
			return list
		end
		if dirty and mayRebuild then
			dirty = false
		end
		local records = snapshot(force)
		local n = records and #records or 0
		if n > K.FULL_FIELD_MIN then
			sawFullField = true
		end
		if sawFullField and n > 0 and n <= K.PARTIAL_FLOOR and list and #list > 0 then
			return list
		end
		if not records then
			list = list or {}
			listAt = now
			return list
		end
		pruneStolen()
		local TAKEABLE = opts.state or { Slot = true, Dropped = true }
		local out, seen = {}, {}
		for _, rec in ipairs(records) do
			local uid = rec.Uid and tostring(rec.Uid)
			if uid and not seen[uid] then
				seen[uid] = true
				if TAKEABLE[rec.State] and not stolen[uid] and not unreachable[uid] then
					local value = calcValue(rec)
					local pos = rec.BoundsCFrame and rec.BoundsCFrame.Position
					if
						pos
						and (not opts.minValue or value >= opts.minValue)
						and (not opts.filter or opts.filter(rec, value))
					then
						out[#out + 1] = {
							uid = uid,
							state = rec.State,
							pos = pos,
							value = value,
							name = displayName(rec),
							rarity = rarityOf(rec),
							rarityId = rarityIdOf(rec),
							assetCategory = rec.AssetCategory,
							assetScale = rec.AssetScale,
							mutations = rec.Mutations,
							kg = weightOf(rec),
							guardHeld = (rec.State == "GuardCarried"),
							dropped = (rec.State == "Dropped"),
							areaId = rec.AreaId,
							nestId = rec.NestId,
						}
					end
				end
			end
		end
		table.sort(out, function(a, b)
			return a.value > b.value
		end)
		if valueCacheN > (#out * 2 + 50) then
			local keep, kept = {}, 0
			for _, e in ipairs(out) do
				local v = valueCache[e.uid]
				if v ~= nil then
					keep[e.uid] = v
					kept = kept + 1
				end
			end
			valueCache, valueCacheN = keep, kept
		end
		list, listAt = out, now
		return list
	end
	function M.best(opts)
		local l = M.list(opts)
		return l and l[1] or nil
	end
	function M.get(uid)
		if not uid then
			return nil
		end
		local rec
		BX.try("eggs.get", function()
			rec = EggState and EggState.ReadFieldEgg and EggState.ReadFieldEgg(uid)
		end)
		if not rec then
			return nil
		end
		return {
			uid = tostring(uid),
			state = rec.State,
			pos = rec.BoundsCFrame and rec.BoundsCFrame.Position,
			value = calcValue(rec),
			name = displayName(rec),
			rarity = rarityOf(rec),
			rarityId = rarityIdOf(rec),
			assetCategory = rec.AssetCategory,
			assetScale = rec.AssetScale,
			mutations = rec.Mutations,
			kg = weightOf(rec),
			areaId = rec.AreaId,
			nestId = rec.NestId,
		}
	end
	function M.carryingUid()
		local found
		BX.try("eggs.carryingUid", function()
			local d = EggState and EggState.ReadFieldEggs and EggState.ReadFieldEggs()
			for _, r in pairs(d and d.Records or {}) do
				if r.State == "Carried" then
					found = tostring(r.Uid)
					break
				end
			end
		end)
		return found
	end
	function M.stillTakeable(uid, states)
		local r = M.get(uid)
		if not r then
			return false, "gone"
		end
		local ok = (states or { Slot = true, Dropped = true })[r.state]
		return ok and true or false, r.state
	end
	local WATCH = { "CarryChanged", "FieldShifted", "FieldRefreshed", "FieldGone", "FieldClaimed", "SnapshotRefreshed" }
	local sc = BX.scope("features.eggs")
	if EggState then
		for _, name in ipairs(WATCH) do
			BX.try("eggs.watch." .. name, function()
				local sig = EggState[name]
				if sig and type(sig) == "table" and type(sig.Connect) == "function" then
					sc:connect(sig, function()
						M.markDirty(name)
					end)
				end
			end)
		end
	end
	BX.require("core.character").onSpawn(sc, "eggs.respawn", function()
		M.invalidate("respawn")
	end)
	return M
end)

-- =============================================================================
-- features/grab.lua
-- =============================================================================

BX.module("features.grab", function(BX)
	local data = BX.require("core.data")
	local exec = BX.require("core.exec")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local eggs = BX.require("features.eggs")
	local svc = BX.require("core.services")
	local M = {}
	local RunService = svc.RunService
	local K = {
		PROMPT_CACHE = 30,
		PROMPT_NEAR = 14,
		PROMPT_WAIT = 0.6,
		STEP_INSIDE = 3,
		CONFIRM_WINDOW = 1.2,
		TRIES = 3,
		RETRY_GAP = 0.15,
	}
	local EggState = data.eggState()
	local prompts, promptsAt = nil, 0
	local function promptList()
		local now = os.clock()
		if prompts and (now - promptsAt) < K.PROMPT_CACHE then
			return prompts
		end
		local found = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				local txt = string.lower(tostring(d.ActionText) .. " " .. tostring(d.ObjectText) .. " " .. d.Name)
				if txt:find("steal") or txt:find("carry") then
					found[#found + 1] = d
				end
			end
		end
		prompts, promptsAt = found, now
		return found
	end
	local function promptPos(p)
		local parent = p.Parent
		if not parent then
			return nil
		end
		if parent:IsA("BasePart") then
			return parent.Position
		end
		if parent:IsA("Model") then
			return parent:GetPivot().Position
		end
		return nil
	end
	local function waitForPrompt(targetPos, cancel, seconds)
		if typeof(targetPos) ~= "Vector3" then
			return false
		end
		local listed = promptList()
		local until_ = os.clock() + dev.scale(seconds or 1.2)
		repeat
			if cancel and cancel() then
				return false
			end
			for _, d in ipairs(listed) do
				if d.Parent and d.Enabled then
					local pos = promptPos(d)
					if pos and (pos - targetPos).Magnitude <= K.PROMPT_NEAR then
						return true
					end
				end
			end
			task.wait(0.05)
		until os.clock() > until_
		return false
	end
	function M.confirm(uid, baseWalkSpeed, carrySignal)
		if carrySignal then
			return true, "CarryChanged"
		end
		local hum = ch.humanoid()
		if hum and baseWalkSpeed and hum.WalkSpeed and hum.WalkSpeed < (baseWalkSpeed - 1) then
			return true, "walkspeed drop"
		end
		local char = ch.get()
		if char then
			for _, c in ipairs(char:GetChildren()) do
				if
					c:IsA("Tool")
					and c:GetAttribute("ItemType") == "AssetEgg"
					and tostring(c:GetAttribute("UID")) == tostring(uid)
				then
					return true, "egg tool in hand"
				end
			end
		end
		local rec = eggs.get(uid)
		if rec and rec.state == "Carried" then
			return true, "ReadFieldEgg"
		end
		local any
		BX.try("grab.confirmAll", function()
			local d = EggState and EggState.ReadFieldEggs and EggState.ReadFieldEggs()
			for _, r in pairs(d and d.Records or {}) do
				if r.State == "Carried" and tostring(r.Uid) == tostring(uid) then
					any = true
					break
				end
			end
		end)
		if any then
			return true, "ReadFieldEggs"
		end
		return false, rec and rec.state or "unknown"
	end
	local function fireAt(targetPos, cancel)
		if not exec.can.prompts then
			return false, "no fireproximityprompt"
		end
		local hrp = ch.root()
		if not hrp then
			return false, "no root"
		end
		local listed = promptList()
		if typeof(targetPos) == "Vector3" then
			waitForPrompt(targetPos, cancel, K.PROMPT_WAIT)
			if cancel and cancel() then
				return false, "cancelled"
			end
		end
		local best, bestDist = nil, math.huge
		for _, d in ipairs(listed) do
			if d.Parent and d.Enabled then
				local pos = promptPos(d)
				if pos then
					local onTarget = (typeof(targetPos) ~= "Vector3") or ((pos - targetPos).Magnitude <= K.PROMPT_NEAR)
					local dist = (hrp.Position - pos).Magnitude
					if onTarget and dist <= (d.MaxActivationDistance + 8) and dist < bestDist then
						best, bestDist = d, dist
					end
				end
			end
		end
		if not best then
			return false, "no prompt for this egg"
		end
		local pos = promptPos(best)
		local limit = (best.MaxActivationDistance or 8) - K.STEP_INSIDE
		if pos and bestDist > limit then
			local from = hrp.Position
			local step = pos - from
			local want = pos - (step.Magnitude > 0.1 and step.Unit or Vector3.new(0, 0, 1)) * math.max(limit * 0.5, 2)
			pcall(function()
				hrp.CFrame = CFrame.new(Vector3.new(want.X, from.Y, want.Z))
				hrp.AssemblyLinearVelocity = Vector3.zero
			end)
			RunService.Heartbeat:Wait()
			local h2 = ch.root()
			if h2 then
				bestDist = (h2.Position - pos).Magnitude
			end
		end
		local wasHold, wasLoS = best.HoldDuration, best.RequiresLineOfSight
		pcall(function()
			best.HoldDuration = 0
			best.RequiresLineOfSight = false
		end)
		local fired = exec.firePrompt(best, 0)
		if fired then
			exec.firePrompt(best)
		end
		pcall(function()
			best.HoldDuration = wasHold
			best.RequiresLineOfSight = wasLoS
		end)
		return fired and true or false,
			fired and ("fired at %.1f studs"):format(bestDist) or "fireproximityprompt failed",
			bestDist
	end
	function M.take(uid, opts)
		opts = opts or {}
		local cancel = opts.cancel
		local tries = opts.tries or K.TRIES
		local targetPos = opts.pos
		local t0 = os.clock()
		local hum0 = ch.humanoid()
		local baseWS = (hum0 and hum0.WalkSpeed and hum0.WalkSpeed > 0) and hum0.WalkSpeed or nil
		local sc = BX.scope("features.grab.attempt")
		local carrySignal = false
		if EggState and EggState.CarryChanged then
			BX.try("grab.watchCarry", function()
				sc:connect(EggState.CarryChanged, function(info)
					if type(info) ~= "table" or info.Uid == nil or tostring(info.Uid) == tostring(uid) then
						carrySignal = true
					end
				end)
			end)
		end
		local function finish(ok, reason, attempt, fireDist)
			sc:destroy()
			if ok then
				eggs.markStolen(uid)
			end
			return ok, { reason = reason, attempts = attempt or 0, ms = (os.clock() - t0) * 1000, distance = fireDist }
		end
		local have, witness = M.confirm(uid, baseWS, carrySignal)
		if have then
			return finish(true, witness, 0)
		end
		for attempt = 1, tries do
			if cancel and cancel() then
				return finish(false, "cancelled", attempt)
			end
			if not ch.root() then
				return finish(false, "no character", attempt)
			end
			local ok, state = eggs.stillTakeable(uid)
			if not ok and not carrySignal then
				return finish(false, "egg " .. tostring(state), attempt)
			end
			local fired, why, dist = fireAt(targetPos, cancel)
			if why == "cancelled" then
				return finish(false, "cancelled", attempt)
			end
			if fired then
				local until_ = os.clock() + dev.scale(K.CONFIRM_WINDOW)
				repeat
					if cancel and cancel() then
						return finish(false, "cancelled", attempt, dist)
					end
					local got, w = M.confirm(uid, baseWS, carrySignal)
					if got then
						return finish(true, w, attempt, dist)
					end
					RunService.Heartbeat:Wait()
				until os.clock() > until_
			end
			if attempt < tries then
				task.wait(dev.scale(K.RETRY_GAP))
			end
		end
		local got, w = M.confirm(uid, baseWS, carrySignal)
		if got then
			return finish(true, w, tries)
		end
		return finish(false, "no confirmation", tries)
	end
	function M.warmPrompts()
		local t0 = os.clock()
		local n = #promptList()
		return (os.clock() - t0) * 1000, n
	end
	return M
end)

-- =============================================================================
-- features/instant.lua
-- =============================================================================

BX.module("features.instant", function(BX)
	local data = BX.require("core.data")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local eggs = BX.require("features.eggs")
	local guard = BX.require("features.guard")
	local svc = BX.require("core.services")
	local M = {}
	local RunService = svc.RunService
	local K = {
		TIMEOUT = 3,
		RACE_THREADS = 3,
		RACE_STAGGER = 0.05,
		LIFT = 2,
		PULLBACK_GAP = 25,
		FREE_CALLS = 12,
		SAME_MSG_GAP = 0.12,
		SAME_MSG_STOP = 30,
	}
	local EggState, SlotIdentity = data.eggState(), data.slotIdentity()
	local function ensureModules()
		if not EggState then
			EggState = data.eggState()
		end
		if not SlotIdentity then
			SlotIdentity = data.slotIdentity()
		end
		M.ready = (EggState ~= nil and type(EggState.CarryFieldEgg) == "function")
		return M.ready
	end
	ensureModules()
	local holdGen = 0
	local function slotKeyFor(uid, areaId, nestId)
		local key = nil
		BX.try("instant.slotKey", function()
			if SlotIdentity and SlotIdentity.LooksLikeFirstAreaUid and SlotIdentity.LooksLikeFirstAreaUid(uid) then
				key = SlotIdentity.SlotKey(areaId, nestId)
			end
		end)
		return key
	end
	function M.take(uid, eggPos, opts)
		opts = opts or {}
		local cancel = opts.cancel or function()
			return false
		end
		if not M.ready and not ensureModules() then
			return false, { reason = "no CarryFieldEgg" }
		end
		if typeof(eggPos) ~= "Vector3" then
			return false, { reason = "no egg position" }
		end
		local char = ch.get()
		if not char then
			return false, { reason = "no character" }
		end
		local t0 = os.clock()
		local target = CFrame.new(eggPos.X, eggPos.Y + K.LIFT, eggPos.Z)
		local slotKey = slotKeyFor(uid, opts.areaId, opts.nestId)
		local deadline = os.clock() + dev.scale(opts.timeout or K.TIMEOUT)
		local sc = BX.scope("features.instant.race")
		holdGen = holdGen + 1
		local myGen = holdGen
		local won, tries, lastMsg = false, 0, nil
		local sameMsg, sameCount = nil, 0
		local bailed = false
		sc:spawn("hold", function()
			while not won and holdGen == myGen and os.clock() < deadline and sc:alive() do
				local c = ch.get()
				if c then
					pcall(function()
						c:PivotTo(target)
					end)
				end
				local h = ch.root()
				if h then
					h.AssemblyLinearVelocity = Vector3.zero
					h.AssemblyAngularVelocity = Vector3.zero
				end
				RunService.Heartbeat:Wait()
			end
		end)
		guard.waitForServerRelease(cancel)
		if cancel() then
			holdGen = holdGen + 1
			sc:destroy()
			return false, { reason = "cancelled", ms = (os.clock() - t0) * 1000 }
		end
		for i = 1, K.RACE_THREADS do
			sc:spawn("invoke" .. i, function()
				task.wait((i - 1) * K.RACE_STAGGER)
				while not won and not bailed and os.clock() < deadline and sc:alive() do
					if cancel() then
						return
					end
					tries = tries + 1
					local ok, res, msg = pcall(function()
						return EggState.CarryFieldEgg(uid, slotKey)
					end)
					if msg ~= nil then
						lastMsg = tostring(msg)
					end
					if type(msg) == "string" and msg:lower():find("downed") then
						local left = guard.ragdollRemaining()
						if left > 0 then
							task.wait(math.min(left, 0.25))
						end
					end
					if not won and type(msg) == "string" then
						if msg == sameMsg then
							sameCount = sameCount + 1
						else
							sameMsg, sameCount = msg, 1
						end
						if sameCount >= K.SAME_MSG_STOP then
							bailed = true
							return
						end
						if tries > K.FREE_CALLS and sameCount > 1 then
							task.wait(K.SAME_MSG_GAP)
						end
					end
					if ok and res == true and not won then
						won = true
						return
					end
					if won then
						return
					end
					RunService.Heartbeat:Wait()
				end
			end)
		end
		local cancelled = false
		while not won and not bailed and os.clock() < deadline do
			if cancel() then
				cancelled = true
				break
			end
			RunService.Heartbeat:Wait()
		end
		holdGen = holdGen + 1
		sc:destroy()
		local ms = (os.clock() - t0) * 1000
		local gap = (function()
			local h = ch.root()
			return h and (h.Position - eggPos).Magnitude or -1
		end)()
		if cancelled then
			return false, { reason = "cancelled", calls = tries, ms = ms }
		end
		if won then
			eggs.markStolen(uid)
			return true, { reason = "instant", calls = tries, ms = ms, gap = gap }
		end
		local rec = eggs.get(uid)
		return false,
			{
				reason = lastMsg or "no accept",
				calls = tries,
				ms = ms,
				gap = gap,
				pulledBack = (gap > K.PULLBACK_GAP),
				eggState = rec and rec.state or "gone",
				eggGone = rec == nil,
			}
	end
	return M
end)

-- =============================================================================
-- features/plot.lua
-- =============================================================================

BX.module("features.plot", function(BX)
	local svc = BX.require("core.services")
	local data = BX.require("core.data")
	local M = {}
	local K = { HOME_TTL = 30 }
	local PlotState = data.plotState()
	local cached, cachedAt, cachedVia = nil, 0, nil
	local function resolve()
		local pos, via
		if PlotState then
			BX.try("plot.findRespawn", function()
				local cf = PlotState.FindRespawnCFrame and PlotState.FindRespawnCFrame()
				if typeof(cf) == "CFrame" then
					pos, via = cf.Position, "FindRespawnCFrame"
				end
			end)
		end
		if not pos then
			BX.try("plot.spawnLocation", function()
				local sl = workspace:FindFirstChildOfClass("SpawnLocation")
				if sl and sl:IsA("BasePart") then
					pos, via = sl.Position + Vector3.new(0, 4, 0), "SpawnLocation"
				end
			end)
		end
		return pos, via
	end
	function M.home()
		local now = os.clock()
		if cached and (now - cachedAt) < K.HOME_TTL then
			return cached, cachedVia
		end
		local pos, via = resolve()
		if not pos then
			return nil, "no plot resolved"
		end
		cached, cachedAt, cachedVia = pos, now, via
		return cached, cachedVia
	end
	local szCache, szAt, szVia = nil, 0, nil
	function M.safeZone()
		local now = os.clock()
		if szCache and (now - szAt) < K.HOME_TTL then
			return szCache, szVia
		end
		local pos, via
		BX.try("plot.spawnLocationZone", function()
			local sl = workspace:FindFirstChildOfClass("SpawnLocation")
			if sl and sl:IsA("BasePart") then
				pos, via = sl.Position + Vector3.new(0, 4, 0), "SpawnLocation"
			end
		end)
		if not pos then
			BX.try("plot.spawnTargetZone", function()
				local st = workspace:FindFirstChild("SpawnTarget", true)
				if st and st:IsA("BasePart") then
					pos, via = st.Position + Vector3.new(0, 4, 0), "SpawnTarget"
				end
			end)
		end
		if not pos then
			pos, via = M.home()
			if pos then
				via = "plot fallback"
			end
		end
		if not pos then
			return nil, "unresolved"
		end
		szCache, szAt, szVia = pos, now, via
		return szCache, szVia
	end
	local lastClaimAt = 0
	local listeners = {}
	function M.claimedSince(t)
		return lastClaimAt > (t or 0)
	end
	function M.onClaim(sc, label, fn)
		listeners[#listeners + 1] = { scope = sc, label = label, fn = fn }
	end
	local sc = BX.scope("features.plot")
	local EggState
	BX.try("plot.resolveEggState", function()
		local found = svc.ReplicatedStorage:FindFirstChild("EggState", true)
		if found and found:IsA("ModuleScript") then
			EggState = require(found)
		end
	end)
	if EggState and EggState.FieldClaimed then
		BX.try("plot.armClaimWatch", function()
			sc:connect(EggState.FieldClaimed, function()
				lastClaimAt = os.clock()
				for i = #listeners, 1, -1 do
					local L = listeners[i]
					if not L.scope or L.scope.dead then
						table.remove(listeners, i)
					else
						BX.try("plot/" .. L.label, L.fn)
					end
				end
			end)
		end)
	end
	return M
end)

-- =============================================================================
-- features/regrab.lua
-- =============================================================================

BX.module("features.regrab", function(BX)
	local eggs = BX.require("features.eggs")
	local instant = BX.require("features.instant")
	local guard = BX.require("features.guard")
	local dev = BX.require("core.device")
	local M = {}
	local K = { SETTLE = 0.08, WAIT = 8.0, POLL = 0.05, TRIES = 4, MAX_PER_STEAL = 2 }
	local function settledPos(uid)
		local r = eggs.get(uid)
		if not r then
			return nil, nil
		end
		return r.pos, r.state
	end
	function M.recover(uid, opts)
		opts = opts or {}
		local cancel = opts.cancel or function()
			return false
		end
		task.wait(K.SETTLE)
		if cancel() then
			return false, { reason = "cancelled", recovery = "cancelled" }
		end
		guard.waitForServerRelease(cancel)
		if cancel() then
			return false, { reason = "cancelled", recovery = "cancelled" }
		end
		local deadline = os.clock() + dev.scale(K.WAIT)
		local state
		repeat
			if cancel() then
				return false, { reason = "cancelled", recovery = "cancelled" }
			end
			_, state = settledPos(uid)
			if state == "Claimed" then
				return false, { reason = "claimed", recovery = "banked" }
			end
			if state == nil then
				return false, { reason = "gone", recovery = "failed" }
			end
			if state == "Slot" or state == "Dropped" then
				break
			end
			task.wait(K.POLL)
		until os.clock() > deadline
		if state ~= "Slot" and state ~= "Dropped" then
			return false, { reason = "never settled", recovery = "failed" }
		end
		for attempt = 1, K.TRIES do
			if cancel() then
				return false, { reason = "cancelled", recovery = "cancelled" }
			end
			local pNow, sNow = settledPos(uid)
			if sNow == "Claimed" then
				return false, { reason = "claimed", recovery = "banked" }
			end
			if not pNow then
				return false, { reason = "gone", recovery = "failed" }
			end
			local got = instant.take(uid, pNow, { cancel = cancel, areaId = opts.areaId, nestId = opts.nestId })
			if got then
				return true, { recovery = "tp", attempts = attempt }
			end
			task.wait(dev.scale(K.POLL))
		end
		return false, { reason = "no regrab", recovery = "failed" }
	end
	return M
end)

-- =============================================================================
-- features/carry.lua
-- =============================================================================

BX.module("features.carry", function(BX)
	local svc = BX.require("core.services")
	local move = BX.require("features.movement")
	local plot = BX.require("features.plot")
	local eggs = BX.require("features.eggs")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local M = {}
	local K = { SPEED = 500, ARRIVE = 5, CLAIM_WAIT = 6 }
	local function holding(uid)
		local r = eggs.get(uid)
		if not r then
			return false, "gone"
		end
		return r.state == "Carried", r.state
	end
	function M.home(uid, opts)
		opts = opts or {}
		local outerCancel = opts.cancel
		local dest = plot.safeZone()
		if not dest then
			return false, { reason = "no safe zone resolved" }
		end
		if not ch.root() then
			return false, { reason = "no character" }
		end
		local lastCheck, lastHeld = 0, true
		local function carryCancel()
			if outerCancel and outerCancel() then
				return true
			end
			local now = os.clock()
			if (now - lastCheck) >= 0.25 then
				lastCheck = now
				lastHeld = holding(uid)
			end
			return not lastHeld
		end
		local arrived, moveInfo = move.travel({
			to = dest,
			speed = K.SPEED,
			arrive = K.ARRIVE,
			carrying = true,
			cancel = carryCancel,
			tag = "carry home",
		})
		local stillOurs, state = holding(uid)
		if not stillOurs then
			return false, { reason = "dropped in transit (" .. tostring(state) .. ")" }
		end
		if outerCancel and outerCancel() then
			return false, { reason = "cancelled" }
		end
		if not arrived then
			return false,
				{ reason = "could not reach the safe zone (" .. tostring(moveInfo and moveInfo.reason) .. ")" }
		end
		move.descend("deliver")
		local claimFrom = os.clock()
		local until_ = os.clock() + dev.scale(K.CLAIM_WAIT)
		repeat
			if outerCancel and outerCancel() then
				return false, { reason = "cancelled" }
			end
			if plot.claimedSince(claimFrom) then
				return true, { reason = "delivered" }
			end
			svc.RunService.Heartbeat:Wait()
		until os.clock() > until_
		local have, st = holding(uid)
		return false, { reason = have and "arrived but never claimed" or ("lost at the door (" .. tostring(st) .. ")") }
	end
	return M
end)

-- =============================================================================
-- features/bait.lua
-- =============================================================================

BX.module("features.bait", function(BX)
	local data = BX.require("core.data")
	local move = BX.require("features.movement")
	local ch = BX.require("core.character")
	local dev = BX.require("core.device")
	local svc = BX.require("core.services")
	local M = {}
	local RunService = svc.RunService
	local K = {
		AREA_WAIT = 5,
		APPROACH = 1200,
		ARRIVE = 4,
		PICKUP_WAIT = 3,
		REHOPS = 2,
		HIT_WAIT = 4.0,
		WITNESS_HOLD = 0.35,
	}
	local EggState, SlotIdentity = data.eggState(), data.slotIdentity()
	local areaCached = nil
	function M.firstAreaId(waitFor)
		if areaCached then
			return areaCached
		end
		if waitFor then
			local deadline = os.clock() + waitFor
			while os.clock() < deadline do
				local there = false
				pcall(function()
					there = workspace.__OBJECTS.Areas.GuardAreas:GetChildren()[1] ~= nil
				end)
				if there then
					break
				end
				task.wait(0.2)
			end
		end
		local best, bestX
		BX.try("bait.resolveArea", function()
			for _, a in ipairs(workspace.__OBJECTS.Areas.GuardAreas:GetChildren()) do
				local b = a:FindFirstChild("Bounds")
				if b and b:IsA("BasePart") then
					local x = b.Position.X - b.Size.X * 0.5
					if not best or x < bestX then
						best, bestX = a.Name, x
					end
				end
			end
		end)
		areaCached = best
		return areaCached
	end
	local function findGuard(areaId)
		if not areaId then
			return nil
		end
		local live = workspace:FindFirstChild("_Guards")
		if live then
			for _, g in ipairs(live:GetChildren()) do
				if g.Name == areaId or g:GetAttribute("AreaId") == areaId then
					return g
				end
			end
		end
		local a
		pcall(function()
			a = workspace.__OBJECTS.Areas.GuardAreas[areaId]
		end)
		return a and a:FindFirstChild("Guard") or nil
	end
	local function guardPart(guard)
		if not guard then
			return nil
		end
		local root = guard:FindFirstChild("HumanoidRootPart")
			or guard:FindFirstChild("Collider")
			or guard:FindFirstChild("Head")
		if root and root:IsA("BasePart") then
			return root
		end
		local best
		for _, d in ipairs(guard:GetDescendants()) do
			if d:IsA("BasePart") then
				local v = d.Size.X * d.Size.Y * d.Size.Z
				if not best or v > best.v then
					best = { p = d, v = v }
				end
			end
		end
		return best and best.p or nil
	end
	function M.prime(opts)
		opts = opts or {}
		local cancel = opts.cancel
		local areaId = M.firstAreaId(K.AREA_WAIT)
		if not areaId then
			return false, { reason = "no bait area" }
		end
		if not EggState then
			EggState = data.eggState()
			SlotIdentity = SlotIdentity or data.slotIdentity()
		end
		if not EggState then
			return false, { reason = "no EggState" }
		end
		local rec
		BX.try("bait.findEgg", function()
			for _, r in pairs(EggState.ReadFieldEggs().Records) do
				if r.AreaId == areaId and r.State == "Slot" and r.BoundsCFrame then
					rec = r
					break
				end
			end
		end)
		if not rec then
			return false, { reason = "no bait egg" }
		end
		local pos = rec.BoundsCFrame.Position
		move.travel({
			to = pos,
			speed = K.APPROACH,
			arrive = K.ARRIVE,
			carrying = false,
			cancel = cancel,
			tag = "bait approach",
		})
		if cancel and cancel() then
			return false, { reason = "cancelled" }
		end
		local slotKey = nil
		BX.try("bait.slotKey", function()
			if SlotIdentity and SlotIdentity.LooksLikeFirstAreaUid and SlotIdentity.LooksLikeFirstAreaUid(rec.Uid) then
				slotKey = SlotIdentity.SlotKey(rec.AreaId, rec.NestId)
			end
		end)
		local got = false
		local deadline = os.clock() + dev.scale(K.PICKUP_WAIT)
		local rehops, tries = 0, 0
		local startPos = ch.root() and ch.root().Position
		while os.clock() < deadline and not got do
			if cancel and cancel() then
				return false, { reason = "cancelled" }
			end
			local here = ch.root()
			if not here then
				return false, { reason = "no character" }
			end
			if startPos and (here.Position - pos).Magnitude > 60 and rehops < K.REHOPS then
				rehops = rehops + 1
				move.travel({
					to = pos,
					speed = K.APPROACH,
					arrive = K.ARRIVE,
					carrying = false,
					cancel = cancel,
					tag = "bait rehop",
				})
				deadline = os.clock() + dev.scale(K.PICKUP_WAIT)
			end
			tries = tries + 1
			local ok, res = pcall(function()
				return EggState.CarryFieldEgg(rec.Uid, slotKey)
			end)
			if ok and res == true then
				got = true
				break
			end
			RunService.Heartbeat:Wait()
		end
		if not got then
			return false, { reason = "no pickup" }
		end
		local guard = findGuard(areaId)
		local gpart = guardPart(guard)
		if gpart then
			local hh = ch.root()
			local char = ch.get()
			if hh and char then
				local gy = move.groundY(gpart.Position) or hh.Position.Y
				pcall(function()
					char:PivotTo(CFrame.new(gpart.Position.X, gy, gpart.Position.Z))
				end)
			end
		end
		local hrp = ch.root()
		local anchorCF = hrp and hrp.CFrame
		if hrp then
			pcall(function()
				hrp.Anchored = true
			end)
		end
		local hitAt, witnessAt = nil, nil
		local dl = os.clock() + dev.scale(K.HIT_WAIT)
		while os.clock() < dl do
			if cancel and cancel() then
				break
			end
			local hh = ch.root()
			if not hh then
				break
			end
			hh.AssemblyLinearVelocity = Vector3.zero
			hh.AssemblyAngularVelocity = Vector3.zero
			if anchorCF then
				pcall(function()
					hh.CFrame = anchorCF
				end)
			end
			local witnessed = false
			local hum = ch.humanoid()
			if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
				witnessed = true
			end
			if not witnessed then
				local okR, r = pcall(EggState.ReadFieldEgg, rec.Uid)
				local st = okR and type(r) == "table" and r.State or nil
				witnessed = (st == "Dropped" or st == "GuardCarried")
			end
			if witnessed and not witnessAt then
				witnessAt = os.clock()
			end
			if witnessAt and (os.clock() - witnessAt) >= K.WITNESS_HOLD then
				hitAt = os.clock()
				break
			end
			RunService.Heartbeat:Wait()
		end
		do
			local hh = ch.root()
			if hh then
				pcall(function()
					hh.Anchored = false
				end)
			end
		end
		return hitAt ~= nil, { reason = hitAt and "hit" or "no hit", areaId = areaId, tries = tries, rehops = rehops }
	end
	return M
end)

-- =============================================================================
-- features/autosteal.lua - KEY: pickNow mode stops when target gone
-- =============================================================================

BX.module("features.autosteal", function(BX)
	local svc = BX.require("core.services")
	local dev = BX.require("core.device")
	local ch = BX.require("core.character")
	local st = BX.require("core.state")
	local eggs = BX.require("features.eggs")
	local grab = BX.require("features.grab")
	local move = BX.require("features.movement")
	local carry = BX.require("features.carry")
	local bait = BX.require("features.bait")
	local adeath = BX.require("features.antideath")
	local guard = BX.require("features.guard")
	local rs = BX.require("core.restore")
	local instant = BX.require("features.instant")
	local regrab = BX.require("features.regrab")
	local hswap = BX.require("features.humanoid")
	local log = BX.require("boot.log").for_module("autosteal")
	local M = {}
	local BACKOFF_BASE, BACKOFF_CAP, IDLE_WAIT = 1.0, 8.0, 0.5

	local currentActivity = "idle"
	function M.activity()
		return currentActivity
	end
	local function setActivity(s)
		currentActivity = tostring(s or "idle")
	end

	local autoTreadmill = true
	function M.setAutoTreadmill(on)
		autoTreadmill = on and true or false
		return true
	end
	function M.autoTreadmillOn()
		return autoTreadmill
	end

	local notifyListeners = {}
	function M.onNotify(fn)
		notifyListeners[#notifyListeners + 1] = fn
	end
	local function fireNotify(title, body, kind, dur)
		for _, fn in ipairs(notifyListeners) do
			task.spawn(function()
				BX.try("autosteal.notify", fn, title, body, kind, dur)
			end)
		end
	end
	M._notify = fireNotify

	M.STATE = {
		PREP_DELIVER_HELD = "PREP_DELIVER_HELD",
		READY_TO_STEAL = "READY_TO_STEAL",
		BAIT_NOT_DONE = "BAIT_NOT_DONE",
		BAIT_DONE = "BAIT_DONE",
		AT_TARGET = "AT_TARGET",
		TARGET_GRAB_RETRY = "TARGET_GRAB_RETRY",
		CARRYING = "CARRYING",
		RETURNING = "RETURNING",
		DELIVERED = "DELIVERED",
	}

	local phases, phaseRun = {}, 0
	local function phase(token, name)
		if token ~= phaseRun then
			phases, phaseRun = {}, token
		end
		phases[#phases + 1] = name
	end
	function M.phases()
		return table.clone(phases)
	end
	local TARGET_RETRIES = 2

	local stopListeners = {}
	function M.onStop(fn)
		stopListeners[#stopListeners + 1] = fn
	end
	local startListeners = {}
	function M.onStart(fn)
		startListeners[#startListeners + 1] = fn
	end
	local function fireStart(why, whose)
		for _, fn in ipairs(startListeners) do
			task.spawn(function()
				BX.try("autosteal.onStart", fn, why, whose)
			end)
		end
	end
	local deliveredListeners = {}
	function M.onDelivered(fn)
		deliveredListeners[#deliveredListeners + 1] = fn
	end
	local function fireDelivered(target)
		if not target then
			return
		end
		for _, fn in ipairs(deliveredListeners) do
			task.spawn(function()
				BX.try("autosteal.onDelivered", fn, target)
			end)
		end
	end

	local runToken, running, cycles, sc, failures = 0, false, 0, nil, 0
	local opts, optsFor, owner = {}, {}, nil

	local function runCycle(token, cancel)
		local cycle = { t0 = os.clock(), stages = {} }
		local function stage(name, fn)
			if cancel() then
				return false, { reason = "cancelled" }
			end
			local s0 = os.clock()
			local ok, info = fn()
			cycle.stages[#cycle.stages + 1] = { name = name, ms = (os.clock() - s0) * 1000, ok = ok and true or false }
			return ok, info
		end
		setActivity("checking")
		local held = eggs.carryingUid()
		if held then
			local isObjective = (opts.uid ~= nil) and (held == opts.uid)
			cycle.prep = not isObjective
			cycle.state = isObjective and M.STATE.RETURNING or M.STATE.PREP_DELIVER_HELD
			phase(token, cycle.state)
			setActivity("carrying held " .. tostring(held))
			local ok2 = stage("carry held", function()
				return carry.home(held, { cancel = cancel })
			end)
			if ok2 then
				cycle.target = { name = isObjective and "selected egg" or "held egg", uid = held }
				if isObjective then
					cycle.state = M.STATE.DELIVERED
					cycle.terminal = true
					return true, "delivered", cycle
				end
				cycle.state = M.STATE.READY_TO_STEAL
				cycle.terminal = false
				return true, "prep: held egg delivered", cycle
			end
			return false, "held egg failed", cycle
		end
		if cycle.state == nil then
			cycle.state = M.STATE.READY_TO_STEAL
		end
		local preTarget = nil
		if opts.pick and not opts.uid then
			local okPre, pre, whyPre = pcall(opts.pick)
			if not okPre then
				return false, "target picker failed: " .. tostring(pre), cycle
			end
			if not pre then
				return false, "nothing to steal" .. (whyPre and (" (" .. tostring(whyPre) .. ")") or ""), cycle
			end
			preTarget = pre
		end
		local firstArea = bait.firstAreaId(0)
		local inBaitArea = nil
		if opts.uid then
			local want = eggs.get(opts.uid)
			inBaitArea = want and firstArea and want.areaId == firstArea or false
		elseif preTarget then
			inBaitArea = firstArea ~= nil and preTarget.areaId == firstArea
		end
		local primed = false
		if inBaitArea then
			cycle.baitSkipped = true
		else
			setActivity("baiting")
			primed = stage("bait", function()
				return bait.prime({ cancel = cancel })
			end)
		end
		cycle.primed = primed and true or false
		if cancel() then
			return false, "cancelled", cycle
		end
		local target
		if opts.uid then
			local want = eggs.get(opts.uid)
			if not want then
				return false, "selected egg is gone", cycle
			end
			if not (want.state == "Slot" or want.state == "Dropped") or not want.pos then
				return false, "waiting for the selected egg", cycle
			end
			target = want
		elseif opts.pick then
			local ok2, want, why2 = true, preTarget, nil
			if not (cycle.baitSkipped and preTarget) then
				ok2, want, why2 = pcall(opts.pick)
			end
			if not ok2 then
				return false, "target picker failed: " .. tostring(want), cycle
			end
			target = want
			if not target then
				return false, "nothing matches the filter" .. (why2 and (" (" .. tostring(why2) .. ")") or ""), cycle
			end
		else
			target = eggs.best()
		end
		if not target then
			return false, "nothing to steal", cycle
		end
		cycle.target = target
		setActivity("target " .. tostring(target.name))
		local here = ch.root()
		cycle.distance = here and (target.pos - here.Position).Magnitude or -1
		cycle.state = M.STATE.BAIT_DONE
		local took, inInfo
		local retries = 0
		for attempt = 0, TARGET_RETRIES do
			cycle.state = (attempt == 0) and M.STATE.AT_TARGET or M.STATE.TARGET_GRAB_RETRY
			setActivity("stealing " .. tostring(target.name))
			took, inInfo = stage(attempt == 0 and "instant" or ("regrab" .. attempt), function()
				return instant.take(
					target.uid,
					target.pos,
					{ cancel = cancel, areaId = target.areaId, nestId = target.nestId }
				)
			end)
			if took or cancel() then
				break
			end
			local stt = inInfo and inInfo.eggState
			local retryable = inInfo and (inInfo.pulledBack or stt == "Slot" or stt == "Dropped")
			if not retryable or attempt == TARGET_RETRIES then
				break
			end
			local fresh = eggs.get(target.uid)
			if not fresh or not fresh.pos then
				break
			end
			target.pos = fresh.pos
			retries = retries + 1
		end
		cycle.grabRetries = retries
		if cancel() then
			return false, "cancelled", cycle
		end
		if took then
			cycle.state = M.STATE.CARRYING
			cycle.transition = "tp"
			setActivity("carrying " .. tostring(target.name))
		else
			cycle.transition = "arc_fallback"
			cycle.instantFail = inInfo and inInfo.reason
			local reached, moveInfo = stage("approach", function()
				return move.travel({
					to = target.pos,
					speed = move.outboundSpeed(),
					arrive = 4,
					carrying = false,
					cancel = cancel,
					tag = "approach",
				})
			end)
			if cancel() then
				return false, "cancelled", cycle
			end
			if not reached then
				return false, "approach: " .. tostring(moveInfo and moveInfo.reason), cycle
			end
			local grabbed, grabInfo = stage("grab", function()
				return grab.take(target.uid, { pos = target.pos, cancel = cancel })
			end)
			if cancel() then
				return false, "cancelled", cycle
			end
			if not grabbed then
				eggs.markUnreachable(target.uid)
				return false, "grab: " .. tostring(grabInfo and grabInfo.reason), cycle
			end
			cycle.state = M.STATE.CARRYING
			setActivity("carrying " .. tostring(target.name))
		end
		cycle.state = M.STATE.RETURNING
		setActivity("delivering " .. tostring(target.name))
		local delivered, carryInfo = stage("carry", function()
			return carry.home(target.uid, { cancel = cancel })
		end)
		local recoveries = 0
		while
			not delivered
			and not cancel()
			and carryInfo
			and carryInfo.reason
			and tostring(carryInfo.reason):find("dropped in transit", 1, true)
			and recoveries < regrab.K.MAX_PER_STEAL
		do
			svc.RunService.Heartbeat:Wait()
			recoveries = recoveries + 1
			cycle.recoveries = recoveries
			cycle.state = M.STATE.TARGET_GRAB_RETRY
			setActivity("recovering " .. tostring(target.name))
			local back = stage("recover" .. recoveries, function()
				return regrab.recover(target.uid, { cancel = cancel, areaId = target.areaId, nestId = target.nestId })
			end)
			if not back then
				return false, "drop recovery failed", cycle
			end
			cycle.state = M.STATE.RETURNING
			setActivity("delivering " .. tostring(target.name))
			delivered, carryInfo = stage("carry" .. recoveries, function()
				return carry.home(target.uid, { cancel = cancel })
			end)
		end
		if cancel() then
			return false, "cancelled", cycle
		end
		if not delivered then
			return false, "carry: " .. tostring(carryInfo and carryInfo.reason), cycle
		end
		cycle.state = M.STATE.DELIVERED
		cycle.terminal = true
		setActivity("delivered " .. tostring(target.name))
		fireDelivered(target)
		return true, "delivered", cycle
	end

	local function reportCycle(ok, why, cycle)
		local parts = {}
		for _, s in ipairs(cycle.stages) do
			parts[#parts + 1] = ("%s=%.0fms%s"):format(s.name, s.ms, s.ok and "" or "!")
		end
		local level = ok and log.info or log.warn
		level(
			"cycle %s in %.2fs [%s] target=%s",
			ok and "DELIVERED" or ("FAILED " .. tostring(why)),
			os.clock() - cycle.t0,
			table.concat(parts, " "),
			cycle.target and cycle.target.name or "-"
		)
	end

	local MAX_PREPS = 3

	local function runLoop(token)
		local preps = 0
		local tmHeld = false
		local lastIdleWhy = nil
		local function releaseTreadmill()
			if not tmHeld then
				return
			end
			tmHeld = false
			BX.try("autosteal.tmRelease", function()
				local hold = BX.require("features.farm.treadmill_on")
				if hold.isOn() then
					hold.setEnabled(false)
				end
			end)
		end
		local function holdTreadmill()
			if tmHeld then
				return
			end
			BX.try("autosteal.tmHold", function()
				local hold = BX.require("features.farm.treadmill_on")
				tmHeld = hold.setEnabled(true, { auto = true }) and true or false
			end)
		end
		local function hasTarget()
			if opts.uid then
				return true
			end
			if not opts.pick then
				return true
			end
			local ok, t = pcall(opts.pick)
			return ok and t ~= nil
		end
		while running and token == runToken and BX.alive() do
			svc.RunService.Heartbeat:Wait()
			if not running or token ~= runToken then
				break
			end
			local isCancelled = function()
				return (not running) or token ~= runToken or (not BX.alive())
			end

			-- UID MODE: check the egg still exists BEFORE running anything.
			-- This is the fix - if the egg we were targeting is gone, stop
			-- the whole run instead of waiting.
			if opts.uid and not eggs.get(opts.uid) then
				log.info("target egg %s is gone - stopping run", tostring(opts.uid))
				return "target-gone"
			end

			if not hasTarget() then
				if lastIdleWhy ~= "no-match" then
					lastIdleWhy = "no-match"
					log.info("idle: nothing matching")
				end
				setActivity("waiting")
				if autoTreadmill then
					holdTreadmill()
				else
					releaseTreadmill()
				end
				task.wait(dev.scale(IDLE_WAIT))
			else
				lastIdleWhy = nil
				releaseTreadmill()
				local ok, why, cycle = runCycle(token, isCancelled)

				-- In UID mode, if the egg disappears mid-cycle, we stop.
				if
					opts.uid
					and (
						why == "selected egg is gone"
						or (type(why) == "string" and why:find("waiting for the selected egg", 1, true))
					)
				then
					log.info("target egg is gone mid-cycle - stopping")
					if cycle then
						reportCycle(ok, why, cycle)
					end
					return "target-gone"
				end

				local idle = type(why) == "string"
						and (why:find("^nothing to steal") or why:find("^nothing matches the filter"))
					or false
				local waiting = idle
					or why == "selected egg is gone"
					or (type(why) == "string" and why:find("waiting for the selected egg", 1, true) ~= nil)
				if waiting then
					if why ~= lastIdleWhy then
						lastIdleWhy = why
						log.info("idle: %s", why)
					end
					setActivity("waiting")
					if autoTreadmill then
						holdTreadmill()
					else
						releaseTreadmill()
					end
					task.wait(dev.scale(IDLE_WAIT))
				else
					if cycle then
						reportCycle(ok, why, cycle)
					end
					if why == "cancelled" then
						break
					end
					if ok and not (cycle and cycle.terminal) then
						failures = 0
						preps = preps + 1
						if preps > MAX_PREPS then
							break
						end
					elseif ok and opts.continuous then
						failures = 0
						cycles = cycles + 1
					elseif ok then
						failures = 0
						cycles = cycles + 1
						break
					else
						failures = failures + 1
						local wait = math.min(BACKOFF_BASE * (2 ^ (failures - 1)), BACKOFF_CAP)
						task.wait(dev.scale(wait))
					end
				end
			end
		end
		releaseTreadmill()
		setActivity("idle")
		if preps > MAX_PREPS then
			return "ended"
		end
		if cycles > 0 then
			return "delivered"
		end
		return "ended"
	end

	local function stop(reason)
		if not running then
			return
		end
		running = false
		runToken = runToken + 1
		st.autoStealOn = false
		setActivity("idle")
		if sc then
			sc:destroy()
			sc = nil
		end
		failures = 0
		local whose = owner
		owner = nil
		opts = {}
		BX.try("autosteal.antideath", adeath.disarm)
		BX.try("autosteal.humanoid", hswap.disarm)
		BX.try("autosteal.guard", guard.disarm)
		BX.try("autosteal.resetMovement", move.reset)
		BX.try("autosteal.unanchor", function()
			local hrp = ch.root()
			if hrp and hrp.Anchored then
				hrp.Anchored = false
			end
		end)
		BX.try("autosteal.tmReleaseOnStop", function()
			local hold = BX.require("features.farm.treadmill_on")
			if hold.isOn() and st.stayOnTreadmill then
				hold.setEnabled(false)
			end
		end)
		BX.try("autosteal.restore", function()
			rs.restoreAll()
		end)
		-- Clear the egg panel highlight (if the panel is loaded).
		BX.try("autosteal.clearPanel", function()
			BX.require("ui.eggpanel").clearActive()
		end)

		if reason == "delivered" then
			fireNotify("Delivered", "Egg is safe - run complete", "success", 3)
		elseif reason == "target-gone" then
			fireNotify("Target gone", "The egg you picked is gone - stopped", "warn", 3)
		elseif reason == "toggled off" then
			fireNotify("Auto Steal", "Stopped by user", "info", 2)
		elseif reason and reason ~= "ended" and reason ~= "picked" then
			fireNotify("Auto Steal stopped", tostring(reason), "warn", 3)
		end

		local why = reason or "requested"
		for _, fn in ipairs(stopListeners) do
			task.spawn(function()
				BX.try("autosteal.onStop", fn, why, whose)
			end)
		end
	end

	local function notifyDelivered(target)
		if not target then
			return
		end
		local name = tostring(target.name or "Egg")
		local rate = target.value and (eggs.formatRate(target.value) .. "/s") or "?"
		fireNotify("Delivered \u{2014} " .. name, rate .. "  \u{B7}  " .. tostring(target.rarity or ""), "success", 4)
	end

	function M.capability()
		local exec = BX.require("core.exec")
		local paths = {}
		if instant.ready then
			paths[#paths + 1] = "instant"
		end
		if exec.can.prompts then
			paths[#paths + 1] = "prompt"
		end
		if #paths == 0 then
			return false, "Auto Steal cannot run on this executor"
		end
		return true, table.concat(paths, " + ")
	end

	local function start(src)
		if running then
			return
		end
		local okCap, capWhy = M.capability()
		if not okCap then
			log.error("%s", capWhy)
			return false, capWhy
		end
		owner = tostring(src or "main")
		opts = optsFor[owner] or {}
		if sc then
			sc:destroy()
		end
		runToken = runToken + 1
		running = true
		st.autoStealOn = true
		sc = BX.scope("features.autosteal")
		local token = runToken
		ch.onSpawn(sc, "autosteal.respawn", function()
			if not running or token ~= runToken then
				return
			end
			failures = 0
		end)
		for _, a in ipairs({ { "humanoid", hswap.arm }, { "guard", guard.arm }, { "antideath", adeath.arm } }) do
			BX.try("autosteal.arm." .. a[1], a[2])
		end
		fireNotify("Auto Steal", "Started (" .. tostring(src or "farm") .. ")", "success", 2.5)
		fireStart("started", owner)
		sc:spawn("loop", function()
			local reason = runLoop(token)
			if token == runToken then
				if reason == "delivered" then
					stop("delivered")
				elseif reason == "target-gone" then
					stop("target-gone")
				elseif running then
					stop(reason or "ended")
				end
			end
		end)
		return true
	end

	function M.setOptions(src, o)
		if type(src) == "table" or src == nil then
			src, o = "main", src
		end
		src = tostring(src)
		optsFor[src] = o or {}
		if running and owner == src then
			opts = optsFor[src]
		end
	end

	function M.setEnabled(on, src)
		src = tostring(src or "main")
		if on then
			local okStart, why = start(src)
			if okStart == false then
				return false, why
			end
		else
			if running and owner ~= nil and owner ~= src then
				return false
			end
			stop("toggled off")
		end
		return true
	end

	function M.pickNow(uid)
		if not uid then
			return false, "no uid"
		end
		if running then
			stop("picked")
		end
		optsFor["farm"] = { uid = uid }
		return start("farm")
	end

	function M.owner()
		return owner
	end
	function M.isRunning()
		return running
	end
	function M.status()
		return {
			running = running,
			token = runToken,
			cycles = cycles,
			failures = failures,
			tier = dev.tier,
			scope = sc and sc:counts() or nil,
		}
	end

	M.stop = stop
	M.onDelivered(notifyDelivered)
	return M
end)

-- =============================================================================
-- features/bossfight.lua
-- =============================================================================

BX.module("features.bossfight", function(BX)
	local svc = BX.require("core.services")
	local ch = BX.require("core.character")
	local net = BX.require("core.net")
	local boss = BX.require("features.boss")
	local mov = BX.require("features.movement")
	local auto = BX.require("features.autosteal")
	local M = {}
	local K = {
		TICK = 0.12,
		SWING_GAP = 0.65,
		REACH = 9,
		EQUIP_SETTLE = 0.25,
		RESPAWN_SETTLE = 0.6,
		HAND_REACH_Y = 30,
		STEP_SPEED = 420,
		MAX_STEP = 14,
		MAX_DT = 0.05,
		Y_TAU = 0.12,
		MOVE_ARRIVE = 1.5,
		SWING_SLACK = 4,
		AIM_EASE = 0.35,
		GROUND_BAND = 25,
		PROBE_UP = 40,
		PROBE_DOWN = 220,
		FLING_UP = 60,
		FLING_MULT = 2.0,
		HAND_BONES = { "UpperHand1.R", "UpperHand1.L", "LowerHand1.R", "LowerHand1.L" },
	}
	local sc, enabled = nil, false
	local stats = { swings = 0, kills = 0 }
	function M.isOn()
		return enabled
	end
	local S = nil
	local function fresh()
		return {
			goal = nil,
			aim = nil,
			lastSolid = nil,
			arenaFloorY = nil,
			lastSwingAt = 0,
			batFor = nil,
			arena = nil,
			ignore = nil,
			ignoreAt = 0,
			inArena = false,
			noclipped = false,
			left = false,
			settleUntil = 0,
			phase = nil,
			kind = nil,
		}
	end
	local function inArena()
		return svc.LocalPlayer:GetAttribute("InBossArena") == true
	end
	M.inArena = inArena
	local function arena()
		local a = S.arena
		if a and a.Parent then
			return a
		end
		a = workspace:FindFirstChild("BossArena") or workspace:FindFirstChild("BossArena", true)
		S.arena = a
		return a
	end
	local function arenaFloor()
		local a = arena()
		local f = a and a:FindFirstChild("Floor", true)
		if f and f:IsA("BasePart") then
			return f
		end
	end
	local function bossModel()
		local a = arena()
		if not a then
			return nil
		end
		local b = a:FindFirstChild("Boss", true)
		if b and b:IsA("Model") then
			return b
		end
	end
	local function phase()
		local b = bossModel()
		if not b then
			return nil
		end
		if b:GetAttribute("Spawning") then
			return nil
		end
		if b:GetAttribute("PhaseTwoAt") ~= nil then
			return "hands"
		end
		return "crystals"
	end
	local probeParams = RaycastParams.new()
	probeParams.FilterType = Enum.RaycastFilterType.Exclude
	probeParams.IgnoreWater = true
	local function refreshIgnore()
		local now = os.clock()
		if S.ignore and (now - S.ignoreAt) < 0.5 then
			return
		end
		local ignore = {}
		for _, pl in ipairs(svc.Players:GetPlayers()) do
			if pl.Character then
				ignore[#ignore + 1] = pl.Character
			end
		end
		local a = arena()
		if a then
			for _, nm in ipairs({ "CrystalTowers", "Boss" }) do
				local d = a:FindFirstChild(nm, true)
				if d then
					ignore[#ignore + 1] = d
				end
			end
		end
		probeParams.FilterDescendantsInstances = ignore
		S.ignore, S.ignoreAt = ignore, now
	end
	local function groundAt(pos)
		refreshIgnore()
		local top = pos.Y + K.PROBE_UP
		local f = arenaFloor()
		if f then
			top = math.max(top, f.Position.Y + K.PROBE_UP)
		end
		local reach = math.max(K.PROBE_DOWN, (top - pos.Y) + K.PROBE_DOWN)
		local r = workspace:Raycast(Vector3.new(pos.X, top, pos.Z), Vector3.new(0, -reach, 0), probeParams)
		if not r then
			return nil
		end
		if f and (r.Position.Y - f.Position.Y) > K.GROUND_BAND then
			return nil
		end
		return r.Position.Y
	end
	local function isBatTool(t)
		return t:IsA("Tool") and (t:GetAttribute("IsBat") == true or t.Name:find("Bat") ~= nil)
	end
	local function equipBat()
		local char = ch.get()
		if not char then
			return nil
		end
		for _, t in ipairs(char:GetChildren()) do
			if isBatTool(t) then
				return t
			end
		end
		local bp = svc.LocalPlayer:FindFirstChild("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if isBatTool(t) then
					local hum = ch.humanoid()
					local ok = hum and pcall(function()
						hum:EquipTool(t)
					end)
					if not ok or t.Parent ~= char then
						t.Parent = char
					end
					return t
				end
			end
		end
	end
	local batSeq = 0
	local function batSwing(bat)
		local ok = pcall(function()
			local rem = net.find("RE/BatSwing/Trigger")
			if not rem then
				error("no BatSwing remote")
			end
			batSeq = batSeq + 1
			rem:FireServer(
				nil,
				("%d:%d:%d"):format(svc.LocalPlayer.UserId, batSeq, math.floor(workspace:GetServerTimeNow() * 1000))
			)
		end)
		if not ok then
			pcall(function()
				bat:Activate()
			end)
		end
	end
	local function readyAfterRagdoll()
		local hm, h = ch.humanoid(), ch.root()
		if not hm or not h then
			return
		end
		hm.PlatformStand = false
		hm.Sit = false
		hm.AutoRotate = true
		local st = hm:GetState()
		if
			st == Enum.HumanoidStateType.Physics
			or st == Enum.HumanoidStateType.PlatformStanding
			or st == Enum.HumanoidStateType.FallingDown
			or st == Enum.HumanoidStateType.Ragdoll
			or st == Enum.HumanoidStateType.Seated
		then
			hm:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		h.AssemblyLinearVelocity = Vector3.zero
		h.AssemblyAngularVelocity = Vector3.zero
	end
	local function antiFling()
		local h, hum = ch.root(), ch.humanoid()
		if not h or not hum then
			return
		end
		local v = h.AssemblyLinearVelocity
		local flat = (v * Vector3.new(1, 0, 1)).Magnitude
		local cap = math.max((hum.WalkSpeed or 16) * K.FLING_MULT, 120)
		if v.Y <= K.FLING_UP and flat <= cap then
			return
		end
		local keep = Vector3.zero
		if flat > 0.001 then
			keep = (v * Vector3.new(1, 0, 1)).Unit * math.min(flat, hum.WalkSpeed or 16)
		end
		h.AssemblyLinearVelocity = Vector3.new(keep.X, math.min(v.Y, 0), keep.Z)
		h.AssemblyAngularVelocity = Vector3.zero
	end
	local function target()
		local h = ch.root()
		if not h then
			return nil
		end
		local ph = phase()
		if not ph then
			return nil
		end
		if ph == "crystals" then
			local a = arena()
			local towers = a and a:FindFirstChild("CrystalTowers", true)
			if not towers then
				return nil
			end
			local best, bestD
			for _, d in ipairs(towers:GetDescendants()) do
				if d:IsA("BasePart") and d.Name == "Hitbox" then
					local hp = d:GetAttribute("Health")
					if type(hp) == "number" and hp > 0 then
						local dist = (d.Position - h.Position).Magnitude
						if not bestD or dist < bestD then
							best, bestD = d, dist
						end
					end
				end
			end
			if best then
				return best, "crystal"
			end
			return nil
		end
		local b = bossModel()
		if not b then
			return nil
		end
		local myY = h.Position.Y
		local low, lowD
		for _, bn in ipairs(K.HAND_BONES) do
			local bone = b:FindFirstChild(bn, true)
			if bone and bone:IsA("Bone") then
				local pos
				pcall(function()
					pos = bone.TransformedWorldCFrame.Position
				end)
				pos = pos or bone.WorldPosition
				if pos then
					local flat = Vector3.new(pos.X - h.Position.X, 0, pos.Z - h.Position.Z).Magnitude
					if (pos.Y - myY) <= K.HAND_REACH_Y and (not lowD or flat < lowD) then
						low, lowD = pos, flat
					end
				end
			end
		end
		if low then
			return low, "hand"
		end
		return nil
	end
	local function leaveArena()
		local a = arena()
		local exit = a and a:FindFirstChild("BossArenaLeaveTeleport", true)
		local part = exit and (exit:IsA("BasePart") and exit or exit:FindFirstChildWhichIsA("BasePart", true))
		local c = ch.get()
		if not (part and c) then
			return false
		end
		c:MoveTo(part.Position + Vector3.new(0, 3, 0))
		return true
	end
	local function setNoclip(on)
		if on == S.noclipped then
			return
		end
		S.noclipped = on
		if on then
			mov.noclip(true)
		elseif not auto.isRunning() then
			mov.noclip(false)
		end
	end
	local function moverStep(dt)
		if not S.inArena or auto.isRunning() then
			return
		end
		if S.settleUntil and os.clock() < S.settleUntil then
			return
		end
		antiFling()
		local goal = S.goal
		if not goal then
			return
		end
		local h, hum = ch.root(), ch.humanoid()
		if not h or not hum then
			return
		end
		if groundAt(h.Position) then
			S.lastSolid = h.Position
		elseif S.lastSolid then
			local back = Vector3.new(S.lastSolid.X - h.Position.X, 0, S.lastSolid.Z - h.Position.Z)
			if back.Magnitude > 1 then
				local st2 = math.min(back.Magnitude, math.min(dt, K.MAX_DT) * K.STEP_SPEED, K.MAX_STEP)
				local nb = h.Position + back.Unit * st2
				local gyb = groundAt(nb) or S.lastSolid.Y
				hum.PlatformStand = false
				h.CFrame = CFrame.lookAt(Vector3.new(nb.X, gyb, nb.Z), Vector3.new(nb.X, gyb, nb.Z) + back.Unit)
				h.AssemblyLinearVelocity = Vector3.zero
			end
			return
		end
		local flat = Vector3.new(goal.pos.X - h.Position.X, 0, goal.pos.Z - h.Position.Z)
		local reach = goal.reach or K.REACH
		local left = flat.Magnitude - reach
		if left <= K.MOVE_ARRIVE then
			S.goal = nil
			return
		end
		local step = math.min(left, math.min(dt, K.MAX_DT) * K.STEP_SPEED, K.MAX_STEP)
		local nxt = h.Position + flat.Unit * step
		local gy = groundAt(Vector3.new(nxt.X, h.Position.Y, nxt.Z))
		if not gy then
			return
		end
		local curY = h.Position.Y
		local k = 1 - math.exp(-dt / K.Y_TAU)
		local dest = Vector3.new(nxt.X, curY + (gy - curY) * k, nxt.Z)
		hum.PlatformStand = false
		hum:Move(Vector3.zero, false)
		h.CFrame = CFrame.lookAt(dest, dest + flat.Unit)
		h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.y or 0, 0)
		h.AssemblyAngularVelocity = Vector3.zero
	end
	local function fightTick()
		local inside = inArena()
		if inside ~= S.inArena then
			S.inArena = inside
			setNoclip(inside)
			S.goal, S.aim = nil, nil
			S.lastSolid, S.arenaFloorY, S.left = nil, nil, false
			if inside then
				S.settleUntil = os.clock() + K.RESPAWN_SETTLE
				readyAfterRagdoll()
			end
		end
		if not inside or auto.isRunning() or S.left then
			return
		end
		if S.settleUntil and os.clock() < S.settleUntil then
			return
		end
		local bat = equipBat()
		if bat and S.batFor ~= bat then
			S.batFor = bat
			task.wait(K.EQUIP_SETTLE)
		end
		local hmz = ch.humanoid()
		if hmz then
			local stt = hmz:GetState()
			if
				hmz.PlatformStand
				or stt == Enum.HumanoidStateType.Physics
				or stt == Enum.HumanoidStateType.PlatformStanding
				or stt == Enum.HumanoidStateType.None
			then
				readyAfterRagdoll()
			end
		end
		local snap = boss.snapshot()
		if snap and tonumber(snap.BossHealth) and snap.BossHealth <= 0 then
			stats.kills = stats.kills + 1
			boss.claimMilestones()
			S.left = leaveArena()
			S.goal, S.aim = nil, nil
			return
		end
		S.phase = phase()
		local part, kind = target()
		if not part then
			S.goal, S.aim, S.kind = nil, nil, nil
			return
		end
		S.kind = kind
		local tpos = (typeof(part) == "Vector3") and part or part.Position
		local h = ch.root()
		if not h then
			return
		end
		local reach = K.REACH
		if part and part:IsA("BasePart") then
			reach = math.max(K.REACH, math.max(part.Size.X, part.Size.Z) * 0.5 - 20)
		end
		local flatDir = Vector3.new(tpos.X - h.Position.X, 0, tpos.Z - h.Position.Z)
		local d = flatDir.Magnitude
		S.aim = tpos
		if d > reach + K.SWING_SLACK then
			S.goal = { pos = tpos, reach = reach }
			return
		end
		S.goal = nil
		if flatDir.Magnitude > 0.1 then
			h.CFrame = h.CFrame:Lerp(CFrame.lookAt(h.CFrame.Position, h.CFrame.Position + flatDir.Unit), K.AIM_EASE)
		end
		if not bat or not bat.Parent then
			return
		end
		if bat:GetAttribute("CooldownActive") == true then
			return
		end
		if os.clock() - S.lastSwingAt < K.SWING_GAP then
			return
		end
		S.lastSwingAt = os.clock()
		batSwing(bat)
		stats.swings = stats.swings + 1
	end
	function M.status()
		if not enabled then
			return { title = "Auto fight", body = "off" }
		end
		if auto.isRunning() then
			return { title = "Auto fight", body = "waiting for Auto Steal" }
		end
		if not S.inArena then
			return { title = "Auto fight", body = "waiting for boss world" }
		end
		if S.left then
			return { title = "Auto fight", body = "Boss dead - leaving" }
		end
		local ph = S.phase
		if not ph then
			return { title = "Auto fight", body = "In arena - spawning" }
		end
		return { title = "Auto fight", body = ("Fighting  \u{B7}  %s  \u{B7}  %d swings"):format(ph, stats.swings) }
	end
	function M.setEnabled(on)
		on = on and true or false
		if on == enabled then
			return true
		end
		if not on then
			enabled = false
			if sc then
				sc:destroy()
				sc = nil
			end
			if S then
				S.goal, S.aim = nil, nil
				setNoclip(false)
			end
			S = nil
			return true
		end
		if not boss.isOn() then
			boss.setEnabled(true)
		end
		S = fresh()
		sc = BX.scope("features.bossfight")
		enabled = true
		sc:onFrame("mover", svc.RunService.Heartbeat, moverStep)
		sc:loop("fight", K.TICK, fightTick)
		ch.onSpawn(sc, "bossfight.respawn", function()
			if not S then
				return
			end
			setNoclip(false)
			S.goal, S.aim, S.batFor = nil, nil, nil
			S.lastSolid, S.arenaFloorY, S.left = nil, nil, false
			S.inArena, S.noclipped = false, false
			S.settleUntil = os.clock() + K.RESPAWN_SETTLE
		end)
		return true
	end
	return M
end)

-- =============================================================================
-- features/prewarm.lua
-- =============================================================================

BX.module("features.prewarm", function(BX)
	local svc = BX.require("core.services")
	local M = {}
	local sc = nil
	function M.start()
		if sc then
			return false
		end
		sc = BX.scope("features.prewarm")
		sc:spawn("warm", function()
			local grab = BX.require("features.grab")
			svc.RunService.Heartbeat:Wait()
			BX.try("prewarm.prompts", function()
				grab.warmPrompts()
			end)
			local plot = BX.require("features.plot")
			svc.RunService.Heartbeat:Wait()
			BX.try("prewarm.safeZone", function()
				plot.safeZone()
			end)
			local bait = BX.require("features.bait")
			svc.RunService.Heartbeat:Wait()
			BX.try("prewarm.baitArea", function()
				bait.firstAreaId(6)
			end)
			local move = BX.require("features.movement")
			local ch = BX.require("core.character")
			svc.RunService.Heartbeat:Wait()
			BX.try("prewarm.ground", function()
				local hrp = ch.root()
				if hrp then
					move.groundY(hrp.Position)
				end
			end)
		end)
		return true
	end
	return M
end)

-- =============================================================================
-- main.lua - with Auto-Save loop
-- =============================================================================

do
	local logmod = BX.require("boot.log")
	local cfg = BX.require("core.config")
	logmod.level = cfg.LOG_LEVEL
	local log = logmod.for_module("startup")
	logmod.session(("Hanssyz %s build %s | generation %d"):format(BX.version, BX.build, BX.generation))

	local startup = { state = "BOOTING", stages = {}, t0 = os.clock() }
	local env = (type(getgenv) == "function" and getgenv()) or _G
	env.HanssyzStartup = startup
	local function setState(s)
		startup.state = s
	end
	local function stage(name, required, fn)
		local s0 = os.clock()
		local ok, res = pcall(fn)
		local ms = (os.clock() - s0) * 1000
		startup.stages[#startup.stages + 1] = {
			name = name,
			result = ok and "OK" or "FAILED",
			detail = ok and nil or tostring(res),
			at = os.clock() - startup.t0,
			ms = ms,
		}
		if not ok and required then
			startup.failedAt = name
			startup.error = tostring(res)
		end
		return ok, res
	end

	setState("BOOTING")
	if not stage("services", true, function()
		BX.require("core.services")
	end) then
		warn("[HANSSYZ] startup failed at services: " .. tostring(startup.error))
		return
	end
	stage("exec", false, function()
		BX.require("core.exec")
	end)
	stage("device", false, function()
		BX.require("core.device")
	end)
	stage("state", false, function()
		BX.require("core.state")
	end)
	stage("util", false, function()
		BX.require("core.util")
	end)
	stage("character", false, function()
		BX.require("core.character")
	end)

	setState("LOADING")
	stage("eggs", false, function()
		BX.require("features.eggs")
	end)

	setState("UI_BUILDING")
	local win
	local okWin = stage("rayfield", true, function()
		win = BX.require("ui.window")
		if not win.ok then
			error(win.error or "window unavailable", 0)
		end
	end)
	if not okWin or not win or not win.ok then
		warn("[HANSSYZ] startup failed at rayfield: " .. tostring(startup.error))
		setState("FAILED")
		return
	end
	stage("hide menu", false, function()
		win.hide()
	end)

	stage("home", false, function()
		BX.require("ui.tabs.home").build(win.tab("Home"))
	end)
	stage("farm", false, function()
		BX.require("ui.tabs.farm").build(win.tab("Farm"))
	end)
	stage("event", false, function()
		BX.require("ui.tabs.event").build(win.tab("Event"))
	end)
	stage("misc", false, function()
		BX.require("ui.tabs.misc").build(win.tab("Misc"))
	end)
	stage("config", false, function()
		local prof = BX.require("core.profiles")
		local look = BX.require("features.misc.appearance")
		prof.setFlagSource(function()
			local w = win.window
			return (type(w) == "table" and type(w.controls) == "table" and w.controls) or {}
		end)
		prof.setAppearanceHooks(look.read, look.apply)
		BX.require("ui.tabs.config").build(win.tab("Config"))
		local bg = cfg.DEFAULT_BACKGROUND
		if bg and bg ~= "" then
			BX.try("startup.bg", function()
				look.setBackground(bg)
			end)
		end
	end)

	stage("webhook", false, function()
		local hook = BX.require("features.misc.webhook")
		BX.require("features.autosteal").onDelivered(function(e)
			hook.onDelivered(e)
		end)
	end)
	stage("treadmill", false, function()
		BX.require("features.treadmill").arm()
	end)
	stage("fps", false, function()
		BX.require("features.fps").arm()
	end)
	stage("jump", false, function()
		BX.require("features.jump").arm()
	end)
	stage("prewarm", false, function()
		BX.require("features.prewarm").start()
	end)
	stage("status HUD module", false, function()
		BX.require("ui.status")
	end)

	stage("notify", false, function()
		local notify = BX.require("ui.notify")
		local auto = BX.require("features.autosteal")
		auto.onNotify(function(title, body, kind, dur)
			notify.show(title, body, kind, dur)
		end)
	end)

	stage("egg panel", false, function()
		BX.require("ui.eggpanel").show(true)
	end)

	-- AUTOSAVE: load once at startup if enabled.
	stage("autoload", false, function()
		local prof = BX.require("core.profiles")
		if prof.autoSaveOn() then
			local ok, applied = prof.loadAuto()
			if ok then
				log.info("autosave restored (%d controls)", applied or 0)
				return "AUTOSAVE"
			end
		end
		-- Fall back to a named profile if no autosave.
		local ok, msg = prof.runAutoLoad()
		if not ok then
			return "SKIPPED: " .. tostring(msg)
		end
	end)

	-- AUTOSAVE: periodic save loop while this generation lives.
	stage("autosave loop", false, function()
		local prof = BX.require("core.profiles")
		local sc = BX.scope("startup.autosave")
		sc:loop("save", cfg.AUTOSAVE_INTERVAL, function()
			if not prof.autoSaveOn() then
				return
			end
			prof.saveAuto()
		end)
	end)

	BX.try("startup.reveal", function()
		win.reveal()
		setState("READY")
		startup.readyAt = os.clock() - startup.t0
		log.info("ready in %.2fs", startup.readyAt)
	end)
	startup.initAt = os.clock() - startup.t0
	logmod.session(("startup complete in %.2fs"):format(startup.initAt))

	BX.profile.start()

	env.HanssyzAudit = function()
		local h = BX.profile.health()
		print(("[HANSSYZ] up %.0fs | mem %.0fMB | %d modules"):format(h.uptime, h.mem, h.loaded))
		return h
	end
	env.HanssyzStages = function()
		for _, s in ipairs(startup.stages) do
			print(
				("[HANSSYZ]   %-18s %-9s %7.0fms%s"):format(
					s.name,
					s.result,
					s.ms or 0,
					s.detail and ("  " .. s.detail) or ""
				)
			)
		end
	end
end
