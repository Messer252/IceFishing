local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local Reel = require(ReplicatedStorage.Shared.Reel)
local World = require(script.Parent.World)

local world, shopPrompt = World.build(Config)
local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "FishingRemotes", ReplicatedStorage
local command = Instance.new("RemoteEvent")
command.Name, command.Parent = "Command", remotes
local event = Instance.new("RemoteEvent")
event.Name, event.Parent = "Event", remotes
local rng = Random.new()
local profiles, sessions, holes, limits = {}, {}, {}, {}

local function notify(player, message)
    event:FireClient(player, "notice", message)
end

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
    event:FireClient(player, "profile", p)
end

local function removeHole(player)
    if holes[player] then holes[player].model:Destroy() holes[player] = nil end
end

local function finish(player, outcome, message)
    local s = sessions[player]
    if not s then return end
    sessions[player] = nil
    if s.rod then s.rod:Destroy() end
    if outcome == "caught" and profiles[player] then
        local fish = s.fish
        local kg = math.floor(fish.kg * rng:NextNumber(0.65, 1.5) * 100) / 100
        local value = math.floor(fish.value * kg / fish.kg)
        local catch = { name = fish.name, rarity = fish.rarity, kg = kg, value = value, color = fish.color }
        table.insert(profiles[player].bag, catch)
        pushProfile(player)
        event:FireClient(player, "caught", catch)
    else
        event:FireClient(player, "ended", message or "The fish escaped. Try another cast!")
    end
end

local function buy(player, data)
    if not nearShop(player) then notify(player, "Visit Frostbite Tackle by the pond to buy gear.") return end
    if sessions[player] then notify(player, "Finish your cast first.") return end
    if type(data) ~= "table" or type(data.category) ~= "string" or type(data.id) ~= "string" then return end
    local item = Config.findGear(data.category, data.id)
    local p = profiles[player]
    if not item then return end
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
        if data.category == "auger" then removeHole(player) end
    end
    pushProfile(player)
    notify(player, item.name .. " equipped.")
end

local function cast(player)
    if sessions[player] then notify(player, "You're already fishing. Use Cancel to stop.") return end
    if not onPond(player) then notify(player, "Walk onto the frozen pond first, then drill a hole.") return end
    local p, root = profiles[player], rootOf(player)
    if #p.bag >= 100 then notify(player, "Your fish bag is full. Sell your catch at the shop.") return end
    local auger = Config.findGear("auger", p.equipped.auger)
    local rod = Config.findGear("rod", p.equipped.rod)
    local lure = Config.findGear("lure", p.equipped.lure)
    local bait = Config.findGear("bait", p.equipped.bait)
    if bait.amount > 0 and (p.bait[bait.id] or 0) <= 0 then
        bait = Config.Gear.bait[1]
        p.equipped.bait = bait.id
    end
    local direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, 1) else direction = direction.Unit end
    local position = root.Position + direction * (auger.size / 2 + 2)
    if Vector2.new(position.X, position.Z).Magnitude > Config.Pond.Radius - auger.size / 2 - 1 then
        notify(player, "Move closer to the middle of the pond to drill safely.") return
    end
    for owner, hole in pairs(holes) do
        if owner ~= player and (hole.position - Vector3.new(position.X, 2, position.Z)).Magnitude < (hole.size + auger.size) / 2 + 2 then
            notify(player, "Give the other fishing hole a little room.") return
        end
    end
    removeHole(player)
    position = Vector3.new(position.X, 2, position.Z)
    holes[player] = { model = World.hole(world, position, auger.size, player), position = position, size = auger.size, expires = os.clock() + Config.HoleLifetime }
    if bait.amount > 0 then p.bait[bait.id] = p.bait[bait.id] - 1 end
    local fish = Config.selectFish(auger.tier, auger.luck + rod.luck + lure.luck + bait.luck, rng:NextNumber())
    local rodModel, rodPart = World.rod(player.Character)
    if rodPart then
        local tip = Instance.new("Attachment")
        tip.Position, tip.Parent = Vector3.new(0, 2.5, 0), rodPart
        local anchor = Instance.new("Attachment")
        anchor.Parent = holes[player].model.DarkWater
        local beam = Instance.new("Beam")
        beam.Attachment0, beam.Attachment1 = tip, anchor
        beam.Width0, beam.Width1, beam.FaceCamera = 0.035, 0.035, true
        beam.Color, beam.Parent = ColorSequence.new(Color3.fromRGB(225, 239, 244)), rodPart
    end
    local token = HttpService:GenerateGUID(false)
    local s = { token = token, phase = rng:NextNumber(0, 6), fish = fish, bar = 0.5, target = 0.5,
        progress = 0.25, tension = 0, width = Config.Fishing.BaseWidth + rod.control,
        held = false, elapsed = 0, accumulator = 0, position = root.Position,
        rod = rodModel, stage = "waiting" }
    sessions[player] = s
    pushProfile(player)
    event:FireClient(player, "waiting", { token = token, hole = auger.size })
    task.delay(rng:NextNumber(1.8, 4.2), function()
        if sessions[player] ~= s then return end
        if not onPond(player) then finish(player, "escaped", "Your cast was interrupted.") return end
        s.stage = "reeling"
        event:FireClient(player, "bite", { token = token, width = s.width, bar = s.bar, target = s.target, progress = s.progress, tension = 0 })
    end)
