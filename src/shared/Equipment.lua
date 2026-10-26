-- Original asset-free models shared by held tools, cabin racks and 3D previews.
local Equipment = {}
local palettes = {
    hand = { 170, 91, 54 }, steel = { 96, 149, 163 }, power = { 226, 163, 57 }, arctic = { 107, 220, 231 },
    twig = { 139, 88, 53 }, birch = { 205, 167, 111 }, carbon = { 75, 127, 166 }, glacier = { 124, 230, 228 },
    plain = { 166, 184, 193 }, copper = { 210, 134, 65 }, silver = { 207, 227, 240 }, aurora = { 166, 139, 245 },
    bread = { 236, 201, 137 }, worms = { 195, 106, 113 }, minnows = { 106, 183, 207 },
}
local metal, dark = Color3.fromRGB(187, 205, 216), Color3.fromRGB(32, 44, 54)

local function piece(model, name, size, cf, color, shape, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = true, false, false, false, true
    p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = model
    return p
end

local function link(model, name, a, b, radius, color, material)
    local delta = b - a
    local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
    return piece(model, name, Vector3.new(delta.Magnitude, radius, radius), cf, color, Enum.PartType.Cylinder, material)
end

local function ring(model, name, center, radius, color)
    for i = 1, 12 do
        local a, b = (i - 1) * math.pi / 6, i * math.pi / 6
        link(model, name, center + Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0),
            center + Vector3.new(math.cos(b) * radius, math.sin(b) * radius, 0), 0.045, color, Enum.Material.Metal)
    end
end

