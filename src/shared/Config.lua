local Config = {}

Config.StartingCoins = 120
Config.MaxCoins = 1000000000
Config.MaxBait = 100000
Config.Region = "Frostbite Pond"
Config.Pond = { CenterX = 0, CenterZ = 0, Radius = 68, SurfaceY = 2 }
Config.ShopPosition = { X = 0, Z = -92 }
Config.ShopDistance = 23
Config.HoleUseDistance = 12
Config.DrillDuration = 2.4
Config.CastDuration = 0.8
Config.Fishing = {
    Tick = 0.08, BarSpeed = 0.55, Gravity = 0.36,
    Response = 12, FixedStep = 1 / 120,
    BaseWidth = 0.23, Gain = 0.16, Loss = 0.07,
    TensionGain = 0.22, TensionLoss = 0.33, Timeout = 35,
}

-- Costs are one-time unlocks. Bait packs are consumed on each cast.
Config.Gear = {
    auger = {
        { id = "hand", name = "Hand Auger", cost = 0, tier = 1, size = 3, drillTime = 2.4, luck = 0, description = "A small hole for pond fish." },
        { id = "steel", name = "Steel Auger", cost = 180, tier = 2, size = 4.5, drillTime = 1.9, luck = 0.2, description = "Wider holes unlock uncommon fish." },
        { id = "power", name = "Power Auger", cost = 650, tier = 3, size = 6, drillTime = 1.5, luck = 0.5, description = "Reach rare fish below the ice." },
        { id = "titanium", name = "Titanium Auger", cost = 1100, tier = 4, size = 7, drillTime = 1.3, luck = 0.65, description = "Lightweight drill for epic fish." },
        { id = "arctic", name = "Arctic Auger", cost = 1800, tier = 5, size = 8, drillTime = 1.1, luck = 0.8, description = "The deepest water hides legendary fish." },
    },
    rod = {
        { id = "twig", name = "Starter Rod", cost = 0, luck = 0, control = 0, description = "Simple, sturdy, and ready to fish." },
        { id = "birch", name = "Fiberglass Ice Rod", cost = 140, luck = 0.25, control = 0.035, description = "A little more luck and reel control." },
        { id = "carbon", name = "Carbon Rod", cost = 500, luck = 0.65, control = 0.07, description = "Better odds and a wider catch zone." },
        { id = "pro", name = "Pro Angler Rod", cost = 950, luck = 0.85, control = 0.09, description = "Fast reeling and stable tension for big fish." },
        { id = "glacier", name = "Glacier Rod", cost = 1500, luck = 1.1, control = 0.11, description = "Premium control for elusive fish." },
    },
    lure = {
        { id = "plain", name = "Plain Hook", cost = 0, luck = 0, description = "Your trusty starter hook." },
        { id = "copper", name = "Copper Spoon", cost = 110, luck = 0.3, description = "A flash of copper attracts better fish." },
        { id = "silver", name = "Silver Spinner", cost = 400, luck = 0.7, description = "An irresistible glimmer under the ice." },
        { id = "soft", name = "Soft Plastic", cost = 200, luck = 0.45, description = "A lifelike action that bass prefer." },
        { id = "blade", name = "Blade Bait", cost = 600, luck = 0.8, description = "Vibration draws pike and walleye." },
        { id = "predator", name = "Predator Jig", cost = 900, luck = 1, description = "A large profile for heavy predators." },
        { id = "aurora", name = "Aurora Jig", cost = 1200, luck = 1.2, description = "A shimmering lure for prized catches." },
    },
    bait = {
        { id = "bread", name = "Bread Crumbs", cost = 0, luck = 0, amount = 0, description = "Unlimited free bait." },
        { id = "worms", name = "Nightcrawlers · 10 casts", cost = 35, luck = 0.5, amount = 10, description = "Fresh bait improves rare-fish odds." },
        { id = "waxworms", name = "Wax Worms · 10 casts", cost = 25, luck = 0.25, amount = 10, description = "Quick bites from small pond species." },
        { id = "mealworms", name = "Mealworms · 10 casts", cost = 45, luck = 0.4, amount = 10, description = "A reliable choice for bass and panfish." },
        { id = "cutbait", name = "Cut Bait · 10 casts", cost = 80, luck = 0.75, amount = 10, description = "Attract bottom-feeding predators." },
        { id = "premium", name = "Premium Live Bait · 10 casts", cost = 160, luck = 1.45, amount = 10, description = "Faster bites and better rare-fish odds." },
        { id = "minnows", name = "Minnows · 10 casts", cost = 100, luck = 1.15, amount = 10, description = "Live bait for the biggest predators." },
    },
}