end

command.OnServerEvent:Connect(function(player, action, data)
    if not profiles[player] or type(action) ~= "string" then return end
    local now = os.clock()
    limits[player] = limits[player] or {}
    local interval = action == "input" and 0.025 or 0.25
    if now - (limits[player][action] or -math.huge) < interval then return end
    limits[player][action] = now
    if action == "ready" then pushProfile(player)
    elseif action == "shop" then
        if nearShop(player) then event:FireClient(player, "shop") else notify(player, "The tackle shop is in the cabin by the pond.") end
    elseif action == "buy" then buy(player, data)
    elseif action == "sell" then
        if not nearShop(player) or sessions[player] then notify(player, "Visit the shop after finishing your cast to sell fish.") return end
        local p, value = profiles[player], 0
        for _, fish in ipairs(p.bag) do value = value + fish.value end
        p.bag, p.coins = {}, p.coins + value
        pushProfile(player)
        notify(player, value > 0 and ("Sold your catch for " .. value .. " coins!") or "Your bag is empty. Head to the pond!")
    elseif action == "cast" then cast(player)
    elseif action == "cancel" then finish(player, "escaped", "Cast cancelled. Used bait is not refunded.")
    elseif action == "input" then
        local s = sessions[player]
        if s and type(data) == "table" and data.token == s.token and type(data.held) == "boolean" then s.held = data.held end
    end
end)

shopPrompt.Triggered:Connect(function(player)
    if profiles[player] and nearShop(player) then event:FireClient(player, "shop") end
end)

local function addPlayer(player)
    if profiles[player] then return end
    profiles[player] = { coins = Config.StartingCoins, bag = {}, bait = { worms = 0, minnows = 0 },
        equipped = { auger = "hand", rod = "twig", lure = "plain", bait = "bread" },
        owned = { auger = { hand = true }, rod = { twig = true }, lure = { plain = true } } }
    local stats = Instance.new("Folder")
    stats.Name, stats.Parent = "leaderstats", player
    for _, name in ipairs({ "Coins", "Fish" }) do
        local value = Instance.new("IntValue")
        value.Name, value.Parent = name, stats
    end
    pushProfile(player)
    player.CharacterRemoving:Connect(function()
        finish(player, "escaped", "Cast interrupted. Head back to the pond!")
        removeHole(player)
    end)
end

Players.PlayerAdded:Connect(addPlayer)
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
    local s = sessions[player]
    if s and s.rod then s.rod:Destroy() end
    sessions[player], profiles[player], limits[player] = nil, nil, nil
    removeHole(player)
end)

RunService.Heartbeat:Connect(function(dt)
    for player, s in pairs(sessions) do
        local root = rootOf(player)
        if not root or (root.Position - s.position).Magnitude > 8 then
            finish(player, "escaped", "Stay by your hole while fishing.")
        elseif s.stage == "reeling" then
            -- Bound lag spikes instead of awarding progress for a stalled server.
            local step = math.min(dt, 0.1)
            s.elapsed, s.accumulator = s.elapsed + step, s.accumulator + step
            local outcome = Reel.step(s, step, s.held, s.fish, Config.Fishing, s.elapsed)
            if outcome then finish(player, outcome)
            elseif s.accumulator >= Config.Fishing.Tick then
                s.accumulator = 0
                event:FireClient(player, "reel", { bar = s.bar, target = s.target, width = s.width, progress = s.progress, tension = s.tension })
            end
        end
    end
    for player, hole in pairs(holes) do
        if not sessions[player] and os.clock() > hole.expires then removeHole(player) end
    end
end)
