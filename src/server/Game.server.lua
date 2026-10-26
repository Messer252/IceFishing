local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local Reel = require(ReplicatedStorage.Shared.Reel)
local HoleRules = require(ReplicatedStorage.Shared.HoleRules)
local Equipment = require(ReplicatedStorage.Shared.Equipment)
local World = require(script.Parent.World)
local Data = require(script.Parent.PlayerDataService)
local AdminService = require(script.Parent.AdminService)
local Progression = require(ReplicatedStorage.Shared.Progression)
local FishGeneration = require(ReplicatedStorage.Shared.FishGeneration)

local world, shopPrompt, sellPrompt = World.build(Config)
local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "FishingRemotes", ReplicatedStorage
local command = Instance.new("RemoteEvent")
command.Name, command.Parent = "Command", remotes
local event = Instance.new("RemoteEvent")
event.Name, event.Parent = "Event", remotes
local rng = Random.new()
local profiles, sessions, holes, limits = {}, {}, {}, {}
local loading, closing = {}, false

local function notify(player, message) event:FireClient(player, "notice", message) end
local function rootOf(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end
local function nearShop(player)
    local root = rootOf(player)
    return root and (root.Position - Vector3.new(Config.ShopPosition.X, root.Position.Y, Config.ShopPosition.Z)).Magnitude < Config.ShopDistance
        and math.abs(root.Position.Y - 4) < 15
end
local function onPond(player)
    local root = rootOf(player)
    return root and Vector2.new(root.Position.X, root.Position.Z).Magnitude < Config.Pond.Radius - 5
        and math.abs(root.Position.Y - Config.Pond.SurfaceY) < 8
end
local function pushProfile(player)
    local p = profiles[player]
    if not p then return end
    player.leaderstats.Coins.Value = p.coins
    player.leaderstats.Fish.Value = #p.bag
    p.level = Progression.describe(p.xp).level
    player.leaderstats.Level.Value = p.level
    event:FireClient(player, "profile", p)
end
local function removeHole(player)
    if holes[player] then holes[player].model:Destroy() holes[player] = nil end
end

local function lockMovement(player, s)
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    s.humanoid, s.character = h, player.Character
    s.movement = { speed = h.WalkSpeed, power = h.JumpPower, height = h.JumpHeight,
        rotate = h.AutoRotate, jumping = h:GetStateEnabled(Enum.HumanoidStateType.Jumping) }
    h.WalkSpeed, h.JumpPower, h.JumpHeight, h.AutoRotate, h.Jump = 0, 0, 0, false, false
    h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end
local function unlockMovement(s)
    if s.character and s.character.Parent then s.character:SetAttribute("FishingStage", nil) end
    local h, m = s.humanoid, s.movement
    if h and h.Parent and m then
        h.WalkSpeed, h.JumpPower, h.JumpHeight, h.AutoRotate = m.speed, m.power, m.height, m.rotate
        h.Jump = false
        h:SetStateEnabled(Enum.HumanoidStateType.Jumping, m.jumping)
    end
end
local function clearTool(s)
    if s.tool then s.tool:Destroy() end
    if s.line then s.line:Destroy() end
    if s.drillEffect then s.drillEffect:Destroy() s.drillEffect = nil end
    s.tool, s.line, s.grip, s.bobber = nil, nil, nil, nil
end
local function setStage(s, stage)
    s.stage, s.stageAt = stage, workspace:GetServerTimeNow()
    s.character:SetAttribute("FishingStageAt", s.stageAt)
    s.character:SetAttribute("FishingStage", stage)
end
local function equip(s, category, id)
    clearTool(s)
    s.tool, s.grip, s.gripBase = Equipment.mount(s.character, category, id)
end
local function snapshot(s)
    return { token = s.token, bar = s.bar, velocity = s.velocity, target = s.target, width = s.width,
        progress = s.progress, tension = s.tension, phase = s.phase, difficulty = s.fish.difficulty,
        elapsed = s.elapsed, serverTime = workspace:GetServerTimeNow() }
end

local function finish(player, outcome, message)
    local s = sessions[player]
    if not s then return end
    sessions[player] = nil
    clearTool(s)
    unlockMovement(s)
    if outcome == "caught" and profiles[player] then
        local fish = s.fish
        local p = profiles[player]
        local discovery = not p.discoveries[fish.id]
        p.discoveries[fish.id] = true
        p.records[fish.id] = math.max(p.records[fish.id] or 0, fish.kg)
        p.statistics.catches = p.statistics.catches + 1
        local xp = fish.xp + (discovery and 15 or 0) + (fish.trophy and 12 or 0)
        local leveledUp = Progression.add(p, xp)
        local catch = { catchId = HttpService:GenerateGUID(false), species = fish.id, name = fish.name,
            rarity = fish.rarity, kg = fish.kg, value = fish.value, color = fish.color, xp = xp,
            trophy = fish.trophy, caughtAt = os.time(), location = Config.Region,
            variant = "Normal", locked = false, favorite = false, discovery = discovery }
        table.insert(p.bag, catch)
        pushProfile(player)
        event:FireClient(player, "caught", catch)
        if leveledUp then notify(player, "Level " .. p.level .. "! New equipment is available in the shop.") end
    else event:FireClient(player, "ended", message or "The fish escaped. Cast into the same hole to try again!") end
    -- The hole deliberately survives catches, cancellations and character resets.
end

local function buy(player, data)
    if not nearShop(player) then notify(player, "Visit Frostbite Tackle by the pond to buy gear.") return end
    if sessions[player] then notify(player, "Finish your cast first.") return end
    if type(data) ~= "table" or type(data.category) ~= "string" or type(data.id) ~= "string" then return end
    local item, p = Config.findGear(data.category, data.id), profiles[player]
    if not item then return end
    local alreadyOwned = data.category ~= "bait" and p.owned[data.category][item.id]
    if not alreadyOwned and Progression.describe(p.xp).level < (item.requiredLevel or 1) then
        notify(player, "Reach level " .. item.requiredLevel .. " to unlock " .. item.name .. ".") return
    end
    if data.category == "bait" then
        if item.amount == 0 then p.equipped.bait = item.id
        elseif (p.bait[item.id] or 0) > 0 and data.equip == true then p.equipped.bait = item.id
        else
            if p.coins < item.cost then notify(player, "You need more coins for that bait pack.") return end
            p.coins = p.coins - item.cost
            p.bait[item.id] = (p.bait[item.id] or 0) + item.amount
            p.equipped.bait = item.id
        end
    else
        if not p.owned[data.category][item.id] then
            if p.coins < item.cost then notify(player, "Catch and sell more fish to afford this gear.") return end
            p.coins = p.coins - item.cost
            p.owned[data.category][item.id] = true
        end
        p.equipped[data.category] = item.id
    end
    pushProfile(player)
    notify(player, item.name .. " equipped.")
end

local cast
local function startLine(player, s, hole)
    if sessions[player] ~= s then return end
    local p = profiles[player]
    local rod = Config.findGear("rod", p.equipped.rod)
    local lure = Config.findGear("lure", p.equipped.lure)
    local bait = Config.findGear("bait", p.equipped.bait)
    if bait.amount > 0 and (p.bait[bait.id] or 0) <= 0 then
        bait, p.equipped.bait = Config.Gear.bait[1], "bread"
    end
    equip(s, "rod", rod.id)
    if not s.tool then finish(player, "escaped", "Your character isn't ready to hold a rod yet. Try again.") return end
    setStage(s, "casting")
    event:FireClient(player, "stage", { token = s.token, stage = "casting", reused = s.reused })
    task.delay(Config.CastDuration, function()
        if sessions[player] ~= s then return end
        if bait.amount > 0 then p.bait[bait.id] = p.bait[bait.id] - 1 end
        s.fish = FishGeneration.roll(Config, HoleRules.fishingTier(hole), hole.luck + rod.luck + lure.luck + bait.luck,
            { bait = bait.id, lure = lure.id, strength = rod.strength }, function() return rng:NextNumber() end)
        s.settings = Config.reelSettings(rod)
        s.width = Config.Fishing.BaseWidth + rod.control
        s.line, s.bobber = World.line(hole, s.tool)
        s.lineLowerUntil = workspace:GetServerTimeNow() + 0.45
        s.hole = hole
        setStage(s, "waiting")
        pushProfile(player)
        event:FireClient(player, "stage", { token = s.token, stage = "waiting", reused = s.reused })
        task.delay(rng:NextNumber(1.8, 4.2) / bait.biteSpeed, function()
            if sessions[player] ~= s then return end
            if not onPond(player) then finish(player, "escaped", "Your cast was interrupted.") return end
            s.elapsed, s.simAccumulator, s.sendAccumulator = 0, 0, 0
            s.target = Reel.target(s.phase, s.fish.difficulty, 0)
            setStage(s, "reeling")
            event:FireClient(player, "bite", snapshot(s))
        end)
    end)
end

cast = function(player, forceNew)
    if player:GetAttribute("AdminFlying") or player:GetAttribute("AdminFrozen") then notify(player, "Stop flying or unfreeze before fishing.") return end
    if sessions[player] then notify(player, "You're already fishing. Use Cancel to stop.") return end
    if not onPond(player) then notify(player, "Walk onto the frozen pond first.") return end
    local p, root = profiles[player], rootOf(player)
    if #p.bag >= 100 then notify(player, "Your fish bag is full. Sell your catch at the shop.") return end
    local auger = Config.findGear("auger", p.equipped.auger)
    local hole = holes[player]
    local distance = hole and (root.Position - hole.position).Magnitude or math.huge
    local reuse = not forceNew and HoleRules.canReuse(hole, player.UserId, distance, Config.HoleUseDistance)
    local position
    if reuse then position = hole.position
    else
        local direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
        direction = direction.Magnitude < 0.1 and Vector3.new(0, 0, 1) or direction.Unit
        position = root.Position + direction * (auger.size / 2 + 1.6)
        position = Vector3.new(position.X, Config.Pond.SurfaceY, position.Z)
        if Vector2.new(position.X, position.Z).Magnitude > Config.Pond.Radius - auger.size / 2 - 1 then
            notify(player, "Move closer to the middle of the pond to drill safely.") return
        end
        for owner, other in pairs(holes) do
            if owner ~= player and (other.position - position).Magnitude < (other.size + auger.size) / 2 + 2 then
                notify(player, "Give the other fishing hole a little room.") return
            end
        end
        for owner, other in pairs(sessions) do
            if owner ~= player and other.drillPosition and (other.drillPosition - position).Magnitude < (other.drillSize + auger.size) / 2 + 2 then
                notify(player, "Another angler is drilling there. Leave a little room.") return
            end
        end
    end
    local lookAt = Vector3.new(position.X, root.Position.Y, position.Z)
    if (lookAt - root.Position).Magnitude > 0.1 then root.CFrame = CFrame.lookAt(root.Position, lookAt) end
    local s = { token = HttpService:GenerateGUID(false), phase = rng:NextNumber(0, 6), bar = 0.5, velocity = 0,
        progress = 0.25, tension = 0, held = false, position = root.Position, reused = reuse }
    if not reuse then s.drillPosition, s.drillSize = position, auger.size end
    sessions[player] = s
    lockMovement(player, s)
    if reuse then startLine(player, s, hole) return end
    equip(s, "auger", auger.id)
    if not s.tool then finish(player, "escaped", "Your character isn't ready to hold an auger yet. Try again.") return end
    setStage(s, "drilling")
    s.drillEffect = World.drilling(world, position)
    local duration = auger.drillTime or Config.DrillDuration
    event:FireClient(player, "stage", { token = s.token, stage = "drilling", startedAt = s.stageAt, duration = duration })
    task.delay(duration, function()
        if sessions[player] ~= s then return end
        removeHole(player)
        local model, prompt = World.hole(world, position, auger.size, player)
        hole = { model = model, position = position, size = auger.size, tier = auger.tier, luck = auger.luck, ownerId = player.UserId }
        holes[player] = hole
        s.drillPosition = nil
        model:SetAttribute("Tier", auger.tier)
        model:SetAttribute("OwnerId", player.UserId)
        prompt.Triggered:Connect(function(visitor)
            if visitor ~= player then notify(visitor, "This is another angler's hole. Drill your own nearby.") return end
            -- Native prompts are still validated server-side for range and state.
            if profiles[player] and holes[player] == hole then cast(player, false) end
        end)
        startLine(player, s, hole)
    end)
end

local function sellFish(player)
    if closing or not profiles[player] or player:GetAttribute("ProfileReady") ~= true then return end
    if not nearShop(player) or sessions[player] then notify(player, "Visit the shop after finishing your cast to sell fish.") return end
    local p, value = profiles[player], 0
    for _, fish in ipairs(p.bag) do value = value + fish.value end
    if p.coins + value > Config.MaxCoins then notify(player, "You have reached the coin limit. Your fish have been kept.") return end
    p.statistics.sold = p.statistics.sold + #p.bag
    p.statistics.earned = p.statistics.earned + value
    p.bag, p.coins = {}, p.coins + value
    pushProfile(player)
    notify(player, value > 0 and ("Sold your catch for " .. value .. " coins!") or "Your bag is empty. Head to the pond!")
end

local allowedActions = { ready = true, shop = true, buy = true, sell = true, cast = true, drill = true, cancel = true, input = true }
command.OnServerEvent:Connect(function(player, action, data)
    if closing or not profiles[player] or player:GetAttribute("ProfileReady") ~= true or type(action) ~= "string" then return end
    if not allowedActions[action] then return end
    local now = os.clock()
    limits[player] = limits[player] or {}
    -- Input transitions must not be dropped by the general UI click debounce.
    local interval = action == "input" and 0.005 or 0.25
    if now - (limits[player][action] or -math.huge) < interval then return end
    limits[player][action] = now
    if action == "ready" then pushProfile(player)
    elseif action == "shop" then
        if nearShop(player) then event:FireClient(player, "shop") else notify(player, "The tackle shop is in the cabin by the pond.") end
    elseif action == "buy" then buy(player, data)
    elseif action == "sell" then sellFish(player)
    elseif action == "cast" then cast(player, false)
    elseif action == "drill" then cast(player, true)
    elseif action == "cancel" then finish(player, "escaped", "Cast cancelled. Your hole is ready to use again.")
    elseif action == "input" then
        local s = sessions[player]
        if s and type(data) == "table" and data.token == s.token and type(data.held) == "boolean" then
            s.held, s.lastInputAt = data.held, now
        end
    end
end)
shopPrompt.Triggered:Connect(function(player)
    if profiles[player] and nearShop(player) then event:FireClient(player, "shop") end
end)
sellPrompt.Triggered:Connect(function(player)
    local root = rootOf(player)
    if root and (root.Position - Vector3.new(11, 4, -86)).Magnitude <= 12 then sellFish(player) end
end)

AdminService.start({ profiles = profiles, remotes = remotes, pushProfile = pushProfile, notify = notify, cancel = finish })

local function addPlayer(player)
    if profiles[player] or loading[player] or closing then return end
    loading[player] = true
    player:SetAttribute("ProfileReady", false)
    local profile, problem = Data.load(player)
    loading[player] = nil
    if not profile then
        if player.Parent == Players then player:Kick(problem or "Your saved profile could not be loaded. Please rejoin.") end
        return
    end
    if closing or player.Parent ~= Players then Data.release(player) return end
    profiles[player] = profile
    local stats = Instance.new("Folder")
    stats.Name, stats.Parent = "leaderstats", player
    for _, name in ipairs({ "Coins", "Fish", "Level" }) do
        local value = Instance.new("IntValue")
        value.Name, value.Parent = name, stats
    end
    player:SetAttribute("ProfileReady", true)
    pushProfile(player)
    player.CharacterRemoving:Connect(function() finish(player, "escaped", "Cast interrupted. Your hole is still there.") end)
end
Players.PlayerAdded:Connect(addPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() addPlayer(player) end) end
Players.PlayerRemoving:Connect(function(player)
    local s = sessions[player]
    if s then clearTool(s) unlockMovement(s) end
    player:SetAttribute("ProfileReady", false)
    sessions[player], profiles[player], limits[player] = nil, nil, nil
    removeHole(player)
    Data.release(player)
end)
game:BindToClose(function()
    closing = true
    for player in pairs(profiles) do
        finish(player, "escaped", "The server is closing.")
        player:SetAttribute("ProfileReady", false)
    end
    Data.shutdown()
end)

local maintenance = 0

RunService.Heartbeat:Connect(function(dt)
    maintenance = maintenance + dt
    if maintenance >= 1 then maintenance = 0 Data.step() end
    for player, s in pairs(sessions) do
        local root = rootOf(player)
        if player:GetAttribute("ProfileReady") ~= true or not root or (root.Position - s.position).Magnitude > 8 then
            finish(player, "escaped", "Your cast was interrupted. The hole is ready to use again.")
        else
            local t = workspace:GetServerTimeNow() - s.stageAt
            if s.grip then
                if s.stage == "drilling" then
                    s.grip.C0 = s.gripBase * CFrame.new(0, math.sin(t * 10) * 0.06, 0) * CFrame.Angles(0, t * 9, 0)
                elseif s.stage == "casting" then
                    s.grip.C0 = s.gripBase * CFrame.Angles(math.sin(math.min(1, t / Config.CastDuration) * math.pi) * 0.55, 0, 0)
                else
                    s.grip.C0 = s.gripBase * CFrame.Angles(math.sin(t * (s.held and 8 or 2)) * (s.stage == "reeling" and 0.07 or 0.02), 0, 0)
                end
            end
            if s.bobber and workspace:GetServerTimeNow() >= s.lineLowerUntil then
                s.bobber.Position = s.hole.position + Vector3.new(math.sin(t * 2) * 0.06, 0.24 + math.sin(t * 4) * 0.035, 0)
            end
            if s.stage == "reeling" then
                if s.lastInputAt and os.clock() - s.lastInputAt > 0.6 then s.held = false end
                s.simAccumulator = s.simAccumulator + math.min(dt, 0.25)
                s.sendAccumulator = s.sendAccumulator + dt
                local outcome
                while s.simAccumulator >= Config.Fishing.FixedStep and not outcome do
                    s.simAccumulator = s.simAccumulator - Config.Fishing.FixedStep
                    s.elapsed = s.elapsed + Config.Fishing.FixedStep
                    outcome = Reel.step(s, Config.Fishing.FixedStep, s.held, s.fish, s.settings, s.elapsed)
                end
                if outcome then finish(player, outcome)
                elseif s.sendAccumulator >= Config.Fishing.Tick then
                    s.sendAccumulator = 0
                    event:FireClient(player, "reel", snapshot(s))
                end
            end
        end
    end
end)
