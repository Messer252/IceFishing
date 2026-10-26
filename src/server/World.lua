local World = {}
local Lighting = game:GetService("Lighting")
local Equipment = require(game:GetService("ReplicatedStorage").Shared.Equipment)
local TweenService = game:GetService("TweenService")

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, position
    p.Anchored, p.Color = true, color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Surface signs stay attached to their physical boards and respect occlusion.
local function signFace(board, face, title, subtitle)
    local surface = Instance.new("SurfaceGui")
    surface.Name, surface.Face = "Lettering", face
    surface.SizingMode, surface.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 45
    surface.AlwaysOnTop, surface.LightInfluence, surface.MaxDistance = false, 0.15, 150
    surface.Parent = board
    for i, value in ipairs({ title, subtitle }) do
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromScale(0.92, i == 1 and 0.49 or 0.25)
        t.Position = UDim2.fromScale(0.04, i == 1 and 0.08 or 0.65)
        t.BackgroundTransparency, t.Text, t.TextScaled = 1, value, true
        t.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        t.TextColor3 = i == 1 and Color3.fromRGB(255, 223, 160) or Color3.fromRGB(176, 223, 213)
        t.Parent = surface
    end
end

local function sign(parent, name, size, position, title, subtitle)
    local board = part(parent, name, size, position, Color3.fromRGB(29, 64, 68), Enum.Material.Wood)
    for _, x in ipairs({ -1, 1 }) do
        part(parent, "SignTrim", Vector3.new(0.2, size.Y + 0.3, size.Z + 0.12), position + Vector3.new(x * size.X / 2, 0, 0), Color3.fromRGB(183, 139, 83), Enum.Material.Wood)
    end
    for _, y in ipairs({ -1, 1 }) do
        part(parent, "SignTrim", Vector3.new(size.X, 0.2, size.Z + 0.12), position + Vector3.new(0, y * size.Y / 2, 0), Color3.fromRGB(183, 139, 83), Enum.Material.Wood)
    end
    signFace(board, Enum.NormalId.Back, title, subtitle)
    signFace(board, Enum.NormalId.Front, title, subtitle)
    return board
end

