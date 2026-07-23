local Config = require "zarg4n_config"
local Development = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function round(value)
    return math.floor(value + 0.5)
end

function Development.Calculate(profile, stats, context)
    local age = tonumber(context.age) or profile.initialized_age or 18
    local current_ovr = tonumber(context.overallrating) or profile.baseline_overall
    local potential = tonumber(context.potential) or profile.baseline_potential
    local rating_score = math.max(-1, math.min(1, ((stats.average_rating or 0) - 6.5) / 1.5))
    local contribution_score = math.min(1, (stats.goal_contribution or 0) / math.max(4, stats.appearances * 0.25))
    local minutes_score = math.min(1, (stats.appearances or 0) / 25)
    local performance_score = rating_score * 0.45 + contribution_score * 0.3 + minutes_score * 0.25
    local age_modifier = math.max(0.15, math.min(1.25, (23 - age) / 8))
    local profile_modifier = (profile.development_profile or 50) / 100
    local team_modifier = math.max(0.85, math.min(1.15, tonumber(context.team_level) or 1))
    local minutes_confidence = stats.minutes_confidence or Config.cameo_minutes_confidence_floor

    local speed = performance_score * age_modifier * (0.65 + profile_modifier * 0.35) * team_modifier
    local potential_delta = 0
    if performance_score >= 0.7 then
        potential_delta = math.min(Config.max_potential_delta_per_season, round(performance_score * 2.5))
    elseif performance_score <= -0.55 and (stats.appearances or 0) >= 10 then
        potential_delta = math.max(Config.min_potential_delta_per_season, round(performance_score * 1.5))
    end

    return {
        development_multiplier = clamp(0.8 + speed * minutes_confidence, 0.75, 1.35),
        potential_delta = potential_delta,
        projected_potential = clamp(potential + potential_delta, current_ovr, 99),
        performance_score = performance_score,
        confidence = minutes_confidence,
    }
end

function Development.Apply(runtime, player_id, result)
    if runtime == nil or runtime.player_development_manager == nil then
        return false, "player development manager unavailable"
    end
    runtime.player_development_manager:AddPlayer(player_id, result.development_multiplier, 0, false)
    return true, nil
end

return Development
