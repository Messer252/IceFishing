local Reel = {}

-- The server advances this simulation; clients only submit hold/release input.
function Reel.step(state, dt, held, fish, settings, elapsed)
    state.bar = math.max(0, math.min(1, state.bar + (held and settings.BarSpeed or -settings.Gravity) * dt))
    state.target = math.max(0.08, math.min(0.92,
        0.5 + math.sin(elapsed * fish.difficulty * 1.9 + state.phase) * 0.28
        + math.sin(elapsed * fish.difficulty * 3.7 + state.phase * 0.7) * 0.12))
    local inside = math.abs(state.bar - state.target) <= state.width / 2
    state.progress = math.max(0, math.min(1, state.progress + (inside and settings.Gain or -settings.Loss) * dt))
    state.tension = math.max(0, math.min(1, state.tension + (inside and -settings.TensionLoss or settings.TensionGain) * dt))
    if state.progress >= 1 then return "caught" end
    if state.tension >= 1 or elapsed >= settings.Timeout then return "escaped" end
    return nil
end

return Reel
