local Input = game:GetService("UserInputService")
local Hints = {}
function Hints.mode()
    local kind = Input:GetLastInputType()
    if tostring(kind):find("Gamepad", 1, true) then return "gamepad" end
    if kind == Enum.UserInputType.Touch or (Input.TouchEnabled and not Input.KeyboardEnabled) then return "touch" end
    return "keyboard"
end
function Hints.hold()
    local mode = Hints.mode()
    return mode == "gamepad" and "HOLD A TO REEL" or mode == "touch" and "HOLD TO REEL" or "HOLD TO REEL [SPACE]"
end
function Hints.hook()
    local mode = Hints.mode()
    return mode == "gamepad" and "HOOK! [A]" or mode == "touch" and "HOOK!" or "HOOK! [SPACE]"
end
function Hints.hookHelp()
    local mode = Hints.mode()
    return mode == "gamepad" and "Press A before the fish slips away." or mode == "touch" and "Tap Hook before the fish slips away." or "Press Hook or Space before the fish slips away."
end
function Hints.cast(fishing)
    local mode = Hints.mode()
    local key = mode == "gamepad" and " [X]" or mode == "keyboard" and " [F]" or ""
    return (fishing and "CANCEL CAST" or "DRILL / CAST") .. key
end
function Hints.bag()
    local mode = Hints.mode()
    return "BAG" .. (mode == "gamepad" and " [R1]" or mode == "keyboard" and " [I]" or "")
end
function Hints.drill()
    return "NEW HOLE" .. (Hints.mode() == "keyboard" and " [G]" or "") .. " / replaces your previous hole"
end
return Hints