function World.build(config)
    local old = workspace:FindFirstChild("FrostbiteWorld")
    if old then old:Destroy() end
    local world = Instance.new("Folder")
    world.Name, world.Parent = "FrostbiteWorld", workspace
    Lighting.ClockTime, Lighting.Brightness = 14, 2
    Lighting.Ambient = Color3.fromRGB(140, 166, 190)
    Lighting.OutdoorAmbient = Color3.fromRGB(165, 187, 207)
    Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd = Color3.fromRGB(197, 219, 235), 210, 580
    local sky = Instance.new("Atmosphere")
    sky.Density, sky.Color, sky.Decay = 0.22, Color3.fromRGB(199, 222, 240), Color3.fromRGB(135, 168, 195)
    sky.Parent = Lighting

    part(world, "Snowfield", Vector3.new(420, 8, 420), Vector3.new(0, -4, 0), Color3.fromRGB(233, 241, 245), Enum.Material.Snow)
    local pond = part(world, "FrozenPond", Vector3.new(2, 136, 136), Vector3.new(0, 1, 0), Color3.fromRGB(145, 201, 219), Enum.Material.Ice)
    pond.Shape, pond.Orientation, pond.Reflectance = Enum.PartType.Cylinder, Vector3.new(0, 0, 90), 0.15
    local rng = Random.new(2026)
    -- Thin pale cracks across the frozen surface, kept non-colliding.
    for i = 1, 30 do
        local angle, radius = rng:NextNumber(0, math.pi * 2), rng:NextNumber(6, 59)
        local crack = part(world, "IceVein", Vector3.new(rng:NextNumber(3, 11), 0.015, 0.09),
            Vector3.new(math.cos(angle) * radius, 2.012, math.sin(angle) * radius), Color3.fromRGB(209, 238, 245), Enum.Material.Ice)
        crack.Orientation, crack.CanCollide, crack.CanQuery = Vector3.new(0, rng:NextNumber(0, 360), 0), false, false
    end
    for i = 1, 58 do
        local angle = i * math.pi * 2 / 58 + rng:NextNumber(-0.04, 0.04)
        local radius = rng:NextNumber(87, 175)
        local x, z = math.cos(angle) * radius, math.sin(angle) * radius
        if not (math.abs(x) < 29 and z < -65) then
            local height = rng:NextNumber(16, 29)
            part(world, "PineTrunk", Vector3.new(2.1, height * 0.6, 2.1), Vector3.new(x, height * 0.3, z), Color3.fromRGB(90, 71, 59), Enum.Material.Wood)
            for level = 1, 3 do
                local width = (4 - level) * 3.5
                local leaf = part(world, "PineBoughs", Vector3.new(width, height * 0.32, width), Vector3.new(x, height * (0.30 + level * 0.19), z), Color3.fromRGB(45 + level * 8, 89 + level * 6, 82 + level * 5), Enum.Material.Grass)
                leaf.Shape = Enum.PartType.Ball
                local snow = part(world, "PineSnow", Vector3.new(width * 0.92, height * 0.15, width * 0.92), leaf.Position + Vector3.new(0, height * 0.1, 0), Color3.fromRGB(238, 246, 250), Enum.Material.Snow)
                snow.Shape = Enum.PartType.Ball
            end
        end
    end

    local shop = Instance.new("Model")
    shop.Name, shop.Parent = "TackleShop", world
    part(shop, "Floor", Vector3.new(32, 1, 23), Vector3.new(0, 0.5, -96), Color3.fromRGB(124, 94, 72), Enum.Material.WoodPlanks)
    part(shop, "BackWall", Vector3.new(32, 15, 1), Vector3.new(0, 8, -107), Color3.fromRGB(111, 74, 54), Enum.Material.WoodPlanks)
    for _, x in ipairs({ -15.5, 15.5 }) do
        part(shop, "SideWall", Vector3.new(1, 15, 23), Vector3.new(x, 8, -96), Color3.fromRGB(111, 74, 54), Enum.Material.WoodPlanks)
        part(shop, "PorchPost", Vector3.new(1.2, 15, 1.2), Vector3.new(x, 8, -82), Color3.fromRGB(85, 59, 47), Enum.Material.Wood)
    end
    part(shop, "Roof", Vector3.new(36, 2, 30), Vector3.new(0, 16, -94), Color3.fromRGB(226, 238, 242), Enum.Material.Snow)
    local counter = part(shop, "Counter", Vector3.new(24, 4, 3), Vector3.new(0, 3, -96), Color3.fromRGB(161, 112, 76), Enum.Material.WoodPlanks)
    sign(shop, "CabinSign", Vector3.new(25, 3.6, 0.6), Vector3.new(0, 12.9, -81.2), "FROSTBITE TACKLE", "AUGERS  •  RODS  •  BAIT  •  LURES")
    sign(shop, "SellSign", Vector3.new(10, 1.8, 0.25), Vector3.new(0, 3.3, -94.35), "SELL YOUR CATCH", "Fresh fish. Fair prices.")
    -- Real 3D stock on the back wall, matching the preview and held models.
    part(shop, "EquipmentRack", Vector3.new(28, 0.4, 2), Vector3.new(0, 4, -105), Color3.fromRGB(81, 59, 45), Enum.Material.Wood)
    for i, id in ipairs({ "twig", "birch", "carbon", "glacier" }) do
        local stock = Equipment.build("rod", id)
        stock.Parent = shop
        stock:PivotTo(CFrame.new(-12 + i * 3.2, 5, -105) * CFrame.Angles(0, 0, math.rad(-12)))
    end
    for i, id in ipairs({ "hand", "power" }) do
        local stock = Equipment.build("auger", id)
        stock.Parent = shop
        stock:PivotTo(CFrame.new(6 + i * 3, 9, -105))
    end
    local promptPart = part(shop, "ShopPrompt", Vector3.new(1, 1, 1), Vector3.new(0, 4, -87), Color3.new(1, 1, 1))
    promptPart.Transparency, promptPart.CanCollide = 1, false
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText = "Shop & sell fish", "Frostbite Tackle"
    prompt.MaxActivationDistance, prompt.HoldDuration, prompt.RequiresLineOfSight = 18, 0, false
    prompt.Parent = promptPart
    local light = Instance.new("PointLight")
    light.Color, light.Range, light.Brightness, light.Parent = Color3.fromRGB(255, 209, 137), 35, 1.8, counter

    local spawn = Instance.new("SpawnLocation")
    spawn.Name, spawn.Size, spawn.Position = "LakesideSpawn", Vector3.new(10, 1, 8), Vector3.new(0, 0.5, -73)
    spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
    spawn.Color, spawn.Material, spawn.Parent = Color3.fromRGB(220, 232, 237), Enum.Material.Snow, world
    sign(world, "PondSign", Vector3.new(12, 4, 0.7), Vector3.new(21, 5, -71), "FROSTBITE POND", "DRILL ONCE. FISH ALL DAY.")
    for _, x in ipairs({ 16, 26 }) do
        part(world, "SignPost", Vector3.new(0.6, 4.6, 0.6), Vector3.new(x, 2.3, -71), Color3.fromRGB(104, 77, 54), Enum.Material.Wood)
    end

    -- An impassable natural edge keeps players inside the playable snowfield.
    for i = 1, 24 do
        local angle = i * math.pi * 2 / 24
        local rock = part(world, "SnowyRidge", Vector3.new(57, 45 + (i % 4) * 7, 44), Vector3.new(math.cos(angle) * 207, 15, math.sin(angle) * 207), Color3.fromRGB(191, 211, 222), Enum.Material.Slate)
        rock.Shape = Enum.PartType.Ball
    end
    local buyer = Instance.new("Model")
    buyer.Name, buyer.Parent = "MaraFishBuyer", world
    local base = Vector3.new(11, 1, -86)
    local torso = part(buyer, "Torso", Vector3.new(2, 2, 1), base + Vector3.new(0, 3, 0), Color3.fromRGB(53, 104, 116))
    local head = part(buyer, "Head", Vector3.new(1.6, 1, 1.2), base + Vector3.new(0, 4.5, 0), Color3.fromRGB(219, 171, 128))
    local npcRoot = part(buyer, "HumanoidRootPart", Vector3.new(2, 2, 1), torso.Position, Color3.new(1, 1, 1))
    npcRoot.Transparency, npcRoot.CanCollide = 1, false
    buyer.PrimaryPart = npcRoot
    local neck = Instance.new("Motor6D")
    neck.Name, neck.Part0, neck.Part1 = "Neck", torso, head
    neck.C0, neck.C1, neck.Parent = CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0), torso
    for _, side in ipairs({ -1, 1 }) do
        part(buyer, side == 1 and "Right Arm" or "Left Arm", Vector3.new(1, 2, 1), base + Vector3.new(side * 1.5, 3, 0), Color3.fromRGB(53, 104, 116))
        part(buyer, side == 1 and "Right Leg" or "Left Leg", Vector3.new(0.95, 2, 1), base + Vector3.new(side * 0.5, 1, 0), Color3.fromRGB(48, 57, 68))
        part(buyer, "Mitten", Vector3.new(0.95, 0.5, 1.02), base + Vector3.new(side * 1.5, 2.15, 0), Color3.fromRGB(179, 133, 75))
        part(buyer, "Eye", Vector3.new(0.1, 0.12, 0.06), base + Vector3.new(side * 0.29, 4.55, 0.62), Color3.fromRGB(30, 42, 44))
    end
    part(buyer, "Beanie", Vector3.new(1.75, 0.45, 1.3), base + Vector3.new(0, 5.05, 0), Color3.fromRGB(210, 146, 67))
    local pom = part(buyer, "PomPom", Vector3.new(0.45, 0.45, 0.45), base + Vector3.new(0, 5.45, 0), Color3.fromRGB(247, 227, 179))
    pom.Shape = Enum.PartType.Ball
    part(buyer, "Scarf", Vector3.new(2.1, 0.3, 1.2), base + Vector3.new(0, 4, 0), Color3.fromRGB(210, 146, 67))
    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayName, humanoid.NameDisplayDistance, humanoid.Parent = "Mara · Fish buyer", 45, buyer
    local sellPrompt = Instance.new("ProximityPrompt")
    sellPrompt.ActionText, sellPrompt.ObjectText = "Sell all fish", "Mara · Fish buyer"
    sellPrompt.MaxActivationDistance, sellPrompt.HoldDuration, sellPrompt.RequiresLineOfSight = 10, 0.25, false
    sellPrompt.Parent = torso
    return world, prompt, sellPrompt
