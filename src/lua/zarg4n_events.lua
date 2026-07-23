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

local function deep_copy(value, copies)
    if type(value) ~= "table" then
        return value
    end

    copies = copies or {}
    if copies[value] ~= nil then
        return copies[value]
    end

    local copy = {}
    copies[value] = copy
    for key, item in pairs(value) do
        copy[deep_copy(key, copies)] = deep_copy(item, copies)
    end
    return setmetatable(copy, getmetatable(value))
end

local function snapshot_profile(profile)
    return {
        last_development = deep_copy(profile.last_development),
        playstyle_candidates = deep_copy(profile.playstyle_candidates),
        last_playstyle_award = deep_copy(profile.last_playstyle_award),
        last_stats = deep_copy(profile.last_stats),
        physical_projection = deep_copy(profile.physical_projection),
        last_processed_date = deep_copy(profile.last_processed_date),
        archetype_phase = deep_copy(profile.archetype_phase),
        role_archetype = deep_copy(profile.role_archetype),
        candidate_affinities = deep_copy(profile.candidate_affinities),
        archetype_history = deep_copy(profile.archetype_history),
        strength_growth_total = deep_copy(profile.strength_growth_total),
        jumping_growth_total = deep_copy(profile.jumping_growth_total),
        pending_transaction = deep_copy(profile.pending_transaction),
        committed_transaction = deep_copy(profile.committed_transaction),
        seasons_observed = deep_copy(profile.seasons_observed),
        identity_revealed = deep_copy(profile.identity_revealed),
    }
end

local function restore_profile(profile, snapshot)
    profile.last_development = deep_copy(snapshot.last_development)
    profile.playstyle_candidates = deep_copy(snapshot.playstyle_candidates)
    profile.last_playstyle_award = deep_copy(snapshot.last_playstyle_award)
    profile.last_stats = deep_copy(snapshot.last_stats)
    profile.physical_projection = deep_copy(snapshot.physical_projection)
    profile.last_processed_date = deep_copy(snapshot.last_processed_date)
    profile.archetype_phase = deep_copy(snapshot.archetype_phase)
    profile.role_archetype = deep_copy(snapshot.role_archetype)
    profile.candidate_affinities = deep_copy(snapshot.candidate_affinities)
    profile.archetype_history = deep_copy(snapshot.archetype_history)
    profile.strength_growth_total = deep_copy(snapshot.strength_growth_total)
    profile.jumping_growth_total = deep_copy(snapshot.jumping_growth_total)
    profile.pending_transaction = deep_copy(snapshot.pending_transaction)
    profile.committed_transaction = deep_copy(snapshot.committed_transaction)
    profile.seasons_observed = deep_copy(snapshot.seasons_observed)
    profile.identity_revealed = deep_copy(snapshot.identity_revealed)
end

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
                sprintspeed = table_ref:GetRecordFieldValue(record, "sprintspeed"),
                interceptions = table_ref:GetRecordFieldValue(record, "interceptions"),
                finishing = table_ref:GetRecordFieldValue(record, "finishing"),
                positioning = table_ref:GetRecordFieldValue(record, "positioning"),
                reactions = table_ref:GetRecordFieldValue(record, "reactions"),
                ballcontrol = table_ref:GetRecordFieldValue(record, "ballcontrol"),
                dribbling = table_ref:GetRecordFieldValue(record, "dribbling"),
                vision = table_ref:GetRecordFieldValue(record, "vision"),
                shortpassing = table_ref:GetRecordFieldValue(record, "shortpassing"),
                longpassing = table_ref:GetRecordFieldValue(record, "longpassing"),
                standingtackle = table_ref:GetRecordFieldValue(record, "standingtackle"),
                defensiveawareness = table_ref:GetRecordFieldValue(record, "defensiveawareness"),
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
                local candidates, evolution = PlayStyles.BuildCandidates(profile, row, stats)
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
                    evolution = evolution,
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
                    local profile_snapshot = snapshot_profile(profile)
                    PlayStyles.ApplyEvolution(profile, transaction.evolution)
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
                        restore_profile(profile, profile_snapshot)
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
