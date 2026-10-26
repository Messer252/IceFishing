local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Content = require(ReplicatedStorage.Shared.Content)
local Expansion = {}
local function part(parent, class, name, size, position, rgb, material)
    local p = Instance.new(class)
    p.Name, p.Size, p.Position, p.Color = name, size, position, Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    p.Anchored, p.Material, p.Parent = true, material or Enum.Material.SmoothPlastic, parent
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.CanTouch = false
    return p
end
local function sign(parent, position, title, subtitle)
    local board = part(parent, "Part", "TrailBoard", Vector3.new(13, 4, 0.5), position, { 35, 64, 71 }, Enum.Material.Wood)
    for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
        local surface = Instance.new("SurfaceGui")
        surface.Face, surface.SizingMode, surface.PixelsPerStud, surface.Parent = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, board
        surface.LightInfluence = 0.15
        for i, value in ipairs({ title, subtitle }) do
            local t = Instance.new("TextLabel")
            t.Text, t.TextScaled, t.BackgroundTransparency = value, true, 1
            t.Size, t.Position = UDim2.fromScale(0.94, i == 1 and 0.45 or 0.25), UDim2.fromScale(0.03, i == 1 and 0.1 or 0.66)
            t.TextColor3, t.Font, t.Parent = Color3.fromRGB(247, 222, 168), Enum.Font.GothamBold, surface
        end
    end
    for _, offset in ipairs({ -5, 5 }) do part(parent, "Part", "Post", Vector3.new(0.5, 4, 0.5), position + Vector3.new(offset, -3, 0), { 112, 79, 51 }, Enum.Material.Wood) end
    return board
end
local function prompt(parent, action, object)
    local p = Instance.new("ProximityPrompt")
    p.ActionText, p.ObjectText, p.MaxActivationDistance, p.RequiresLineOfSight = action, object, 12, false
    p.Parent = parent
    return p
end
local function pine(parent, x, z, height)
    part(parent, "Part", "PineTrunk", Vector3.new(1.2, height * 0.6, 1.2), Vector3.new(x, height * 0.3, z), { 91, 70, 53 }, Enum.Material.Wood)
    -- Crossed wedge boughs give a pointed, faceted conifer silhouette.
    for tier = 1, 3 do
        local width, y = (4 - tier) * 3, height * (0.27 + tier * 0.19)
        for quarter = 0, 3 do
            local angle = quarter * math.pi / 2
            local direction = Vector3.new(math.sin(angle), 0, math.cos(angle))
            local leaf = part(parent, "WedgePart", "PineBough", Vector3.new(width, height * 0.32, width / 2), Vector3.new(x, y, z) + direction * width / 4, { 43, 89 + tier * 6, 78 }, Enum.Material.Grass)
            leaf.CFrame = CFrame.new(leaf.Position) * CFrame.Angles(0, angle, 0)
            leaf.CanCollide, leaf.CanQuery = false, false
            local snow = part(parent, "WedgePart", "SnowBough", leaf.Size * 0.91, leaf.Position + Vector3.new(0, 0.34, 0), { 232, 243, 247 }, Enum.Material.Snow)
            snow.CFrame, snow.CanCollide, snow.CanQuery = CFrame.new(snow.Position) * CFrame.Angles(0, angle, 0), false, false
        end
    end
end
local function hut(parent, position, color)
    part(parent, "Part", "ShelterFloor", Vector3.new(12, 0.6, 11), position, { 121, 88, 62 }, Enum.Material.WoodPlanks)
    part(parent, "Part", "ShelterBack", Vector3.new(12, 9, 0.5), position + Vector3.new(0, 4.7, -5.2), color, Enum.Material.WoodPlanks)
    for _, x in ipairs({ -5.7, 5.7 }) do part(parent, "Part", "ShelterWall", Vector3.new(0.5, 9, 11), position + Vector3.new(x, 4.7, 0), color, Enum.Material.WoodPlanks) end
    part(parent, "Part", "SnowRoof", Vector3.new(14, 1, 13), position + Vector3.new(0, 9.5, 0), { 235, 245, 249 }, Enum.Material.Snow)
    local lantern = part(parent, "Part", "Lantern", Vector3.new(0.8, 1.1, 0.8), position + Vector3.new(4, 6, 4.8), { 255, 218, 142 }, Enum.Material.Neon)
    local light = Instance.new("PointLight")
    light.Color, light.Range, light.Brightness, light.Parent = Color3.fromRGB(255, 215, 148), 20, 1.1, lantern
    part(parent, "Part", "Bench", Vector3.new(7, 0.6, 2), position + Vector3.new(0, 2, -3.6), { 136, 98, 66 }, Enum.Material.WoodPlanks)
