require "imports/career_mode/enums"
require "imports/other/helpers"
local Stats = require "zarg4n_stats"
local Profile = require "zarg4n_player_profile"
local Development = require "zarg4n_development"
local PhysicalGrowth = require "zarg4n_physical_growth"
local PlayStyles = require "zarg4n_playstyles"
local PlayerWriter = require "zarg4n_player_writer"
local Logger = require "zarg4n_logger"
local Config = require "zarg4n_config"
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
                record = record,
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
                trait1 = table_ref:GetRecordFieldValue(record, "trait1"),
                icontrait1 = table_ref:GetRecordFieldValue(record, "icontrait1"),
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
    local players_table = LE.db:GetTable("players")
    local state_changed = false
    for player_id, _ in pairs(player_ids) do
        local row = row_for_player(player_id)
        local key = tostring(player_id)
        if row ~= nil and row.age <= Config.max_profile_age and self.runtime.state.players[key] == nil then
            self.runtime.state.players[key] = Profile.Create(row, self.runtime.state.save_uid)
        end
        if row ~= nil and row.age <= Config.max_profile_age and self.runtime.state.players[key] ~= nil then
            local profile = self.runtime.state.players[key]
            PlayStyles.HydrateProfile(profile, row)
            local committed = profile.committed_transaction
            if committed ~= nil then
                if PlayerWriter.Matches(
                    players_table,
                    row.record,
                    row,
                    profile,
                    committed.result,
                    committed.physical,
                    committed.award
                ) then
                    profile.committed_transaction = nil
                    state_changed = true
                else
                    local reconciled, reconcile_error = pcall(function()
                        PlayerWriter.Apply(
                            players_table,
                            row.record,
                            row,
                            profile,
                            committed.result,
                            committed.physical,
                            committed.award
                        )
                        local applied, development_error = Development.Apply(
                            LE,
                            player_id,
                            committed.result
                        )
                        if not applied then
                            error(development_error)
                        end
                        self.runtime.player_development_manager:Save()
                    end)
                    if not reconciled then
                        Logger:Error("Career save reconciliation failed for "
                            .. tostring(player_id) .. ": " .. tostring(reconcile_error))
                    end
                end
            end
        end
    end
    self.runtime.state.initialized = true
    if state_changed then
        local saved, save_error = self.runtime.state_store:Save(self.runtime.state)
        if not saved then
            Logger:Error("Reconciliation checkpoint failed: " .. tostring(save_error))
        end
    end
end

