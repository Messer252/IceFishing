local FishGeneration = {}

function FishGeneration.roll(config, tier, luck, context, random)
    local species = config.selectFish(tier, luck, random(), context)
    local weightRoll = random()
    local rawWeight = species.minWeight + (species.maxWeight - species.minWeight) * weightRoll
    local kg = math.max(species.minWeight, math.min(species.maxWeight, math.floor(rawWeight * 100 + 0.5) / 100))
    local strength = context.strength or 6
    local resistance = 1 + math.max(0, kg / strength - 1) * 0.12
    local variant = context.variant or { name = "Normal", multiplier = 1 }
    local baseValue = math.max(1, math.floor(species.value * kg / species.kg * variant.multiplier))
    return { incomeMultiplier = context.incomeMultiplier or 1, luckMultiplier = context.luckMultiplier or 1, variant = variant.name, id = species.id, name = species.name, rarity = species.rarity, tier = species.tier,
        kg = kg, value = baseValue * (context.incomeMultiplier or 1),
        difficulty = math.min(2.15, species.difficulty * (0.9 + weightRoll * 0.2) * resistance),
        xp = species.xp, behavior = species.behavior, color = variant.color or species.color, trophy = weightRoll >= 0.95 }
end

return FishGeneration