end
local function npc(parent, position, name, action)
    local model = Instance.new("Model") model.Name, model.Parent = name, parent
    local torso = part(model, "Part", "Torso", Vector3.new(2, 2, 1), position + Vector3.new(0, 3, 0), { 96, 109, 138 })
    local head = part(model, "Part", "Head", Vector3.new(1.6, 1, 1.2), position + Vector3.new(0, 4.5, 0), { 218, 171, 129 })
    for _, side in ipairs({ -1, 1 }) do
        part(model, "Part", "Arm", Vector3.new(1, 2, 1), position + Vector3.new(side * 1.5, 3, 0), { 96, 109, 138 })
        part(model, "Part", "Leg", Vector3.new(0.9, 2, 1), position + Vector3.new(side * 0.5, 1, 0), { 49, 60, 73 })
        local eye = part(model, "Part", "Eye", Vector3.new(0.1, 0.1, 0.08), head.Position + Vector3.new(side * 0.3, 0.1, 0.63), { 25, 33, 43 })
        eye.CanCollide = false
    end
    part(model, "Part", "Hat", Vector3.new(1.85, 0.45, 1.4), position + Vector3.new(0, 5.1, 0), { 192, 145, 84 })
    sign(parent, position + Vector3.new(0, 7.4, -0.5), name, action)
    return prompt(torso, action, name)
end
function Expansion.build(world)
    local callbacks = {}
    local oldTrees = {}
    for _, item in ipairs(world:GetChildren()) do
        if item.Name == "PineTrunk" then table.insert(oldTrees, item.Position) end
        if item.Name == "PineTrunk" or item.Name == "PineBoughs" or item.Name == "PineSnow" then item:Destroy() end
        if item.Name == "SnowyRidge" then
            -- Replace the original giant spheres with varied low rock ridges.
            item.Shape, item.Size, item.Position = Enum.PartType.Block, Vector3.new(55, 24, 38), Vector3.new(item.Position.X, 8, item.Position.Z)
            item.Orientation = Vector3.new(0, math.deg(math.atan2(item.Position.X, item.Position.Z)), 0)
        end
    end
    for i, position in ipairs(oldTrees) do if i % 2 == 0 then pine(world, position.X, position.Z, 19 + i % 7) end end
    for i, region in ipairs(Content.Regions) do
        local folder = Instance.new("Folder") folder.Name, folder.Parent = "Region_" .. region.id, world
        if i > 1 then
            part(folder, "Part", "Snowfield", Vector3.new(300, 8, 300), Vector3.new(region.x, -4, region.z), { 232, 241, 247 }, Enum.Material.Snow)
            local ice = part(folder, "Part", "FrozenLake", Vector3.new(2, region.radius * 2, region.radius * 2), Vector3.new(region.x, 1, region.z), region.color, Enum.Material.Ice)
            ice.Shape, ice.Orientation, ice.Reflectance = Enum.PartType.Cylinder, Vector3.new(0, 0, 90), 0.12
            for tree = 1, 16 do
                local angle = tree * math.pi / 8
                if math.sin(angle) > -0.65 then pine(folder, region.x + math.cos(angle) * (region.radius + 28), region.z + math.sin(angle) * (region.radius + 28), 18 + tree % 9) end
            end
            for ridge = 1, 10 do
                local angle = ridge * math.pi / 5
                local mountain = part(folder, "WedgePart", "Mountain", Vector3.new(52, 24 + ridge % 3 * 8, 34), Vector3.new(region.x + math.cos(angle) * 142, 10, region.z + math.sin(angle) * 142), { 173, 194, 209 }, Enum.Material.Slate)
                mountain.Orientation = Vector3.new(0, math.deg(angle), 0)
            end
            hut(folder, Vector3.new(region.x + 20, 0.5, region.z - region.radius - 14), { 77, 108, 119 })
        end
        local trailPosition = Vector3.new(region.x - 13, 5, region.z - region.radius - 12)
        local board = sign(folder, trailPosition, region.name, "TRAILS / PLAN YOUR NEXT TRIP")
        table.insert(callbacks, { prompt = prompt(board, "Travel & unlock lakes", "Trail board"), position = trailPosition, menu = "Map" })
        -- A short wooden dock leads from the trail stop onto the ice.
        part(folder, "Part", "Dock", Vector3.new(7, 0.4, 21), Vector3.new(region.x + 10, 2.4, region.z - region.radius + 3), { 125, 95, 69 }, Enum.Material.WoodPlanks)
        for _, side in ipairs({ -3.5, 3.5 }) do
            for n = 0, 2 do part(folder, "Part", "DockPost", Vector3.new(0.5, 4.5, 0.5), Vector3.new(region.x + 10 + side, 2.2, region.z - region.radius - 6 + n * 9), { 90, 70, 53 }, Enum.Material.Wood) end
        end
        hut(folder, Vector3.new(region.x - region.radius * 0.65, 2.5, region.z + 12), { 93, 110, 134 })
        if i == 3 or i == 5 then
            for c = 1, 7 do
                local crystal = part(folder, "WedgePart", "IceCrystal", Vector3.new(3, 7 + c % 3 * 3, 3), Vector3.new(region.x + region.radius + 12, 3, region.z + c * 5 - 20), region.color, Enum.Material.Glass)
                crystal.Transparency = 0.18
            end
        end
    end
    hut(world, Vector3.new(-45, 0.5, -102), { 123, 83, 69 })
    hut(world, Vector3.new(45, 0.5, -110), { 78, 105, 111 })
    table.insert(callbacks, { prompt = npc(world, Vector3.new(-28, 0, -83), "Nolan / Trail guide", "Fishing guide"), position = Vector3.new(-28, 4, -83), menu = "Guide" })
    table.insert(callbacks, { prompt = npc(world, Vector3.new(28, 0, -91), "Iris / Outpost tasks", "Quests & rewards"), position = Vector3.new(28, 4, -91), menu = "Quests" })
    return callbacks
end
return Expansion
