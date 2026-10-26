-- Execute the real server and client controllers against small Roblox API fakes.
-- These regressions verify event/lifecycle logic, not rendering or engine physics.
local Config = dofile("src/shared/Config.lua")
local Reel = dofile("src/shared/Reel.lua")
local HoleRules = dofile("src/shared/HoleRules.lua")
local Progression = dofile("src/shared/Progression.lua")
local FishGeneration = dofile("src/shared/FishGeneration.lua")
local Settings = dofile("src/server/ServerSettings.lua")
local Schema = dofile("src/server/ProfileSchema.lua").create(Config, Progression)
local checks = 0
local mode = "server"
local function check(value, message) assert(value, message) checks = checks + 1 end
local function signal()
    local s = { handlers = {} }
    function s:Connect(fn) table.insert(self.handlers, { fn = fn, mode = mode }) return { Disconnect = function() end } end
    function s:Fire(...)
        for _, handler in ipairs(self.handlers) do
            local previous = mode
            mode = handler.mode
            handler.fn(...)
            mode = previous
        end
    end
    return s
end
local Vec = {}
Vec.__index = function(v, key)
    if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if key == "Unit" then return v / v.Magnitude end
    return Vec[key]
end
local function vec(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vec) end
Vec.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vec.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vec.__mul = function(a, b) return vec(a.X * b, a.Y * b, a.Z * b) end
Vec.__div = function(a, b) return vec(a.X / b, a.Y / b, a.Z / b) end
Vec.__unm = function(a) return vec(-a.X, -a.Y, -a.Z) end
local CF = {}
CF.__index = CF
local function cf(x, y, z)
    return setmetatable({ Position = type(x) == "table" and x or vec(x, y, z), LookVector = vec(0, 0, -1) }, CF)
end
CF.__mul = function(a, b) return cf(a.Position + b.Position) end
function CF:Lerp(other) return other end
local methods, meta = {}, {}
local currentPlayer
local function instance(class)
    local obj = { props = { ClassName = class, Name = class, Visible = true, Anchored = false, PlatformStand = false, MoveDirection = vec() }, children = {}, attributes = {} }
    for _, name in ipairs({ "OnServerEvent", "OnClientEvent", "Triggered", "CharacterRemoving", "CharacterAdded", "Activated", "InputBegan", "InputEnded", "InputChanged", "Destroying" }) do obj.props[name] = signal() end
    return setmetatable(obj, meta)
end
meta.__index = function(obj, key)
    if methods[key] then return methods[key] end
    if obj.props[key] ~= nil then return obj.props[key] end
    for _, child in ipairs(obj.children) do if child.Name == key and not child.destroyed then return child end end
end
meta.__newindex = function(obj, key, value)
    obj.props[key] = value
    if key == "Parent" and value then table.insert(value.children, obj) end
    if key == "CFrame" then obj.props.Position = value.Position end
end
function methods:GetChildren()
    local result = {}
    for _, c in ipairs(self.children) do if not c.destroyed then table.insert(result, c) end end
    return result
end
function methods:GetDescendants()
    local result = {}
    for _, c in ipairs(self:GetChildren()) do
        table.insert(result, c)
        for _, descendant in ipairs(c:GetDescendants()) do table.insert(result, descendant) end
    end
    return result
end
function methods:FindFirstChild(name) for _, c in ipairs(self:GetChildren()) do if c.Name == name then return c end end end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), "Missing child " .. name) end
function methods:FindFirstChildOfClass(name) for _, c in ipairs(self:GetChildren()) do if c.ClassName == name then return c end end end
function methods:IsA(name) return self.ClassName == name end
function methods:Destroy()
    self.Destroying:Fire()
    for _, c in ipairs(self:GetChildren()) do c:Destroy() end
    rawset(self, "destroyed", true)
    self.Parent = nil
end
function methods:GetAttributeChangedSignal(name)
    self.attributeSignals = self.attributeSignals or {}
    self.attributeSignals[name] = self.attributeSignals[name] or signal()
    return self.attributeSignals[name]
end
function methods:SetAttribute(name, value)
    local old = self.attributes[name]
    self.attributes[name] = value
    if old ~= value and self.attributeSignals and self.attributeSignals[name] then self.attributeSignals[name]:Fire() end
