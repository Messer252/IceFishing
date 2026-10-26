local Inventory = {}
local ranks = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
function Inventory.find(bag, id)
    for i, fish in ipairs(bag) do if fish.catchId == id then return fish, i end end
end
function Inventory.protected(fish) return fish.locked == true or fish.favorite == true end
function Inventory.query(bag, search, sort)
    local result = {}
    local query = string.lower(tostring(search or "")):sub(1, 60)
    for _, fish in ipairs(bag) do
        if string.find(string.lower(fish.name), query, 1, true) then table.insert(result, fish) end
    end
    table.sort(result, function(a, b)
        local av, bv
        if sort == "Rarity" then av, bv = ranks[a.rarity] or 0, ranks[b.rarity] or 0
        elseif sort == "Weight" then av, bv = a.kg, b.kg
        elseif sort == "Value" then av, bv = a.value, b.value
        else av, bv = a.caughtAt or 0, b.caughtAt or 0 end
        if av == bv then return a.catchId < b.catchId end
        return av > bv
    end)
    return result
end
function Inventory.setFlag(profile, id, key, value)
    if (key ~= "locked" and key ~= "favorite") or type(value) ~= "boolean" then return false, "Invalid fish setting." end
    local fish = Inventory.find(profile.bag, id)
    if not fish then return false, "That fish is no longer in your bag." end
    fish[key] = value
    return true
end
function Inventory.sell(profile, id, cap)
    local value, count, keep = 0, 0, {}
    local selected = id == nil or Inventory.find(profile.bag, id)
    if not selected then return false, "That fish is no longer in your bag." end
    for _, fish in ipairs(profile.bag) do
        if (id == nil or fish.catchId == id) and not Inventory.protected(fish) then
            value, count = value + fish.value, count + 1
        else table.insert(keep, fish) end
    end
    if count == 0 then return false, "No sellable fish. Favorites and locked catches are protected." end
    if profile.coins + value > cap then return false, "Coin limit reached. Your catches were kept." end
    profile.bag, profile.coins = keep, profile.coins + value
    profile.statistics.sold, profile.statistics.earned = profile.statistics.sold + count, profile.statistics.earned + value
    return true, value, count
end
return Inventory
