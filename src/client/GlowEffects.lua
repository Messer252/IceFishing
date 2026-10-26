local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Rules = require(ReplicatedStorage.Shared.GlowRules)
local Effects = {}
function Effects.start(remotes)
    local folder = Instance.new("Folder") folder.Name, folder.Parent = "LocalGlowEvents", workspace
    local visuals, reduced = {}, false
    local bloom = Instance.new("BloomEffect")
    bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold, bloom.Parent = "FrostbiteGlowBloom", 0.18, 18, 1.6, Lighting
    local function cylinder(parent, name, diameter, y, zone, alpha)
        local p = Instance.new("Part")
        p.Name, p.Size = name, Vector3.new(0.025, diameter, diameter)
        p.CFrame = CFrame.new(zone.x, y, zone.z) * CFrame.Angles(0, 0, math.pi / 2)
        p.Shape, p.Material, p.Color = Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(zone.color[1], zone.color[2], zone.color[3])
        p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
        p.Transparency, p.Parent = alpha, parent
        return p
    end
    local function build(zone)
        local model = Instance.new("Model") model.Name, model.Parent = "Glow_" .. zone.id, folder
        local disc = cylinder(model, "LightThroughIce", zone.radius * 2, 2.025, zone, 0.88)
        local center = cylinder(model, "DeepGlow", zone.radius * 1.15, 1.10, zone, 0.35)
        for i = 1, 24 do
            local function point(angle) return Vector3.new(zone.x + math.cos(angle) * zone.radius, 2.04, zone.z + math.sin(angle) * zone.radius) end
            local a, b = point((i - 1) * math.pi / 12), point(i * math.pi / 12)
            local edge = Instance.new("Part")
            edge.Name, edge.Size = "BonusBoundary", Vector3.new((b - a).Magnitude, 0.025, 0.055)
            edge.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
            edge.Material, edge.Color, edge.Transparency = Enum.Material.Neon, center.Color, 0.5
            edge.Anchored, edge.CanCollide, edge.CanQuery, edge.CanTouch, edge.CastShadow, edge.Parent = true, false, false, false, false, model
        end
        local light = Instance.new("PointLight")
        light.Color, light.Range, light.Brightness, light.Shadows, light.Parent = center.Color, zone.radius * 2.4, 1.3, false, center
        local orbs = {}
        for i = 1, 8 do
            local p = Instance.new("Part")
            p.Name, p.Size, p.Shape = "UnderIceLight", Vector3.new(0.35, 0.35, 0.35), Enum.PartType.Ball
            p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
            p.Material, p.Color, p.Parent = Enum.Material.Neon, center.Color, model
            table.insert(orbs, p)
        end
        local gui = Instance.new("BillboardGui")
        gui.Adornee, gui.Size, gui.StudsOffset, gui.MaxDistance, gui.AlwaysOnTop, gui.Parent = disc, UDim2.fromOffset(240, 52), Vector3.new(0, 2.4, 0), 85, false, disc
        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundTransparency, label.Font, label.TextSize = UDim2.fromScale(1, 1), 1, Enum.Font.GothamBold, 13
        label.TextColor3, label.TextStrokeTransparency, label.Parent = center.Color, 0.35, gui
        return { model = model, zone = zone, disc = disc, light = light, orbs = orbs, label = label }
    end
    remotes.Event.OnClientEvent:Connect(function(kind, data)
        if kind == "profile" then reduced = data.settings.reducedEffects
        elseif kind == "glowZones" then
            local keep = {}
            for _, zone in ipairs(data) do
                keep[zone.id] = true
                if not visuals[zone.id] then visuals[zone.id] = build(zone) end
                visuals[zone.id].zone = zone
            end
            for id, visual in pairs(visuals) do if not keep[id] then visual.model:Destroy() visuals[id] = nil end end
        end
    end)
    local accumulator = 0
    RunService.RenderStepped:Connect(function(dt)
        accumulator = accumulator + dt
        if accumulator < 0.05 then return end
        accumulator = 0
        local now = workspace:GetServerTimeNow()
        bloom.Enabled = not reduced and next(visuals) ~= nil
        for id, visual in pairs(visuals) do
            local zone = visual.zone
            if now >= zone.expiresAt then visual.model:Destroy() visuals[id] = nil
            else
                visual.disc.Transparency = reduced and 0.88 or 0.87 + math.sin(now * 1.7) * 0.025
                visual.light.Brightness = reduced and 0.8 or 1.3 + math.sin(now * 1.5) * 0.3
                visual.label.Text = zone.name .. " / " .. math.ceil(zone.expiresAt - now) .. "s\n" .. Rules.label(zone)
                for i, orb in ipairs(visual.orbs) do
                    orb.Transparency = reduced and i > 3 and 1 or 0.08
                    local angle = i * math.pi / 4 + (reduced and 0 or now * 0.13)
                    local radius = zone.radius * (0.32 + (i % 3) * 0.14)
                    orb.Position = Vector3.new(zone.x + math.cos(angle) * radius, 1.20 + math.sin(now + i) * 0.12, zone.z + math.sin(angle) * radius)
                end
            end
        end
    end)
end
return Effects
