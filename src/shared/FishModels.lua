local Config = require(script.Parent.Config)
local FishModels = {}
local function part(model, class, name, size, position, color)
    local p = Instance.new(class)
    p.Name, p.Size, p.CFrame, p.Color = name, size, CFrame.new(position), color
    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
    p.Material, p.Parent = Enum.Material.SmoothPlastic, model
    return p
end
function FishModels.build(id, rgb, silhouette)
    local species = Config.findFish(id) or Config.Fish[1]
    rgb = silhouette and { 35, 51, 64 } or rgb or species.color
    local color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    local dark = Color3.fromRGB(rgb[1] * 0.55, rgb[2] * 0.55, rgb[3] * 0.55)
    local model = Instance.new("Model")
    model.Name = species.id
    local length, height = species.style == "panfish" and 2.8 or 4, species.style == "panfish" and 1.5 or 0.9
    local body = part(model, "Part", "Body", Vector3.new(length, height, 0.75), Vector3.new(), color)
    body.Shape, model.PrimaryPart = Enum.PartType.Ball, body
    local head = part(model, "Part", "Head", Vector3.new(1.05, height * 0.85, 0.7), Vector3.new(length * 0.36, 0, 0), color)
    head.Shape = Enum.PartType.Ball
    for _, side in ipairs({ -1, 1 }) do
        local tail = part(model, "WedgePart", "Tail", Vector3.new(0.8, height * 0.6, 0.22), Vector3.new(-length / 2 - 0.12, side * height * 0.23, 0), dark)
        tail.CFrame = tail.CFrame * CFrame.Angles(0, 0, math.rad(side * 55))
        local eye = part(model, "Part", "Eye", Vector3.new(0.19, 0.19, 0.09), Vector3.new(length * 0.43, height * 0.15, side * 0.35), silhouette and color or Color3.fromRGB(249, 237, 192))
        eye.Shape = Enum.PartType.Ball
        local pupil = part(model, "Part", "Pupil", Vector3.new(0.09, 0.1, 0.07), eye.Position + Vector3.new(0.025, 0, side * 0.04), silhouette and color or Color3.fromRGB(14, 29, 39))
        pupil.Shape = Enum.PartType.Ball
        local fin = part(model, "WedgePart", "PectoralFin", Vector3.new(0.65, 0.48, 0.1), Vector3.new(0.25, -height * 0.16, side * 0.44), dark)
        fin.CFrame = fin.CFrame * CFrame.Angles(math.rad(side * 35), 0, math.rad(-20))
    end
    part(model, "WedgePart", "DorsalFin", Vector3.new(length * 0.36, height * 0.4, 0.12), Vector3.new(-0.3, height * 0.48, 0), dark)
    if species.style == "catfish" then
        for _, side in ipairs({ -1, 1 }) do
            local whisker = part(model, "Part", "Whisker", Vector3.new(0.8, 0.045, 0.045), Vector3.new(length * 0.49, -0.1, side * 0.4), dark)
            whisker.CFrame = whisker.CFrame * CFrame.Angles(0, math.rad(side * 45), 0)
        end
    else
        for i = 1, 4 do
            local stripe = part(model, "Part", "Marking", Vector3.new(0.09, height * 0.65, 0.04), Vector3.new(-length * 0.25 + i * length * 0.13, 0.07, 0.375), dark)
            stripe.Transparency = 0.35
        end
    end
    return model
end
return FishModels
