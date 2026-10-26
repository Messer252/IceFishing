-- Run from the repository root with Lua 5.3+ or Fengari.
local Config = dofile("src/shared/Config.lua")
local Reel = dofile("src/shared/Reel.lua")
local count = 0
local function check(condition, message)
    assert(condition, message)
    count = count + 1
end

for tier = 1, 4 do
    local seen = {}
    for i = 0, 9999 do
        local fish = Config.selectFish(tier, 2, i / 10000)
        assert(fish.tier <= tier, "An auger selected a locked fish")
        seen[fish.id] = true
    end
    for _, fish in ipairs(Config.Fish) do
        check(not not seen[fish.id] == (fish.tier <= tier), "Every unlocked fish must be reachable")
    end
end

local function highTierCount(luck)
    local result = 0
    for i = 0, 9999 do
        if Config.selectFish(4, luck, i / 10000).tier >= 3 then result = result + 1 end
    end
    return result
end
check(highTierCount(3) > highTierCount(0), "Gear luck must improve rare-fish odds")
local qualityCounts = { 0, 0 }
for index, luck in ipairs({ 0, 3 }) do
    for i = 0, 999 do
        if Config.selectFish(1, luck, i / 1000).id == "bluegill" then qualityCounts[index] = qualityCounts[index] + 1 end
    end
end
check(qualityCounts[2] > qualityCounts[1], "Luck must also improve starter-tier fish quality")
check(Config.findGear("rod", "carbon").control > Config.findGear("rod", "twig").control, "Rod upgrades improve control")
check(Config.findGear("invalid", "fake") == nil, "Invalid items must be rejected")
check(Config.findGear("bait", "bread").amount == 0, "Players always have a free bait option")
for category, items in pairs(Config.Gear) do
    local ids = {}
    for _, gear in ipairs(items) do
        check(not ids[gear.id], "Duplicate " .. category .. " ID")
        ids[gear.id] = true
        check(gear.cost >= 0, "Negative gear price")
    end
end

local function simulate(fish, control, follow)
    local s = { phase = 1.7, bar = 0.5, target = 0.5, width = Config.Fishing.BaseWidth + control, progress = 0.25, tension = 0 }
    local result
    for i = 1, 60 * 40 do
        local held = follow and s.bar < s.target or false
        result = Reel.step(s, 1 / 60, held, fish, Config.Fishing, i / 60)
        assert(s.bar >= 0 and s.bar <= 1 and s.progress >= 0 and s.progress <= 1 and s.tension >= 0 and s.tension <= 1, "Simulation escaped its bounds")
        if result then return result, i / 60 end
    end
    return result
end

for _, fish in ipairs(Config.Fish) do
    local result, duration = simulate(fish, Config.findGear("rod", "glacier").control, true)
    check(result == "caught", fish.name .. " should be catchable with good input")
    check(duration > 3, "Catch should require sustained play")
end
check(simulate(Config.Fish[1], 0, true) == "caught", "Starter rod must catch starter fish")
check(simulate(Config.Fish[1], 0, false) == "escaped", "Doing nothing must lose the fish")
local timeout = { phase = 0, bar = 0.5, target = 0.5, width = 1, progress = 0.1, tension = 0 }
check(Reel.step(timeout, 0, false, Config.Fish[1], Config.Fishing, 36) == "escaped", "Overlong encounters time out")
print("PASS: " .. count .. " gameplay checks, including 62,000 fish selections and reel simulations")
