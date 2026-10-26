local HoleRules = {}

function HoleRules.canReuse(hole, userId, distance, maxDistance)
    return hole ~= nil and hole.ownerId == userId and distance <= maxDistance
end

-- Existing holes retain the tier of the auger that drilled them.
function HoleRules.fishingTier(hole)
    return hole.tier
end

return HoleRules
