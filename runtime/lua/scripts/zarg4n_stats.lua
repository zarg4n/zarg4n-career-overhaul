local Config = require "zarg4n_config"
local Stats = {}

local function add(target, key, value)
    target[key] = (target[key] or 0) + (tonumber(value) or 0)
end

function Stats.Aggregate(player_id, raw_stats)
    local result = {
        player_id = player_id,
        appearances = 0,
        goals = 0,
        assists = 0,
        clean_sheets = 0,
        saves = 0,
        cards = 0,
        rating_total = 0,
        competitions = 0,
    }

    for _, row in ipairs(raw_stats or {}) do
        local appearances = tonumber(row.app) or 0
        result.competitions = result.competitions + 1
        add(result, "appearances", appearances)
        add(result, "goals", row.goals)
        add(result, "assists", row.assists)
        add(result, "clean_sheets", row.clean_sheets)
        add(result, "saves", row.saves)
        add(result, "cards", row.yellow)
        add(result, "cards", row.red and row.red * 2 or 0)
        add(result, "rating_total", row.avg)
    end

    if result.appearances > 0 then
        result.average_rating = result.rating_total / result.appearances / 10
    else
        result.average_rating = 0
    end

    result.sample_confidence = math.max(
        Config.sample_confidence_floor,
        math.min(1, result.appearances / Config.regular_appearance_sample)
    )
    result.goal_contribution = result.goals + result.assists * 0.8
    return result
end

return Stats
