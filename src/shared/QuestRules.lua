local QuestRules = {}
function QuestRules.accept(profile, definition, now)
    local state = profile.quests[definition.id]
    if profile.level < definition.level then return false, "Reach level " .. definition.level .. " first." end
    if definition.prerequisite and not (profile.quests[definition.prerequisite] and profile.quests[definition.prerequisite].claimed) then return false, "Finish the previous quest first." end
    if state then
        if not state.claimed then return false, "This quest is already active." end
        if not definition.repeatSeconds then return false, "You already completed this quest." end
        if now < (state.claimedAt or 0) + definition.repeatSeconds then return false, "This quest is resting. Try again shortly." end
    end
    profile.quests[definition.id] = { progress = 0, acceptedAt = now, claimed = false, seen = {} }
    return true
end
function QuestRules.record(profile, definitions, event, data, now)
    for _, definition in ipairs(definitions) do
        local state = profile.quests[definition.id]
        if state and not state.claimed and definition.event == event and now >= state.acceptedAt then
            local matches = (not definition.species or definition.species == data.species)
                and (not definition.region or definition.region == data.region)
                and (not definition.minRarity or (data.rarityRank or 0) >= definition.minRarity)
                and (not definition.trophy or data.trophy == true)
                and (not definition.variant or data.variant ~= "Normal" and data.variant ~= nil)
                and (not definition.snow or data.weather == "LightSnow" or data.weather == "HeavySnow" or data.weather == "Blizzard")
            if matches then
                local gain = data.amount or 1
                if definition.distinct then
                    if not data.species or state.seen[data.species] then gain = 0 else state.seen[data.species] = true gain = 1 end
                end
                state.progress = math.min(definition.goal, state.progress + gain)
            end
        end
    end
end
function QuestRules.claim(profile, definition, now, cap, addXP)
    local state = profile.quests[definition.id]
    if not state or state.claimed or state.progress < definition.goal then return false, "This quest isn't ready to claim." end
    if profile.coins + definition.coins > cap then return false, "Coin limit reached. Your reward is waiting." end
    state.claimed, state.claimedAt = true, now
    profile.coins = profile.coins + definition.coins
    addXP(profile, definition.xp)
    return true
end
return QuestRules
