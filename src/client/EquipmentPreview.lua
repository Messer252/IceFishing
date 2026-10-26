local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Equipment = require(ReplicatedStorage.Shared.Equipment)
local FishModels = require(ReplicatedStorage.Shared.FishModels)
local Preview = {}
local views, dragging = {}, nil

local function visible(viewport)
    local node = viewport
    local position, size = viewport.AbsolutePosition, viewport.AbsoluteSize
    while node do
        if node:IsA("GuiObject") and not node.Visible then return false end
        if node:IsA("ScrollingFrame") then
            local p, s = node.AbsolutePosition, node.AbsoluteSize
            if position.Y + size.Y < p.Y - 64 or position.Y > p.Y + s.Y + 64
                or position.X + size.X < p.X or position.X > p.X + s.X then return false end
        end
        node = node.Parent
    end
    return true
end
local function initialize(view)
    local viewport = view.viewport
    local world = Instance.new("WorldModel") world.Parent = viewport
    local model = view.factory()
    model.Parent = world
    local bounds, size = model:GetBoundingBox()
    model:PivotTo(CFrame.new(-bounds.Position) * model:GetPivot())
    local camera = Instance.new("Camera") camera.FieldOfView, camera.Parent = 36, viewport
    viewport.CurrentCamera = camera
    viewport.Ambient, viewport.LightColor = Color3.fromRGB(180, 198, 213), Color3.fromRGB(255, 236, 209)
    viewport.LightDirection = Vector3.new(-1, -0.6, -1)
    view.world, view.model, view.camera, view.base = world, model, camera, model:GetPivot()
    view.height, view.width, view.hiddenFor = size.Y, math.max(size.X, size.Z), 0
end
local function mount(viewport, factory)
    local view = { viewport = viewport, factory = factory, angle = 0.4, zoom = 1, hiddenFor = 0 }
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
function Preview.mount(viewport, category, id) mount(viewport, function() return Equipment.build(category, id) end) end
function Preview.fish(viewport, species, color, silhouette, variant)
    mount(viewport, function()
        return FishModels.build(species, color, silhouette, variant, viewport.AbsoluteSize.Y >= 150 and "high" or "low")
    end)
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
    for viewport, view in pairs(views) do
        if viewport.Parent and visible(viewport) then
            if not view.model then initialize(view) end
            view.hiddenFor = 0
            if not dragging or dragging.view ~= view then view.angle = view.angle + dt * 0.35 end
            view.model:PivotTo(CFrame.Angles(0, view.angle, 0) * view.base)
            local aspect = math.max(0.2, viewport.AbsoluteSize.X / math.max(1, viewport.AbsoluteSize.Y))
            local distance = math.max(view.height, view.width / aspect) / (2 * math.tan(math.rad(18))) * 1.22 * view.zoom
            view.camera.CFrame = CFrame.lookAt(Vector3.new(0, view.height * 0.06, distance), Vector3.new())
        else
            view.hiddenFor = view.hiddenFor + dt
            -- A full bag can contain 100 fish. Only retain visible previews.
            if view.model and view.hiddenFor > 2 then
                view.world:Destroy() view.camera:Destroy()
                view.world, view.model, view.camera = nil, nil, nil
            end
        end
    end
end
return Preview
