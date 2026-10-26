local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Reel = require(ReplicatedStorage.Shared:WaitForChild("Reel"))
local Progression = require(ReplicatedStorage.Shared:WaitForChild("Progression"))
local Content = require(ReplicatedStorage.Shared:WaitForChild("Content"))
local InputHints = require(script.Parent:WaitForChild("InputHints"))
local Inventory = require(ReplicatedStorage.Shared:WaitForChild("Inventory"))
local Preview = require(script.Parent:WaitForChild("EquipmentPreview"))
require(script.Parent:WaitForChild("AnglerAnimation")).start()
local remotes = ReplicatedStorage:WaitForChild("FishingRemotes")
local command, event = remotes:WaitForChild("Command"), remotes:WaitForChild("Event")
local C = {
    panel = Color3.fromRGB(20, 41, 54), card = Color3.fromRGB(32, 57, 71),
    text = Color3.fromRGB(232, 245, 249), muted = Color3.fromRGB(167, 196, 208),
    mint = Color3.fromRGB(131, 230, 201), gold = Color3.fromRGB(255, 213, 136),
    red = Color3.fromRGB(248, 134, 137), dark = Color3.fromRGB(16, 33, 44),
}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "FrostbiteUI", false, Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function make(class, parent, props)
    local object = Instance.new(class)
    for k, v in pairs(props or {}) do object[k] = v end
    object.Parent = parent
    return object
end
local function rounded(object, radius)
    make("UICorner", object, { CornerRadius = UDim.new(0, radius or 12) })
end
local function frame(parent, size, position, color)
    local f = make("Frame", parent, { Size = size, Position = position, BackgroundColor3 = color or C.panel, BorderSizePixel = 0 })
    rounded(f)
    return f
end
local function text(parent, value, size, position, fontSize, color)
    return make("TextLabel", parent, { Text = value, Size = size, Position = position,
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = fontSize or 15,
        TextColor3 = color or C.text, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true })
end
local function button(parent, value, size, position, callback, color)
    local b = make("TextButton", parent, { Text = value, Size = size, Position = position,
        BackgroundColor3 = color or C.mint, TextColor3 = C.dark, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = true })
    rounded(b, 9)
    if callback then b.Activated:Connect(callback) end
    return b
end
local function send(action, data) command:FireServer(action, data) end
local profile, activeTab, modalMode = nil, "auger", "shop"
local shopMobile = false
local fishing, token, held = false, nil, false
local reelView, jumpLock = nil, nil
local drillingInfo, hookingInfo = nil, nil
local adventure
local keyHeld, reelPointer = false, nil

local brand = frame(gui, UDim2.fromOffset(252, 76), UDim2.fromOffset(16, 16))
text(brand, "Hooked!", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 20, C.mint).Font = Enum.Font.GothamBold
text(brand, "ICE FISHING  /  FROZEN WILDERNESS", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 43), 10, C.muted)
local wallet = frame(gui, UDim2.fromOffset(190, 138), UDim2.new(1, -206, 0, 16))
local coins = text(wallet, "120 coins", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 9), 21, C.gold)
coins.Font = Enum.Font.GothamBold
local bagCount = text(wallet, "Loading your profile...", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 43), 13, C.muted)
local levelLabel = text(wallet, "Level 1", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 68), 11, C.mint)
local xpTrack = frame(wallet, UDim2.new(1, -24, 0, 7), UDim2.fromOffset(12, 94), C.dark)
local xpFill = frame(xpTrack, UDim2.fromScale(0, 1), UDim2.fromOffset(0, 0), C.mint)
local dataMode = text(wallet, "Loading saved progress...", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 106), 10, C.muted)
player:GetAttributeChangedSignal("DataMode"):Connect(function() dataMode.Text = player:GetAttribute("DataMode") or "Loading saved progress..." end)
local guide = frame(gui, UDim2.fromOffset(246, 167), UDim2.fromOffset(16, 108))
text(guide, "A QUIET DAY ON THE ICE", UDim2.fromOffset(218, 26), UDim2.fromOffset(14, 10), 12, C.gold).Font = Enum.Font.GothamBold
text(guide, "01  Walk onto the frozen pond\n02  Drill once, reuse your hole\n03  Hook the bite, then track the fish\n04  Sell fish at the cabin for gear", UDim2.fromOffset(218, 110), UDim2.fromOffset(14, 43), 14, C.muted)

