local Enums = require "imports/career_mode/enums"
local Helpers = require "imports/other/helpers"
local Stats = require "zarg4n_stats"
local Profile = require "zarg4n_player_profile"
local Development = require "zarg4n_development"
local PhysicalGrowth = require "zarg4n_physical_growth"
local PlayStyles = require "zarg4n_playstyles"
local Date = require "imports/core/date"

local Events = {}
Events.__index = Events

local function row_for_player(player_id)
    local table_ref = LE.db:GetTable("players")
    local record = table_ref:GetFirstRecord()
    while record > 0 do
        if table_ref:GetRecordFieldValue(record, "playerid") == player_id then
            local position_id = table_ref:GetRecordFieldValue(record, "preferredposition1")
            local birthdate = table_ref:GetRecordFieldValue(record, "birthdate")
            local date = GetCurrentDate()
            local date_obj = Date:new()
            date_obj:FromGregorianDays(birthdate)
            return {
                playerid = player_id,
                position_name = GetPlayerPrimaryPositionName(position_id),
                age = CalculatePlayerAge(date, date_obj),
                overallrating = table_ref:GetRecordFieldValue(record, "overallrating"),
                potential = table_ref:GetRecordFieldValue(record, "potential"),
                strength = table_ref:GetRecordFieldValue(record, "strength"),
                jumping = table_ref:GetRecordFieldValue(record, "jumping"),
                shotpower = table_ref:GetRecordFieldValue(record, "shotpower"),
                longshots = table_ref:GetRecordFieldValue(record, "longshots"),
                stamina = table_ref:GetRecordFieldValue(record, "stamina"),
                acceleration = table_ref:GetRecordFieldValue(record, "acceleration"),
                interceptions = table_ref:GetRecordFieldValue(record, "interceptions"),
                height = table_ref:GetRecordFieldValue(record, "height"),
                weight = table_ref:GetRecordFieldValue(record, "weight"),
            }
        end
        record = table_ref:GetNextValidRecord()
    end
    return nil
end

function Events.new(runtime)
    return setmetatable({ runtime = runtime }, Events)
end

function Events:InitializePlayers()
    local player_ids = GetUserSeniorTeamPlayerIDs()
    for player_id, _ in pairs(player_ids) do
        local row = row_for_player(player_id)
        if row ~= nil and self.runtime.state.players[tostring(player_id)] == nil then
            self.runtime.state.players[tostring(player_id)] = Profile.Create(row, self.runtime.state.save_uid)
        end
    end
    self.runtime.state.initialized = true
end

function Events:ProcessSeasonEnd()
    local player_ids = GetUserSeniorTeamPlayerIDs()
    for player_id, _ in pairs(player_ids) do
        local key = tostring(player_id)
        local row = row_for_player(player_id)
        local profile = self.runtime.state.players[key]
        if row ~= nil and profile == nil then
            profile = Profile.Create(row, self.runtime.state.save_uid)
            self.runtime.state.players[key] = profile
        end
        if row ~= nil and profile ~= nil and Profile.Validate(profile) then
            local stats = Stats.Aggregate(player_id, GetPlayerStats(player_id))
            local result = Development.Calculate(profile, stats, row)
            Development.Apply(LE, player_id, result)
            local candidates = PlayStyles.BuildCandidates(profile, row, stats)
            profile.last_development = result
            profile.playstyle_candidates = candidates
            profile.last_stats = stats
            profile.last_processed_date = GetCurrentDate():ToInt()
            profile.physical_projection = PhysicalGrowth.Calculate(profile, row, row)
        end
    end
end

function Events:OnCareerEvent(_, event_id, _)
    if event_id == Enums.ENUM_CM_EVENT_MSG_INITIAL_USER_ADDED
        or event_id == Enums.ENUM_CM_EVENT_MSG_POST_LOAD_PREPARE then
        self:InitializePlayers()
    elseif event_id == Enums.ENUM_CM_EVENT_MSG_END_OF_SEASON_REACHED then
        self:ProcessSeasonEnd()
    end
end

return Events
