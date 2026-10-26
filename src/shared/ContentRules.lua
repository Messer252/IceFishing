local Rules = {}
function Rules.unlock(profile, region)
    if profile.level < region.level then return false, "Reach level " .. region.level .. " to travel here." end
    if profile.unlockedRegions[region.id] then return true end
    if profile.coins < region.price then return false, "You need " .. region.price .. " coins to unlock this trail." end
    profile.coins = profile.coins - region.price
    profile.unlockedRegions[region.id] = true
    return true
end
function Rules.setting(profile, key, value, defaults)
    if defaults[key] == nil then return false, "Unknown setting." end
    if type(defaults[key]) == "boolean" then
        if type(value) ~= "boolean" then return false, "Invalid setting." end
    elseif type(value) ~= "number" or value ~= value or value < 0 or value > 1 then return false, "Volume must be between 0 and 1." end
    profile.settings[key] = value
    return true
end
function Rules.tutorial(profile, tutorial, event)
    local state = profile.tutorial
    if state.completed or state.skipped then return end
    local step = tutorial[state.step]
    if step and step.event == event then state.step = state.step + 1 end
    if state.step > #tutorial then state.completed = true end
end
function Rules.collect(profile, catch, milestones, cap, addXP)
    local record = profile.collection[catch.species] or { count = 0, biggest = 0, variants = {} }
    record.count, record.biggest = record.count + 1, math.max(record.biggest, catch.kg)
    record.variants[catch.variant] = true
    profile.collection[catch.species] = record
    local discovered = 0
    for _, value in pairs(profile.discoveries) do if value then discovered = discovered + 1 end end
    local rewards = {}
    for _, milestone in ipairs(milestones) do
        local key = "collection_" .. milestone.count
        if discovered >= milestone.count and not profile.achievements[key] and profile.coins + milestone.coins <= cap then
            profile.achievements[key] = true
            profile.coins = profile.coins + milestone.coins
            addXP(profile, milestone.xp)
            table.insert(rewards, milestone.count)
        end
    end
    if catch.trophy then profile.achievements.firstTrophy = true end
    return rewards
end
return Rules
