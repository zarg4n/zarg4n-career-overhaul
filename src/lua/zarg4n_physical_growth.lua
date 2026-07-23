local Config = require "zarg4n_config"
local PhysicalGrowth = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function PhysicalGrowth.Calculate(profile, player_row, context)
    local age = tonumber(context.age) or profile.initialized_age or 18
    local years_left = math.max(0, math.min(4, 19 - age))
    local maturity = math.max(0, math.min(1, years_left / 5))
    local body_factor = (profile.body_growth_potential or 50) / 100
    local physical_factor = (profile.physical_potential or 50) / 100
    local height_delta = 0
    local weight_delta = 0

    if age <= 18 then
        height_delta = math.floor(Config.max_height_delta_cm * body_factor * maturity * 0.65 + 0.5)
        weight_delta = math.floor(Config.max_weight_delta_kg * body_factor * maturity * 0.45 + 0.5)
    end

    return {
        height_delta_cm = clamp(height_delta, 0, Config.max_height_delta_cm),
        weight_delta_kg = clamp(weight_delta, 0, Config.max_weight_delta_kg),
        strength_growth = clamp(math.floor(physical_factor * 3 + 0.5), 0, 3),
        jumping_growth = clamp(math.floor((profile.aerial_potential or 50) / 40), 0, 3),
    }
end

return PhysicalGrowth
