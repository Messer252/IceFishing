local Progression = {}
Progression.MaxLevel = 100
Progression.MaxXP = 10000000

function Progression.requiredXP(level)
    return 80 + (level - 1) * 45
end

function Progression.describe(totalXP)
    local remaining, level = math.max(0, math.floor(totalXP or 0)), 1
    while level < Progression.MaxLevel and remaining >= Progression.requiredXP(level) do
        remaining = remaining - Progression.requiredXP(level)
        level = level + 1
    end
    if level == Progression.MaxLevel then remaining = Progression.requiredXP(level) end
    return { level = level, current = remaining, required = Progression.requiredXP(level),
        fraction = level == Progression.MaxLevel and 1 or remaining / Progression.requiredXP(level) }
end

function Progression.add(profile, amount)
    local before = Progression.describe(profile.xp).level
    profile.xp = math.min(Progression.MaxXP, profile.xp + math.max(0, math.floor(amount)))
    profile.level = Progression.describe(profile.xp).level
    return profile.level > before
end

return Progression
