-- Minimal geometry-only Roblox API fakes. No rendering/physics emulation.
local Support = {}
local Vec, CF = {}, {}
local function vector(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vec) end
Vec.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then return v / v.Magnitude end
    return Vec[k]
end
Vec.__add = function(a, b) return vector(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vec.__sub = function(a, b) return vector(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vec.__unm = function(a) return vector(-a.X, -a.Y, -a.Z) end
Vec.__mul = function(a, b) return vector(a.X * b, a.Y * b, a.Z * b) end
Vec.__div = function(a, b) return vector(a.X / b, a.Y / b, a.Z / b) end
function Vec:Cross(b) return vector(self.Y * b.Z - self.Z * b.Y, self.Z * b.X - self.X * b.Z, self.X * b.Y - self.Y * b.X) end
local function frame(position, rotation)
    return setmetatable({ Position = position or vector(), rotation = rotation or { 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, CF)
end
CF.__index = CF
local function rotate(r, v) return vector(r[1] * v.X + r[2] * v.Y + r[3] * v.Z, r[4] * v.X + r[5] * v.Y + r[6] * v.Z, r[7] * v.X + r[8] * v.Y + r[9] * v.Z) end
CF.__mul = function(a, b)
    local r = {}
    for row = 0, 2 do for col = 0, 2 do
        local value = 0 for k = 0, 2 do value = value + a.rotation[row * 3 + k + 1] * b.rotation[k * 3 + col + 1] end
        r[row * 3 + col + 1] = value
    end end
    return frame(a.Position + rotate(a.rotation, b.Position), r)
end
local methods = {}
local function instance(class)
    return setmetatable({ properties = { ClassName = class, Name = class }, children = {}, attributes = {} }, {
        __index = function(t, k)
            if methods[k] then return methods[k] end
            if k == "Position" and t.properties.CFrame then return t.properties.CFrame.Position end
            return t.properties[k]
        end,
        __newindex = function(t, k, v)
            t.properties[k] = v
            if k == "Parent" and v then table.insert(v.children, t) end
        end,
    })
end
function methods:SetAttribute(k, v) self.attributes[k] = v end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:GetChildren() return self.children end
function methods:GetDescendants() return self.children end
function methods:FindFirstChild(name) for _, p in ipairs(self.children) do if p.Name == name then return p end end end
function methods:IsA(class) return class == self.ClassName or class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "WedgePart") end
function Support.load()
    local config, recipes = dofile("src/shared/Config.lua"), dofile("src/shared/FishAppearance.lua")
    local enum = setmetatable({}, { __index = function(t, k)
        local values = setmetatable({}, { __index = function(_, key) return key end }) rawset(t, k, values) return values
    end })
    local env = setmetatable({
        script = { Parent = { Config = config, FishAppearance = recipes } }, require = function(module) return module end,
        Instance = { new = instance }, Enum = enum, Vector3 = { new = vector },
        Color3 = { fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end },
        CFrame = {
            new = function(x, y, z) return frame(type(x) == "table" and x or vector(x, y, z)) end,
            Angles = function(x, y, z)
                local sx, cx, sy, cy, sz, cz = math.sin(x), math.cos(x), math.sin(y), math.cos(y), math.sin(z), math.cos(z)
                return frame(nil, { cy * cz, -cy * sz, sy, cx * sz + sx * sy * cz, cx * cz - sx * sy * sz, -sx * cy,
                    sx * sz - cx * sy * cz, sx * cz + cx * sy * sz, cx * cy })
            end,
            lookAt = function(a, b)
                local back = (a - b).Unit
                local right = vector(0, 1, 0):Cross(back)
                if right.Magnitude < 0.001 then right = vector(1, 0, 0) else right = right.Unit end
                local up = back:Cross(right)
                return frame(a, { right.X, up.X, back.X, right.Y, up.Y, back.Y, right.Z, up.Z, back.Z })
            end,
        },
    }, { __index = _G })
    return assert(loadfile("src/shared/FishModels.lua", "t", env))(), config, recipes
end
return Support
