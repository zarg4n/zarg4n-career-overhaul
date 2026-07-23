local Config = require "zarg4n_config"
local Positions = require "zarg4n_positions"
local Development = {}

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function round(value)
    if value < 0 then
        return math.ceil(value - 0.5)
    end
    return math.floor(value + 0.5)
end

local function age_growth_factor(age)
    if age <= 20 then
        return 1.00
    elseif age <= 23 then
        return 0.85
    elseif age <= 26 then
        return 0.65
    elseif age <= 28 then
        return 0.50
    elseif age == 29 then
        return 0.35
    elseif age <= 32 then
        return 0.15
    end
    return 0
end

local function maximum_positive_adjustment(age)
    if age <= 20 then
        return 0.22
    elseif age <= 23 then
        return 0.18
    elseif age <= 26 then
        return 0.14
    elseif age <= 28 then
        return 0.11
    elseif age == 29 then
        return 0.08
    elseif age <= 32 then
        return 0.04
    end
    return 0
end

function Development.Calculate(profile, stats, context)
    local age = tonumber(context.age) or profile.initialized_age or 18
    local current_ovr = tonumber(context.overallrating) or profile.baseline_overall
    local potential = tonumber(context.potential) or profile.baseline_potential
    local rating_score = math.max(-1, math.min(1, ((stats.average_rating or 0) - 6.5) / 1.5))
    local appearances = tonumber(stats.appearances) or 0
    local goal_score = math.min(1, (stats.goal_contribution or 0) / math.max(4, appearances * 0.25))
    local clean_sheet_score = math.min(1, (stats.clean_sheets or 0) / math.max(4, appearances * 0.45))
    local save_score = math.min(1, (stats.saves or 0) / math.max(20, appearances * 2.5))
    local position = Positions.Normalize(context.position_name or profile.position)
    local defenders = { CB = true, LB = true, RB = true, LWB = true, RWB = true }
    local contribution_score = goal_score
    if position == "GK" then
        contribution_score = (tonumber(stats.saves) or 0) > 0
            and (clean_sheet_score * 0.65 + save_score * 0.35)
            or clean_sheet_score
    elseif defenders[position] then
        contribution_score = math.max(goal_score * 0.5, clean_sheet_score)
    elseif position == "CDM" then
        contribution_score = math.max(goal_score, clean_sheet_score * 0.5)
    end
    local appearance_score = math.min(1, (stats.appearances or 0) / 25)
    local participation_bonus = rating_score > 0 and appearance_score * 0.25 or 0
    local performance_score = rating_score * 0.45 + contribution_score * 0.3 + participation_bonus
    local age_modifier = age_growth_factor(age)
    local profile_modifier = (profile.development_profile or 50) / 100
    local team_modifier = math.max(0.85, math.min(1.15, tonumber(context.team_level) or 1))
    local sample_confidence = stats.sample_confidence or Config.sample_confidence_floor
    local write_potential = age <= Config.max_dynamic_potential_age

    local speed = performance_score * age_modifier * (0.65 + profile_modifier * 0.35) * team_modifier
    local development_adjustment = speed * sample_confidence * 0.25
    if development_adjustment > 0 then
        development_adjustment = math.min(development_adjustment, maximum_positive_adjustment(age))
    end
    local potential_delta = 0
    if write_potential and performance_score >= 0.7 and (stats.appearances or 0) >= 15 then
        local positive_cap = age <= 20 and 2 or 1
        potential_delta = math.min(
            Config.max_potential_delta_per_season,
            positive_cap,
            round(performance_score * 2)
        )
    elseif write_potential and performance_score <= -0.25 and (stats.appearances or 0) >= 15 then
        potential_delta = math.max(
            Config.min_potential_delta_per_season,
            math.floor(performance_score * 1.5)
        )
    end

    return {
        development_multiplier = clamp(1 + development_adjustment, 0.85, 1.22),
        potential_delta = potential_delta,
        projected_potential = write_potential
            and clamp(potential + potential_delta, 0, 99)
            or potential,
        write_potential = write_potential,
        performance_score = performance_score,
        confidence = sample_confidence,
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
