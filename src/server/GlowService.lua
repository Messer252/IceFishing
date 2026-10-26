local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Content = require(ReplicatedStorage.Shared.Content)
local Rules = require(ReplicatedStorage.Shared.GlowRules)
local GlowService = {}
function GlowService.start(context)
    local random = context.random or Random.new()
    local clock = context.clock or function() return workspace:GetServerTimeNow() end
    local zones, counter = {}, 0
    local nextEvent = clock() + 20
    local api = {}
    function api.snapshot()
        local result = {}
        for _, zone in ipairs(zones) do
            local copy = {}
            for key, value in pairs(zone) do
                if key == "color" then copy.color = { value[1], value[2], value[3] } else copy[key] = value end
            end
            table.insert(result, copy)
        end
        return result
    end
    function api.send(player) context.event:FireClient(player, "glowZones", api.snapshot()) end
    local function broadcast()
        local snapshot = api.snapshot()
        for player in pairs(context.profiles) do context.event:FireClient(player, "glowZones", snapshot) end
    end
    function api.bonuses(regionId, position) return Rules.at(zones, clock(), regionId, position) end
    function api.step()
        local now, changed = clock(), false
        for i = #zones, 1, -1 do
            if zones[i].expiresAt <= now then table.remove(zones, i) changed = true end
        end
        if now >= nextEvent and #zones < 3 then
            local occupied, candidates = {}, {}
            for player, profile in pairs(context.profiles) do
                local root = context.root(player)
                local region = root and Content.regionAt(root.Position.X, root.Position.Z, 32)
                if region and profile.unlockedRegions[region.id] and not occupied[region.id] then
                    occupied[region.id] = true table.insert(candidates, region)
                end
            end
            if #candidates > 0 then
                table.sort(candidates, function(a, b) return a.id < b.id end)
                local region = candidates[math.min(#candidates, math.floor(random:NextNumber() * #candidates) + 1)]
                local kind = Rules.typeFor(random:NextNumber())
                local radius = random:NextNumber(10, 13)
                local angle = random:NextNumber(0, math.pi * 2)
                local distance = random:NextNumber(0.15, 0.70) * (region.radius - radius - 7)
                counter = counter + 1
                table.insert(zones, { id = tostring(counter), regionId = region.id, name = kind.name,
                    x = region.x + math.cos(angle) * distance, z = region.z + math.sin(angle) * distance,
                    radius = radius, income = kind.income, luck = kind.luck, color = kind.color,
                    expiresAt = now + random:NextNumber(85, 115) })
                for player in pairs(context.profiles) do
                    context.event:FireClient(player, "glowNotice", kind.name .. " is glowing beneath " .. region.name .. ". Fish inside the light for " .. Rules.label(kind) .. "!")
                end
                changed = true
            end
            nextEvent = now + random:NextNumber(80, 140)
        elseif now >= nextEvent then nextEvent = now + 15 end
        if changed then broadcast() end
    end
    return api
end
return GlowService