function Events:ProcessSeasonEnd()
    local current_date = GetCurrentDate():ToInt()
    if self.runtime.state.last_processed_date == current_date then
        return
    end

    local players_table = LE.db:GetTable("players")
    local player_ids = GetUserSeniorTeamPlayerIDs()
    local all_successful = true
    for player_id, _ in pairs(player_ids) do
        local key = tostring(player_id)
        local row = row_for_player(player_id)
        local profile = self.runtime.state.players[key]
        if row ~= nil and row.age <= Config.max_profile_age and profile == nil then
            profile = Profile.Create(row, self.runtime.state.save_uid)
            self.runtime.state.players[key] = profile
        end
        if row ~= nil
            and row.age <= Config.max_profile_age
            and profile ~= nil
            and profile.last_processed_date ~= current_date
            and Profile.Validate(profile) then
            profile.regular_playstyles = profile.regular_playstyles or {}
            profile.plus_playstyles = profile.plus_playstyles or {}
            profile.base_strength = profile.base_strength or row.strength
            profile.base_jumping = profile.base_jumping or row.jumping
            profile.strength_growth_total = tonumber(profile.strength_growth_total) or 0
            profile.jumping_growth_total = tonumber(profile.jumping_growth_total) or 0
            PlayStyles.HydrateProfile(profile, row)
            local transaction = profile.pending_transaction
            if transaction == nil or transaction.date ~= current_date then
                local stats = Stats.Aggregate(player_id, GetPlayerStats(player_id))
                local result = Development.Calculate(profile, stats, row)
                local candidates = PlayStyles.BuildCandidates(profile, row, stats)
                local physical = PhysicalGrowth.Calculate(profile, row, {
                    age = row.age,
                    performance_score = result.performance_score,
                })
                physical.strength_total = profile.strength_growth_total
                    + (tonumber(physical.strength_growth) or 0)
                physical.jumping_total = profile.jumping_growth_total
                    + (tonumber(physical.jumping_growth) or 0)
                transaction = {
                    date = current_date,
                    stats = stats,
                    result = result,
                    candidates = candidates,
                    physical = physical,
                    award = PlayStyles.ResolveAward(profile, row, stats, candidates),
                }
                profile.pending_transaction = transaction
                local prepared, prepare_error = self.runtime.state_store:Save(self.runtime.state)
                if not prepared then
                    Logger:Error("Player transaction prepare failed for "
                        .. tostring(player_id) .. ": " .. tostring(prepare_error))
                    profile.pending_transaction = nil
                    transaction = nil
                    all_successful = false
                end
            end

            if transaction ~= nil then
                local ok, error_message = pcall(function()
                    PlayerWriter.Apply(
                        players_table,
                        row.record,
                        row,
                        profile,
                        transaction.result,
                        transaction.physical,
                        transaction.award
                    )
                    local applied, development_error = Development.Apply(
                        LE,
                        player_id,
                        transaction.result
                    )
                    if not applied then
                        error(development_error)
                    end
                    self.runtime.player_development_manager:Save()
                end)

                if not ok then
                    Logger:Error("Player transaction failed for "
                        .. tostring(player_id) .. ": " .. tostring(error_message))
                    all_successful = false
                else
                    local previous_seasons = profile.seasons_observed
                    local previous_identity = profile.identity_revealed
                    local previous_strength_total = profile.strength_growth_total
                    local previous_jumping_total = profile.jumping_growth_total
                    local previous_committed = profile.committed_transaction
                    profile.last_development = transaction.result
                    profile.playstyle_candidates = transaction.candidates
                    profile.last_playstyle_award = transaction.award
                    profile.last_stats = transaction.stats
                    profile.last_processed_date = current_date
                    profile.physical_projection = transaction.physical
                    profile.strength_growth_total = transaction.physical.strength_total
                    profile.jumping_growth_total = transaction.physical.jumping_total
                    profile.committed_transaction = transaction
                    profile.pending_transaction = nil
                    Profile.AdvanceSeason(profile)
                    local committed, commit_error = self.runtime.state_store:Save(self.runtime.state)
                    if not committed then
                        profile.last_processed_date = nil
                        profile.pending_transaction = transaction
                        profile.seasons_observed = previous_seasons
                        profile.identity_revealed = previous_identity
                        profile.strength_growth_total = previous_strength_total
                        profile.jumping_growth_total = previous_jumping_total
                        profile.committed_transaction = previous_committed
                        Logger:Error("Player transaction commit failed for "
                            .. tostring(player_id) .. ": " .. tostring(commit_error))
                        all_successful = false
                    end
                end
            end
        end
    end

    if all_successful then
        self.runtime.state.last_processed_date = current_date
        local saved, save_error = self.runtime.state_store:Save(self.runtime.state)
        if not saved then
            self.runtime.state.last_processed_date = 0
            Logger:Error("Season checkpoint failed: " .. tostring(save_error))
        end
    else
        self.runtime.state.last_processed_date = 0
    end
end

function Events:OnCareerEvent(_, event_id, _)
    if event_id == ENUM_CM_EVENT_MSG_INITIAL_USER_ADDED
        or event_id == ENUM_CM_EVENT_MSG_POST_LOAD_PREPARE then
        self:InitializePlayers()
    elseif event_id == ENUM_CM_EVENT_MSG_END_OF_SEASON_REACHED then
        self:ProcessSeasonEnd()
    end
end

return Events