end

function World.hole(parent, position, diameter, owner)
    local model = Instance.new("Model")
    model.Name, model.Parent = "Hole_" .. owner.UserId, parent
    local rim = part(model, "SnowRim", Vector3.new(0.1, diameter + 0.65, diameter + 0.65), Vector3.new(position.X, 2.04, position.Z), Color3.fromRGB(231, 249, 251), Enum.Material.Snow)
    rim.Shape, rim.Orientation, rim.CanCollide = Enum.PartType.Cylinder, Vector3.new(0, 0, 90), false
    local water = part(model, "DarkWater", Vector3.new(0.12, diameter, diameter), Vector3.new(position.X, 2.11, position.Z), Color3.fromRGB(19, 57, 76), Enum.Material.Glass)
    water.Shape, water.Orientation, water.CanCollide, water.Reflectance = Enum.PartType.Cylinder, Vector3.new(0, 0, 90), false, 0.2
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText = "Cast again", owner.DisplayName .. "'s fishing hole"
    prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.HoldDuration = 10, false, 0
    prompt.Parent = water
    return model, prompt
end

function World.line(hole, equipment)
    local model = Instance.new("Model")
    model.Name, model.Parent = "FishingLine", hole.model
    local bobber = part(model, "Bobber", Vector3.new(0.25, 0.4, 0.25), hole.position + Vector3.new(0, 1.7, 0), Color3.fromRGB(236, 107, 78))
    bobber.Shape, bobber.CanCollide, bobber.CanQuery = Enum.PartType.Ball, false, false
    local anchor = Instance.new("Attachment")
    anchor.Parent = bobber
    local beam = Instance.new("Beam")
    beam.Attachment0 = equipment.PrimaryPart:FindFirstChild("LineTip")
    beam.Attachment1, beam.Width0, beam.Width1, beam.FaceCamera = anchor, 0.025, 0.025, true
    beam.Segments, beam.CurveSize0, beam.CurveSize1 = 16, 0.35, 0.35
    beam.Color, beam.Parent = ColorSequence.new(Color3.fromRGB(227, 238, 241)), bobber
    TweenService:Create(bobber, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = hole.position + Vector3.new(0, 0.24, 0) }):Play()
    return model, bobber
