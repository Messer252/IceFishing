local FishGeneration = {}

function FishGeneration.roll(config, tier, luck, context, random)
    local species = config.selectFish(tier, luck, random(), context)
    local weightRoll = random()
    local rawWeight = species.minWeight + (species.maxWeight - species.minWeight) * weightRoll
    local kg = math.max(species.minWeight, math.min(species.maxWeight, math.floor(rawWeight * 100 + 0.5) / 100))
    local strength = context.strength or 6
    local resistance = 1 + math.max(0, kg / strength - 1) * 0.12
    return { id = species.id, name = species.name, rarity = species.rarity, tier = species.tier,
        kg = kg, value = math.max(1, math.floor(species.value * kg / species.kg)),
        difficulty = math.min(2.15, species.difficulty * (0.9 + weightRoll * 0.2) * resistance),
        xp = species.xp, color = species.color, trophy = weightRoll >= 0.95 }
end

return FishGeneration