local dock = frame(gui, UDim2.fromOffset(468, 166), UDim2.new(0.5, -234, 1, -106))
local castButton = button(dock, "DRILL / CAST  [F]", UDim2.fromOffset(282, 42), UDim2.fromOffset(12, 10), function() send(fishing and "cancel" or "cast") end)
local openBag
local bagButton = button(dock, "BAG  [I]", UDim2.fromOffset(152, 42), UDim2.fromOffset(304, 10), function() if openBag then openBag() end end, Color3.fromRGB(191, 218, 232))
local drillButton = button(dock, "NEW HOLE  [G]  /  replaces your previous hole", UDim2.new(1, -24, 0, 27), UDim2.fromOffset(12, 59), function()
    if not fishing then send("drill") end
end, Color3.fromRGB(191, 218, 232))
for i, page in ipairs({ "Journal", "Quests", "Map", "Settings" }) do
    button(dock, page:upper(), UDim2.fromOffset(103, 29), UDim2.fromOffset(12 + (i - 1) * 113, 94), function()
        if adventure then adventure.open(page) end
    end, Color3.fromRGB(191, 218, 232))
end
local area = frame(gui, UDim2.fromOffset(230, 55), UDim2.new(0.5, -115, 0, 16))
local areaText = text(area, "Frostbite Pond", UDim2.new(1, -20, 1, -12), UDim2.fromOffset(10, 6), 12, C.muted)
areaText.TextXAlignment = Enum.TextXAlignment.Center
local loadout = text(dock, "Walk onto the ice to begin", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 136), 11, C.muted)
loadout.TextXAlignment = Enum.TextXAlignment.Center

local toast = frame(gui, UDim2.new(0.8, 0, 0, 72), UDim2.new(0.1, 0, 0, 104))
toast.Visible = false
make("UISizeConstraint", toast, { MaxSize = Vector2.new(580, 90) })
toast.AnchorPoint, toast.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 104)
local toastText = text(toast, "", UDim2.new(1, -28, 1, -16), UDim2.fromOffset(14, 8), 16)
toastText.TextXAlignment = Enum.TextXAlignment.Center
local toastId = 0
local function notice(message, color)
    toastId = toastId + 1
    local id = toastId
    toastText.Text, toastText.TextColor3, toast.Visible = message, color or C.text, true
    task.delay(4.5, function() if toastId == id then toast.Visible = false end end)
end

local shade = make("TextButton", gui, { Text = "", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, BorderSizePixel = 0, Visible = false, AutoButtonColor = false })
local modal = frame(shade, UDim2.fromOffset(650, 530), UDim2.fromScale(0.5, 0.5))
modal.AnchorPoint = Vector2.new(0.5, 0.5)
local modalScale = make("UIScale", modal, { Scale = 1 })
local modalTitle = text(modal, "HOOKED! TACKLE", UDim2.new(1, -90, 0, 34), UDim2.fromOffset(22, 16), 23, C.gold)
modalTitle.Font = Enum.Font.GothamBold
local modalSubtitle = text(modal, "Better gear. Bigger holes. Rarer fish.", UDim2.new(1, -44, 0, 24), UDim2.fromOffset(22, 52), 14, C.muted)
button(modal, "X", UDim2.fromOffset(36, 36), UDim2.new(1, -54, 0, 18), function() shade.Visible = false end, Color3.fromRGB(181, 203, 213))
local tabs = frame(modal, UDim2.new(1, -44, 0, 40), UDim2.fromOffset(22, 88), C.dark)
local list = make("ScrollingFrame", modal, { Size = UDim2.new(1, -44, 1, -208), Position = UDim2.fromOffset(22, 140), BackgroundTransparency = 1,
    BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = C.muted })
make("UIListLayout", list, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
make("UIPadding", list, { PaddingBottom = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) })
local sell = button(modal, "SELL ALL FISH", UDim2.new(1, -44, 0, 40), UDim2.new(0, 22, 1, -54), function() send("sell") end, C.gold)
local tabButtons, render = {}, nil
for i, category in ipairs({ "auger", "rod", "bait", "lure" }) do
    tabButtons[category] = button(tabs, string.upper(category) .. "S", UDim2.new(0.25, -6, 1, -8), UDim2.new((i - 1) * 0.25, 3, 0, 4), function()
        activeTab = category
        if render then render() end
    end, C.card)
end

