local Config = require "zarg4n_config"
local PhysicalGrowth = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function PhysicalGrowth.Calculate(profile, player_row, context)
    local age = tonumber(context.age) or profile.initialized_age or 18
    local initial_age = tonumber(profile.initialized_age) or age
    local years_elapsed = math.max(0, age - initial_age + 1)
    local body_factor = (profile.body_growth_potential or 50) / 100
    local physical_factor = (profile.physical_potential or 50) / 100
    local performance_score = tonumber(context.performance_score) or 0
    local height_delta = 0
    local weight_delta = 0

    if initial_age <= 18 and age <= 20 and body_factor >= 0.45 then
        local height_window = math.max(1, 20 - initial_age + 1)
        local height_progress = clamp(years_elapsed / height_window, 0, 1)
        height_delta = math.floor(Config.max_height_delta_cm * body_factor * height_progress + 0.5)
    end

    if initial_age <= 18 and age <= 23 and (body_factor + physical_factor) / 2 >= 0.45 then
        local weight_window = math.max(1, 23 - initial_age + 1)
        local weight_progress = clamp(years_elapsed / weight_window, 0, 1)
        local mass_factor = body_factor * 0.45 + physical_factor * 0.55
        weight_delta = math.floor(Config.max_weight_delta_kg * mass_factor * weight_progress + 0.5)
    elseif initial_age > 18 and age <= 23 and body_factor >= 0.75 then
        weight_delta = 1
    end

    return {
        height_delta_cm = clamp(height_delta, 0, Config.max_height_delta_cm),
        weight_delta_kg = clamp(weight_delta, 0, Config.max_weight_delta_kg),
        strength_growth = age <= 23 and performance_score >= 0.15
            and (physical_factor >= 0.75 and 2 or (physical_factor >= 0.5 and 1 or 0)) or 0,
        jumping_growth = age <= 23 and performance_score >= 0.15
            and ((profile.aerial_potential or 50) >= 60 and 1 or 0) or 0,
    }
end

return PhysicalGrowth
