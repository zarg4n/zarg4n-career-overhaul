local Positions = {}

local ALIASES = {
    RCB = "CB",
    LCB = "CB",
    RDM = "CDM",
    LDM = "CDM",
    RCM = "CM",
    LCM = "CM",
    RAM = "CAM",
    LAM = "CAM",
    RS = "ST",
    LS = "ST",
    RF = "CF",
    LF = "CF",
}

function Positions.Normalize(position)
    local value = string.upper(tostring(position or ""))
    return ALIASES[value] or value
end

return Positions