local inspection = frame(modal, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), C.panel)
inspection.Visible = false
local inspectTitle = text(inspection, "EQUIPMENT", UDim2.new(1, -140, 0, 38), UDim2.fromOffset(22, 18), 22, C.gold)
inspectTitle.Font = Enum.Font.GothamBold
button(inspection, "BACK", UDim2.fromOffset(90, 34), UDim2.new(1, -112, 0, 18), function() inspection.Visible = false end, C.gold)
local inspectDescription = text(inspection, "", UDim2.new(1, -44, 0, 45), UDim2.new(0, 22, 1, -95), 15, C.muted)
text(inspection, "Drag to rotate  /  Scroll to zoom", UDim2.new(1, -44, 0, 24), UDim2.new(0, 22, 1, -36), 12, C.mint).TextXAlignment = Enum.TextXAlignment.Center
local function inspect(category, item)
    local old = inspection:FindFirstChild("EquipmentView")
    if old then old:Destroy() end
    inspectTitle.Text, inspectDescription.Text = item.name, item.description
    local viewport = make("ViewportFrame", inspection, { Name = "EquipmentView", Size = UDim2.new(1, -44, 1, -180), Position = UDim2.fromOffset(22, 68),
        BackgroundColor3 = C.dark, BorderSizePixel = 0 })
    rounded(viewport)
    Preview.mount(viewport, category, item.id)
    inspection.Visible = true
end

local function bagValue(sellable)
    local sum = 0
    if profile then for _, fish in ipairs(profile.bag) do if not sellable or not Inventory.protected(fish) then sum = sum + fish.value end end end
    return sum
end