end

function World.drilling(parent, position)
    local source = part(parent, "IceShavings", Vector3.new(0.2, 0.2, 0.2), position + Vector3.new(0, 0.2, 0), Color3.new(1, 1, 1))
    source.Transparency, source.CanCollide, source.CanQuery = 1, false, false
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(Color3.fromRGB(223, 249, 255))
    emitter.Rate, emitter.Lifetime, emitter.Speed = 28, NumberRange.new(0.25, 0.55), NumberRange.new(3, 7)
    emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
    emitter.SpreadAngle, emitter.Acceleration, emitter.Parent = Vector2.new(65, 65), Vector3.new(0, -16, 0), source
    return source
end

function World.catchEffect(parent, position, catch)
    local FishModels = require(game:GetService("ReplicatedStorage").Shared.FishModels)
    local model = FishModels.build(catch.species, catch.color)
    model:ScaleTo(math.min(0.8, 0.35 + catch.kg ^ 0.25 * 0.08))
    model.Parent = parent
    local value = Instance.new("CFrameValue")
    value.Value, value.Parent = CFrame.new(position + Vector3.new(0, 0.4, 0)), model
    model:PivotTo(value.Value)
    local connection = value.Changed:Connect(function(cf) if model.Parent then model:PivotTo(cf) end end)
    model.Destroying:Connect(function() connection:Disconnect() end)
    local tween = TweenService:Create(value, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = CFrame.new(position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(65)) })
    tween.Completed:Connect(function() model:Destroy() end)
    tween:Play()
    game:GetService("Debris"):AddItem(model, 1.2)
end

return World
