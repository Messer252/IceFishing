local Config = require(script.Parent.Config)
local Appearance = require(script.Parent.FishAppearance)
local FishModels = {}
local function mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

function FishModels.build(id, tint, silhouette, variant, detail)
    local species = Config.findFish(id) or Config.Fish[1]
    local recipe = Appearance[species.id] or Appearance.perch
    local high = detail ~= "low"
    local l, h, w = recipe.length, recipe.height, recipe.depth
    local function color(role)
        if silhouette then return Color3.fromRGB(31, 47, 59) end
        local rgb = recipe[role] or recipe.body
        -- Normal fish use natural species colors, not the rarity/UI palette.
        -- Variants tint the skin while retaining contrasting markings.
        if tint and variant and variant ~= "Normal" then
            local amount = role == "marking" and 0.12 or role == "back" and 0.32 or 0.5
            rgb = mix(rgb, tint, amount)
        end
        return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    end
    local iris = recipe.iris or { 223, 190, 98 }
    local model = Instance.new("Model")
    model.Name = species.id
    model:SetAttribute("SpeciesId", species.id)
    model:SetAttribute("Anatomy", recipe.head)
    model:SetAttribute("Pattern", recipe.pattern)
    model:SetAttribute("Variant", variant or "Normal")
    local function part(name, size, position, role, class, rotation)
        local p = Instance.new(class or "Part")
        p.Name, p.Size, p.CFrame = name, size, CFrame.new(position)
        if rotation then p.CFrame = p.CFrame * rotation end
        p.Color = type(role) == "string" and color(role) or role
        p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
        p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        p.Material, p.Reflectance = Enum.Material.SmoothPlastic, 0.025
        p.Parent = model
        return p
    end
    local function oval(name, size, position, role)
        local p = part(name, size, position, role)
        p.Shape = Enum.PartType.Ball
        return p
    end
    local function link(name, a, b, thickness, role)
        local delta = b - a
        local p = part(name, Vector3.new(delta.Magnitude, thickness, thickness), (a + b) / 2, role)
        p.Shape = Enum.PartType.Cylinder
        p.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
        return p
    end
    local function fin(name, x, y, z, length, height, role, angle)
        -- Wedges have a Y/Z triangular cross section; rotate it into X/Y.
        return part(name, Vector3.new(0.065, height, length), Vector3.new(x, y, z), role or "fin", "WedgePart",
            CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(angle or 0, 0, 0))
    end
    local body = oval("Body", Vector3.new(l * 0.88, h, w), Vector3.new(-l * 0.04, 0, 0), "body")
    model.PrimaryPart = body
    oval("DarkBack", Vector3.new(l * 0.77, h * 0.60, w * 0.91), Vector3.new(-l * 0.06, h * 0.19, 0), "back")
    oval("PaleBelly", Vector3.new(l * 0.75, h * 0.57, w * 0.88), Vector3.new(-l * 0.015, -h * 0.21, 0), "belly")
    oval("TailPeduncle", Vector3.new(l * 0.23, h * 0.37, w * 0.48), Vector3.new(-l * 0.43, -h * 0.025, 0), "body")
    local headL = l * (recipe.head == "bass" and 0.31 or 0.27)
    local headH = h * (recipe.head == "catfish" and 0.56 or recipe.head == "small" and 0.72 or 0.80)
    local headW = w * (recipe.head == "catfish" and 1.24 or recipe.head == "small" and 0.72 or 0.92)
    local headX = l * 0.32
    oval("Head", Vector3.new(headL, headH, headW), Vector3.new(headX, -h * 0.025, 0), "body")
    local snout = recipe.snout or 0
    local noseX = headX + headL * 0.43
    if snout > 0 then
        local snoutH = recipe.head == "gar" and h * 0.18 or h * 0.28
        oval("Snout", Vector3.new(snout, snoutH, headW * (recipe.head == "gar" and 0.43 or 0.76)), Vector3.new(noseX + snout * 0.32, -h * 0.08, 0), "back")
        oval("LowerJaw", Vector3.new(snout * 0.92, h * 0.10, headW * 0.65), Vector3.new(noseX + snout * 0.37, -h * 0.20, 0), "belly")
        noseX = noseX + snout * 0.77
    end
    local mouthSize = recipe.mouth or (recipe.head == "catfish" and 0.48 or recipe.head == "small" and 0.18 or 0.27)
    if recipe.head == "sturgeon" then
        oval("UnderslungMouth", Vector3.new(0.30, 0.055, 0.25), Vector3.new(headX + 0.12, -headH * 0.48, 0), silhouette and color("body") or Color3.fromRGB(30, 39, 35))
    else
        local mouthY = -h * 0.12
        local mouthH = snout > 0 and h * (recipe.head == "gar" and 0.12 or recipe.head == "leviathan" and 0.34 or 0.20) or headH * mouthSize
        local mouthW = headW * (recipe.head == "gar" and 0.38 or 0.66)
        local cavity = silhouette and color("body") or Color3.fromRGB(28, 35, 29)
        oval("MouthOpening", Vector3.new(0.055, mouthH, mouthW), Vector3.new(noseX, mouthY, 0), cavity)
        local segments = high and 10 or 6
        for i = 1, segments do
            local function point(t) return Vector3.new(noseX + 0.018, mouthY + math.cos(t) * mouthH * 0.52, math.sin(t) * mouthW * 0.52) end
            link("Lip", point((i - 1) * math.pi * 2 / segments), point(i * math.pi * 2 / segments), 0.035, "belly")
        end
        if recipe.head == "bass" or recipe.head == "catfish" then
            oval("ProtrudingJaw", Vector3.new(headL * 0.67, headH * 0.17, headW * 0.72), Vector3.new(headX + headL * 0.22, -headH * 0.34, 0), "belly")
        end
    end
    local hulls = {
        { -l * 0.04, 0, l * 0.88, h, w }, { -l * 0.06, h * 0.19, l * 0.77, h * 0.60, w * 0.91 },
        { -l * 0.015, -h * 0.21, l * 0.75, h * 0.57, w * 0.88 },
    }
    local function surface(x, y)
        local z = 0
        for _, hull in ipairs(hulls) do
            local inside = 1 - ((x - hull[1]) / (hull[3] / 2)) ^ 2 - ((y - hull[2]) / (hull[4] / 2)) ^ 2
            if inside > 0 then z = math.max(z, hull[5] / 2 * math.sqrt(inside)) end
        end
        return z + 0.014
    end
    local function patch(name, x, y, width, height, role, side, angle)
        local p = oval(name, Vector3.new(width, height, 0.035), Vector3.new(x, y, side * surface(x, y)), role)
        if angle then p.CFrame = p.CFrame * CFrame.Angles(0, 0, angle) end
        return p
    end
    local function bars(count, role)
        for i = 1, count do
            local x = -l * 0.34 + i / (count + 1) * l * 0.65
            for row = -1, 1 do for _, side in ipairs({ -1, 1 }) do
                local bar = patch("VerticalBar", x + math.sin(i) * row * l * 0.004, row * h * 0.21, l * math.min(0.047, 0.50 / count * 0.55), h * (row == 0 and 0.29 or 0.36), role, side)
                if row == 0 then bar.Shape = Enum.PartType.Block end
            end end
        end
    end
    local function spots(count, role, wide)
        for i = 1, count do
            local column = (i - 1) % (high and 8 or 5)
            local row = math.floor((i - 1) / (high and 8 or 5))
            local x = -l * 0.33 + column / ((high and 8 or 5) - 1) * l * 0.58 + math.sin(i * 2.7) * l * 0.012
            local y = (row % 3 - 1) * h * 0.22 + math.sin(i * 1.7) * h * 0.055
            for _, side in ipairs({ -1, 1 }) do
                patch("SpeciesSpot", x, y, l * (wide and 0.065 or 0.025), h * (wide and 0.075 or 0.08), role, side, math.sin(i) * 0.5)
            end
        end
    end
    for _, side in ipairs({ -1, 1 }) do
        local eye = oval("Iris", Vector3.new(0.18, 0.18, 0.07) * (recipe.glassEye and 1.25 or 1), Vector3.new(headX + headL * 0.12, headH * 0.21, side * headW * 0.43),
            silhouette and color("body") or (variant == "Albino" and Color3.fromRGB(194, 93, 88) or Color3.fromRGB(iris[1], iris[2], iris[3])))
        eye.Reflectance = recipe.glassEye and 0.25 or 0.05
        oval("Pupil", Vector3.new(0.09, 0.11, 0.045), eye.Position + Vector3.new(0.014, 0, side * 0.035), silhouette and color("body") or Color3.fromRGB(14, 24, 24))
        oval("GillPlate", Vector3.new(headL * 0.20, headH * 0.66, 0.035), Vector3.new(headX - headL * 0.26, -h * 0.02, side * headW * 0.45), "body")
        for i = 1, 3 do
            local function point(index)
                local y = headH * (0.35 - index * 0.23)
                return Vector3.new(headX - headL * (0.21 + math.sin(index / 3 * math.pi) * 0.08), y, side * headW * 0.46)
            end
            link("GillSlit", point(i - 1), point(i), 0.022, "back")
        end
        if recipe.ear then
            oval("OpercularSpot", Vector3.new(l * 0.09, h * 0.20, 0.045), Vector3.new(headX - headL * 0.35, h * 0.08, side * headW * 0.47), silhouette and color("body") or Color3.fromRGB(20, 39, 38))
            if recipe.pattern == "pumpkinseed" then
                oval("OrangeEarEdge", Vector3.new(l * 0.035, h * 0.17, 0.05), Vector3.new(headX - headL * 0.43, h * 0.08, side * headW * 0.48), "spot")
            end
        end
        fin("PectoralFin", l * 0.18, -h * 0.28, side * w * 0.46, l * 0.19, h * 0.38, "fin", side * 0.55)
        fin("PelvicFin", -l * 0.05, -h * 0.48, side * w * 0.22, l * 0.13, h * 0.28, "fin", math.pi)
        if recipe.whiteFins then link("WhiteFinEdge", Vector3.new(l * 0.23, -h * 0.25, side * w * 0.5), Vector3.new(l * 0.08, -h * 0.47, side * w * 0.55), 0.045, "belly") end
    end
    local function dorsal(x, width, height, spines)
        fin("DorsalFin", x, h * 0.42 + height / 2, 0, width, height, "fin")
        for i = 1, spines do
            local xx = x - width / 2 + width * i / (spines + 1)
            fin("DorsalSpine", xx, h * 0.46 + height * 0.55, 0, width / (spines + 1) * 0.55, height * (0.75 + 0.25 * math.sin(i / (spines + 1) * math.pi)), "back")
        end
    end
    if recipe.dorsal == "rear" then dorsal(-l * 0.29, l * 0.18, h * 0.50, high and 3 or 1)
    elseif recipe.dorsal == "long" then dorsal(-l * 0.16, l * 0.52, h * 0.28, 0) dorsal(l * 0.15, l * 0.09, h * 0.24, 0)
    elseif recipe.dorsal == "double" then dorsal(l * 0.08, l * 0.23, h * 0.51, high and 6 or 3) dorsal(-l * 0.20, l * 0.18, h * 0.30, 0)
    elseif recipe.dorsal == "notched" then dorsal(l * 0.09, l * 0.22, h * 0.32, high and 4 or 2) dorsal(-l * 0.12, l * 0.20, h * 0.43, 0)
    elseif recipe.dorsal == "crown" then dorsal(-l * 0.04, l * 0.46, h * 0.55, high and 7 or 4)
    elseif recipe.dorsal == "sail" then dorsal(-l * 0.05, l * 0.55, h * 0.72, high and 5 or 2)
    elseif recipe.dorsal == "catfish" then dorsal(l * 0.08, l * 0.12, h * 0.50, 1)
    else dorsal(-l * 0.04, l * 0.24, h * 0.40, high and 3 or 1) end
    if recipe.adipose then oval("AdiposeFin", Vector3.new(l * 0.09, h * 0.22, 0.10), Vector3.new(-l * 0.29, h * 0.40, 0), "fin") end
    fin("AnalFin", -l * 0.25, -h * 0.48, 0, l * (recipe.head == "burbot" and 0.40 or 0.18), h * 0.26, "fin", math.pi)
    local tailX, tailLength, tailHeight = -l * 0.52, l * 0.20, h * (recipe.tail == "deepfork" and 1.42 or 1.10)
    if recipe.tail == "round" or recipe.tail == "truncate" or recipe.tail == "fan" then
        local p = oval("RoundedTail", Vector3.new(tailLength * (recipe.tail == "fan" and 0.65 or 0.85), tailHeight, 0.14), Vector3.new(tailX - tailLength * 0.16, 0, 0), "fin")
        if recipe.tail == "truncate" then p.Shape = Enum.PartType.Block p.Size = Vector3.new(tailLength * 0.57, tailHeight * 0.83, 0.13) end
    elseif recipe.tail == "veil" then
        for i = -1, 1 do
            local flow = oval("FlowingTail", Vector3.new(tailLength * 1.5, tailHeight * 0.48, 0.10), Vector3.new(tailX - tailLength * 0.23, i * tailHeight * 0.27, 0), "fin")
            flow.CFrame = flow.CFrame * CFrame.Angles(0, 0, -i * 0.22)
        end
    else
        for _, side in ipairs({ -1, 1 }) do
            local scale = recipe.tail == "asymmetric" and (side == 1 and 1.5 or 0.65) or 1
            fin("CaudalLobe", tailX - tailLength * 0.1, side * tailHeight * 0.27 * scale, 0, tailLength, tailHeight * 0.59 * scale, "fin", side * 0.42)
        end
    end
    for i = 1, high and 7 or 3 do
        local fraction = i / ((high and 7 or 3) + 1) - 0.5
        if math.abs(fraction) > 0.1 or recipe.tail == "fan" or recipe.tail == "round" or recipe.tail == "truncate" or recipe.tail == "veil" then
            link("TailRay", Vector3.new(-l * 0.46, 0, 0.085), Vector3.new(tailX - tailLength * 0.32, fraction * tailHeight * 0.88, 0.085), 0.022, "back")
        end
    end
    if recipe.whiteTail then link("WhiteTailTip", Vector3.new(tailX - tailLength * 0.35, -tailHeight * 0.2, 0.10), Vector3.new(tailX - tailLength * 0.48, -tailHeight * 0.48, 0.10), 0.075, "belly") end
    local pattern = recipe.pattern
    if pattern == "bars" then bars(high and recipe.bars or math.min(5, recipe.bars), "marking")
    elseif pattern == "bluegill" then bars(high and 6 or 4, "marking")
    elseif pattern == "horizontal" or pattern == "lateral" or pattern == "rainbow" then
        local rows = pattern == "horizontal" and 5 or 1
        for row = 1, rows do for i = 1, high and 8 or 5 do for _, side in ipairs({ -1, 1 }) do
            local x = -l * 0.33 + i / ((high and 8 or 5) + 1) * l * 0.62
            patch(pattern == "rainbow" and "RoseLateralStripe" or "LateralStripe", x, (row - (rows + 1) / 2) * h * 0.13, l * 0.11,
                h * (pattern == "horizontal" and 0.026 or 0.13), pattern == "rainbow" and "spot" or "marking", side)
        end end end
        if pattern == "rainbow" then spots(high and 18 or 8, "marking") end
    elseif pattern == "pike" then spots(high and 21 or 10, "spot", true)
    elseif pattern == "char" or pattern == "laketrout" then spots(high and 22 or 10, "spot")
    elseif pattern == "crappie" or pattern == "mottle" then
        local spotsCount = pattern == "crappie" and (high and 30 or 14) or (high and 18 or 9)
        local function hash(i, seed) local n = math.sin(i * seed) * 43758.5453 return n - math.floor(n) end
        for i = 1, spotsCount do for _, side in ipairs({ -1, 1 }) do
            local x = -l * 0.32 + hash(i, 12.9898) * l * 0.59
            local y = (hash(i, 78.233) - 0.5) * h * 0.59
            patch("MottledPatch", x, y, l * (pattern == "crappie" and 0.025 or 0.04) * (1 + hash(i, 19.13)),
                h * (0.06 + hash(i, 38.91) * 0.10), i % 5 == 0 and pattern == "mottle" and "spot" or "marking", side, i * 0.8)
        end end
    elseif pattern == "pumpkinseed" then
        spots(high and 16 or 8, "spot")
        for _, side in ipairs({ -1, 1 }) do for i = 1, 4 do
            link("TurquoiseCheekRay", Vector3.new(headX - headL * 0.12, -headH * 0.18, side * headW * 0.48), Vector3.new(headX + headL * 0.28, headH * (i * 0.14 - 0.4), side * headW * 0.49), 0.038, "marking")
        end end
    elseif pattern == "walleye" then bars(high and 5 or 3, "marking") spots(high and 8 or 4, "spot")
    elseif pattern == "scutes" or pattern == "armor" then
        for i = 1, high and 8 or 5 do
            local x = -l * 0.35 + i / ((high and 8 or 5) + 1) * l * 0.66
            fin("DorsalScute", x, h * 0.46, 0, l * 0.055, h * (pattern == "armor" and 0.23 or 0.12), "marking")
            for _, side in ipairs({ -1, 1 }) do for _, yy in ipairs({ -0.19, 0.20 }) do
                patch("LateralScute", x, yy * h, l * 0.065, h * 0.16, "marking", side, math.pi / 4)
            end end
        end
    elseif pattern == "diamonds" then
        for row = -1, 1 do for i = 1, high and 10 or 5 do for _, side in ipairs({ -1, 1 }) do
            local x = -l * 0.36 + i / ((high and 10 or 5) + 1) * l * 0.68 + (row % 2) * l * 0.018
            local scale = patch("GanoidScale", x, row * h * 0.20, l * 0.027, h * 0.13, "marking", side, math.pi / 4)
            scale.Shape = Enum.PartType.Block
        end end end
    elseif pattern == "koi" then
        for i = 1, 8 do for _, side in ipairs({ -1, 1 }) do
            patch("KoiColorPatch", -l * 0.27 + (i % 4) * l * 0.16, (i < 5 and 0.14 or -0.15) * h, l * 0.14, h * 0.30, i % 3 == 0 and "spot" or "marking", side, i * 0.4)
        end end
    elseif pattern == "snowfin" or pattern == "glow" then
        for i = 1, high and 12 or 6 do for _, side in ipairs({ -1, 1 }) do
            local dot = patch("LuminousPearl", -l * 0.34 + i / ((high and 12 or 6) + 1) * l * 0.66, math.sin(i * 0.7) * h * 0.18, l * 0.025, h * 0.10, "marking", side)
            if recipe.glow and not silhouette then dot.Material = Enum.Material.Neon end
        end end
    end
    if recipe.head == "leviathan" then
        for i = 1, 3 do fin("CranialIceCrest", headX + (i - 2) * headL * 0.18, headH * 0.50, 0, headL * 0.16, h * (0.25 + i * 0.05), "marking") end
    end
    local barbelCount = recipe.barbels or 0
    for i = 1, barbelCount do
        local side = i % 2 == 0 and -1 or 1
        local start, finish
        if barbelCount == 1 then start, finish = Vector3.new(noseX - 0.15, -headH * 0.35, 0), Vector3.new(noseX + 0.18, -headH * 0.98, 0)
        elseif recipe.head == "sturgeon" then
            start = Vector3.new(headX + headL * 0.27, -headH * 0.38, (i - 2.5) * w * 0.15)
            finish = start + Vector3.new(0.08, -h * 0.42, 0)
        else
            start = Vector3.new(noseX - 0.10, -headH * 0.13, side * headW * (0.17 + math.floor((i - 1) / 2) * 0.07))
            finish = start + Vector3.new(-0.3 - i * 0.04, -0.15 - i * 0.025, side * (recipe.head == "catfish" and 0.65 or 0.28))
        end
        local middle = (start + finish) / 2 + Vector3.new(0.10, 0.06, 0)
        link("Barbel", start, middle, 0.035, "belly") link("BarbelTip", middle, finish, 0.022, "belly")
    end
    if recipe.teeth and high then
        for i = 1, 5 do for _, side in ipairs({ -1, 1 }) do
            fin("Tooth", noseX - 0.15 - i * 0.12, -h * 0.17, side * headW * 0.22, 0.055, 0.085, "belly")
        end end
    end
    return model
end
return FishModels
