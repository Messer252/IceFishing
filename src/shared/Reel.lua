local Reel = {}

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

function Reel.target(phase, difficulty, elapsed, behavior)
    local frequency = behavior == "heavy" and 0.8 or behavior == "burst" and 1.5 or 1.25
    local amplitude = behavior == "heavy" and 0.23 or 0.26
    local pulse = (behavior == "burst" or behavior == "mythic") and math.sin(elapsed * 0.9 + phase) ^ 7 * 0.045 or 0
    return 0.5 + math.sin(elapsed * difficulty * frequency + phase) * amplitude
        + math.sin(elapsed * difficulty * 2.1 + phase * 0.7) * 0.10 + pulse
end

-- Exact integration of a responding velocity keeps behavior independent of FPS.
function Reel.moveBar(state, dt, held, settings)
    local desired = held and settings.BarSpeed or -settings.Gravity
    local velocity = state.velocity or 0
    local decay = math.exp(-settings.Response * dt)
    local movement = desired * dt + (velocity - desired) * (1 - decay) / settings.Response
    local half = (state.width or 0) / 2
    local raw = state.bar + movement
    state.bar = clamp(raw, half, 1 - half)
    state.velocity = raw ~= state.bar and 0 or desired + (velocity - desired) * decay
end

-- Only the server uses the outcome to award a catch.
function Reel.step(state, dt, held, fish, settings, elapsed)
    Reel.moveBar(state, dt, held, settings)
    state.target = Reel.target(state.phase, fish.difficulty, elapsed, fish.behavior)
    local inside = math.abs(state.bar - state.target) <= state.width / 2
    state.progress = clamp(state.progress + (inside and settings.Gain or -settings.Loss) * dt, 0, 1)
    state.tension = clamp(state.tension + (inside and -settings.TensionLoss or settings.TensionGain) * dt, 0, 1)
    if state.progress >= 1 then return "caught" end
    if state.tension >= 1 or elapsed >= settings.Timeout then return "escaped" end
    return nil
end

function Reel.newView(snapshot)
    return { bar = snapshot.bar, velocity = snapshot.velocity or 0, width = snapshot.width,
        progress = snapshot.progress, tension = snapshot.tension, snapshot = snapshot,
        error = 0, velocityError = 0 }
end

function Reel.receiveView(view, snapshot, now, held, settings)
    if snapshot.serverTime <= view.snapshot.serverTime then return end
    local projected = { bar = snapshot.bar, velocity = snapshot.velocity, width = snapshot.width }
    Reel.moveBar(projected, clamp(now - snapshot.serverTime, 0, 0.25), held, settings)
    view.error, view.velocityError = projected.bar - view.bar, projected.velocity - view.velocity
    view.snapshot = snapshot
end

-- Render every frame, predict input locally, gently reconcile server errors.
-- Receiving a packet never directly repositions the UI.
function Reel.viewStep(view, dt, held, now, settings)
    dt = clamp(dt, 0, 0.05)
    Reel.moveBar(view, dt, held, settings)
    local alpha = 1 - math.exp(-10 * dt)
    view.bar = clamp(view.bar + view.error * alpha, view.width / 2, 1 - view.width / 2)
    view.velocity = view.velocity + view.velocityError * alpha
    view.error, view.velocityError = view.error * (1 - alpha), view.velocityError * (1 - alpha)
    local snapshot = view.snapshot
    view.progress = view.progress + (snapshot.progress - view.progress) * alpha
    view.tension = view.tension + (snapshot.tension - view.tension) * alpha
    view.target = Reel.target(snapshot.phase, snapshot.difficulty,
        snapshot.elapsed + math.max(0, now - snapshot.serverTime), snapshot.behavior)
    return view
end

return Reel
