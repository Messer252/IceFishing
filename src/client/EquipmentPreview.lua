local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Equipment = require(ReplicatedStorage.Shared.Equipment)
local FishModels = require(ReplicatedStorage.Shared.FishModels)
local Preview = {}
local views, dragging = {}, nil

local function mountModel(viewport, model)
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    model.Parent = world
    local bounds, size = model:GetBoundingBox()
    model:PivotTo(CFrame.new(-bounds.Position) * model:GetPivot())
    local base = model:GetPivot()
    local camera = Instance.new("Camera")
    camera.FieldOfView = 36
    camera.Parent, viewport.CurrentCamera = viewport, camera
    viewport.Ambient, viewport.LightColor = Color3.fromRGB(180, 198, 213), Color3.fromRGB(255, 236, 209)
    viewport.LightDirection = Vector3.new(-1, -0.6, -1)
    local view = { model = model, camera = camera, viewport = viewport, base = base,
        angle = 0.4, height = size.Y, width = math.max(size.X, size.Z), zoom = 1 }
    views[viewport] = view
    viewport.Active = true
    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = { view = view, input = input, x = input.Position.X }
        end
    end)
    viewport.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then view.zoom = math.max(0.75, math.min(1.5, view.zoom - input.Position.Z * 0.1)) end
    end)
    viewport.Destroying:Connect(function()
        views[viewport] = nil
        if dragging and dragging.view == view then dragging = nil end
    end)
end

function Preview.mount(viewport, category, id) mountModel(viewport, Equipment.build(category, id)) end
function Preview.fish(viewport, species, color, silhouette) mountModel(viewport, FishModels.build(species, color, silhouette)) end
local function visible(viewport)
    local node = viewport
    while node do
        if node:IsA("GuiObject") and not node.Visible then return false end
        node = node.Parent
    end
    return true
end

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragging.input) then
        dragging.view.angle = dragging.view.angle + (input.Position.X - dragging.x) * 0.012
        dragging.x = input.Position.X
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if dragging and (input == dragging.input or input.UserInputType == Enum.UserInputType.MouseButton1) then dragging = nil end
end)
UserInputService.WindowFocusReleased:Connect(function() dragging = nil end)

function Preview.step(dt)
    for viewport, v in pairs(views) do
        if viewport.Parent and visible(viewport) then
            if not dragging or dragging.view ~= v then v.angle = v.angle + dt * 0.35 end
            v.model:PivotTo(CFrame.Angles(0, v.angle, 0) * v.base)
            local aspect = math.max(0.2, viewport.AbsoluteSize.X / math.max(1, viewport.AbsoluteSize.Y))
            local distance = math.max(v.height, v.width / aspect) / (2 * math.tan(math.rad(18))) * 1.22 * v.zoom
            v.camera.CFrame = CFrame.lookAt(Vector3.new(0, v.height * 0.06, distance), Vector3.new())
        end
    end
end
return Preview
