-- Run from the repository root with Lua 5.3+ or Fengari.
local Config = dofile("src/shared/Config.lua")
local Reel = dofile("src/shared/Reel.lua")
local HoleRules = dofile("src/shared/HoleRules.lua")
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

-- Regression: gsub returns a string AND a replacement count. The HUD must
-- receive exactly one value when appending names with table.insert.
local names = {}
for category, items in pairs(Config.Gear) do
    for _, item in ipairs(items) do
        check(select("#", Config.gearName(category, item.id)) == 1, "HUD labels must return only one value")
        table.insert(names, Config.gearName(category, item.id))
    end
end
check(Config.gearName("bait", "worms") == "Worms", "Bait labels omit pack quantities")

local hole = { ownerId = 123, tier = 1, size = 3 }
local starterSpecies = 0
for _, fish in ipairs(Config.Fish) do if fish.tier == 1 then starterSpecies = starterSpecies + 1 end end
check(starterSpecies >= 5, "The starter pond has at least five catchable species")
check(HoleRules.canReuse(hole, 123, 6, Config.HoleUseDistance), "Nearby owned holes can be reused")
check(not HoleRules.canReuse(hole, 999, 6, Config.HoleUseDistance), "Other players cannot take over a hole")
check(not HoleRules.canReuse(hole, 123, 30, Config.HoleUseDistance), "Distant holes cannot be used remotely")
check(not HoleRules.canReuse(nil, 123, 0, Config.HoleUseDistance), "Missing holes must be drilled")
check(HoleRules.fishingTier(hole) == 1, "Existing hole retains its original fish tier")

local function movement(fps)
    local s = { bar = 0.35, velocity = 0, width = 0.23 }
    for _ = 1, fps / 2 do Reel.moveBar(s, 1 / fps, true, Config.Fishing) end
    return s.bar
end
check(math.abs(movement(30) - movement(120)) < 0.000001, "Control movement is frame-rate independent")

local function packet(time, bar)
    return { token = "test", bar = bar, velocity = 0, target = 0.5, width = 0.23,
        progress = 0.25, tension = 0, phase = 1.7, difficulty = 0.7, elapsed = time, serverTime = time }
end
local view = Reel.newView(packet(0, 0.5))
local movingFrames, largestStep = 0, 0
local previous = view.bar
for i = 1, 120 do
    local now, held = i / 60, i < 60
    if i % 5 == 0 then
        local before = view.bar
        -- Deliberately delayed, uneven packets with substantial correction.
        Reel.receiveView(view, packet(now - 0.06, 0.45 + math.sin(now) * 0.1), now, held, Config.Fishing)
        check(view.bar == before, "Packet receipt must never snap the displayed bar")
    end
    Reel.viewStep(view, 1 / 60, held, now, Config.Fishing)
    local delta = math.abs(view.bar - previous)
    largestStep = math.max(largestStep, delta)
    if delta > 0.00001 then movingFrames = movingFrames + 1 end
    check(view.bar >= view.width / 2 and view.bar <= 1 - view.width / 2, "The full control zone stays on screen")
    previous = view.bar
end
check(movingFrames > 100, "The reel animates between network updates")
check(largestStep < 0.03, "Corrections are spread across frames")
local current = view.snapshot
Reel.receiveView(view, packet(0, 0.1), 2, false, Config.Fishing)
check(view.snapshot == current, "Stale packets cannot rewind the minigame")
local localView = Reel.newView(packet(0, 0.5))
Reel.viewStep(localView, 1 / 60, true, 1 / 60, Config.Fishing)
check(localView.bar > 0.5, "Input responds before a server packet arrives")
print("PASS: " .. count .. " gameplay checks, including 62,000 fish selections and reel simulations")
