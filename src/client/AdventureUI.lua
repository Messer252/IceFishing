local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Content = require(ReplicatedStorage.Shared.Content)
local Config = require(ReplicatedStorage.Shared.Config)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Preview = require(script.Parent.EquipmentPreview)
local Ui = require(script.Parent.Ui)
local Adventure = {}
function Adventure.start(gui, remotes, onOpen)
    local c, player = Ui.colors, Players.LocalPlayer
    local profile, active, sort, selected = nil, "Inventory", "Recent", nil
    local query, detailId = "", nil
    local mobile, panelWidth, panelHeight = false, 760, 590
    local lastViewport = Vector2.zero
    local command, event = remotes.Command, remotes.Event
    local function send(action, data) command:FireServer(action, data) end
    local shade = Ui.make("Frame", gui, { Name = "AdventureOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false, ZIndex = 6 })
    local panel = Ui.frame(shade, UDim2.fromOffset(760, 590), UDim2.fromScale(0.5, 0.5))
    panel.Name = "FieldKitPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    local scale = Ui.make("UIScale", panel, { Scale = 1 })
    local title = Ui.text(panel, "ANGLER'S FIELD KIT", UDim2.new(1, -90, 0, 32), UDim2.fromOffset(20, 16), 23, c.gold)
    title.Font = Enum.Font.GothamBold
    local subtitle = Ui.text(panel, "", UDim2.new(1, -40, 0, 26), UDim2.fromOffset(20, 52), 13, c.muted)
    Ui.button(panel, "X", UDim2.fromOffset(36, 34), UDim2.new(1, -56, 0, 16), function() shade.Visible = false end, c.gold)
    local render
    local tabs = Ui.make("ScrollingFrame", panel, { Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 86), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(840, 0), ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.X })
    for i, name in ipairs({ "Inventory", "Gear", "Journal", "Quests", "Map", "Settings", "Guide" }) do
        Ui.button(tabs, name, UDim2.fromOffset(112, 32), UDim2.fromOffset((i - 1) * 120, 0), function() active, detailId = name, nil if render then render() end end)
    end
    local search = Ui.make("TextBox", panel, { Text = "", PlaceholderText = "Search fish species...", Size = UDim2.fromOffset(450, 30), Position = UDim2.fromOffset(20, 134), ClearTextOnFocus = false,
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = c.text, BackgroundColor3 = c.card, BorderSizePixel = 0 })
    Ui.round(search)
    local sorts = { "Recent", "Rarity", "Weight", "Value" }
    local sortButton
    sortButton = Ui.button(panel, "Sort: Recent", UDim2.fromOffset(250, 30), UDim2.fromOffset(490, 134), function()
        local index = table.find(sorts, sort) or 1
        sort = sorts[index % #sorts + 1] sortButton.Text = "Sort: " .. sort render()
    end, c.gold)
    local list = Ui.make("ScrollingFrame", panel, { Size = UDim2.fromOffset(720, 355), Position = UDim2.fromOffset(20, 176), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5 })
    Ui.make("UIListLayout", list, { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder })
    Ui.make("UIPadding", list, { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
    local footer = Ui.text(panel, "", UDim2.fromOffset(500, 35), UDim2.fromOffset(20, 543), 12, c.muted)
    local sell = Ui.button(panel, "SELL UNPROTECTED", UDim2.fromOffset(200, 34), UDim2.fromOffset(540, 541), function() send("sell") end, c.gold)
    local inspect = Ui.frame(panel, UDim2.new(1, -30, 1, -30), UDim2.fromOffset(15, 15))
    inspect.Visible = false
    Ui.button(inspect, "BACK", UDim2.fromOffset(90, 32), UDim2.new(1, -110, 0, 14), function() inspect.Visible = false end, c.gold)
    local info = Ui.text(inspect, "", UDim2.new(1, -40, 0, 120), UDim2.new(0, 20, 1, -145), 15)
    local function showFish(fish, silhouette)
        local old = inspect:FindFirstChild("FishPreview") if old then old:Destroy() end
        local view = Ui.make("ViewportFrame", inspect, { Name = "FishPreview", Size = UDim2.new(1, -40, 1, -230), Position = UDim2.fromOffset(20, 65), BackgroundColor3 = c.dark, BorderSizePixel = 0 })
        Ui.round(view) Preview.fish(view, fish.species or fish.id, fish.color, silhouette)
        info.Text = silhouette and "An undiscovered species. Explore its lake and experiment with equipment." or
            (fish.name .. "\n" .. (fish.variant or "Normal") .. " / " .. fish.rarity .. " / " .. tostring(fish.kg or fish.biggest or 0) .. " kg\n" ..
            (fish.value and (fish.value .. " coins / " .. (fish.location or Config.Region) .. "\nCaught " .. os.date("!%Y-%m-%d %H:%M UTC", fish.caughtAt or 0)) or
            ("Preferred bait: " .. Config.gearName("bait", fish.preferredBait) .. " / " .. (fish.regionOnly and Content.region(fish.regionOnly).name or "Multiple lakes") .. "\nMore active: " .. (fish.preferredTime or "Day") .. " / " .. Content.weather(fish.preferredWeather).name)))
        inspect.Visible = true
    end
    local function card(height)
        local row = Ui.frame(list, UDim2.new(1, 0, 0, mobile and math.max(height, 154) or height), UDim2.fromOffset(0, 0), c.card)
        return row
    end
    local function preview(row, species, color, hidden)
        local view = Ui.make("ViewportFrame", row, { Size = UDim2.fromOffset(mobile and 76 or 92, 76), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = c.dark, BorderSizePixel = 0 })
        Ui.round(view) Preview.fish(view, species, color, hidden)
    end
    render = function()
        if not profile then return end
        inspect.Visible = false
        local position = list.CanvasPosition
        for _, item in ipairs(list:GetChildren()) do if item:IsA("Frame") or item:IsA("TextLabel") then item:Destroy() end end
        local inventory = active == "Inventory"
        search.Visible, sortButton.Visible, sell.Visible = inventory, inventory, inventory
        list.Position = UDim2.fromOffset(20, inventory and 176 or 134)
        list.Size = UDim2.new(1, -40, 0, panelHeight - (inventory and (mobile and 280 or 235) or 193))
        footer.Size = UDim2.new(1, mobile and -40 or -240, 0, mobile and 42 or 35)
        footer.Position = UDim2.new(0, 20, 1, mobile and (inventory and -96 or -53) or -47)
        sell.Size, sell.Position = UDim2.new(mobile and 1 or 0, mobile and -40 or 200, 0, 34), UDim2.new(mobile and 0 or 1, mobile and 20 or -220, 1, -46)
        search.Size = UDim2.new(0.6, -28, 0, 30)
        sortButton.Size, sortButton.Position = UDim2.new(0.4, -22, 0, 30), UDim2.new(0.6, 10, 0, 134)
        subtitle.Text = active .. " / Level " .. profile.level .. " / " .. profile.coins .. " coins"
        footer.Text = ""
        if inventory then
            local fishes = Inventory.query(profile.bag, query, sort)
            footer.Text = #profile.bag .. "/100 catches. Favorites and locks protect fish from sales."
            if #fishes == 0 then Ui.text(list, "No matching catches. Your next story is under the ice.", UDim2.new(1, 0, 0, 70), UDim2.fromOffset(0, 0), 17, c.muted) end
            for i, fish in ipairs(fishes) do
                local row = card(126) row.LayoutOrder = i
                preview(row, fish.species, fish.color)
                Ui.text(row, fish.name .. (fish.trophy and " / TROPHY" or ""), UDim2.new(1, mobile and -108 or -130, 0, mobile and 38 or 26), UDim2.fromOffset(mobile and 96 or 112, 8), 17).Font = Enum.Font.GothamBold
                Ui.text(row, (fish.variant or "Normal") .. " / " .. fish.rarity .. " / " .. fish.kg .. " kg / " .. fish.value .. " coins", UDim2.new(1, mobile and -108 or -130, 0, mobile and 54 or 24), UDim2.fromOffset(mobile and 96 or 112, mobile and 50 or 37), 13, c.muted)
                Ui.button(row, "INSPECT", UDim2.fromOffset(mobile and 66 or 92, mobile and 30 or 26), UDim2.fromOffset(8, mobile and 112 or 91), function() showFish(fish) end, c.gold)
                Ui.button(row, fish.favorite and "UNFAVORITE" or "FAVORITE", UDim2.fromOffset(mobile and 76 or 130, 30), UDim2.fromOffset(mobile and 80 or 112, mobile and 112 or 80), function() send("fishFlag", { id = fish.catchId, key = "favorite", value = not fish.favorite }) end, fish.favorite and c.gold or c.mint)
                Ui.button(row, fish.locked and "UNLOCK" or "LOCK", UDim2.fromOffset(mobile and 60 or 110, 30), UDim2.fromOffset(mobile and 162 or 255, mobile and 112 or 80), function() send("fishFlag", { id = fish.catchId, key = "locked", value = not fish.locked }) end)
                Ui.button(row, "SELL ONE", UDim2.fromOffset(mobile and 70 or 130, 30), UDim2.new(mobile and 1 or 0, mobile and -78 or 380, 0, mobile and 112 or 80), function() send("sellOne", { id = fish.catchId }) end, c.gold)
            end
        elseif active == "Gear" then
            footer.Text = "Equip owned items here. Shop for upgrades at the cabin. Finish a cast before changing gear."
            local order = 0
            for _, category in ipairs({ "auger", "rod", "bait", "lure" }) do
                for _, item in ipairs(Config.Gear[category]) do
                    local owned = category == "bait" and (item.amount == 0 or (profile.bait[item.id] or 0) > 0) or category ~= "bait" and profile.owned[category][item.id]
                    if owned then
                        order = order + 1 local row = card(112) row.LayoutOrder = order
                        local view = Ui.make("ViewportFrame", row, { Size = UDim2.fromOffset(76, 88), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = c.dark, BorderSizePixel = 0 })
                        Ui.round(view) Preview.mount(view, category, item.id)
                        Ui.text(row, item.name, UDim2.new(1, -110, 0, mobile and 42 or 30), UDim2.fromOffset(96, 8), 16)
                        Ui.text(row, Config.gearStats(category, item), UDim2.new(1, mobile and -110 or -270, 0, 54), UDim2.fromOffset(96, mobile and 48 or 40), 11, c.muted)
                        Ui.button(row, profile.equipped[category] == item.id and "EQUIPPED" or "EQUIP", UDim2.fromOffset(130, 30), UDim2.new(1, -145, 0, mobile and 112 or 65), function()
                            send("equip", { category = category, id = item.id })
                        end, profile.equipped[category] == item.id and c.gold or c.mint)
                    end
                end
            end
        elseif active == "Journal" then
            local discovered = 0 for _, found in pairs(profile.discoveries) do if found then discovered = discovered + 1 end end
            footer.Text = discovered .. "/" .. #Config.Fish .. " species / " .. math.floor(discovered / #Config.Fish * 100) .. "% discovered. Milestones reward coins and XP."
            for i, species in ipairs(Config.Fish) do
                local found, record = profile.discoveries[species.id], profile.collection[species.id]
                local row = card(102) row.LayoutOrder = i
                preview(row, species.id, species.color, not found)
                Ui.text(row, found and species.name or "??? / Undiscovered", UDim2.new(1, mobile and -108 or -260, 0, mobile and 40 or 28), UDim2.fromOffset(mobile and 96 or 112, 9), 17, found and c.text or c.muted)
                local variants = {} if record then for variant, seen in pairs(record.variants) do if seen then table.insert(variants, variant) end end table.sort(variants) end
                Ui.text(row, found and ("Caught " .. (record and record.count or 1) .. " / Best " .. (record and record.biggest or 0) .. " kg\nVariants: " .. table.concat(variants, ", ")) or "Explore the lakes and try different bait.", UDim2.new(1, mobile and -108 or -260, 0, mobile and 85 or 46), UDim2.fromOffset(mobile and 96 or 112, mobile and 54 or 40), 12, c.muted)
                Ui.button(row, "VIEW", UDim2.fromOffset(76, 30), mobile and UDim2.fromOffset(8, 104) or UDim2.new(1, -95, 0, 35), function() showFish(species, not found) end, c.gold)
            end
        elseif active == "Quests" then
            footer.Text = "Accept before fishing. Claim earned rewards here; saved progress survives rejoining."
            for i, definition in ipairs(Content.Quests) do
                local state = profile.quests[definition.id]
                local row = card(118) row.LayoutOrder = i
                Ui.text(row, definition.title, UDim2.new(1, mobile and -28 or -210, 0, mobile and 38 or 28), UDim2.fromOffset(14, 8), 18, c.gold)
                Ui.text(row, definition.description .. "\n" .. definition.coins .. " coins / " .. definition.xp .. " XP / Level " .. definition.level, UDim2.new(1, mobile and -28 or -210, 0, mobile and 50 or 48), UDim2.fromOffset(14, mobile and 49 or 39), 13, c.muted)
                local label = not state and "ACCEPT" or (state.claimed and (definition.repeatSeconds and "REPEAT" or "COMPLETED") or (state.progress >= definition.goal and "CLAIM" or (state.progress .. "/" .. definition.goal)))
                if state and ((state.claimed and not definition.repeatSeconds) or (not state.claimed and state.progress < definition.goal)) then
                    local status = Ui.text(row, label, UDim2.fromOffset(150, 36), UDim2.new(1, -165, 0, mobile and 108 or 39), 14, c.gold)
                    status.TextXAlignment = Enum.TextXAlignment.Center
                else
                    Ui.button(row, label, UDim2.fromOffset(150, 36), UDim2.new(1, -165, 0, mobile and 108 or 39), function()
                        send("quest", { id = definition.id, mode = state and not state.claimed and "claim" or "accept" })
                    end, state and state.progress >= definition.goal and c.gold or c.mint)
                end
            end
        elseif active == "Map" then
            footer.Text = "Use a trail board near a lake entrance. Unlocks are permanent; return trips are free."
            for i, region in ipairs(Content.Regions) do
                local row = card(104) row.LayoutOrder = i
                Ui.text(row, region.name, UDim2.new(1, mobile and -28 or -210, 0, 30), UDim2.fromOffset(14, 8), 19, c.gold)
                Ui.text(row, "Level " .. region.level .. " / " .. (profile.unlockedRegions[region.id] and "Trail unlocked" or (region.price .. " coins to unlock")) .. "\nRegional luck +" .. region.luck .. (i > 1 and " / Unique regional species" or " / Beginner-friendly ice"), UDim2.new(1, mobile and -28 or -210, 0, 56), UDim2.fromOffset(14, 43), 13, c.muted)
                Ui.button(row, profile.unlockedRegions[region.id] and "TRAVEL" or "UNLOCK & TRAVEL", UDim2.fromOffset(165, 38), UDim2.new(1, -180, 0, mobile and 109 or 34), function() send("travel", { id = region.id }) end)
            end
        elseif active == "Settings" then
            footer.Text = "Settings save with your profile. Reduced effects helps smaller devices."
            for i, key in ipairs({ "musicVolume", "sfxVolume", "reducedEffects", "highContrast" }) do
                local names = { musicVolume = "Music & ambience", sfxVolume = "Sound effects", reducedEffects = "Reduced effects", highContrast = "High contrast menus" }
                local row = card(82) row.LayoutOrder = i
                local value = profile.settings[key]
                Ui.text(row, names[key], UDim2.new(1, -28, 0, 30), UDim2.fromOffset(14, 10), 17)
                if type(value) == "boolean" then
                    Ui.button(row, value and "ON" or "OFF", UDim2.fromOffset(150, 34), UDim2.new(1, -170, 0, mobile and 60 or 24), function() send("setting", { key = key, value = not value }) end, value and c.gold or c.mint)
                else
                    Ui.text(row, math.floor(value * 100) .. "%", UDim2.fromOffset(100, 30), UDim2.new(1, -210, 0, mobile and 60 or 24), 16)
                    Ui.button(row, "-", UDim2.fromOffset(55, 34), UDim2.new(1, -300, 0, mobile and 60 or 24), function() send("setting", { key = key, value = math.max(0, math.floor(value * 10 - 1) / 10) }) end)
                    Ui.button(row, "+", UDim2.fromOffset(55, 34), UDim2.new(1, -80, 0, mobile and 60 or 24), function() send("setting", { key = key, value = math.min(1, math.floor(value * 10 + 1) / 10) }) end)
                end
            end
        else
            local step = profile.tutorial.step
            footer.Text = profile.tutorial.completed and "Guide completed. These instructions remain available." or ("Current step " .. step .. " of " .. #Content.Tutorial .. " / Talk to Nolan at the outpost.")
            for i, instruction in ipairs(Content.Tutorial) do
                local row = card(100) row.LayoutOrder = i
                Ui.text(row, i .. " / " .. instruction.title .. (i < step and " / DONE" or ""), UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 8), 18, i == step and c.gold or c.text)
                Ui.text(row, instruction.description, UDim2.new(1, -28, 0, mobile and 94 or 52), UDim2.fromOffset(14, 43), 13, c.muted)
            end
            if not profile.tutorial.completed then
                local row = card(48)
                row.LayoutOrder = 100
                Ui.button(row, "SKIP TUTORIAL", UDim2.fromOffset(200, 32), UDim2.fromOffset(14, 8), function() send("tutorial", { skip = true }) end, c.gold)
            end
        end
        list.CanvasPosition = position
    end
    search:GetPropertyChangedSignal("Text"):Connect(function() query = search.Text if shade.Visible and active == "Inventory" then render() end end)
    local api = {}
    function api.open(name)
        if not profile then return end
        active, detailId = name or "Inventory", nil
        onOpen() shade.Visible = true render()
        panel.Position = UDim2.fromScale(0.5, 0.53)
        TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
    end
    function api.close() shade.Visible = false end
    local catchCard = Ui.frame(gui, UDim2.fromOffset(420, 204), UDim2.new(0.5, -210, 0.2, 0))
    catchCard.Visible, catchCard.ZIndex = false, 4
    local catchScale = Ui.make("UIScale", catchCard, { Scale = 1 })
    local catchText = Ui.text(catchCard, "", UDim2.fromOffset(260, 152), UDim2.fromOffset(148, 26), 16)
    Ui.button(catchCard, "X", UDim2.fromOffset(30, 26), UDim2.new(1, -38, 0, 6), function() catchCard.Visible = false end, c.gold)
    local serial = 0
    event.OnClientEvent:Connect(function(kind, data)
        if kind == "profile" then
            profile = data
            c.text = data.settings.highContrast and Color3.new(1, 1, 1) or Color3.fromRGB(232, 245, 249)
            c.muted = data.settings.highContrast and Color3.fromRGB(233, 233, 233) or Color3.fromRGB(170, 198, 211)
            if shade.Visible then render() end
        elseif kind == "openContent" then api.open(data)
        elseif kind == "stage" then api.close() catchCard.Visible = false
        elseif kind == "caught" then
            serial = serial + 1 local current = serial
            local old = catchCard:FindFirstChild("CatchPreview") if old then old:Destroy() end
            local view = Ui.make("ViewportFrame", catchCard, { Name = "CatchPreview", Size = UDim2.fromOffset(132, 176), Position = UDim2.fromOffset(8, 14), BackgroundTransparency = 1 })
            Preview.fish(view, data.species, data.color)
            catchText.Text = data.name .. "\n" .. data.variant .. " / " .. data.rarity .. "\n" .. data.kg .. " kg / " .. data.value .. " coins\n+" .. data.xp .. " XP" .. (data.discovery and " / NEW" or "") .. (data.trophy and "\nTROPHY CATCH" or "")
            catchCard.Visible = true
            task.delay(data.rarity == "Legendary" and 7 or 5, function() if current == serial then catchCard.Visible = false end end)
        end
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or UserInputService:GetFocusedTextBox() then return end
        local keys = { [Enum.KeyCode.J] = "Journal", [Enum.KeyCode.K] = "Quests", [Enum.KeyCode.M] = "Map", [Enum.KeyCode.O] = "Settings", [Enum.KeyCode.H] = "Guide" }
        if keys[input.KeyCode] then api.open(keys[input.KeyCode]) end
    end)
    RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if camera then
            if camera.ViewportSize ~= lastViewport then
                lastViewport = camera.ViewportSize
                mobile = lastViewport.X < 650
                panelWidth, panelHeight = math.min(760, lastViewport.X - 20), math.min(590, lastViewport.Y - 60)
                panel.Size, scale.Scale = UDim2.fromOffset(panelWidth, panelHeight), 1
                info.Size, info.Position = UDim2.new(1, -40, 0, 120), UDim2.new(0, 20, 1, -145)
                local view = inspect:FindFirstChild("FishPreview")
                if view then view.Size = UDim2.new(1, -40, 1, -240) end
                if profile and shade.Visible then render() end
            end
            catchScale.Scale = math.min(1, (camera.ViewportSize.X - 20) / 420)
            catchCard.AnchorPoint, catchCard.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0.18, 0)
        end
    end)
    return api
end
return Adventure