function Equipment.build(category, id)
    local model = Instance.new("Model")
    model.Name = category .. "_" .. id
    local rgb = palettes[id] or { 170, 210, 220 }
    local accent = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    local handle = piece(model, "Handle", Vector3.new(0.27, 0.9, 0.27), CFrame.new(), dark)
    model.PrimaryPart = handle
    if category == "rod" then
        handle.Color, handle.Material = Color3.fromRGB(173, 133, 87), Enum.Material.Wood
        local length = id == "glacier" and 6.4 or 5.8
        for i = 1, 4 do
            local from = Vector3.new(0, 0.45 + (i - 1) * length / 4, 0)
            local to = Vector3.new(0, 0.45 + i * length / 4, 0)
            link(model, "RodBlank", from, to, 0.16 - i * 0.025, accent, Enum.Material.Metal)
            ring(model, "LineGuide", to + Vector3.new(0, 0, -0.09), 0.10, metal)
        end
        link(model, "ReelFoot", Vector3.new(0, 0.15, 0), Vector3.new(0, 0.15, -0.42), 0.12, metal)
        piece(model, "ReelSpool", Vector3.new(0.52, 0.65, 0.65), CFrame.new(0, 0.05, -0.52), accent, Enum.PartType.Cylinder, Enum.Material.Metal)
        piece(model, "SpoolLine", Vector3.new(0.34, 0.52, 0.52), CFrame.new(0, 0.05, -0.52), Color3.fromRGB(223, 233, 222), Enum.PartType.Cylinder)
        link(model, "Crank", Vector3.new(0.32, 0.05, -0.52), Vector3.new(0.32, -0.35, -0.72), 0.09, metal)
        piece(model, "CrankKnob", Vector3.new(0.3, 0.18, 0.18), CFrame.new(0.42, -0.35, -0.72), dark, Enum.PartType.Cylinder)
        local tip = Instance.new("Attachment")
        tip.Name, tip.Position, tip.Parent = "LineTip", Vector3.new(0, length + 0.45, 0), handle
    elseif category == "auger" then
        link(model, "DrillShaft", Vector3.new(0, 0.3, 0), Vector3.new(0, -4.6, 0), 0.19, metal, Enum.Material.Metal)
        for i = 1, 64 do
            local function point(t) return Vector3.new(math.cos(t * math.pi * 6) * 0.55, -1 - t * 3.4, math.sin(t * math.pi * 6) * 0.55) end
            link(model, "SpiralFlight", point((i - 1) / 64), point(i / 64), 0.24, accent, Enum.Material.Metal)
        end
        piece(model, "CuttingBlade", Vector3.new(1.3, 0.1, 0.42), CFrame.new(0, -4.55, 0) * CFrame.Angles(0, 0, 0.1), metal, nil, Enum.Material.Metal)
        link(model, "Crossbar", Vector3.new(-0.9, 0.45, 0), Vector3.new(0.9, 0.45, 0), 0.14, metal)
        for _, x in ipairs({ -0.85, 0.85 }) do
            piece(model, "Grip", Vector3.new(0.55, 0.28, 0.28), CFrame.new(x, 0.45, 0), dark, Enum.PartType.Cylinder)
        end
        if id == "power" or id == "arctic" then
            piece(model, "MotorHousing", Vector3.new(1.1, 0.95, 0.85), CFrame.new(0, 0.8, 0), accent)
            piece(model, "FuelCap", Vector3.new(0.16, 0.3, 0.3), CFrame.new(0.33, 1.32, 0) * CFrame.Angles(0, 0, math.pi / 2), dark, Enum.PartType.Cylinder)
            for i = 1, 4 do piece(model, "CoolingVent", Vector3.new(0.65, 0.045, 0.04), CFrame.new(0, 0.5 + i * 0.13, -0.44), dark) end
        end
    elseif category == "lure" then
        handle.Transparency = 1
        piece(model, "Spoon", Vector3.new(0.65, 1.65, 0.2), CFrame.new(0, 0.5, 0), accent, Enum.PartType.Ball, Enum.Material.Metal)
        ring(model, "Eyelet", Vector3.new(0, 1.45, 0), 0.14, metal)
        for i = 1, 12 do
            local a, b = (i - 1) * math.pi / 9, i * math.pi / 9
            link(model, "Hook", Vector3.new(0.27 * math.sin(a), -0.55 - 0.35 * math.cos(a), 0), Vector3.new(0.27 * math.sin(b), -0.55 - 0.35 * math.cos(b), 0), 0.065, metal)
        end
        piece(model, "Eye", Vector3.new(0.12, 0.12, 0.08), CFrame.new(0, 0.8, -0.12), dark, Enum.PartType.Ball)
    else
        handle.Transparency = 1
        piece(model, "BaitTin", Vector3.new(1.3, 1.8, 1.8), CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(223, 231, 221), Enum.PartType.Cylinder)
        piece(model, "Lid", Vector3.new(0.18, 1.9, 1.9), CFrame.new(0, 1.01, 0) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.PartType.Cylinder, Enum.Material.Metal)
        piece(model, "LabelBand", Vector3.new(0.55, 1.84, 1.84), CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.PartType.Cylinder)
        if id == "worms" then
            for i = 1, 7 do piece(model, "Worm", Vector3.new(0.14, 0.14, 0.5), CFrame.new((i % 3 - 1) * 0.26, 1.15, (i % 2 - 0.5) * 0.5) * CFrame.Angles(0, i, 0), accent, Enum.PartType.Ball) end
        else
            for i = 1, 4 do piece(model, "Bait", Vector3.new(0.35, 0.23, 0.65), CFrame.new((i % 2 - 0.5) * 0.7, 1.17, (math.floor(i / 2) - 1) * 0.45), accent, Enum.PartType.Ball) end
        end
    end
    return model
end

function Equipment.mount(character, category, id)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not hand then return nil end
    local model = Equipment.build(category, id)
    local handle = model.PrimaryPart
    local offset = category == "rod" and (CFrame.new(0, -0.25, -0.15) * CFrame.Angles(math.rad(-112), 0, 0))
        or (CFrame.new(0, -0.3, -0.3) * CFrame.Angles(math.rad(-70), 0, 0))
    -- Cache authored transforms before moving the handle, then weld the assembly.
    local transforms = {}
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then transforms[p] = p.CFrame end
    end
    for p, cf in pairs(transforms) do
        p.CFrame, p.Anchored = hand.CFrame * offset * cf, false
    end
    for p in pairs(transforms) do
        if p ~= handle then
            local weld = Instance.new("WeldConstraint")
            weld.Part0, weld.Part1, weld.Parent = handle, p, p
        end
    end
    local grip = Instance.new("Motor6D")
    grip.Name, grip.Part0, grip.Part1 = "EquipmentGrip", hand, handle
    grip.C0, grip.Parent = offset, handle
    model.Parent = character
    return model, grip, offset
end

return Equipment
