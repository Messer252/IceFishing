local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
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
local fishing, token, held = false, nil, false

local brand = frame(gui, UDim2.fromOffset(252, 76), UDim2.fromOffset(16, 16))
text(brand, "F R O S T B I T E", UDim2.new(1, -28, 0, 28), UDim2.fromOffset(14, 10), 20, C.mint).Font = Enum.Font.GothamBold
text(brand, "ICE FISHING  /  FROZEN WILDERNESS", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 43), 10, C.muted)
local wallet = frame(gui, UDim2.fromOffset(190, 76), UDim2.new(1, -206, 0, 16))
local coins = text(wallet, "120 coins", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 9), 21, C.gold)
coins.Font = Enum.Font.GothamBold
local bagCount = text(wallet, "0 fish in bag", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 43), 13, C.muted)
local guide = frame(gui, UDim2.fromOffset(246, 167), UDim2.fromOffset(16, 108))
text(guide, "A QUIET DAY ON THE ICE", UDim2.fromOffset(218, 26), UDim2.fromOffset(14, 10), 12, C.gold).Font = Enum.Font.GothamBold
text(guide, "01  Walk onto the frozen pond\n02  Drill a hole and cast your line\n03  Hold to follow the moving fish\n04  Sell fish at the cabin for gear", UDim2.fromOffset(218, 110), UDim2.fromOffset(14, 43), 14, C.muted)

local dock = frame(gui, UDim2.fromOffset(468, 90), UDim2.new(0.5, -234, 1, -106))
local castButton = button(dock, "DRILL & FISH  [F]", UDim2.fromOffset(208, 42), UDim2.fromOffset(12, 10), function() send(fishing and "cancel" or "cast") end)
button(dock, "SHOP  [B]", UDim2.fromOffset(108, 42), UDim2.fromOffset(230, 10), function() send("shop") end, C.gold)
local openBag
button(dock, "BAG  [I]", UDim2.fromOffset(108, 42), UDim2.fromOffset(348, 10), function() if openBag then openBag() end end, Color3.fromRGB(191, 218, 232))
local loadout = text(dock, "Walk onto the ice to begin", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 60), 11, C.muted)
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
local modalTitle = text(modal, "FROSTBITE TACKLE", UDim2.fromOffset(490, 34), UDim2.fromOffset(22, 16), 23, C.gold)
modalTitle.Font = Enum.Font.GothamBold
local modalSubtitle = text(modal, "Better gear. Bigger holes. Rarer fish.", UDim2.fromOffset(540, 24), UDim2.fromOffset(22, 52), 14, C.muted)
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

local function bagValue()
    local sum = 0
    if profile then for _, fish in ipairs(profile.bag) do sum = sum + fish.value end end
    return sum
end

render = function()
    for _, child in ipairs(list:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
    if not profile then return end
    local isShop = modalMode == "shop"
    tabs.Visible = isShop
    modalTitle.Text = isShop and "FROSTBITE TACKLE" or "YOUR FISH BAG"
    modalSubtitle.Text = isShop and ("Balance: " .. profile.coins .. " coins  /  Purchases auto-equip") or "Bring your catch to the cabin to sell it."
    list.Position = UDim2.fromOffset(22, isShop and 140 or 90)
    list.Size = UDim2.new(1, -44, 1, isShop and -208 or -158)
    sell.Text = "SELL ALL FISH  /  " .. bagValue() .. " COINS"
    for category, b in pairs(tabButtons) do
        b.BackgroundColor3 = category == activeTab and C.mint or C.card
        b.TextColor3 = category == activeTab and C.dark or C.muted
    end
    if isShop then
        for i, item in ipairs(Config.Gear[activeTab]) do
            local category = activeTab
            local card = frame(list, UDim2.new(1, 0, 0, 100), UDim2.fromOffset(0, 0), C.card)
            card.LayoutOrder = i
            text(card, item.name, UDim2.new(1, -166, 0, 28), UDim2.fromOffset(14, 8), 17).Font = Enum.Font.GothamBold
            text(card, item.description, UDim2.new(1, -175, 0, 43), UDim2.fromOffset(14, 38), 13, C.muted)
            local equipped = profile.equipped[category] == item.id
            local owned = category ~= "bait" and profile.owned[category][item.id]
            local stock = category == "bait" and (profile.bait[item.id] or 0) or 0
            local hasBait = category == "bait" and (item.amount == 0 or stock > 0)
            local caption = equipped and "EQUIPPED" or ((owned or hasBait) and "EQUIP" or (item.cost .. " COINS"))
            if category == "bait" and equipped and item.amount > 0 then caption = "+10 / " .. item.cost .. " COINS" end
            button(card, caption, UDim2.fromOffset(136, 36), UDim2.new(1, -150, 0, 22), function()
                send("buy", { category = category, id = item.id, equip = hasBait and not equipped })
            end, equipped and C.gold or C.mint)
            if category == "bait" then
                text(card, item.amount == 0 and "Unlimited" or (stock .. " casts left"), UDim2.fromOffset(136, 22), UDim2.new(1, -150, 0, 63), 12, C.muted).TextXAlignment = Enum.TextXAlignment.Center
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

openBag = function() modalMode = "bag" render() shade.Visible = true end

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
text(reel, "CATCH PROGRESS", UDim2.fromOffset(180, 20), UDim2.fromOffset(22, 134), 10, C.muted)
text(reel, "LINE TENSION", UDim2.fromOffset(140, 20), UDim2.new(0.66, 0, 0, 134), 10, C.red)
local holdButton = button(reel, "HOLD / SPACE TO REEL", UDim2.new(1, -44, 0, 43), UDim2.fromOffset(22, 162), nil)

local function setHeld(value)
    held = value
    if token then send("input", { token = token, held = held }) end
end
holdButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setHeld(true) end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setHeld(false) end
end)
UserInputService.WindowFocusReleased:Connect(function() setHeld(false) end)
UserInputService.InputBegan:Connect(function(input, processed)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Space and fishing then setHeld(true) return end
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then send(fishing and "cancel" or "cast")
    elseif input.KeyCode == Enum.KeyCode.B then send("shop")
    elseif input.KeyCode == Enum.KeyCode.I then openBag() end
end)

