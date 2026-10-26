local Config = dofile("src/shared/Config.lua")
local Progression = dofile("src/shared/Progression.lua")
local Fish = dofile("src/shared/FishGeneration.lua")
local Settings = dofile("src/server/ServerSettings.lua")
local Policy = dofile("src/server/AdminPolicy.lua")
local checks = 0
local function check(value, message) assert(value, message) checks = checks + 1 end
check(Progression.describe(0).level == 1, "New anglers start at level one")
check(Progression.describe(79).level == 1 and Progression.describe(80).level == 2, "Level thresholds are exact")
local p = { xp = 0 }
check(Progression.add(p, 205) and p.level == 3, "Large XP rewards can cross multiple levels")
Progression.add(p, -100)
check(p.xp == 205, "XP rewards never subtract earned progress")
check(Progression.describe(Progression.MaxXP).level == 100, "The level curve has a bounded cap")
local expected = { "Bluegill", "Yellow Perch", "Pumpkinseed", "Black Crappie", "Largemouth Bass", "Smallmouth Bass", "White Bass", "Walleye", "Northern Pike", "Burbot", "Muskellunge", "Lake Trout", "Flathead Catfish", "Lake Sturgeon", "Golden Walleye" }
for _, name in ipairs(expected) do
    local found = false
    for _, fish in ipairs(Config.Fish) do if fish.name == name then found = true end end
    check(found, "Missing species: " .. name)
end
for _, fish in ipairs(Config.Fish) do
    check(fish.minWeight > 0 and fish.maxWeight > fish.minWeight and fish.xp > 0 and fish.location == "pond", "Fish definitions include bounded weights, XP and location")
    check(Config.findGear("bait", fish.preferredBait) ~= nil, "Preferred bait exists")
end
for _, auger in ipairs(Config.Gear.auger) do
    local encounter = Fish.roll(Config, auger.tier, 2, { strength = 55 }, function() return 0.999999 end)
    check(encounter.tier <= auger.tier and encounter.kg > 0 and encounter.value > 0, "Augers cannot generate fish beyond their tier")
end
local species = Config.Fish[1]
check(Config.weightFor(species, 0, { bait = species.preferredBait }) > Config.weightFor(species, 0), "Species preferences make bait meaningful")
local starter, upgraded = Config.findGear("rod", "twig"), Config.findGear("rod", "glacier")
local weak = Fish.roll(Config, 5, 0, { strength = 1 }, function() return 1 end)
local strong = Fish.roll(Config, 5, 0, { strength = 100 }, function() return 1 end)
check(weak.difficulty > strong.difficulty and weak.kg == strong.kg, "Strength changes heavy-fish difficulty rather than changing the weight roll")
for _, species in ipairs(Config.Fish) do
    local single = { selectFish = function() return species end }
    for _, roll in ipairs({ 0, 1 }) do
        local encounter = Fish.roll(single, 5, 0, { strength = 55 }, function() return roll end)
        check(encounter.kg >= species.minWeight - 0.001 and encounter.kg <= species.maxWeight + 0.001, "Encounter weights remain within configured species bounds")
    end
end
check(Config.reelSettings(upgraded).Gain > Config.reelSettings(starter).Gain, "Reel speed affects actual catch progress")
check(Config.reelSettings(upgraded).TensionGain < Config.reelSettings(starter).TensionGain, "Stability reduces actual tension buildup")
for category, items in pairs(Config.Gear) do for _, item in ipairs(items) do check(#Config.gearStats(category, item) > 5, "Every equipment card has real stats") end end
local policy = Policy.new(Settings, false)
check(not policy.isAdmin(123), "Unconfigured players are not admins")
check(not policy.allowResolved(-1) and not policy.allowResolved(0 / 0), "Failed or invalid account lookups grant no access")
check(policy.allowResolved(123) and policy.isAdmin(123), "A server-resolved numeric user ID can be authorized")
check(not policy.isAdmin(456), "Display names and client state cannot authorize another user ID")
check(not policy.validate({ action = "money", targetId = 123, amount = 0 / 0 }), "NaN grants are rejected")
check(not policy.validate({ action = "money", targetId = 123, amount = -1 }), "Negative grants are rejected")
check(not policy.validate({ action = "money", targetId = 123, amount = 1.5 }), "Fractional grants are rejected")
check(not policy.validate({ action = "money", targetId = 123, amount = Settings.MaxMoneyGrant + 1 }), "Excessive grants are rejected")
check(not policy.validate({ action = "money", targetId = "unbenator", amount = 10 }), "Targets must be numeric server identities")
check(not policy.validate({ action = "arbitraryCode", targetId = 123 }), "Unknown admin commands are rejected")
check(policy.validate({ action = "money", targetId = 456, amount = 100 }), "Valid grants pass validation")
local settings = {}
for k, v in pairs(Settings) do settings[k] = v end
settings.StudioAdminUserIds = { -1 }
check(not Policy.new(settings, false).isAdmin(-1) and Policy.new(settings, true).isAdmin(-1), "Studio-only test admin IDs never authorize live players")
print("PASS: " .. checks .. " progression, fish and admin-policy checks")
