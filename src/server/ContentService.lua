local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Content = require(ReplicatedStorage.Shared.Content)
local Rules = require(ReplicatedStorage.Shared.ContentRules)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Quests = require(ReplicatedStorage.Shared.QuestRules)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Config = require(ReplicatedStorage.Shared.Config)
local Service = {}
function Service.start(context)
    local api = {}
    function api.ensure(profile)
        if not profile.quests.firstIce then
            profile.quests.firstIce = { progress = 0, acceptedAt = os.time(), claimed = false, seen = {} }
        end
    end
    function api.record(player, event, data)
        local profile = context.profiles[player]
        if not profile then return end
        Rules.tutorial(profile, Content.Tutorial, event)
        Quests.record(profile, Content.Quests, event, data or {}, os.time())
    end
    function api.catch(player, catch)
        local profile = context.profiles[player]
        local milestones = Rules.collect(profile, catch, Content.CollectionMilestones, Config.MaxCoins, Progression.add)
        api.record(player, "catch", { species = catch.species, region = catch.regionId, rarityRank = Content.Rarity[catch.rarity],
            variant = catch.variant, trophy = catch.trophy, weather = catch.weather })
        for _, count in ipairs(milestones) do context.notify(player, "Journal milestone: " .. count .. " species! Coins and XP awarded.") end
    end
    function api.handle(player, action, data)
        local profile = context.profiles[player]
        if not profile or type(data) ~= "table" then return end
        local ok, message
        if action == "fishFlag" then
            if type(data.id) ~= "string" or #data.id > 80 then return end
            ok, message = Inventory.setFlag(profile, data.id, data.key, data.value)
        elseif action == "sellOne" then
            if type(data.id) ~= "string" or #data.id > 80 then return end
            context.sell(player, data.id) return
        elseif action == "equip" then
            local item = type(data.category) == "string" and type(data.id) == "string" and Config.findGear(data.category, data.id)
            if not item then return end
            if context.sessions[player] then context.notify(player, "Finish your cast before switching equipment.") return end
            if data.category == "bait" then
                if item.amount > 0 and (profile.bait[item.id] or 0) < 1 then context.notify(player, "You are out of that bait.") return end
            elseif not profile.owned[data.category][item.id] then context.notify(player, "Buy this equipment at the shop first.") return end
            profile.equipped[data.category] = item.id
            ok, message = true, item.name .. " equipped."
        elseif action == "quest" then
            local definition = type(data.id) == "string" and Content.quest(data.id)
            if not definition then return end
            if data.mode == "accept" then ok, message = Quests.accept(profile, definition, os.time())
            elseif data.mode == "claim" then ok, message = Quests.claim(profile, definition, os.time(), Config.MaxCoins, Progression.add)
            else return end
            if ok then message = data.mode == "accept" and ("Accepted: " .. definition.title) or ("Quest reward: +" .. definition.coins .. " coins / +" .. definition.xp .. " XP") end
        elseif action == "travel" then
            local region = type(data.id) == "string" and Content.region(data.id)
            if not region then return end
            if context.sessions[player] or player:GetAttribute("Traveling") then context.notify(player, "Finish your cast or current trip before traveling.") return end
            if not context.nearTrail(player) then context.notify(player, "Visit a trail board to unlock or travel to a lake.") return end
            if player:GetAttribute("AdminFrozen") then context.notify(player, "Unfreeze before traveling.") return end
            ok, message = Rules.unlock(profile, region)
            if ok then
                context.stopFlight(player)
                local root = context.root(player)
                if root then
                    local destination = Vector3.new(region.x, 5, region.z - region.radius - 9)
                    local anchored = root.Anchored
                    root.Anchored = true
                    player:SetAttribute("Traveling", true)
                    message = "Opening the trail to " .. region.name .. "..."
                    task.spawn(function()
                        local loaded = pcall(function()
                            if workspace.StreamingEnabled then player:RequestStreamAroundAsync(destination, 4) end
                        end)
                        if loaded and root.Parent and context.root(player) == root and player:GetAttribute("ProfileReady") == true then
                            root.CFrame = CFrame.new(destination)
                            root.AssemblyLinearVelocity = Vector3.zero
                            player:SetAttribute("RegionId", region.id) player:SetAttribute("RegionName", region.name)
                            api.record(player, "visit", { region = region.id })
                            context.pushProfile(player)
                            context.notify(player, "Welcome to " .. region.name .. ".")
                        elseif context.profiles[player] then context.notify(player, "The trail could not load. Your unlock is kept; please retry.") end
                        if root.Parent then root.Anchored = anchored end
                        if player.Parent then player:SetAttribute("Traveling", false) end
                    end)
                end
            end
        elseif action == "setting" then ok, message = Rules.setting(profile, data.key, data.value, Content.DefaultSettings)
        elseif action == "tutorial" and data.skip == true then
            profile.tutorial.skipped, profile.tutorial.completed = true, true
            ok, message = true, "Tutorial skipped. You can reread the guide any time."
        else return end
        if ok then context.pushProfile(player) end
        if message then context.notify(player, message) end
    end
    return api
end
return Service
