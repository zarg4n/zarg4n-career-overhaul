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

local function number(row, ...)
    for index = 1, select("#", ...) do
        local value = tonumber(row[select(index, ...)])
        if value ~= nil then
            return value
        end
    end
    return 0
end

local function phase_for_age(age)
    if age <= 18 then
        return "prospect"
    elseif age <= 23 then
        return "emerging"
    elseif age <= 26 then
        return "established"
    elseif age <= 29 then
        return "prime"
    end
    return "veteran"
end

local function fallback_archetype(position)
    if position == "GK" then
        return "goalkeeper"
    elseif position == "CB" or position == "LB" or position == "RB"
        or position == "LWB" or position == "RWB" then
        return "balanced_defender"
    elseif position == "CDM" or position == "CM" or position == "CAM" then
        return "balanced_midfielder"
    elseif position == "ST" then
        return "balanced_forward"
    elseif position == "LW" or position == "RW" or position == "LM"
        or position == "RM" or position == "CF" then
        return "balanced_winger"
    end
    return "unresolved"
end

local function build_evolution(profile, player_row)
    local age = number(player_row, "age")
    if age == 0 then
        age = tonumber(profile.initialized_age) or 18
    end

    local position = player_row.position_name or profile.position or ""
    local speed = (number(player_row, "acceleration") + number(player_row, "sprint_speed", "sprintspeed")) / 2
    local finishing = number(player_row, "finishing")
    local positioning = number(player_row, "positioning", "attackposition")
    local previous = profile.role_archetype
    local role = fallback_archetype(position)
    local wide_forward = position == "LW" or position == "RW"
        or position == "LM" or position == "RM" or position == "CF"

    if wide_forward and age >= 26 and finishing >= 82 and positioning >= 82 then
        role = "efficient_forward"
    elseif wide_forward and speed >= 82 then
        role = "explosive_winger"
    end

    local history_entry = nil
    if previous ~= nil and previous ~= role then
        history_entry = {
            age = age,
            from = previous,
            to = role,
        }
    end

    return {
        archetype_phase = phase_for_age(age),
        role_archetype = role,
        candidate_affinities = {},
        history_entry = history_entry,
    }
end

function PlayStyles.BuildCandidates(profile, player_row, stats)
    local candidates = {}
    local evolution = build_evolution(profile, player_row)

    local strength = number(player_row, "strength")
    local jumping = number(player_row, "jumping")
    local shot_power = number(player_row, "shotpower")
    local long_shots = number(player_row, "longshots")
    local stamina = number(player_row, "stamina")
    local acceleration = number(player_row, "acceleration")
    local sprint_speed = number(player_row, "sprint_speed", "sprintspeed")
    local interceptions = number(player_row, "interceptions")
    local finishing = number(player_row, "finishing")
    local positioning = number(player_row, "positioning", "attackposition")
    local reactions = number(player_row, "reactions")
    local ball_control = number(player_row, "ballcontrol")
    local dribbling = number(player_row, "dribbling")
    local vision = number(player_row, "vision")
    local short_passing = number(player_row, "shortpassing")
    local long_passing = number(player_row, "longpassing")
    local standing_tackle = number(player_row, "standingtackle")
    local defensive_awareness = number(player_row, "defensiveawareness")

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
    if sprint_speed >= 82 and acceleration >= 78 then
        candidate(candidates, "RAPID", sprint_speed + acceleration, "sustained_speed")
    end
    if dribbling >= 82 and ball_control >= 78 then
        candidate(candidates, "TECHNICAL", dribbling + ball_control, "technical_carrying")
    end
    if interceptions >= 78 or (profile.mental_potential or 0) >= 80 then
        candidate(candidates, "INTERCEPT", interceptions + profile.mental_potential, "mental_profile")
    end
    if finishing >= 80 and positioning >= 78 then
        candidate(candidates, "FINESSE_SHOT", finishing + positioning, "efficient_finishing")
    end
    if finishing >= 82 and shot_power >= 72 then
        candidate(candidates, "LOW_DRIVEN_SHOT", finishing + shot_power, "box_finishing")
    end
    if ball_control >= 82 and reactions >= 80 then
        candidate(candidates, "FIRST_TOUCH", ball_control + reactions, "efficient_control")
    end
    if vision >= 82 and short_passing >= 80 then
        candidate(candidates, "INCISIVE_PASS", vision + short_passing, "creative_passing")
    end
    if short_passing >= 84 and ball_control >= 80 then
        candidate(candidates, "TIKI_TAKA", short_passing + ball_control, "combination_passing")
    end
    if long_passing >= 82 then
        candidate(candidates, "LONG_BALL_PASS", long_passing + vision, "range_passing")
    end
    if standing_tackle >= 80 and defensive_awareness >= 78 then
        candidate(candidates, "ANTICIPATE", standing_tackle + defensive_awareness, "defensive_reading")
    end

    local behavior_bonus = math.min(20, (stats.goal_contribution or 0) * 2 + (stats.average_rating or 0))
    for _, item in ipairs(candidates) do
        if evolution.role_archetype == "efficient_forward"
            and (item.id == "FINESSE_SHOT" or item.id == "LOW_DRIVEN_SHOT" or item.id == "FIRST_TOUCH") then
            item.score = item.score + 16
        elseif evolution.role_archetype == "explosive_winger"
            and (item.id == "QUICK_STEP" or item.id == "RAPID" or item.id == "TECHNICAL") then
            item.score = item.score + 12
        end
        item.score = item.score + behavior_bonus
        evolution.candidate_affinities[item.id] = item.score
    end

    table.sort(candidates, function(left, right)
        return left.score > right.score
    end)

    local result = {}
    for index = 1, math.min(3, #candidates) do
        table.insert(result, candidates[index])
    end
    return result, evolution
end

function PlayStyles.ApplyEvolution(profile, evolution)
    if evolution == nil then
        return
    end

    profile.archetype_phase = evolution.archetype_phase
    profile.role_archetype = evolution.role_archetype
    local candidate_affinities = {}
    for id, score in pairs(profile.candidate_affinities or {}) do
        candidate_affinities[id] = score
    end
    for id, score in pairs(evolution.candidate_affinities or {}) do
        candidate_affinities[id] = score
    end
    profile.candidate_affinities = candidate_affinities

    local entry = evolution.history_entry
    if entry ~= nil then
        local archetype_history = {}
        for _, existing in ipairs(profile.archetype_history or {}) do
            table.insert(archetype_history, existing)
        end
        table.insert(archetype_history, entry)
        profile.archetype_history = archetype_history
    end
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
