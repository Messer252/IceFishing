-- Versioned, deterministic migrations; safe to run repeatedly in UpdateAsync.
local ProfileSchema = {}
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = clone(v) end
    return result
end
ProfileSchema.clone = clone
local function finite(value) return type(value) == "number" and value == value and math.abs(value) < math.huge end

function ProfileSchema.create(config, progression)
    local schema = { version = 2, clone = clone }
    function schema.new()
        local profile = { schemaVersion = 2, coins = config.StartingCoins, xp = 0, level = 1, bag = {}, bait = {},
            equipped = { auger = "hand", rod = "twig", lure = "plain", bait = "bread" },
            owned = { auger = { hand = true }, rod = { twig = true }, lure = { plain = true } },
            discoveries = {}, records = {}, statistics = { catches = 0, sold = 0, earned = 0 },
            settings = {}, quests = {}, unlockedRegions = { pond = true } }
        for _, bait in ipairs(config.Gear.bait) do if bait.amount > 0 then profile.bait[bait.id] = 0 end end
        return profile
    end
    function schema.migrate(raw)
        if type(raw) ~= "table" then return nil, "invalid profile" end
        if raw.schemaVersion and (not finite(raw.schemaVersion) or raw.schemaVersion > 2) then return nil, "unsupported data version" end
        if not finite(raw.coins) or raw.coins < 0 or raw.coins > config.MaxCoins then return nil, "invalid currency" end
        local p = schema.new()
        for _, key in ipairs({ "owned", "bait", "equipped" }) do
            if raw[key] ~= nil and type(raw[key]) ~= "table" then return nil, "invalid " .. key end
        end
        for _, category in ipairs({ "rod", "auger", "lure" }) do
            if raw.owned and raw.owned[category] ~= nil and type(raw.owned[category]) ~= "table" then return nil, "invalid equipment ownership" end
        end
        p.coins = math.floor(raw.coins)
        if raw.xp ~= nil and (not finite(raw.xp) or raw.xp < 0) then return nil, "invalid XP" end
        p.xp = math.min(progression.MaxXP, math.floor(raw.xp or 0))
        p.level = progression.describe(p.xp).level
        for category, items in pairs(config.Gear) do
            if category ~= "bait" then
                for _, item in ipairs(items) do
                    if raw.owned and raw.owned[category] and raw.owned[category][item.id] == true then p.owned[category][item.id] = true end
                end
            else
                for _, item in ipairs(items) do
                    local count = raw.bait and raw.bait[item.id]
                    if count ~= nil and (not finite(count) or count < 0) then return nil, "invalid bait count" end
                    if item.amount > 0 then p.bait[item.id] = math.min(100000, math.floor(count or 0)) end
                end
            end
            local equipped = raw.equipped and raw.equipped[category]
            if config.findGear(category, equipped) and (category == "bait" or p.owned[category][equipped]) then p.equipped[category] = equipped end
        end
        if raw.bag ~= nil and type(raw.bag) ~= "table" then return nil, "invalid fish inventory" end
        if raw.bag and #raw.bag > 100 then return nil, "oversized fish inventory" end
        local ids = {}
        for i, fish in ipairs(raw.bag or {}) do
            if type(fish) ~= "table" or type(fish.name) ~= "string" or not finite(fish.value) or fish.value < 1
                or fish.value > 10000000 or not finite(fish.kg) or fish.kg <= 0 or fish.kg > 10000 then
                return nil, "invalid fish entry"
            end
            local entry = clone(fish)
            if type(entry.rarity) ~= "string" or type(entry.color) ~= "table" then return nil, "invalid fish appearance" end
            for channel = 1, 3 do
                if not finite(entry.color[channel]) or entry.color[channel] < 0 or entry.color[channel] > 255 then return nil, "invalid fish color" end
            end
            entry.catchId = type(entry.catchId) == "string" and entry.catchId or ("legacy-" .. i)
            if ids[entry.catchId] then return nil, "duplicate catch ID" end
            ids[entry.catchId] = true
            table.insert(p.bag, entry)
        end
        for _, key in ipairs({ "discoveries", "records", "statistics", "settings", "quests", "unlockedRegions" }) do
            if raw[key] ~= nil and type(raw[key]) ~= "table" then return nil, "invalid " .. key end
            if raw[key] then p[key] = clone(raw[key]) end
        end
        for _, key in ipairs({ "catches", "sold", "earned" }) do
            local value = p.statistics[key]
            if value ~= nil and (not finite(value) or value < 0) then return nil, "invalid statistics" end
            p.statistics[key] = math.floor(value or 0)
        end
        for id, value in pairs(p.discoveries) do
            if type(id) ~= "string" or type(value) ~= "boolean" then return nil, "invalid discoveries" end
        end
        for id, value in pairs(p.records) do
            if type(id) ~= "string" or not finite(value) or value <= 0 then return nil, "invalid fish records" end
        end
        return p
    end
    return schema
end
return ProfileSchema
