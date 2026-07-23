local PlayStyles = {}

local function candidate(list, id, score, reason)
    table.insert(list, { id = id, score = score, reason = reason })
end

function PlayStyles.BuildCandidates(profile, player_row, stats)
    local candidates = {}
    local strength = tonumber(player_row.strength) or 0
    local jumping = tonumber(player_row.jumping) or 0
    local shot_power = tonumber(player_row.shotpower) or 0
    local long_shots = tonumber(player_row.longshots) or 0
    local stamina = tonumber(player_row.stamina) or 0
    local acceleration = tonumber(player_row.acceleration) or 0
    local interceptions = tonumber(player_row.interceptions) or 0

    if strength >= 78 or (profile.physical_potential or 0) >= 75 then
        candidate(candidates, "BRUISER", strength + profile.physical_potential, "physical_profile")
    end
    if jumping >= 78 or (profile.aerial_potential or 0) >= 78 then
        candidate(candidates, "AERIAL", jumping + profile.aerial_potential, "aerial_profile")
    end
    if shot_power >= 78 and long_shots >= 70 then
        candidate(candidates, "POWER_SHOT", shot_power + long_shots, "shooting_profile")
    end
    if stamina >= 80 or (profile.physical_potential or 0) >= 82 then
        candidate(candidates, "RELENTLESS", stamina + profile.physical_potential, "endurance_profile")
    end
    if acceleration >= 82 or (profile.speed_potential or 0) >= 80 then
        candidate(candidates, "QUICK_STEP", acceleration + profile.speed_potential, "speed_profile")
    end
    if interceptions >= 78 or (profile.mental_potential or 0) >= 80 then
        candidate(candidates, "INTERCEPT", interceptions + profile.mental_potential, "mental_profile")
    end

    local behavior_bonus = math.min(20, (stats.goal_contribution or 0) * 2 + (stats.average_rating or 0))
    for _, item in ipairs(candidates) do
        item.score = item.score + behavior_bonus
    end

    table.sort(candidates, function(left, right)
        return left.score > right.score
    end)

    local result = {}
    for index = 1, math.min(3, #candidates) do
        table.insert(result, candidates[index])
    end
    return result
end

function PlayStyles.ChoosePlus(candidates, selected_id)
    for _, item in ipairs(candidates or {}) do
        if item.id == selected_id then
            return item
        end
    end
    return nil
end

return PlayStyles