Config.Fish = {
    { id = "perch", name = "Yellow Perch", rarity = "Common", tier = 1, weight = 52, value = 25, kg = 0.6, difficulty = 0.70, color = { 228, 188, 86 } },
    { id = "bluegill", name = "Bluegill", rarity = "Common", tier = 1, weight = 35, value = 35, kg = 0.9, difficulty = 0.85, color = { 107, 181, 210 } },
    { id = "pumpkinseed", name = "Pumpkinseed", rarity = "Common", tier = 1, weight = 25, value = 30, kg = 0.7, difficulty = 0.75, color = { 232, 152, 83 } },
    { id = "crappie", name = "Black Crappie", rarity = "Common", tier = 1, weight = 20, value = 40, kg = 1.1, difficulty = 0.9, color = { 176, 188, 203 } },
    { id = "whitebass", name = "White Bass", rarity = "Uncommon", tier = 1, weight = 9, value = 55, kg = 1.8, difficulty = 0.95, color = { 122, 215, 160 } },
    { id = "trout", name = "Rainbow Trout", rarity = "Uncommon", tier = 2, weight = 19, value = 80, kg = 2.2, difficulty = 1.05, color = { 122, 215, 160 } },
    { id = "walleye", name = "Walleye", rarity = "Rare", tier = 3, weight = 13, value = 110, kg = 3.4, difficulty = 1.15, color = { 122, 215, 160 } },
    { id = "pike", name = "Northern Pike", rarity = "Rare", tier = 3, weight = 7, value = 230, kg = 6.5, difficulty = 1.30, color = { 121, 157, 255 } },
    { id = "char", name = "Arctic Char", rarity = "Rare", tier = 3, weight = 4, value = 340, kg = 4.5, difficulty = 1.45, color = { 121, 157, 255 } },
    { id = "sturgeon", name = "Lake Sturgeon", rarity = "Legendary", tier = 5, weight = 1.2, value = 900, kg = 18, difficulty = 1.65, color = { 248, 197, 92 } },
    { id = "spirit", name = "Aurora Spiritfish", rarity = "Legendary", tier = 5, weight = 0.45, value = 1600, kg = 8, difficulty = 1.85, color = { 219, 145, 255 } },
    { id = "largemouth", name = "Largemouth Bass", rarity = "Uncommon", tier = 2, weight = 15, value = 85, kg = 2.8, difficulty = 1.05, color = { 122, 215, 160 } },
    { id = "smallmouth", name = "Smallmouth Bass", rarity = "Uncommon", tier = 2, weight = 17, value = 75, kg = 2.1, difficulty = 1.0, color = { 122, 215, 160 } },
    { id = "burbot", name = "Burbot", rarity = "Rare", tier = 3, weight = 6, value = 250, kg = 5.2, difficulty = 1.3, color = { 121, 157, 255 } },
    { id = "muskellunge", name = "Muskellunge", rarity = "Epic", tier = 4, weight = 2.6, value = 480, kg = 11, difficulty = 1.5, color = { 203, 148, 250 } },
    { id = "laketrout", name = "Lake Trout", rarity = "Epic", tier = 4, weight = 3.2, value = 430, kg = 9, difficulty = 1.4, color = { 203, 148, 250 } },
    { id = "flathead", name = "Flathead Catfish", rarity = "Epic", tier = 4, weight = 2.1, value = 520, kg = 14, difficulty = 1.55, color = { 203, 148, 250 } },
    { id = "goldenwalleye", name = "Golden Walleye", rarity = "Legendary", tier = 5, weight = 0.8, value = 1150, kg = 6, difficulty = 1.75, color = { 248, 197, 92 } },
    { id = "snowfin", name = "Whisperpine Snowfin", rarity = "Rare", tier = 3, weight = 5, value = 270, kg = 3.8, difficulty = 1.25, regionOnly = "lake", color = { 167, 221, 220 } },
    { id = "glasskoi", name = "Glass Koi", rarity = "Epic", tier = 4, weight = 2.7, value = 590, kg = 7, difficulty = 1.5, regionOnly = "crystal", color = { 174, 232, 246 } },
    { id = "tundragar", name = "Tundra Gar", rarity = "Epic", tier = 4, weight = 2.3, value = 640, kg = 14, difficulty = 1.65, regionOnly = "north", color = { 144, 190, 161 } },
    { id = "leviathan", name = "Glacier Leviathan", rarity = "Legendary", tier = 5, weight = 0.6, value = 2200, kg = 34, difficulty = 1.95, regionOnly = "glacier", color = { 179, 158, 249 } },
}

local rodStats = {
    twig = { 1, 6, 1, 0 }, birch = { 2, 12, 1.08, 0.08 }, carbon = { 5, 22, 1.16, 0.16 },
    pro = { 8, 35, 1.23, 0.23 }, glacier = { 12, 55, 1.30, 0.30 },
}
for _, rod in ipairs(Config.Gear.rod) do
    local values = rodStats[rod.id]
    rod.requiredLevel, rod.strength, rod.reelSpeed, rod.stability = values[1], values[2], values[3], values[4]