render = function()
    for _, child in ipairs(list:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
    if not profile then return end
    inspection.Visible = false
    local isShop = modalMode == "shop"
    tabs.Visible = isShop
    modalTitle.Text = isShop and "HOOKED! TACKLE" or "YOUR FISH BAG"
    modalSubtitle.Text = isShop and ("Balance: " .. profile.coins .. " coins  /  Purchases auto-equip") or "Bring your catch to the cabin to sell it."
    list.Position = UDim2.fromOffset(22, isShop and 140 or 90)
    list.Size = UDim2.new(1, -44, 1, isShop and -208 or -158)
    sell.Text = "SELL UNPROTECTED  /  " .. bagValue(true) .. " COINS"
    for category, b in pairs(tabButtons) do
        b.BackgroundColor3 = category == activeTab and C.mint or C.card
        b.TextColor3 = category == activeTab and C.dark or C.muted
    end
    if isShop then
        for i, item in ipairs(Config.Gear[activeTab]) do
            local category = activeTab
            local card = frame(list, UDim2.new(1, 0, 0, shopMobile and 206 or 124), UDim2.fromOffset(0, 0), C.card)
            card.LayoutOrder = i
            local viewport = make("ViewportFrame", card, { Size = UDim2.fromOffset(88, 86), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = C.dark, BorderSizePixel = 0 })
            rounded(viewport, 8)
            Preview.mount(viewport, category, item.id)
            button(card, "3D VIEW", UDim2.fromOffset(88, 22), UDim2.fromOffset(8, 97), function() inspect(category, item) end, C.gold)
            text(card, item.name, UDim2.new(1, shopMobile and -126 or -270, 0, shopMobile and 42 or 28), UDim2.fromOffset(110, 8), 16).Font = Enum.Font.GothamBold
            text(card, item.description, UDim2.new(1, shopMobile and -126 or -276, 0, shopMobile and 66 or 40), UDim2.fromOffset(110, shopMobile and 54 or 38), 12, C.muted)
            text(card, Config.gearStats(category, item), UDim2.new(1, shopMobile and -28 or -276, 0, 37), UDim2.fromOffset(shopMobile and 14 or 110, shopMobile and 128 or 82), 10, C.mint)
            local equipped = profile.equipped[category] == item.id
            local owned = category ~= "bait" and profile.owned[category][item.id]
            local stock = category == "bait" and (profile.bait[item.id] or 0) or 0
            local hasBait = category == "bait" and (item.amount == 0 or stock > 0)
            local caption = equipped and "EQUIPPED" or ((owned or hasBait) and "EQUIP" or (item.cost .. " COINS"))
            local locked = not owned and (profile.level or 1) < (item.requiredLevel or 1)
            if locked then caption = "LEVEL " .. item.requiredLevel end
            if category == "bait" and equipped and item.amount > 0 then caption = "+10 / " .. item.cost .. " COINS" end
            button(card, caption, UDim2.fromOffset(136, 36), UDim2.new(1, -150, 0, shopMobile and 166 or 22), function()
                send("buy", { category = category, id = item.id, equip = hasBait and not equipped })
            end, equipped and C.gold or C.mint)
            if category == "bait" then
                text(card, item.amount == 0 and "Unlimited" or (stock .. " casts left"), UDim2.fromOffset(136, 22), shopMobile and UDim2.fromOffset(12, 170) or UDim2.new(1, -150, 0, 63), 12, C.muted).TextXAlignment = Enum.TextXAlignment.Center
            end
        end
    else
        if #profile.bag == 0 then text(list, "Your next great catch is under the ice.", UDim2.new(1, 0, 0, 90), UDim2.fromOffset(0, 0), 18, C.muted) end
        for i = #profile.bag, 1, -1 do
            local fish = profile.bag[i]
            local card = frame(list, UDim2.new(1, 0, 0, 72), UDim2.fromOffset(0, 0), C.card)
            card.LayoutOrder = #profile.bag - i
            text(card, fish.name, UDim2.new(1, -150, 0, 30), UDim2.fromOffset(14, 7), 17, Color3.fromRGB(fish.color[1], fish.color[2], fish.color[3])).Font = Enum.Font.GothamBold
            text(card, fish.rarity .. "  /  " .. fish.kg .. " kg", UDim2.new(1, -150, 0, 23), UDim2.fromOffset(14, 39), 13, C.muted)
            text(card, fish.value .. " coins", UDim2.fromOffset(120, 40), UDim2.new(1, -132, 0, 16), 17, C.gold).TextXAlignment = Enum.TextXAlignment.Right
        end
    end
    list.CanvasPosition = Vector2.zero
end

adventure = require(script.Parent:WaitForChild("AdventureUI")).start(gui, remotes, function() shade.Visible = false end)
openBag = function() adventure.open("Inventory") end

local reel = frame(gui, UDim2.fromOffset(490, 218), UDim2.new(0.5, -245, 1, -338))
reel.Visible = false
local reelTitle = text(reel, "WAITING FOR A BITE...", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 17, C.gold)
reelTitle.Font, reelTitle.TextXAlignment = Enum.Font.GothamBold, Enum.TextXAlignment.Center
local track = frame(reel, UDim2.new(1, -44, 0, 40), UDim2.fromOffset(22, 48), C.dark)
track.ClipsDescendants = true
local zone = frame(track, UDim2.fromScale(0.23, 1), UDim2.fromScale(0.5, 0), C.mint)
zone.BackgroundTransparency, zone.AnchorPoint = 0.3, Vector2.new(0.5, 0)
local marker = frame(track, UDim2.new(0, 6, 1, -8), UDim2.new(0.5, 0, 0, 4), C.gold)
marker.AnchorPoint = Vector2.new(0.5, 0)
local caption = text(reel, "Keep the gold fish marker inside your green zone", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 92), 12, C.muted)
caption.TextXAlignment = Enum.TextXAlignment.Center
local progressBack = frame(reel, UDim2.new(0.64, -20, 0, 8), UDim2.fromOffset(22, 123), C.dark)
local progressFill = frame(progressBack, UDim2.fromScale(0.25, 1), UDim2.fromOffset(0, 0), C.mint)
local tensionBack = frame(reel, UDim2.new(0.3, 0, 0, 8), UDim2.new(0.66, 0, 0, 123), C.dark)
local tensionFill = frame(tensionBack, UDim2.fromScale(0, 1), UDim2.fromOffset(0, 0), C.red)
local progressLabel = text(reel, "CATCH PROGRESS", UDim2.fromOffset(180, 20), UDim2.fromOffset(22, 134), 10, C.muted)
local tensionLabel = text(reel, "LINE TENSION", UDim2.fromOffset(140, 20), UDim2.new(0.66, 0, 0, 134), 10, C.red)
local holdButton = button(reel, InputHints.hold(), UDim2.new(1, -44, 0, 43), UDim2.fromOffset(22, 162), nil)

local function refreshInputHints()
    castButton.Text, bagButton.Text, drillButton.Text = InputHints.cast(fishing), InputHints.bag(), InputHints.drill()
    holdButton.Text = hookingInfo and InputHints.hook() or InputHints.hold()
    if hookingInfo then caption.Text = InputHints.hookHelp() end
end
UserInputService.LastInputTypeChanged:Connect(refreshInputHints)
refreshInputHints()

local function updateHeld()
    held = keyHeld or reelPointer ~= nil
    if token then send("input", { token = token, held = held }) end
