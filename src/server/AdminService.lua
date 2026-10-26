local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Progression = require(ReplicatedStorage.Shared.Progression)
local Config = require(ReplicatedStorage.Shared.Config)
local Settings = require(script.Parent.ServerSettings)
local Policy = require(script.Parent.AdminPolicy)
local Admin = {}

function Admin.start(context)
    local policy = Policy.new(Settings, RunService:IsStudio())
    local command, event = Instance.new("RemoteEvent"), Instance.new("RemoteEvent")
    command.Name, event.Name = "AdminCommand", "AdminEvent"
    command.Parent, event.Parent = context.remotes, context.remotes
    local limits, flying, frozen = {}, {}, {}
    local function status(player, text) event:FireClient(player, "result", text) end
    local function mark(player) player:SetAttribute("IsAdmin", policy.isAdmin(player.UserId)) end
    local function roster(player)
        local list = {}
        for _, target in ipairs(Players:GetPlayers()) do
            table.insert(list, { userId = target.UserId, username = target.Name, displayName = target.DisplayName,
                coins = context.profiles[target] and context.profiles[target].coins or nil })
        end
        event:FireClient(player, "roster", list)
    end
    local function rootOf(player)
        local char = player.Character
        return char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
    end
    local function stopFlying(player)
        local state = flying[player]
        if state then
            for _, item in ipairs(state.instances) do item:Destroy() end
            if state.humanoid.Parent then
                state.humanoid.PlatformStand, state.humanoid.AutoRotate = state.platformStand, state.autoRotate
            end
            if state.root.Parent then
                state.root.AssemblyLinearVelocity, state.root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            end
            flying[player] = nil
        end
        player:SetAttribute("AdminFlying", false)
    end
    local function unfreeze(player)
        local state = frozen[player]
        if state and state.root.Parent then state.root.Anchored = state.anchored end
        frozen[player] = nil
        player:SetAttribute("AdminFrozen", false)
    end
    local function setup(player)
        mark(player)
        player.CharacterRemoving:Connect(function() stopFlying(player) unfreeze(player) end)
    end
    Players.PlayerAdded:Connect(setup)
    for _, player in ipairs(Players:GetPlayers()) do setup(player) end
    Players.PlayerRemoving:Connect(function(player) stopFlying(player) unfreeze(player) limits[player] = nil end)
    task.spawn(function()
        for attempt = 1, 3 do
            local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(Settings.AdminUsername) end)
            if ok and policy.allowResolved(id) then
                warn("[Admin] " .. Settings.AdminUsername .. " resolved to UserId " .. id .. ". Pin this ID in ServerSettings.AdminUserIds to retain access after renaming.")
                for _, player in ipairs(Players:GetPlayers()) do mark(player) end
                return
            end
            if attempt < 3 then task.wait(attempt * 2) end
        end
        warn("[Admin] Owner lookup failed; no username-based privileges granted. Numeric AdminUserIds remain available.")
    end)
    command.OnServerEvent:Connect(function(actor, request)
        -- Player attributes and UI visibility are never permission checks.
        if not policy.isAdmin(actor.UserId) then return end
        local now = os.clock()
        if now - (limits[actor] or -math.huge) < 0.3 then return end
        limits[actor] = now
        local valid, problem = policy.validate(request)
        if not valid then status(actor, problem) return end
        local action = request.action
        if action == "roster" then roster(actor) return end
        local selfAction = action == "fly" or action == "pond" or action == "shop"
        local target = selfAction and actor or Players:GetPlayerByUserId(request.targetId)
        if not target then status(actor, "That player has left the server.") roster(actor) return end
        if target ~= actor and policy.isAdmin(target.UserId) and (action == "kick" or action == "freeze" or action == "respawn") then
            status(actor, "That action is protected for other admins.") return
        end
        local profile = context.profiles[target]
        if target:GetAttribute("Traveling") and action ~= "money" and action ~= "xp" and action ~= "kick" then
            status(actor, "That player's trail is loading. Try again in a moment.") return
        end
        if action == "money" or action == "xp" then
            if not profile or target:GetAttribute("ProfileReady") ~= true then status(actor, "That player's saved profile is not ready.") return end
            if action == "money" then
                if profile.coins + request.amount > Config.MaxCoins then status(actor, "That grant exceeds the player's coin limit.") return end
                profile.coins = profile.coins + request.amount
                context.notify(target, "An admin gave you " .. request.amount .. " coins.")
            else
                if profile.xp + request.amount > Progression.MaxXP then status(actor, "That grant exceeds the player's XP limit.") return end
                Progression.add(profile, request.amount)
                context.notify(target, "An admin gave you " .. request.amount .. " XP.")
            end
            context.pushProfile(target)
        elseif action == "kick" then
            if target == actor then status(actor, "Choose another player to kick.") return end
            local reason = type(request.reason) == "string" and request.reason:gsub("%c", " "):sub(1, 160) or "Removed by an administrator."
            if #reason < 1 then reason = "Removed by an administrator." end
            target:Kick(reason)
        else
            local root, humanoid = rootOf(target)
            if not root or not humanoid or humanoid.Health <= 0 then status(actor, "That character is not ready.") return end
            if action == "fly" then
                if flying[actor] then stopFlying(actor)
                else
                    context.cancel(actor, "escaped", "Cast cancelled for admin flight.")
                    unfreeze(actor)
                    local attachment = Instance.new("Attachment")
                    attachment.Name, attachment.Parent = "AdminFlightAttachment", root
                    local velocity = Instance.new("LinearVelocity")
                    velocity.Name, velocity.Attachment0, velocity.RelativeTo = "AdminFlightVelocity", attachment, Enum.ActuatorRelativeTo.World
                    velocity.MaxForce, velocity.VectorVelocity, velocity.Parent = 10000000, Vector3.zero, root
                    local orientation = Instance.new("AlignOrientation")
                    orientation.Name, orientation.Mode, orientation.Attachment0 = "AdminFlightOrientation", Enum.OrientationAlignmentMode.OneAttachment, attachment
                    orientation.MaxTorque, orientation.Responsiveness, orientation.Parent = 10000000, 20, root
                    orientation.CFrame = root.CFrame.Rotation
                    flying[actor] = { instances = { velocity, orientation, attachment }, humanoid = humanoid,
                        root = root, platformStand = humanoid.PlatformStand, autoRotate = humanoid.AutoRotate }
                    humanoid.PlatformStand, humanoid.AutoRotate = true, false
                    actor:SetAttribute("AdminFlySpeed", Settings.FlySpeed)
                    actor:SetAttribute("AdminFlying", true)
                end
            elseif action == "freeze" then
                context.cancel(target, "escaped", "An admin paused your movement.")
                stopFlying(target)
                if not frozen[target] then frozen[target] = { root = root, anchored = root.Anchored } end
                root.Anchored = true
                target:SetAttribute("AdminFrozen", true)
            elseif action == "unfreeze" then unfreeze(target)
            elseif action == "heal" then humanoid.Health = humanoid.MaxHealth
            elseif action == "respawn" then
                context.cancel(target, "escaped", "Respawning...")
                stopFlying(target) unfreeze(target)
                task.spawn(function()
                    local ok = pcall(function() target:LoadCharacterAsync() end)
                    if not ok and actor.Parent then status(actor, "The respawn could not finish. Try again.") end
                end)
            else
                local destination
                if action == "pond" then destination = CFrame.new(0, 6, -40)
                elseif action == "shop" then destination = CFrame.new(0, 4, -85)
                else
                    local actorRoot = rootOf(actor)
                    if not actorRoot then status(actor, "Your character is not ready.") return end
                    if action == "gotoPlayer" then destination, target, root = root.CFrame * CFrame.new(3, 0, 0), actor, actorRoot
                    elseif action == "bring" then destination = actorRoot.CFrame * CFrame.new(3, 0, 0) end
                end
                context.cancel(target, "escaped", "Cast cancelled for teleport.")
                root.CFrame, root.AssemblyLinearVelocity = destination, Vector3.zero
            end
        end
        warn(string.format("[Admin] actor=%d action=%s target=%d amount=%s", actor.UserId, action, target.UserId, tostring(request.amount or "-")))
        status(actor, "Done: " .. action .. " / " .. target.Name)
        roster(actor)
    end)
    return { stopFlying = stopFlying, isAdmin = policy.isAdmin }
end
return Admin
