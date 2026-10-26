local Rules = dofile("src/shared/GlowRules.lua")
local Content = dofile("src/shared/Content.lua")
local Config = dofile("src/shared/Config.lua")
local Generation = dofile("src/shared/FishGeneration.lua")
local Inventory = dofile("src/shared/Inventory.lua")
local Progression = dofile("src/shared/Progression.lua")
local Schema = dofile("src/server/ProfileSchema.lua").create(Config, Progression)
local count = 0
local function check(condition, message) assert(condition, message) count = count + 1 end
local now, messages = 0, {}
local playerA, playerB = {}, {}
local profiles = { [playerA] = Schema.new(), [playerB] = Schema.new() }
local event = { FireClient = function(_, player, kind, data) table.insert(messages, { player = player, kind = kind, data = data }) end }
local root = { Position = { X = 0, Y = 5, Z = 0 } }
local random = { values = { 0, 0.95, 0.5, 0, 0, 0.5, 0.5 }, at = 0 }
function random:NextNumber(a, b)
    self.at = self.at + 1
    local fraction = self.values[self.at] or 0.5
    return a and a + (b - a) * fraction or fraction
end
local env = setmetatable({
    game = { GetService = function() return { Shared = { Content = Content, GlowRules = Rules } } end },
    require = function(module) return module end,
}, { __index = _G })
local Service = assert(loadfile("src/server/GlowService.lua", "t", env))()
local glow = Service.start({ profiles = profiles, event = event, root = function() return root end, random = random, clock = function() return now end })
glow.step()
check(#glow.snapshot() == 0, "Events do not spawn on every heartbeat")
now = 21 glow.step()
local zone = glow.snapshot()[1]
check(zone and zone.income == 2 and zone.luck == 2, "Rare aurora zones offer both bonuses")
check(zone.radius >= 10 and zone.radius <= 13, "Glow zones stay small enough to be fishing spots")
check(math.sqrt(zone.x ^ 2 + zone.z ^ 2) + zone.radius < Content.region("pond").radius, "Zones fit inside their lake")
local pointA, pointB = { X = zone.x - 3, Z = zone.z }, { X = zone.x + 3, Z = zone.z }
local a, b = glow.bonuses("pond", pointA), glow.bonuses("pond", pointB)
check(a.income == 2 and b.income == 2 and a.luck == 2 and b.luck == 2, "Multiple players can use the same zone without consuming it")
check(glow.bonuses("lake", pointA).income == 1, "A zone cannot affect another region")
check(glow.bonuses("pond", { X = zone.x + zone.radius + 0.1, Z = zone.z }).luck == 1, "Holes outside the circle receive no bonus")
check(Rules.effectiveLuck(0, 2) == 1 and Rules.effectiveLuck(3, 2) == 7, "Double luck benefits starter gear and doubles baseline-plus-gear luck")
local copy = glow.snapshot()
copy[1].income, copy[1].color[1] = 999, 0
check(glow.bonuses("pond", pointA).income == 2 and glow.snapshot()[1].color[1] ~= 0, "Client snapshots cannot change authoritative zone bonuses")
local duplicate = { zone, zone }
check(Rules.at(duplicate, now, "pond", pointA).income == 2, "Overlapping income zones do not silently multiply to 4x")
local context = { region = "pond", strength = 6, incomeMultiplier = 2, luckMultiplier = 2 }
local boosted = Generation.roll(Config, 1, Rules.effectiveLuck(0, 2), context, function() return 0.1 end)
local ordinary = Generation.roll(Config, 1, Rules.effectiveLuck(0, 2), { region = "pond", strength = 6 }, function() return 0.1 end)
check(boosted.value == ordinary.value * 2, "Income bonuses exactly double the rounded catch value")
check(boosted.tier == 1, "Luck zones never bypass the auger's fish-tier limit")
check(boosted.incomeMultiplier == 2 and boosted.luckMultiplier == 2, "A hooked fish captures its bonuses in the encounter record")
local highQuality = { 0, 0 }
for index, luck in ipairs({ 0, Rules.effectiveLuck(0, 2) }) do
    for i = 0, 9999 do
        if Config.selectFish(1, luck, i / 10000, { region = "pond" }).id == "whitebass" then highQuality[index] = highQuality[index] + 1 end
    end
end
check(highQuality[2] > highQuality[1], "Double luck actually improves starter-tier encounter odds")
for i, player in ipairs({ playerA, playerB }) do
    profiles[player].bag = { { catchId = "shared-zone-" .. i, species = boosted.id, name = boosted.name, rarity = boosted.rarity,
        color = boosted.color, kg = boosted.kg, value = boosted.value, variant = boosted.variant, incomeMultiplier = boosted.incomeMultiplier } }
end
now = zone.expiresAt
glow.step()
check(glow.bonuses("pond", pointA).income == 1, "Zones stop granting bonuses at their expiration time")
check(#glow.snapshot() == 0, "Expired events are removed from the shared registry")
for _, player in ipairs({ playerA, playerB }) do
    check(Inventory.sell(profiles[player], nil, Config.MaxCoins) and profiles[player].coins == 120 + boosted.value,
        "Each player keeps and sells their own boosted catch after the zone expires")
end
local notices = 0
for _, message in ipairs(messages) do if message.kind == "glowNotice" then notices = notices + 1 end end
check(notices == 2, "An event announces itself to both players")
glow.send(playerA)
check(messages[#messages].kind == "glowZones" and messages[#messages].player == playerA, "Late join/ready requests receive the current event snapshot")
check(Rules.typeFor(0).income == 2 and Rules.typeFor(0).luck == 1 and Rules.typeFor(0.6).luck == 2 and Rules.typeFor(0.6).income == 1, "Regular events offer distinct income or luck bonuses")
print("PASS: " .. count .. " shared glow-event, multiplier and expiration checks")
