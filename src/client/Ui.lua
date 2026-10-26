local Ui = {}
Ui.colors = { panel = Color3.fromRGB(20, 41, 54), card = Color3.fromRGB(32, 57, 71),
    text = Color3.fromRGB(232, 245, 249), muted = Color3.fromRGB(170, 198, 211),
    mint = Color3.fromRGB(131, 230, 201), gold = Color3.fromRGB(255, 213, 136), dark = Color3.fromRGB(14, 29, 39) }
function Ui.make(class, parent, props)
    local item = Instance.new(class)
    for key, value in pairs(props or {}) do item[key] = value end
    item.Parent = parent
    return item
end
function Ui.round(item) Ui.make("UICorner", item, { CornerRadius = UDim.new(0, 10) }) end
function Ui.frame(parent, size, position, color)
    local item = Ui.make("Frame", parent, { Size = size, Position = position, BackgroundColor3 = color or Ui.colors.panel, BorderSizePixel = 0 })
    Ui.round(item) return item
end
function Ui.text(parent, value, size, position, fontSize, color)
    return Ui.make("TextLabel", parent, { Text = value, Size = size, Position = position, TextSize = fontSize or 14, Font = Enum.Font.Gotham,
        TextColor3 = color or Ui.colors.text, BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left })
end
function Ui.button(parent, value, size, position, callback, color)
    local item = Ui.make("TextButton", parent, { Text = value, Size = size, Position = position, TextSize = 12, Font = Enum.Font.GothamBold,
        BackgroundColor3 = color or Ui.colors.mint, TextColor3 = Ui.colors.dark, BorderSizePixel = 0, AutoButtonColor = true, Selectable = true })
    Ui.round(item) item.Activated:Connect(callback) return item
end
return Ui
