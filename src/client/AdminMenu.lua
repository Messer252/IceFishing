local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local AdminMenu = {}

function AdminMenu.start(gui, remotes)
    local player = Players.LocalPlayer
    local command, event = remotes:WaitForChild("AdminCommand"), remotes:WaitForChild("AdminEvent")
    local navy, card, mint, gold, white = Color3.fromRGB(20, 41, 54), Color3.fromRGB(32, 57, 71), Color3.fromRGB(131, 230, 201), Color3.fromRGB(255, 213, 136), Color3.fromRGB(232, 245, 249)
    local function make(class, parent, props)
        local object = Instance.new(class)
        for k, v in pairs(props) do object[k] = v end
        object.Parent = parent
        return object
    end
    local function round(object) make("UICorner", object, { CornerRadius = UDim.new(0, 9) }) end
    local function text(parent, value, size, position, fontSize)
        return make("TextLabel", parent, { Text = value, Size = size, Position = position, TextSize = fontSize or 14,
            Font = Enum.Font.Gotham, TextColor3 = white, TextWrapped = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    end
    local function button(parent, value, size, position, callback, color)
        local object = make("TextButton", parent, { Text = value, Size = size, Position = position, TextSize = 13, Font = Enum.Font.GothamBold,
            BackgroundColor3 = color or mint, TextColor3 = navy, BorderSizePixel = 0 })
        round(object) object.Activated:Connect(callback) return object
    end
    local function box(parent, placeholder, size, position)
        local object = make("TextBox", parent, { Text = "", PlaceholderText = placeholder, Size = size, Position = position, TextSize = 14,
            Font = Enum.Font.Gotham, TextColor3 = white, PlaceholderColor3 = Color3.fromRGB(170, 194, 206), BackgroundColor3 = card,
            BorderSizePixel = 0, ClearTextOnFocus = false })
        round(object) return object
    end
    local overlay = make("Frame", gui, { Name = "AdminOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, ZIndex = 10 })
    local panel = make("Frame", overlay, { Size = UDim2.fromOffset(680, 560), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = navy, BorderSizePixel = 0 })
    round(panel)
    local scale = make("UIScale", panel, { Scale = 1 })
    text(panel, "FROSTBITE / ADMIN", UDim2.fromOffset(520, 34), UDim2.fromOffset(20, 14), 22).Font = Enum.Font.GothamBold
    text(panel, "Manage players in this server", UDim2.fromOffset(530, 24), UDim2.fromOffset(20, 49), 13)
    button(panel, "X", UDim2.fromOffset(36, 34), UDim2.new(1, -56, 0, 16), function() overlay.Visible = false end, gold)
    local selected, confirm = nil, nil
    local selection = text(panel, "Select a player", UDim2.fromOffset(415, 32), UDim2.fromOffset(245, 88), 17)
    local result = text(panel, "Choose a player, amount, and action.", UDim2.new(1, -40, 0, 48), UDim2.fromOffset(20, 492), 13)
    local rosterList = make("ScrollingFrame", panel, { Size = UDim2.fromOffset(205, 355), Position = UDim2.fromOffset(20, 90),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y })
    make("UIListLayout", rosterList, { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder })
    local amount = box(panel, "Amount (whole number)", UDim2.fromOffset(410, 36), UDim2.fromOffset(245, 128))
    local reason = box(panel, "Kick reason (optional)", UDim2.fromOffset(410, 36), UDim2.fromOffset(245, 174))
    local function request(action, needsTarget, needsConfirmation)
        if not player:GetAttribute("IsAdmin") then overlay.Visible = false return end
        if needsTarget and not selected then result.Text = "Select a player first." return end
        if needsConfirmation then
            local key = action .. ":" .. tostring(selected)
            if not confirm or confirm.key ~= key or os.clock() > confirm.expires then
                confirm = { key = key, expires = os.clock() + 6 }
                result.Text = "Press " .. action .. " again within 6 seconds to confirm for the selected player."
                return
            end
        end
        confirm = nil
        command:FireServer({ action = action, targetId = selected, amount = tonumber(amount.Text), reason = reason.Text })
    end
    local actions = {
        { "Give coins", "money" }, { "Give XP", "xp" }, { "Go to player", "gotoPlayer" }, { "Bring player", "bring" },
        { "Freeze", "freeze" }, { "Unfreeze", "unfreeze" }, { "Heal", "heal" }, { "Respawn", "respawn", true }, { "Kick", "kick", true },
    }
    for i, action in ipairs(actions) do
        local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
        button(panel, action[1], UDim2.fromOffset(198, 34), UDim2.fromOffset(245 + column * 212, 222 + row * 43), function()
            request(action[2], true, action[3])
        end, action[2] == "kick" and Color3.fromRGB(241, 144, 139) or mint)
    end
    local flyButton = button(panel, "Fly: OFF", UDim2.fromOffset(130, 34), UDim2.fromOffset(245, 446), function() request("fly") end, gold)
    button(panel, "To pond", UDim2.fromOffset(130, 34), UDim2.fromOffset(385, 446), function() request("pond") end, gold)
    button(panel, "To shop", UDim2.fromOffset(130, 34), UDim2.fromOffset(525, 446), function() request("shop") end, gold)
    button(panel, "Refresh players", UDim2.fromOffset(205, 30), UDim2.fromOffset(20, 451), function() request("roster") end, gold)
    local function toggle()
        if not player:GetAttribute("IsAdmin") then return end
        overlay.Visible = not overlay.Visible
        if overlay.Visible then request("roster") end
    end
    local badge = button(gui, "ADMIN  [F2]", UDim2.fromOffset(190, 30), UDim2.new(1, -206, 0, 164), toggle, gold)
    badge.Name = "AdminButton"
    badge.Visible = player:GetAttribute("IsAdmin") == true
    player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
        badge.Visible = player:GetAttribute("IsAdmin") == true
        if not badge.Visible then overlay.Visible = false end
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.F2 then toggle() end
    end)
    event.OnClientEvent:Connect(function(kind, data)
        if not player:GetAttribute("IsAdmin") then return end
        if kind == "result" then result.Text = data
        elseif kind == "roster" then
            for _, child in ipairs(rosterList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            local found = false
            for i, target in ipairs(data) do
                if target.userId == selected then found = true end
                local entry = button(rosterList, "@" .. target.username .. "\n" .. target.displayName, UDim2.new(1, -6, 0, 55), UDim2.fromOffset(0, 0), function()
                    selected, confirm = target.userId, nil
                    selection.Text = "@" .. target.username .. "  /  " .. target.userId
                end, selected == target.userId and gold or mint)
                entry.LayoutOrder = i
            end
            if not found then selected, confirm = nil, nil selection.Text = "Select a player" end
        end
    end)
    -- Flight uses server-created constraints, enabled only after server approval.
    local up, down, flightBound = false, false, false
    local flightHud = make("Frame", gui, { Size = UDim2.fromOffset(260, 95), Position = UDim2.new(0.5, -130, 0, 90), BackgroundColor3 = navy, BorderSizePixel = 0, Visible = false })
    round(flightHud)
    text(flightHud, "FLY / WASD · Space up · Ctrl down", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 4), 12)
    local upButton = button(flightHud, "UP", UDim2.fromOffset(110, 40), UDim2.fromOffset(10, 42), function() end)
    local downButton = button(flightHud, "DOWN", UDim2.fromOffset(110, 40), UDim2.fromOffset(140, 42), function() end)
    local upPointer, downPointer
    upButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then upPointer = input end end)
    downButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then downPointer = input end end)
    UserInputService.InputEnded:Connect(function(input)
        if input == upPointer or input.UserInputType == Enum.UserInputType.MouseButton1 then upPointer = nil end
        if input == downPointer or input.UserInputType == Enum.UserInputType.MouseButton1 then downPointer = nil end
    end)
    UserInputService.WindowFocusReleased:Connect(function() up, down, upPointer, downPointer = false, false, nil, nil end)
    RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if camera then scale.Scale = math.min(1, (camera.ViewportSize.X - 20) / 680, (camera.ViewportSize.Y - 60) / 560) end
        local enabled = player:GetAttribute("IsAdmin") == true and player:GetAttribute("AdminFlying") == true
        flyButton.Text, flightHud.Visible = enabled and "Fly: ON" or "Fly: OFF", enabled
        if enabled and not flightBound then
            ContextActionService:BindActionAtPriority("AdminFlightVertical", function(_, state, input)
                local pressed = state == Enum.UserInputState.Begin
                if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then up = pressed else down = pressed end
                return Enum.ContextActionResult.Sink
            end, false, Enum.ContextActionPriority.High.Value + 200, Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB)
            flightBound = true
        elseif not enabled and flightBound then
            ContextActionService:UnbindAction("AdminFlightVertical")
            flightBound, up, down, upPointer, downPointer = false, false, false, nil, nil
        end
        if not enabled or not camera then return end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local velocity = root and root:FindFirstChild("AdminFlightVelocity")
        local orientation = root and root:FindFirstChild("AdminFlightOrientation")
        if not velocity or not orientation or not humanoid then return end
        local direction = Vector3.zero
        if not UserInputService:GetFocusedTextBox() and not overlay.Visible then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
            if direction.Magnitude < 0.01 then direction = humanoid.MoveDirection end
            direction = direction + Vector3.new(0, ((up or upPointer) and 1 or 0) - ((down or downPointer) and 1 or 0), 0)
        end
        velocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * (player:GetAttribute("AdminFlySpeed") or 55) or Vector3.zero
        orientation.CFrame = camera.CFrame.Rotation
    end)
end
return AdminMenu