end
function methods:Kick(reason) self.KickedReason = reason end
function methods:LoadCharacterAsync() self.RespawnCount = (self.RespawnCount or 0) + 1 end
function methods:GetAttribute(name) return self.attributes[name] end
function methods:SetStateEnabled(_, value) self["stateEnabled_" .. mode] = value end
function methods:GetStateEnabled() return self["stateEnabled_" .. mode] ~= false end
function methods:FireClient(recipient, ...) if recipient == currentPlayer then self.OnClientEvent:Fire(...) end end
function methods:FireServer(...) self.OnServerEvent:Fire(currentPlayer, ...) end
local function child(parent, class, name)
    local i = instance(class)
    i.Name, i.Parent = name or class, parent
    return i
end
local now, tasks = 0, {}
local function delay(dt, fn) table.insert(tasks, { at = now + dt, fn = fn, mode = mode }) end
local function spawn(fn)
    local co = coroutine.create(fn)
    local function resume()
        local ok, dt = coroutine.resume(co)
        assert(ok, dt)
        if coroutine.status(co) ~= "dead" then delay(dt or 0, resume) end
    end
    delay(0, resume)
end
local heartbeat, render = signal(), signal()
local function tick(dt)
    now = now + dt
    local pending = tasks
    tasks = {}
    for _, task in ipairs(pending) do
        if task.at <= now then
            local previous = mode
            mode = task.mode
            task.fn()
            mode = previous
        else table.insert(tasks, task) end
    end
    heartbeat:Fire(dt)
    render:Fire(dt)
end
local function advance(seconds) for _ = 1, math.ceil(seconds * 60) do tick(1 / 60) end end
local storage, players = instance("ReplicatedStorage"), instance("Players")
players.PlayerAdded, players.PlayerRemoving = signal(), signal()
local player = instance("Player")
player.UserId, player.DisplayName, player.Parent = 123, "TestAngler", players
currentPlayer, players.LocalPlayer = player, player
local playerList = { player }
function players:GetPlayers() return playerList end
function players:GetPlayerByUserId(id) for _, p in ipairs(playerList) do if p.UserId == id then return p end end end
function players:GetUserIdFromNameAsync(name) assert(name == "unbenator") return 123 end
player.Name = "unbenator"
local character = instance("Model")
character.Name, character.Parent, player.Character = "Character", instance("Workspace"), character
local humanoid = child(character, "Humanoid")
humanoid.Health, humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = 100, 16, 50, 7.2, true
CF.Rotation = cf()
humanoid.MaxHealth = 100
local root = child(character, "Part", "HumanoidRootPart")
root.Position, root.CFrame = vec(0, 5, 0), cf(0, 5, 0)
child(player, "PlayerGui")
local worldState = { holes = {}, tools = {} }
local World = {}
function World.build()
    worldState.sellPrompt = instance("ProximityPrompt")
    return instance("Folder"), instance("ProximityPrompt"), worldState.sellPrompt
end
function World.drilling() return instance("Part") end
function World.hole(_, position, size)
    local model = instance("Model")
    local prompt = instance("ProximityPrompt")
    table.insert(worldState.holes, { model = model, prompt = prompt, position = position, size = size })
    return model, prompt
end
function World.line() return instance("Model"), instance("Part") end
local Equipment = {}
function Equipment.mount(anglerCharacter, category, id)
    table.insert(worldState.tools, { category = category, id = id })
    local model = instance("Model")
    model.Parent = anglerCharacter
    return model, instance("Motor6D"), cf()
end
local shared = child(storage, "Folder", "Shared")
for name, module in pairs({ Config = Config, Reel = Reel, HoleRules = HoleRules, Equipment = Equipment, Progression = Progression, FishGeneration = FishGeneration }) do
    local m = child(shared, "ModuleScript", name)
    m.module = module
end
local serverFolder = instance("Folder")
child(serverFolder, "ModuleScript", "World").module = World
local workspaceFake = { GetServerTimeNow = function() return now end }
local bound = {}
local context = {}
function context:BindActionAtPriority(name, fn, _, priority) bound[name] = { fn = fn, priority = priority } end
function context:UnbindAction(name) bound[name] = nil end
local input = { InputBegan = signal(), InputEnded = signal(), InputChanged = signal(), WindowFocusReleased = signal(), GetFocusedTextBox = function() return nil end, IsKeyDown = function() return false end }
local enums = setmetatable({ ContextActionPriority = { High = { Value = 3000 } } }, { __index = function(t, k)
    local values = setmetatable({}, { __index = function(_, n) return n end }) rawset(t, k, values) return values
end })
local services = { Players = players, ReplicatedStorage = storage, RunService = { Heartbeat = heartbeat, RenderStepped = render, IsStudio = function() return true end },
    HttpService = { GenerateGUID = function() return tostring(now) end }, UserInputService = input, ContextActionService = context }