local function endFishing()
    fishing, token, held, reel.Visible = false, nil, false, false
    castButton.Text = "DRILL & FISH  [F]"
end
local function drawReel(data)
    zone.Position, zone.Size = UDim2.fromScale(data.bar, 0), UDim2.fromScale(data.width, 1)
    marker.Position = UDim2.new(data.target, 0, 0, 4)
    progressFill.Size, tensionFill.Size = UDim2.fromScale(data.progress, 1), UDim2.fromScale(data.tension, 1)
end

event.OnClientEvent:Connect(function(kind, data)
    if kind == "profile" then
        profile = data
        coins.Text, bagCount.Text = data.coins .. " coins", #data.bag .. " fish  /  " .. bagValue() .. " coin value"
        local names = {}
        for _, category in ipairs({ "auger", "rod", "lure", "bait" }) do
            local gear = Config.findGear(category, data.equipped[category])
            table.insert(names, gear.name:gsub(" · 10 casts", ""))
        end
        loadout.Text = table.concat(names, "  /  ")
        if shade.Visible then render() end
    elseif kind == "notice" then notice(data)
    elseif kind == "shop" then modalMode = "shop" render() shade.Visible = true
    elseif kind == "waiting" then
        fishing, token, held = true, data.token, false
        shade.Visible, reel.Visible, track.Visible, holdButton.Visible = false, true, false, false
        reelTitle.Text, caption.Text = "LINE IN. TAKE A BREATH.", "Listening beneath the ice..."
        progressFill.Size, tensionFill.Size = UDim2.fromScale(0, 1), UDim2.fromScale(0, 1)
        castButton.Text = "CANCEL CAST  [F]"
    elseif kind == "bite" then
        token, track.Visible, holdButton.Visible = data.token, true, true
        reelTitle.Text = "FISH ON!"
        caption.Text = "Hold to move right. Release to drift left. Follow the gold fish."
        drawReel(data)
    elseif kind == "reel" then drawReel(data)
    elseif kind == "caught" then
        endFishing()
        notice("CAUGHT  " .. data.name .. "\n" .. data.rarity .. "  /  " .. data.kg .. " kg  /  " .. data.value .. " coins", Color3.fromRGB(data.color[1], data.color[2], data.color[3]))
    elseif kind == "ended" then endFishing() notice(data) end
end)

local elapsed, lastViewport = 0, Vector2.zero
RunService.RenderStepped:Connect(function(dt)
    elapsed = elapsed + dt
    if token and elapsed > 0.12 then
        elapsed = 0
        send("input", { token = token, held = held })
    end
    local camera = workspace.CurrentCamera
    if camera and camera.ViewportSize ~= lastViewport then
        lastViewport = camera.ViewportSize
        modalScale.Scale = math.min(1, (lastViewport.X - 24) / 650, (lastViewport.Y - 60) / 530)
        local scale = math.min(1, (lastViewport.X - 20) / 490)
        local ds = dock:FindFirstChildOfClass("UIScale") or make("UIScale", dock)
        local rs = reel:FindFirstChildOfClass("UIScale") or make("UIScale", reel)
        ds.Scale, rs.Scale = scale, scale
        dock.AnchorPoint, dock.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12)
        reel.AnchorPoint, reel.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -24 - 90 * scale)
        guide.Visible = lastViewport.X > 850 and lastViewport.Y > 580
        brand.Visible = lastViewport.X > 490
    end
end)

-- Retry the handshake until the server has registered this player.
task.spawn(function()
    while not profile do send("ready") task.wait(1) end
end)