end
local function lockJump()
    if jumpLock then return end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        jumpLock = { humanoid = humanoid, enabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) }
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        humanoid.Jump = false
    end
    ContextActionService:BindActionAtPriority("FrostbiteReel", function(_, state)
        keyHeld = state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox()
        updateHeld()
        return Enum.ContextActionResult.Sink
    end, false, Enum.ContextActionPriority.High.Value + 100, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end
local function releaseJump()
    ContextActionService:UnbindAction("FrostbiteReel")
    if jumpLock and jumpLock.humanoid.Parent then
        jumpLock.humanoid.Jump = false
        jumpLock.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpLock.enabled)
    end
    jumpLock = nil
end
holdButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        reelPointer = input
        updateHeld()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input == reelPointer or (reelPointer and input.UserInputType == Enum.UserInputType.MouseButton1) then reelPointer = nil updateHeld() end
end)
UserInputService.WindowFocusReleased:Connect(function() keyHeld, reelPointer = false, nil updateHeld() end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.F then send(fishing and "cancel" or "cast")
    elseif input.KeyCode == Enum.KeyCode.G and not fishing then send("drill")
    elseif input.KeyCode == Enum.KeyCode.B then send("shop")
    elseif input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.ButtonR1 then openBag()
    elseif input.KeyCode == Enum.KeyCode.ButtonX then send(fishing and "cancel" or "cast")
    elseif input.KeyCode == Enum.KeyCode.ButtonY then send("shop") end
end)

local function endFishing()
    fishing, token, held, reel.Visible = false, nil, false, false
    keyHeld, reelPointer, reelView, drillingInfo, hookingInfo = false, nil, nil, nil, nil
    releaseJump()
    castButton.Text = InputHints.cast(false)
end
player.CharacterRemoving:Connect(endFishing)
local function drawReel(data)
    zone.Position, zone.Size = UDim2.fromScale(data.bar, 0), UDim2.fromScale(data.width, 1)
    marker.Position = UDim2.new(data.target, 0, 0, 4)
    progressFill.Size, tensionFill.Size = UDim2.fromScale(data.progress, 1), UDim2.fromScale(data.tension, 1)
end

event.OnClientEvent:Connect(function(kind, data)
    if kind == "profile" then
        profile = data
        local progress = Progression.describe(data.xp)
        levelLabel.Text = "Level " .. progress.level .. "  /  " .. progress.current .. " of " .. progress.required .. " XP"
        xpFill.Size = UDim2.fromScale(progress.fraction, 1)
        dataMode.Text = player:GetAttribute("DataMode") or "Saved progression"
        coins.Text, bagCount.Text = data.coins .. " coins", #data.bag .. " fish  /  " .. bagValue() .. " coin value"
        local names = {}
        for _, category in ipairs({ "auger", "rod", "lure", "bait" }) do
            table.insert(names, Config.gearName(category, data.equipped[category]))
        end
        loadout.Text = table.concat(names, "  /  ")
        if shade.Visible then render() end
    elseif kind == "notice" or kind == "glowNotice" then notice(data)
    elseif kind == "shop" then adventure.close() modalMode = "shop" render() shade.Visible = true
    elseif kind == "stage" then
        hookingInfo = nil
        holdButton.Text = InputHints.hold()
        drillingInfo = data.stage == "drilling" and data or nil
        progressLabel.Text = drillingInfo and "DRILL PROGRESS" or "CATCH PROGRESS"
        tensionLabel.Visible, tensionBack.Visible = false, false
        fishing, token, held, reelView = true, data.token, false, nil
        keyHeld, reelPointer = false, nil
        lockJump()
        shade.Visible, reel.Visible, track.Visible, holdButton.Visible = false, true, false, false
        if data.stage == "drilling" then
            reelTitle.Text, caption.Text = "CUTTING THROUGH THE ICE", "Your auger is making a permanent fishing hole."
        elseif data.stage == "casting" then
            reelTitle.Text, caption.Text = data.reused and "BACK TO YOUR FISHING SPOT" or "CASTING YOUR LINE", "Getting the line ready..."
        else reelTitle.Text, caption.Text = "LINE IN. TAKE A BREATH.", "Listening beneath the ice..." end
        progressFill.Size, tensionFill.Size = UDim2.fromScale(0, 1), UDim2.fromScale(0, 1)
        castButton.Text = InputHints.cast(true)
    elseif kind == "hook" and data.token == token then
        hookingInfo = data
        keyHeld, reelPointer = false, nil
        updateHeld()
        reelTitle.Text, caption.Text = "BITE! HOOK THE FISH", InputHints.hookHelp()
        holdButton.Text, holdButton.Visible = InputHints.hook(), true
        track.Visible, tensionLabel.Visible, tensionBack.Visible = false, false, false
        progressLabel.Text = "REACTION WINDOW"
    elseif kind == "bite" and data.token == token then
        hookingInfo = nil
        holdButton.Text, progressLabel.Text = InputHints.hold(), "CATCH PROGRESS"
        track.Visible, holdButton.Visible = true, true
        tensionLabel.Visible, tensionBack.Visible = true, true
        local bonuses = ""
        if (data.incomeMultiplier or 1) > 1 then bonuses = bonuses .. " / VALUE x2" end
        if (data.luckMultiplier or 1) > 1 then bonuses = bonuses .. " / LUCK x2" end
        reelTitle.Text = "FISH ON!" .. bonuses
        caption.Text = "Hold to move right. Release to drift left. Follow the gold fish."
        reelView = Reel.newView(data)
        drawReel(Reel.viewStep(reelView, 0, held, workspace:GetServerTimeNow(), Config.Fishing))
    elseif kind == "reel" and data.token == token and reelView then
        Reel.receiveView(reelView, data, workspace:GetServerTimeNow(), held, Config.Fishing)
    elseif kind == "caught" then
        endFishing()
    elseif kind == "ended" then endFishing() notice(data) end
end)