end
for _, auger in ipairs(Config.Gear.auger) do auger.requiredLevel = ({ 1, 3, 6, 9, 12 })[auger.tier] end
for _, lure in ipairs(Config.Gear.lure) do lure.requiredLevel = math.max(1, math.floor(lure.cost / 180)) end
for _, bait in ipairs(Config.Gear.bait) do bait.biteSpeed = bait.id == "bread" and 1 or (bait.id == "premium" and 1.5 or 1.2) end
local preferences = {
    perch = "waxworms", bluegill = "bread", pumpkinseed = "mealworms", crappie = "waxworms",
    whitebass = "minnows", largemouth = "worms", smallmouth = "mealworms", trout = "worms",
    walleye = "minnows", pike = "minnows", burbot = "cutbait", char = "waxworms",
    muskellunge = "minnows", laketrout = "premium", flathead = "cutbait", sturgeon = "cutbait",
    goldenwalleye = "premium", spirit = "premium",
}
for _, fish in ipairs(Config.Fish) do
    fish.minWeight, fish.maxWeight = math.floor(fish.kg * 0.65 * 100 + 0.5) / 100, math.floor(fish.kg * 1.5 * 100 + 0.5) / 100
    fish.xp = 16 + fish.tier * 8
    fish.preferredBait = preferences[fish.id] or "premium"
    fish.preferredLure = fish.tier >= 3 and "predator" or "soft"
    fish.behavior = ({ "drift", "sweep", "burst", "heavy", "mythic" })[fish.tier]
    fish.preferredRegion = fish.regionOnly or ({ "pond", "lake", "north", "crystal", "glacier" })[fish.tier]
    fish.style = (fish.id == "flathead" or fish.id == "burbot") and "catfish" or (fish.tier >= 3 and "predator" or "panfish")
    fish.location, fish.preferredWeather, fish.preferredTime = fish.regionOnly or "pond", ({ "Clear", "LightSnow", "HeavySnow", "Blizzard", "Aurora" })[fish.tier], fish.tier >= 3 and "Night" or "Day"
end

function Config.reelSettings(rod)
    local settings = {}
    for key, value in pairs(Config.Fishing) do settings[key] = value end
    settings.Gain = settings.Gain * rod.reelSpeed
    settings.TensionGain = settings.TensionGain * (1 - rod.stability)
    return settings
end

function Config.gearStats(category, item)
    if category == "rod" then
        return string.format("Luck +%.2f / Control +%.0f%% / %d kg / Reel x%.2f / Stability %.0f%%", item.luck, item.control * 100, item.strength, item.reelSpeed, item.stability * 100)
    elseif category == "auger" then return string.format("%g-stud hole / Tier %d / Drill %.1fs", item.size, item.tier, item.drillTime)
    elseif category == "bait" then return string.format("Luck +%.2f / Bite speed x%.1f", item.luck, item.biteSpeed)
    else return string.format("Luck +%.2f / Permanent lure", item.luck) end
end

function Config.findGear(category, id)
    for _, item in ipairs(Config.Gear[category] or {}) do
        if item.id == id then return item end
    end
    return nil
end

function Config.gearName(category, id)
    local gear = Config.findGear(category, id)
    -- Parentheses intentionally discard gsub's second return value.
    return gear and (gear.name:gsub(" · 10 casts", "")) or "Unknown gear"
end

function Config.weightFor(fish, luck, context)
    -- Value adds a small quality boost within a tier, so starter-pond gear
    -- upgrades help even before a player unlocks the next auger.
    local quality = fish.tier - 1 + math.log(fish.value / 25) * 0.2
    local preference = 1
    if context and context.bait == fish.preferredBait then preference = preference * 1.5 end
    if context and context.lure == fish.preferredLure then preference = preference * 1.25 end
    if context and context.region == fish.preferredRegion then preference = preference * 2 end
    if context and context.weather == fish.preferredWeather then preference = preference * 1.15 end
    if context and context.night ~= nil and (context.night and "Night" or "Day") == fish.preferredTime then preference = preference * 1.25 end
    return fish.weight * (1 + math.max(0, luck) * quality * 0.75) * preference
end

function Config.findFish(id)
    for _, fish in ipairs(Config.Fish) do if fish.id == id then return fish end end
    return nil
end
function Config.available(fish, tier, context)
    return fish.tier <= tier and (not context or not context.region or not fish.regionOnly or fish.regionOnly == context.region)
end

-- Accepts an injected [0, 1) roll to make the selection logic testable.
function Config.selectFish(tier, luck, roll, context)
    local total = 0
    for _, fish in ipairs(Config.Fish) do
        if Config.available(fish, tier, context) then total = total + Config.weightFor(fish, luck, context) end
    end
    local target = math.max(0, math.min(0.999999, roll)) * total
    for _, fish in ipairs(Config.Fish) do
        if Config.available(fish, tier, context) then
            target = target - Config.weightFor(fish, luck, context)
            if target < 0 then return fish end
        end
    end
    return Config.Fish[1]
end

return Config