local env = setmetatable({
    game = { BindToClose = function(_, fn) worldState.shutdown = fn end, GetService = function(_, name) return assert(services[name], "Missing service " .. name) end },
    workspace = workspaceFake, Instance = { new = instance }, Enum = enums,
    Vector3 = { new = vec, zero = vec() }, Vector2 = { new = vec, zero = vec() }, CFrame = { new = cf, Angles = function() return cf() end, lookAt = function(position) return cf(position) end },
    Color3 = { new = vec, fromRGB = vec }, UDim = { new = function(...) return { ... } end },
    UDim2 = { new = function(...) return { ... } end, fromOffset = function(...) return { ... } end, fromScale = function(...) return { ... } end },
    Random = { new = function() return { NextNumber = function(_, lo, hi) if not lo then return 0.1 end return (lo + hi) / 2 end } end },
    task = { delay = delay, spawn = spawn, wait = function(dt) return coroutine.yield(dt) end },
    warn = function() end, os = { clock = function() return now end, time = function() return math.floor(1000 + now) end }, require = function(module) return module.module end,
    script = { Parent = serverFolder },
}, { __index = _G })
child(serverFolder, "ModuleScript", "ServerSettings").module = Settings
child(serverFolder, "ModuleScript", "AdminPolicy").module = dofile("src/server/AdminPolicy.lua")
child(serverFolder, "ModuleScript", "AdminService").module = assert(loadfile("src/server/AdminService.lua", "t", env))()
child(serverFolder, "ModuleScript", "PlayerDataService").module = {
    load = function(p) p:SetAttribute("DataMode", "Studio sandbox · not saved") return Schema.new() end,
    release = function() return true end, step = function() end, shutdown = function() end,
}
assert(loadfile("src/server/Game.server.lua", "t", env))()
local command = storage.FishingRemotes.Command
local event = storage.FishingRemotes.Event
local lastProfile, lastBite, lastStage, caught = nil, nil, nil, 0
event.OnClientEvent:Connect(function(kind, data)
    if kind == "profile" then lastProfile = data elseif kind == "bite" then lastBite = data
    elseif kind == "stage" then lastStage = data elseif kind == "caught" then caught = caught + 1 end
end)
local function send(action, data) advance(0.3) command.OnServerEvent:Fire(player, action, data) end
send("ready")
check(lastProfile.coins == 120, "Server initializes coins")
send("cast")
check(lastStage.stage == "drilling", "A first cast drills using an auger")
check(worldState.tools[1].category == "auger", "A real auger mounting call occurs")
check(humanoid.WalkSpeed == 0 and humanoid.JumpPower == 0 and not humanoid:GetStateEnabled("Jumping"), "Drilling locks movement and jump")
advance(Config.DrillDuration + Config.CastDuration + 0.1)
check(#worldState.holes == 1, "Drilling creates one hole")
check(worldState.tools[2].category == "rod", "Casting switches from auger to rod")
local originalHole = worldState.holes[1]
send("cancel")
check(not originalHole.model.destroyed, "Cancellation preserves the drilled hole")
check(humanoid.WalkSpeed == 16 and humanoid.JumpPower == 50 and humanoid:GetStateEnabled("Jumping"), "Cancellation restores movement and jump")
send("cast")
check(lastStage.stage == "casting" and lastStage.reused, "Recasting bypasses drilling")
advance(4.5)
check(#worldState.holes == 1, "Recasting does not duplicate the hole")
check(lastBite and lastBite.serverTime, "Reeling includes a timed prediction snapshot")
-- Follow the real shared target to land one fish through the actual server loop.
for _ = 1, 1800 do
    if caught > 0 then break end
    command.OnServerEvent:Fire(player, "input", { token = lastBite.token, held = (lastBite.bar < lastBite.target) })
    tick(1 / 60)
    -- Read continuously published server snapshots for the controller.
    -- The observer below updates lastBite for the remaining frames.
    if not worldState.reelObserver then
        worldState.reelObserver = true
        event.OnClientEvent:Connect(function(kind, data) if kind == "reel" then lastBite = data end end)
    end
end
check(caught == 1 and #lastProfile.bag == 1, "A successful server simulation awards exactly one fish")
check(not originalHole.model.destroyed, "Catching preserves the same hole")
check(lastProfile.xp > 0 and lastProfile.statistics.catches == 1 and lastProfile.bag[1].catchId, "Catches grant XP and persistent unique inventory records")
check(humanoid.WalkSpeed == 16, "Landing a fish restores movement")
-- Character reset cancels a new cast without deleting its hole.
send("cast")
player.CharacterRemoving:Fire(character)
check(not originalHole.model.destroyed and humanoid.WalkSpeed == 16, "Reset cleans up the cast and retains the hole")
advance(6)
check(caught == 1, "Cancelled delayed callbacks cannot award another catch")
-- Explicit new-hole interaction is the only way to replace a nearby hole.
send("drill")
advance(Config.DrillDuration + 0.1)
check(#worldState.holes == 2 and originalHole.model.destroyed, "Explicit drilling replaces the old hole")
send("cancel")
local replacement = worldState.holes[2]
root.CFrame = cf(0, 5, -92)
send("buy", { category = "bait", id = "worms" })
check(lastProfile.bait.worms == 10 and lastProfile.coins == 85, "Shop purchases remain authoritative")
check(not replacement.model.destroyed, "Purchasing gear preserves the existing hole")
local beforeSale = lastProfile.coins
local saleValue = lastProfile.bag[1].value
root.CFrame = cf(11, 4, -86)
worldState.sellPrompt.Triggered:Fire(player)
check(lastProfile.coins == beforeSale + saleValue and #lastProfile.bag == 0, "The fish-selling NPC sells the actual inventory")
worldState.sellPrompt.Triggered:Fire(player)
check(lastProfile.coins == beforeSale + saleValue, "Repeated NPC interaction cannot sell the same fish twice")
-- Run actual client GUI construction and profile handling (including HUD bug).
local clientFolder = instance("Folder")
child(clientFolder, "ModuleScript", "EquipmentPreview").module = { mount = function() end, step = function() end }
child(clientFolder, "ModuleScript", "AnglerAnimation").module = { start = function() end }
child(clientFolder, "ModuleScript", "AdminMenu").module = assert(loadfile("src/client/AdminMenu.lua", "t", env))()
env.script = { Parent = clientFolder }
mode = "client"
assert(loadfile("src/client/Game.client.lua", "t", env))()
send("ready")
local function findText(needle)
    for _, object in ipairs(player.PlayerGui:GetDescendants()) do if object.Text and tostring(object.Text):find(needle, 1, true) then return object end end
end
check(findText("Hand Auger  /  Starter Rod"), "Actual client profile handler formats the equipment HUD without errors")
-- The shop render path constructs previews for every equipment category.
send("shop")
check(findText("3D VIEW"), "The actual shop exposes enlarged 3D inspection")
for _, label in ipairs({ "RODS", "BAITS", "LURES" }) do findText(label).Activated:Fire() end
root.CFrame = cf(0, 5, 0)
send("cast")
check(bound.FrostbiteReel and bound.FrostbiteReel.priority > 3000, "Reeling input is bound above the default jump controls")
local result = bound.FrostbiteReel.fn("FrostbiteReel", "Begin")
check(result == "Sink" and not humanoid:GetStateEnabled("Jumping"), "Space is consumed while fishing rather than jumping")
send("cancel")
check(not bound.FrostbiteReel and humanoid:GetStateEnabled("Jumping"), "Ending a cast unbinds Space and restores jumping")
check(not replacement.model.destroyed, "Client/server round trip still preserves the same hole")

local guest = instance("Player")
guest.UserId, guest.DisplayName, guest.Parent = 456, "unbenator", players
guest.Name = "GuestAngler"
table.insert(playerList, guest)
local guestCharacter = instance("Model")
guestCharacter.Parent, guest.Character = character.Parent, guestCharacter
local guestHumanoid = child(guestCharacter, "Humanoid")
guestHumanoid.Health, guestHumanoid.WalkSpeed, guestHumanoid.JumpPower, guestHumanoid.JumpHeight, guestHumanoid.AutoRotate = 100, 16, 50, 7.2, true
guestHumanoid.MaxHealth = 100
local guestRoot = child(guestCharacter, "Part", "HumanoidRootPart")
guestRoot.CFrame = cf(24, 5, 0)
players.PlayerAdded:Fire(guest)
root.CFrame = cf(24, 5, 0)
send("drill")
command.OnServerEvent:Fire(guest, "cast")
check(guestHumanoid.WalkSpeed == 16, "Another player cannot drill into a reserved in-progress hole")
guestRoot.CFrame = cf(-24, 5, 0)
advance(0.3)
command.OnServerEvent:Fire(guest, "cast")
check(guestHumanoid.WalkSpeed == 0 and humanoid.WalkSpeed == 0, "Separated players can drill simultaneously")
advance(Config.DrillDuration + 0.2)
check(guest.leaderstats.Coins.Value == 120, "Each player has an isolated coin balance")
send("cancel")
check(humanoid.WalkSpeed == 16 and guestHumanoid.WalkSpeed == 0, "Cancelling one session does not cancel another player's session")
local adminCommand = storage.FishingRemotes.AdminCommand
local function admin(request, actor) advance(0.35) adminCommand.OnServerEvent:Fire(actor or player, request) end
check(player:GetAttribute("IsAdmin") == true and guest:GetAttribute("IsAdmin") == false, "Only the server-resolved owner's user ID receives admin access")
check(findText("ADMIN  [F2]"), "The admin menu is created for the authorized account")
local guestCoins = guest.leaderstats.Coins.Value
guest:SetAttribute("IsAdmin", true)
admin({ action = "money", targetId = guest.UserId, amount = 500 }, guest)
check(guest.leaderstats.Coins.Value == guestCoins, "Forging an IsAdmin attribute or display name cannot grant money")
admin({ action = "money", targetId = guest.UserId, amount = -100 })
check(guest.leaderstats.Coins.Value == guestCoins, "Invalid admin grant amounts leave the balance unchanged")
admin({ action = "money", targetId = guest.UserId, amount = 500 })
check(guest.leaderstats.Coins.Value == guestCoins + 500, "Authorized admin money grants update the target's authoritative profile")
admin({ action = "xp", targetId = guest.UserId, amount = 205 })
check(guest.leaderstats.Level.Value == 3, "Admin XP grants update the target's actual progression")
admin({ action = "freeze", targetId = guest.UserId })
check(guestRoot.Anchored and guest:GetAttribute("AdminFrozen") and guestHumanoid.WalkSpeed == 16, "Freeze cancels fishing before locking movement")
admin({ action = "unfreeze", targetId = guest.UserId })
check(not guestRoot.Anchored and not guest:GetAttribute("AdminFrozen"), "Unfreeze restores the character's prior anchoring state")
admin({ action = "fly" })
advance(0.1)
check(player:GetAttribute("AdminFlying") and root:FindFirstChild("AdminFlightVelocity") and humanoid.PlatformStand, "Fly creates server-authorized flight constraints")
check(bound.AdminFlightVertical, "Flight captures its vertical controls")
send("cast")
check(not character:GetAttribute("FishingStage"), "An admin cannot start fishing while flying")
admin({ action = "fly" })
advance(0.1)
check(not player:GetAttribute("AdminFlying") and not root:FindFirstChild("AdminFlightVelocity") and not humanoid.PlatformStand, "Stopping flight cleans up constraints and restores the humanoid")
check(not bound.AdminFlightVertical, "Stopping flight releases the input binding")
guestHumanoid.Health = 10
admin({ action = "heal", targetId = guest.UserId })
check(guestHumanoid.Health == 100, "Heal restores the selected character's health")
admin({ action = "bring", targetId = guest.UserId })
check(guestRoot.Position.X == root.Position.X + 3, "Bring teleports the selected character near the admin")
local guestX = guestRoot.Position.X
admin({ action = "gotoPlayer", targetId = guest.UserId })
check(root.Position.X == guestX + 3, "Go to player teleports the admin near the selected character")
admin({ action = "pond" })
check(root.Position.Z == -40, "The pond shortcut uses the approved destination")
admin({ action = "shop" })
check(root.Position.Z == -85, "The shop shortcut uses the approved destination")
admin({ action = "respawn", targetId = guest.UserId })
advance(0.1)
check(guest.RespawnCount == 1, "Respawn invokes the selected player's character reload")
admin({ action = "kick", targetId = player.UserId })
check(not player.KickedReason, "Self-kick is refused")
admin({ action = "kick", targetId = guest.UserId, reason = "Test reason" })
check(guest.KickedReason == "Test reason", "Kick acts on the selected player with the supplied reason")
players.PlayerRemoving:Fire(guest)
check(guestHumanoid.WalkSpeed == 16, "Disconnect cleanup restores only the departing player's session")
print("PASS: " .. checks .. " controller integration checks (Roblox API fakes; not engine validation)")
