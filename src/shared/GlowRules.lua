local Rules = {}
Rules.Types = {
    { id = "gold", name = "Golden Shoal", income = 2, luck = 1, color = { 255, 202, 98 } },
    { id = "blue", name = "Lucky Current", income = 1, luck = 2, color = { 100, 225, 250 } },
    { id = "aurora", name = "Aurora Bloom", income = 2, luck = 2, color = { 185, 142, 255 } },
}
function Rules.typeFor(roll)
    return roll < 0.45 and Rules.Types[1] or roll < 0.90 and Rules.Types[2] or Rules.Types[3]
end
function Rules.at(zones, now, regionId, position)
    local result = { income = 1, luck = 1, names = {} }
    for _, zone in ipairs(zones) do
        local x, z = position.X - zone.x, position.Z - zone.z
        if zone.regionId == regionId and zone.expiresAt > now and x * x + z * z <= zone.radius * zone.radius then
            result.income, result.luck = math.max(result.income, zone.income), math.max(result.luck, zone.luck)
            table.insert(result.names, zone.name)
        end
    end
    return result
end
function Rules.effectiveLuck(baseLuck, multiplier)
    -- Include baseline luck so a starter loadout still benefits from 2x luck.
    return (1 + math.max(0, baseLuck)) * multiplier - 1
end
function Rules.label(bonus)
    local parts = {}
    if bonus.income > 1 then table.insert(parts, "2x catch value") end
    if bonus.luck > 1 then table.insert(parts, "2x luck") end
    return table.concat(parts, " + ")
end
return Rules
