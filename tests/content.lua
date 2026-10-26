local Config = dofile("src/shared/Config.lua")
local Content = dofile("src/shared/Content.lua")
local Inventory = dofile("src/shared/Inventory.lua")
local Quests = dofile("src/shared/QuestRules.lua")
local Rules = dofile("src/shared/ContentRules.lua")
local Progression = dofile("src/shared/Progression.lua")
local Gate = dofile("src/shared/NetworkGate.lua")
local Schema = dofile("src/server/ProfileSchema.lua").create(Config, Progression)
local count = 0
local function check(value, message) assert(value, message) count = count + 1 end
local function fish(id, locked, favorite)
    return { catchId = id, species = "perch", name = "Yellow Perch", rarity = "Common", color = { 200, 180, 80 },
        kg = 1, value = 30, caughtAt = 10, variant = "Normal", locked = locked or false, favorite = favorite or false }
end
local p = Schema.new()
p.bag = { fish("free"), fish("locked", true), fish("favorite", false, true) }
local ok, value, sold = Inventory.sell(p, nil, Config.MaxCoins)
check(ok and value == 30 and sold == 1 and #p.bag == 2, "Bulk sales protect both favorites and locked catches")
check(not Inventory.sell(p, "free", Config.MaxCoins), "A sold catch ID cannot be replayed for another payout")
check(not Inventory.sell(p, "locked", Config.MaxCoins), "Individual sales cannot bypass a fish lock")
check(not Inventory.sell(p, "other-player-id", Config.MaxCoins), "Players cannot sell another player's fish ID")
check(Inventory.setFlag(p, "locked", "locked", false), "Unlock is an explicit boolean update")
check(Inventory.setFlag(p, "locked", "locked", false) and not p.bag[1].locked, "Duplicate flag requests do not toggle state back")
check(not Inventory.setFlag(p, "favorite", "value", 99999), "Inventory commands cannot edit fish values")
p.coins = Config.MaxCoins
local before = #p.bag
check(not Inventory.sell(p, "locked", Config.MaxCoins) and #p.bag == before, "A coin-cap sale preserves the inventory atomically")
check(#Inventory.query(p.bag, "Perch", "Value") == 2 and #Inventory.query(p.bag, ".", "Value") == 0, "Inventory search is literal and case-insensitive")
p.bag = { fish("z"), fish("a") }
p.bag[1].kg, p.bag[2].value = 3, 99
check(Inventory.query(p.bag, "", "Weight")[1].catchId == "z" and Inventory.query(p.bag, "", "Value")[1].catchId == "a", "Inventory sort modes use catch properties")

p = Schema.new()
local first, nextQuest = Content.quest("firstIce"), Content.quest("firstCatch")
check(not Quests.accept(p, nextQuest, 100), "Quest prerequisites are enforced")
check(Quests.accept(p, first, 100), "A valid available quest can be accepted")
check(not Quests.accept(p, first, 100), "Active quests cannot be reset by replaying accept")
check(not Quests.claim(p, first, 100, Config.MaxCoins, Progression.add), "Incomplete quests cannot pay rewards")
Quests.record(p, Content.Quests, "drill", {}, 101)
check(p.quests.firstIce.progress == 1, "Matching gameplay events advance accepted quests")
local coins = p.coins
check(Quests.claim(p, first, 102, Config.MaxCoins, Progression.add) and p.coins == coins + first.coins, "Quest rewards are paid once after completion")
coins = p.coins
check(not Quests.claim(p, first, 103, Config.MaxCoins, Progression.add) and p.coins == coins, "Duplicate claims cannot duplicate coins or XP")
check(Quests.accept(p, nextQuest, 103), "Claimed prerequisites unlock the next quest")
p.level = 2
local variety = Content.quest("variety")
Quests.accept(p, variety, 100)
for _ = 1, 5 do Quests.record(p, Content.Quests, "catch", { species = "perch" }, 101) end
check(p.quests.variety.progress == 1, "Distinct-species quests do not count repeated catches twice")
Quests.record(p, Content.Quests, "catch", { species = "bluegill" }, 102)
Quests.record(p, Content.Quests, "catch", { species = "crappie" }, 103)
check(p.quests.variety.progress == 3, "Distinct-species quests track separate species")
local repeatQuest = Content.quest("perchPatrol")
Quests.accept(p, repeatQuest, 100)
for _ = 1, 5 do Quests.record(p, Content.Quests, "catch", { species = "perch" }, 110) end
Quests.claim(p, repeatQuest, 111, Config.MaxCoins, Progression.add)
check(not Quests.accept(p, repeatQuest, 112), "Repeat quests enforce a cooldown")
check(Quests.accept(p, repeatQuest, 232) and p.quests.perchPatrol.progress == 0, "Repeat quests restart only after the cooldown")
p.quests.perchPatrol.progress = 5 p.coins = Config.MaxCoins
check(not Quests.claim(p, repeatQuest, 233, Config.MaxCoins, Progression.add) and not p.quests.perchPatrol.claimed, "A capped reward stays claimable instead of being discarded")

p = Schema.new()
local lake = Content.region("lake")
check(not Rules.unlock(p, lake) and not p.unlockedRegions.lake, "Level requirements protect region access")
p.level = 3
check(not Rules.unlock(p, lake) and p.coins == 120, "Insufficient funds cannot unlock a region")
p.coins = 1000
check(Rules.unlock(p, lake) and p.coins == 650 and p.unlockedRegions.lake, "Region unlocks charge the authoritative price")
check(Rules.unlock(p, lake) and p.coins == 650, "Unlocked trips cannot be charged twice")
for _, region in ipairs(Content.Regions) do
    check(Content.regionAt(region.x, region.z).id == region.id, "Region geometry maps its own center")
end
local koi = Config.findFish("glasskoi")
check(not Config.available(koi, 5, { region = "pond" }) and Config.available(koi, 5, { region = "crystal" }), "Regional species cannot spawn in another lake")
check(not Config.available(koi, 3, { region = "crystal" }), "Regional unlocks do not bypass auger tier requirements")
check(Rules.setting(p, "sfxVolume", 0.4, Content.DefaultSettings) and p.settings.sfxVolume == 0.4, "Valid settings update the profile")
check(not Rules.setting(p, "sfxVolume", 0 / 0, Content.DefaultSettings) and not Rules.setting(p, "coins", 10000, Content.DefaultSettings), "Settings reject NaN and unknown fields")
check(not Rules.setting(p, "reducedEffects", 1, Content.DefaultSettings), "Boolean settings cannot be replaced with numbers")

p = Schema.new()
for _, instruction in ipairs(Content.Tutorial) do Rules.tutorial(p, Content.Tutorial, instruction.event) end
check(p.tutorial.completed and p.tutorial.step == 7, "The tutorial advances through actual gameplay events")
local same = p.tutorial.step Rules.tutorial(p, Content.Tutorial, "drill")
check(p.tutorial.step == same, "Completed tutorials do not repeat")
p = Schema.new()
p.discoveries = { perch = true, bluegill = true, crappie = true }
Rules.collect(p, fish("one"), Content.CollectionMilestones, Config.MaxCoins, Progression.add)
coins = p.coins
Rules.collect(p, fish("two"), Content.CollectionMilestones, Config.MaxCoins, Progression.add)
check(p.coins == coins and p.achievements.collection_3, "Collection milestone rewards are not replayable")
local gold = fish("gold") gold.variant, gold.kg, gold.trophy = "Golden", 2, true
Rules.collect(p, gold, Content.CollectionMilestones, Config.MaxCoins, Progression.add)
check(p.collection.perch.count == 3 and p.collection.perch.biggest == 2 and p.collection.perch.variants.Golden and p.achievements.firstTrophy, "The journal records counts, biggest fish, variants and trophies")
local migrated = Schema.migrate(p)
check(migrated and migrated.collection.perch.variants.Golden and migrated.tutorial.step == 1, "New collection/tutorial data survives validation")
local old = Schema.new() old.schemaVersion, old.collection = 2, nil
old.discoveries.perch, old.records.perch = true, 1.5
local restored = Schema.migrate(old)
check(restored.schemaVersion == 3 and restored.collection.perch.biggest == 1.5 and restored.coins == old.coins, "Phase 2 records migrate without losing progress")

local variants = {}
for i = 0, 9999 do local variant = Content.rollVariant(i / 10000) variants[variant.name] = (variants[variant.name] or 0) + 1 end
check(variants.Normal >= 8799 and variants.Normal <= 8801 and variants.Aurora >= 39 and variants.Aurora <= 41, "Variant probabilities preserve a common normal catch and rare specials")
for _, variant in ipairs(Content.Variants) do check(variants[variant.name] and variant.multiplier >= 1, "Every configured variant is reachable") end
local states = {}
for i = 0, 4 do local state = Content.environment(i * Content.WeatherSeconds + 1) states[state.weather] = true if state.weather == "Aurora" then check(state.night, "Aurora weather occurs at night") end end
check(states.Clear and states.Blizzard and states.Aurora, "The environment cycles through all configured weather")
check(Content.environment(0).hour == Content.environment(Content.DaySeconds * 5).hour, "The day clock cycles deterministically")

local gate = Gate.new()
local allowed = 0
for i = 1, 600 do if gate:allow(1, "input", i / 60) then allowed = allowed + 1 end end
check(allowed == 600, "Normal reel input does not exhaust the network budget")
local accepted = 0
for i = 1, 100 do if gate:allow(2, "ready", 1) then accepted = accepted + 1 end end
check(accepted == 1, "Rapid ready requests cannot flood full inventory snapshots")
check(gate:allow(2, "ready", 2.1), "Rate limits recover over time")
local large = 0
for i = 1, 100 do if gate:allow(3, "fishFlag", i / 4, 100) then large = large + 1 end end
check(large < 40, "Large-inventory mutations have a stricter full-snapshot budget")
gate:remove(2) check(not gate.users[2], "Disconnect cleanup removes limiter state")
print("PASS: " .. count .. " inventory, quest, collection, travel, environment and network checks")
