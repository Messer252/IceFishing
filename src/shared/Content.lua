local Content = {}
Content.Rarity = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
Content.Regions = {
    { id = "pond", name = "Frostbite Pond", x = 0, z = 0, radius = 68, level = 1, price = 0, luck = 0, color = { 145, 201, 219 } },
    { id = "lake", name = "Whisperpine Lake", x = 360, z = 0, radius = 86, level = 3, price = 350, luck = 0.25, color = { 122, 183, 205 } },
    { id = "crystal", name = "Crystal Reservoir", x = 720, z = 0, radius = 84, level = 6, price = 1100, luck = 0.5, color = { 152, 216, 229 } },
    { id = "north", name = "Northern Wilds", x = 1080, z = 0, radius = 94, level = 10, price = 2600, luck = 0.8, color = { 110, 162, 187 } },
    { id = "glacier", name = "Forgotten Glacier", x = 1440, z = 0, radius = 92, level = 15, price = 5200, luck = 1.2, color = { 173, 194, 233 } },
}
Content.Variants = {
    { name = "Normal", chance = 0.88, multiplier = 1 },
    { name = "Frosted", chance = 0.045, multiplier = 1.4, color = { 195, 235, 250 } },
    { name = "Albino", chance = 0.03, multiplier = 1.6, color = { 245, 227, 225 } },
    { name = "Midnight", chance = 0.02, multiplier = 1.9, color = { 89, 98, 162 } },
    { name = "Golden", chance = 0.013, multiplier = 2.4, color = { 248, 203, 83 } },
    { name = "Crystal", chance = 0.008, multiplier = 3.0, color = { 125, 236, 240 } },
    { name = "Aurora", chance = 0.004, multiplier = 4.0, color = { 208, 144, 253 } },
}
Content.Weather = {
    { id = "Clear", name = "Clear winter day", snow = 0, fog = 580, luck = 0 },
    { id = "LightSnow", name = "Light snow", snow = 22, fog = 480, luck = 0.10 },
    { id = "HeavySnow", name = "Heavy snow", snow = 50, fog = 340, luck = 0.20 },
    { id = "Blizzard", name = "Blizzard", snow = 85, fog = 220, luck = 0.35 },
    { id = "Aurora", name = "Aurora night", snow = 8, fog = 500, luck = 0.5 },
}
Content.DaySeconds = 1200
Content.WeatherSeconds = 180
Content.HookWindow = 2.2
Content.CollectionMilestones = { { count = 3, coins = 80, xp = 40 }, { count = 6, coins = 200, xp = 90 }, { count = 12, coins = 600, xp = 180 }, { count = 20, coins = 1600, xp = 350 } }
Content.Quests = {
    { id = "firstIce", title = "Break the ice", description = "Drill your first fishing hole.", event = "drill", goal = 1, coins = 25, xp = 15, level = 1 },
    { id = "firstCatch", title = "Something beneath", description = "Catch a fish.", event = "catch", goal = 1, coins = 40, xp = 25, prerequisite = "firstIce", level = 1 },
    { id = "firstSale", title = "A fair trade", description = "Sell a fish to Mara or the tackle shop.", event = "sell", goal = 1, coins = 50, xp = 25, prerequisite = "firstCatch", level = 1 },
    { id = "firstUpgrade", title = "Tools of the trade", description = "Buy any paid equipment or bait.", event = "buy", goal = 1, coins = 65, xp = 30, prerequisite = "firstSale", level = 1 },
    { id = "perchPatrol", title = "Perch patrol", description = "Catch five Yellow Perch. Repeatable.", event = "catch", species = "perch", goal = 5, coins = 140, xp = 70, repeatSeconds = 120, level = 2 },
    { id = "variety", title = "A varied catch", description = "Catch three different species after accepting.", event = "catch", distinct = true, goal = 3, coins = 180, xp = 80, level = 2 },
    { id = "rare", title = "Blue-ribbon angler", description = "Catch a Rare fish or better.", event = "catch", minRarity = 3, goal = 1, coins = 220, xp = 100, level = 4 },
    { id = "trophy", title = "A story worth telling", description = "Land a trophy-sized fish.", event = "catch", trophy = true, goal = 1, coins = 300, xp = 140, level = 4 },
    { id = "winter", title = "Snow day", description = "Catch three fish during snow or a blizzard.", event = "catch", snow = true, goal = 3, coins = 180, xp = 90, level = 3 },
    { id = "explorer", title = "Beyond the pines", description = "Visit Crystal Reservoir.", event = "visit", region = "crystal", goal = 1, coins = 350, xp = 150, level = 6 },
    { id = "variant", title = "An unusual shimmer", description = "Catch any non-Normal variant.", event = "catch", variant = true, goal = 1, coins = 250, xp = 120, level = 3 },
}
Content.Tutorial = {
    { event = "drill", title = "Meet the ice", description = "Walk onto the pond. F / Drill & Cast equips your auger and creates a hole. Better augers drill faster and make larger holes." },
    { event = "cast", title = "Your fishing spot", description = "The rod equips after drilling. Use F or the hole prompt to cast again from the same hole. G / New Hole replaces it." },
    { event = "catch", title = "Hook, then reel", description = "Press Space / A / Hook when a fish bites. Hold to move right, release to drift left. Keep the gold fish inside your green zone." },
    { event = "sell", title = "Bring home your catch", description = "Visit Mara by the cabin. Favorite or lock special fish in your bag before selling. Sell All protects both." },
    { event = "buy", title = "Make it yours", description = "Use the cabin shop to buy or equip rods, augers, bait, and lures. 3D View lets you inspect equipment. Bread is always free." },
    { event = "visit", title = "Beyond the pond", description = "Accept quests, fill your journal, and gain levels. Use a trail board to unlock and travel to new lakes." },
}
Content.DefaultSettings = { musicVolume = 0.35, sfxVolume = 0.65, reducedEffects = false, highContrast = false }

local function find(list, key, value) for _, item in ipairs(list) do if item[key] == value then return item end end end
function Content.region(id) return find(Content.Regions, "id", id) end
function Content.quest(id) return find(Content.Quests, "id", id) end
function Content.weather(id) return find(Content.Weather, "id", id) or Content.Weather[1] end
function Content.regionAt(x, z, margin)
    for _, region in ipairs(Content.Regions) do
        local dx, dz = x - region.x, z - region.z
        if dx * dx + dz * dz < (region.radius + (margin or 0)) ^ 2 then return region end
    end
end
function Content.rollVariant(roll)
    local sum = 0
    for _, variant in ipairs(Content.Variants) do sum = sum + variant.chance if roll < sum then return variant end end
    return Content.Variants[1]
end
function Content.environment(seconds)
    local hour = (14 + seconds / Content.DaySeconds * 24) % 24
    local index = math.floor(seconds / Content.WeatherSeconds) % #Content.Weather + 1
    -- Aurora is a real night event; avoid a bright midday aurora.
    if index == 5 then hour = 22 + (seconds % Content.WeatherSeconds) / Content.WeatherSeconds end
    return { hour = hour, weather = Content.Weather[index].id, night = hour >= 18 or hour < 6 }
end
return Content
