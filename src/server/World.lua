local World = {}
local Lighting = game:GetService("Lighting")

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, position
    p.Anchored, p.Color = true, color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function label(adornee, text, color, size)
    local board = Instance.new("BillboardGui")
    board.Size = UDim2.fromOffset(size or 230, 65)
    board.StudsOffset = Vector3.new(0, 3, 0)
    board.MaxDistance, board.AlwaysOnTop = 100, false
    board.Adornee, board.Parent = adornee, adornee
    local t = Instance.new("TextLabel")
    t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    t.Text, t.TextColor3 = text, color
    t.TextSize, t.Font = 21, Enum.Font.GothamBold
    t.TextStrokeTransparency = 0.65
    t.Parent = board
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
    label(counter, "FROSTBITE TACKLE\nGEAR  /  BAIT  /  SELL FISH", Color3.fromRGB(255, 224, 163), 340)
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
    local sign = part(world, "PondSign", Vector3.new(12, 5, 0.7), Vector3.new(19, 5, -71), Color3.fromRGB(67, 95, 100), Enum.Material.Wood)
    label(sign, "FROSTBITE POND\nWalk onto the ice to drill", Color3.fromRGB(228, 245, 250), 300)

    -- An impassable natural edge keeps players inside the playable snowfield.
    for i = 1, 24 do
        local angle = i * math.pi * 2 / 24
        local rock = part(world, "SnowyRidge", Vector3.new(57, 45 + (i % 4) * 7, 44), Vector3.new(math.cos(angle) * 207, 15, math.sin(angle) * 207), Color3.fromRGB(191, 211, 222), Enum.Material.Slate)
        rock.Shape = Enum.PartType.Ball
    end
    return world, prompt
end

function World.hole(parent, position, diameter, owner)
    local model = Instance.new("Model")
    model.Name, model.Parent = "Hole_" .. owner.UserId, parent
    local rim = part(model, "SnowRim", Vector3.new(0.1, diameter + 0.65, diameter + 0.65), Vector3.new(position.X, 2.04, position.Z), Color3.fromRGB(231, 249, 251), Enum.Material.Snow)
    rim.Shape, rim.Orientation, rim.CanCollide = Enum.PartType.Cylinder, Vector3.new(0, 0, 90), false
    local water = part(model, "DarkWater", Vector3.new(0.12, diameter, diameter), Vector3.new(position.X, 2.11, position.Z), Color3.fromRGB(19, 57, 76), Enum.Material.Glass)
    water.Shape, water.Orientation, water.CanCollide, water.Reflectance = Enum.PartType.Cylinder, Vector3.new(0, 0, 90), false, 0.2
    return model
end

function World.rod(character)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not hand then return nil end
    local model = Instance.new("Model")
    model.Name, model.Parent = "FishingRod", character
    local rod = part(model, "Rod", Vector3.new(0.12, 5, 0.12), Vector3.new(0, 0, 0), Color3.fromRGB(185, 116, 62), Enum.Material.Wood)
    rod.Anchored, rod.CanCollide, rod.Massless = false, false, true
    rod.CFrame = hand.CFrame * CFrame.new(0, -1, -1.9) * CFrame.Angles(math.rad(-65), 0, 0)
    local weld = Instance.new("WeldConstraint")
    weld.Part0, weld.Part1, weld.Parent = hand, rod, rod
    return model, rod
end

return World