local elapsed, lastViewport = 0, Vector2.zero
RunService.RenderStepped:Connect(function(dt)
    elapsed = elapsed + dt
    if drillingInfo then
        local progress = math.max(0, math.min(1, (workspace:GetServerTimeNow() - drillingInfo.startedAt) / drillingInfo.duration))
        progressFill.Size = UDim2.fromScale(progress, 1)
        caption.Text = "Drilling  " .. math.floor(progress * 100) .. "%  /  Reuse this hole for future casts"
    end
    if reelView then drawReel(Reel.viewStep(reelView, dt, held, workspace:GetServerTimeNow(), Config.Fishing)) end
    Preview.step(dt)
    if hookingInfo then progressFill.Size = UDim2.fromScale(math.max(0, 1 - (workspace:GetServerTimeNow() - hookingInfo.startedAt) / hookingInfo.duration), 1) end
    local hour = workspace:GetAttribute("WorldHour") or 14
    areaText.Text = (player:GetAttribute("RegionName") or "Frostbite Pond") .. "\n" .. Content.weather(workspace:GetAttribute("Weather")).name .. " / " .. string.format("%02d:%02d", math.floor(hour), math.floor(hour % 1 * 60))
    if token and elapsed > 0.12 then
        elapsed = 0
        send("input", { token = token, held = held })
    end
    local camera = workspace.CurrentCamera
    if camera and camera.ViewportSize ~= lastViewport then
        lastViewport = camera.ViewportSize
        shopMobile = lastViewport.X < 650
        modal.Size = UDim2.fromOffset(math.min(650, lastViewport.X - 20), math.min(530, lastViewport.Y - 60))
        modalScale.Scale = 1
        modalTitle.TextSize, inspectTitle.TextSize = shopMobile and 18 or 23, shopMobile and 18 or 22
        if shade.Visible then render() end
        holdButton.TextSize, caption.TextSize = shopMobile and 20 or 14, shopMobile and 15 or 12
        for _, item in ipairs(dock:GetDescendants()) do if item:IsA("TextButton") then item.TextSize = shopMobile and 18 or 14 end end
        local scale = math.min(1, (lastViewport.X - 20) / 490)
        local ds = dock:FindFirstChildOfClass("UIScale") or make("UIScale", dock)
        local rs = reel:FindFirstChildOfClass("UIScale") or make("UIScale", reel)
        ds.Scale, rs.Scale = scale, scale
        dock.AnchorPoint, dock.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12)
        reel.AnchorPoint, reel.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -24 - 166 * scale)
        guide.Visible = lastViewport.X > 850 and lastViewport.Y > 580
        brand.Visible = lastViewport.X > 590
        area.Visible = lastViewport.X > 760

    end
end)

require(script.Parent:WaitForChild("AdminMenu")).start(gui, remotes)
require(script.Parent:WaitForChild("Feedback")).start(remotes)
require(script.Parent:WaitForChild("GlowEffects")).start(remotes)

-- Retry the handshake until the server has registered this player.
task.spawn(function()
    while not profile do send("ready") task.wait(1) end
end)
