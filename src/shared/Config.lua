local Config = {}

Config.StartingCoins = 120
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
        { id = "arctic", name = "Arctic Auger", cost = 1800, tier = 4, size = 8, drillTime = 1.1, luck = 0.8, description = "The deepest water hides legendary fish." },
    },
    rod = {
        { id = "twig", name = "Starter Rod", cost = 0, luck = 0, control = 0, description = "Simple, sturdy, and ready to fish." },
        { id = "birch", name = "Birch Rod", cost = 140, luck = 0.25, control = 0.035, description = "A little more luck and reel control." },
        { id = "carbon", name = "Carbon Rod", cost = 500, luck = 0.65, control = 0.07, description = "Better odds and a wider catch zone." },
        { id = "glacier", name = "Glacier Rod", cost = 1500, luck = 1.1, control = 0.11, description = "Premium control for elusive fish." },
    },
    lure = {
        { id = "plain", name = "Plain Hook", cost = 0, luck = 0, description = "Your trusty starter hook." },
        { id = "copper", name = "Copper Spoon", cost = 110, luck = 0.3, description = "A flash of copper attracts better fish." },
        { id = "silver", name = "Silver Spinner", cost = 400, luck = 0.7, description = "An irresistible glimmer under the ice." },
        { id = "aurora", name = "Aurora Jig", cost = 1200, luck = 1.2, description = "A shimmering lure for prized catches." },
    },
    bait = {
        { id = "bread", name = "Bread Crumbs", cost = 0, luck = 0, amount = 0, description = "Unlimited free bait." },
        { id = "worms", name = "Worms · 10 casts", cost = 35, luck = 0.5, amount = 10, description = "Fresh bait improves rare-fish odds." },
        { id = "minnows", name = "Minnows · 10 casts", cost = 100, luck = 1.15, amount = 10, description = "Live bait for the biggest predators." },
    },
}

Config.Fish = {
    { id = "perch", name = "Yellow Perch", rarity = "Common", tier = 1, weight = 52, value = 25, kg = 0.6, difficulty = 0.70, color = { 228, 188, 86 } },
    { id = "bluegill", name = "Frost Bluegill", rarity = "Common", tier = 1, weight = 35, value = 35, kg = 0.9, difficulty = 0.85, color = { 107, 181, 210 } },
    { id = "pumpkinseed", name = "Pumpkinseed", rarity = "Common", tier = 1, weight = 25, value = 30, kg = 0.7, difficulty = 0.75, color = { 232, 152, 83 } },
    { id = "crappie", name = "Black Crappie", rarity = "Common", tier = 1, weight = 20, value = 40, kg = 1.1, difficulty = 0.9, color = { 176, 188, 203 } },
    { id = "whitebass", name = "White Bass", rarity = "Uncommon", tier = 1, weight = 9, value = 55, kg = 1.8, difficulty = 0.95, color = { 122, 215, 160 } },
    { id = "trout", name = "Rainbow Trout", rarity = "Uncommon", tier = 2, weight = 19, value = 80, kg = 2.2, difficulty = 1.05, color = { 122, 215, 160 } },
    { id = "walleye", name = "Ice Walleye", rarity = "Uncommon", tier = 2, weight = 13, value = 110, kg = 3.4, difficulty = 1.15, color = { 122, 215, 160 } },
    { id = "pike", name = "Northern Pike", rarity = "Rare", tier = 3, weight = 7, value = 230, kg = 6.5, difficulty = 1.30, color = { 121, 157, 255 } },
    { id = "char", name = "Arctic Char", rarity = "Rare", tier = 3, weight = 4, value = 340, kg = 4.5, difficulty = 1.45, color = { 121, 157, 255 } },
    { id = "sturgeon", name = "Glacier Sturgeon", rarity = "Legendary", tier = 4, weight = 1.2, value = 900, kg = 18, difficulty = 1.65, color = { 248, 197, 92 } },
    { id = "spirit", name = "Aurora Spiritfish", rarity = "Legendary", tier = 4, weight = 0.45, value = 1600, kg = 8, difficulty = 1.85, color = { 219, 145, 255 } },
}

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

function Config.weightFor(fish, luck)
    -- Value adds a small quality boost within a tier, so starter-pond gear
    -- upgrades help even before a player unlocks the next auger.
    local quality = fish.tier - 1 + math.log(fish.value / 25) * 0.2
    return fish.weight * (1 + math.max(0, luck) * quality * 0.75)
end

-- Accepts an injected [0, 1) roll to make the selection logic testable.
function Config.selectFish(tier, luck, roll)
    local total = 0
    for _, fish in ipairs(Config.Fish) do
        if fish.tier <= tier then total = total + Config.weightFor(fish, luck) end
    end
    local target = math.max(0, math.min(0.999999, roll)) * total
    for _, fish in ipairs(Config.Fish) do
        if fish.tier <= tier then
            target = target - Config.weightFor(fish, luck)
            if target < 0 then return fish end
        end
    end
    return Config.Fish[1]
end

return Config
