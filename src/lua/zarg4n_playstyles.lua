local PlayStyles = {}

local FLAGS = {
    FINESSE_SHOT = 1,
    CHIP_SHOT = 2,
    POWER_SHOT = 4,
    DEAD_BALL = 8,
    PRECISION_HEADER = 16,
    ACROBATIC = 32,
    LOW_DRIVEN_SHOT = 64,
    GAMECHANGER = 128,
    INCISIVE_PASS = 256,
    PINGED_PASS = 512,
    LONG_BALL_PASS = 1024,
    TIKI_TAKA = 2048,
    WHIPPED_PASS = 4096,
    INVENTIVE = 8192,
    JOCKEY = 16384,
    BLOCK = 32768,
    INTERCEPT = 65536,
    ANTICIPATE = 131072,
    SLIDE_TACKLE = 262144,
    AERIAL_FORTRESS = 524288,
    TECHNICAL = 1048576,
    RAPID = 2097152,
    FIRST_TOUCH = 4194304,
    TRICKSTER = 8388608,
    PRESS_PROVEN = 16777216,
    QUICK_STEP = 33554432,
    RELENTLESS = 67108864,
    LONG_THROW = 134217728,
    BRUISER = 268435456,
    ENFORCER = 536870912,
}

local FLAG_ORDER = {
    "FINESSE_SHOT", "CHIP_SHOT", "POWER_SHOT", "DEAD_BALL", "PRECISION_HEADER",
    "ACROBATIC", "LOW_DRIVEN_SHOT", "GAMECHANGER", "INCISIVE_PASS", "PINGED_PASS",
    "LONG_BALL_PASS", "TIKI_TAKA", "WHIPPED_PASS", "INVENTIVE", "JOCKEY", "BLOCK",
    "INTERCEPT", "ANTICIPATE", "SLIDE_TACKLE", "AERIAL_FORTRESS", "TECHNICAL",
    "RAPID", "FIRST_TOUCH", "TRICKSTER", "PRESS_PROVEN", "QUICK_STEP", "RELENTLESS",
    "LONG_THROW", "BRUISER", "ENFORCER",
}

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
        candidate(candidates, "AERIAL_FORTRESS", jumping + profile.aerial_potential, "aerial_profile")
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

local function contains(list, id)
    for _, value in ipairs(list or {}) do
        if value == id then
            return true
        end
    end
    return false
end

function PlayStyles.AddFlag(current_value, id)
    local flag = FLAGS[id]
    if flag == nil then
        return tonumber(current_value) or 0
    end

    local value = tonumber(current_value) or 0
    if math.floor(value / flag) % 2 == 1 then
        return value
    end
    return value + flag
end

function PlayStyles.HasFlag(current_value, id)
    local flag = FLAGS[id]
    if flag == nil then
        return false
    end
    return math.floor((tonumber(current_value) or 0) / flag) % 2 == 1
end

local function decode_flags(value)
    local result = {}
    local flags = tonumber(value) or 0
    for _, id in ipairs(FLAG_ORDER) do
        local flag = FLAGS[id]
        if math.floor(flags / flag) % 2 == 1 then
            table.insert(result, id)
        end
    end
    return result
end

function PlayStyles.HydrateProfile(profile, player_row)
    profile.regular_playstyles = profile.regular_playstyles or {}
    profile.plus_playstyles = profile.plus_playstyles or {}
    for _, id in ipairs(decode_flags(player_row.trait1)) do
        if not contains(profile.regular_playstyles, id) then
            table.insert(profile.regular_playstyles, id)
        end
    end
    for _, id in ipairs(decode_flags(player_row.icontrait1)) do
        if not contains(profile.plus_playstyles, id) then
            table.insert(profile.plus_playstyles, id)
        end
    end
end

function PlayStyles.ResolveAward(profile, player_row, stats, candidates)
    local appearances = tonumber(stats.appearances) or 0
    local average_rating = tonumber(stats.average_rating) or 0
    if appearances < 8 or average_rating < 6.7 then
        return nil
    end

    local overall = tonumber(player_row.overallrating) or 0
    local regular = profile.regular_playstyles or {}
    local plus = profile.plus_playstyles or {}
    local plus_limit = overall >= 85 and 2 or (overall >= 80 and 1 or 0)

    if #plus < plus_limit and #regular >= plus_limit * 2 then
        for _, item in ipairs(candidates or {}) do
            if contains(regular, item.id) and not contains(plus, item.id) then
                return { id = item.id, level = "plus", reason = item.reason }
            end
        end
    end

    if overall >= 70 and #regular < 5 then
        for _, item in ipairs(candidates or {}) do
            if not contains(regular, item.id) then
                return { id = item.id, level = "regular", reason = item.reason }
            end
        end
    end

    return nil
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
