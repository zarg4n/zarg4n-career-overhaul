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
local SaveGuard = require "zarg4n_save_guard"
local TransferObserver = require "zarg4n_transfer_observer"
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
        regular_playstyles = deep_copy(profile.regular_playstyles),
        plus_playstyles = deep_copy(profile.plus_playstyles),
    }
end

local function restore_in_memory_profile(profile, snapshot)
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
    profile.regular_playstyles = deep_copy(snapshot.regular_playstyles)
    profile.plus_playstyles = deep_copy(snapshot.plus_playstyles)
end

local function append_unique(list, value)
    for _, item in ipairs(list) do
        if item == value then return end
    end
    table.insert(list, value)
end

local function commit_profile(profile, transaction, current_date)
    PlayStyles.ApplyEvolution(profile, transaction.evolution)
    profile.last_development = transaction.result
    profile.playstyle_candidates = transaction.candidates
    profile.last_playstyle_award = transaction.award
    profile.last_stats = transaction.stats
    profile.last_processed_date = current_date
    profile.physical_projection = transaction.physical
    profile.strength_growth_total = transaction.physical.strength_total
    profile.jumping_growth_total = transaction.physical.jumping_total
    if transaction.award ~= nil and transaction.award.id ~= nil then
        if transaction.award.level == "plus" then
            append_unique(profile.plus_playstyles, transaction.award.id)
        else
            append_unique(profile.regular_playstyles, transaction.award.id)
        end
    end
    profile.committed_transaction = transaction
    profile.pending_transaction = nil
    Profile.AdvanceSeason(profile)
end

local function rows_for_players(players_table, player_ids)
    local rows = {}
    local current_date = GetCurrentDate()
    local record = players_table:GetFirstRecord()
    while record > 0 do
        local player_id = players_table:GetRecordFieldValue(record, "playerid")
        if player_ids[player_id] then
            local position_id = players_table:GetRecordFieldValue(record, "preferredposition1")
            local birthdate = players_table:GetRecordFieldValue(record, "birthdate")
            local date_obj = Date:new()
            date_obj:FromGregorianDays(birthdate)
            rows[player_id] = {
                record = record,
                playerid = player_id,
                position_name = GetPlayerPrimaryPositionName(position_id),
                age = CalculatePlayerAge(current_date, date_obj),
                overallrating = players_table:GetRecordFieldValue(record, "overallrating"),
                potential = players_table:GetRecordFieldValue(record, "potential"),
                strength = players_table:GetRecordFieldValue(record, "strength"),
                jumping = players_table:GetRecordFieldValue(record, "jumping"),
                shotpower = players_table:GetRecordFieldValue(record, "shotpower"),
                longshots = players_table:GetRecordFieldValue(record, "longshots"),
                stamina = players_table:GetRecordFieldValue(record, "stamina"),
                acceleration = players_table:GetRecordFieldValue(record, "acceleration"),
                sprintspeed = players_table:GetRecordFieldValue(record, "sprintspeed"),
                interceptions = players_table:GetRecordFieldValue(record, "interceptions"),
                finishing = players_table:GetRecordFieldValue(record, "finishing"),
                positioning = players_table:GetRecordFieldValue(record, "positioning"),
                reactions = players_table:GetRecordFieldValue(record, "reactions"),
                ballcontrol = players_table:GetRecordFieldValue(record, "ballcontrol"),
                dribbling = players_table:GetRecordFieldValue(record, "dribbling"),
                vision = players_table:GetRecordFieldValue(record, "vision"),
                shortpassing = players_table:GetRecordFieldValue(record, "shortpassing"),
                longpassing = players_table:GetRecordFieldValue(record, "longpassing"),
                standingtackle = players_table:GetRecordFieldValue(record, "standingtackle"),
                defensiveawareness = players_table:GetRecordFieldValue(record, "defensiveawareness"),
                height = players_table:GetRecordFieldValue(record, "height"),
                weight = players_table:GetRecordFieldValue(record, "weight"),
                trait1 = players_table:GetRecordFieldValue(record, "trait1"),
                icontrait1 = players_table:GetRecordFieldValue(record, "icontrait1"),
            }
        end
        record = players_table:GetNextValidRecord()
    end
    return rows
end

function Events.new(runtime)
    return setmetatable({
        runtime = runtime,
        transfer_observer = TransferObserver.New(),
    }, Events)
end

function Events:EnsureDevelopmentManagerReady()
    if self.runtime.development_manager_ready == true then
        return true
    end
    local loaded, load_error = pcall(function()
        self.runtime.player_development_manager:Load()
    end)
    if not loaded then
        Logger:Error("Development manager load failed: " .. tostring(load_error))
        return false
    end
    self.runtime.development_manager_ready = true
    return true
end

function Events:CommitPreparedTransaction(
    players_table,
    row,
    profile,
    transaction,
    player_id
)
    local profile_snapshot = snapshot_profile(profile)
    local database_applied, database_error = pcall(function()
        local target_matches = PlayerWriter.Matches(
            players_table,
            row.record,
            row,
            profile,
            transaction.result,
            transaction.physical,
            transaction.award
        )
        if not target_matches then
            PlayerWriter.Apply(
                players_table,
                row.record,
                row,
                profile,
                transaction.result,
                transaction.physical,
                transaction.award
            )
        end
        local applied, development_error = Development.Apply(
            LE,
            player_id,
            transaction.result
        )
        if not applied then error(development_error) end
        self.runtime.player_development_manager:Save()
    end)

    if not database_applied then
        restore_in_memory_profile(profile, profile_snapshot)
        Logger:Error("Prepared player transaction failed for "
            .. tostring(player_id) .. ": " .. tostring(database_error))
        return false
    end

    commit_profile(profile, transaction, transaction.date)
    local committed, commit_error = self.runtime.state_store:Save(self.runtime.state)
    if not committed then
        restore_in_memory_profile(profile, profile_snapshot)
        Logger:Error("Prepared player transaction remains pending for "
            .. tostring(player_id) .. ": " .. tostring(commit_error))
        return false
    end
    return true
end

function Events:InitializePlayers()
    local can_write = SaveGuard.CanWrite(self.runtime.state)
    if not can_write then
        return
    end
    if not self:EnsureDevelopmentManagerReady() then
        return
    end

    local player_ids = GetUserSeniorTeamPlayerIDs()
    local players_table = LE.db:GetTable("players")
    local rows = rows_for_players(players_table, player_ids)
    local state_changed = false
    for player_id, _ in pairs(player_ids) do
        local row = rows[player_id]
        local key = tostring(player_id)
        if row ~= nil and row.age <= Config.max_profile_age and self.runtime.state.players[key] == nil then
            self.runtime.state.players[key] = Profile.Create(row, self.runtime.state.save_uid)
            state_changed = true
        end
        if row ~= nil and row.age <= Config.max_profile_age and self.runtime.state.players[key] ~= nil then
            local profile = self.runtime.state.players[key]
            PlayStyles.HydrateProfile(profile, row)
            local pending = profile.pending_transaction
            if pending ~= nil then
                if not self:CommitPreparedTransaction(
                    players_table,
                    row,
                    profile,
                    pending,
                    player_id
                ) then
                    Logger:Warn("Pending player transaction will be retried")
                end
            else
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
    end
    if self.runtime.state.initialized ~= true then
        self.runtime.state.initialized = true
        state_changed = true
    end
    if state_changed then
        local saved, save_error = self.runtime.state_store:Save(self.runtime.state)
        if not saved then
            Logger:Error("Reconciliation checkpoint failed: " .. tostring(save_error))
        end
    end
end

function Events:ProcessSeasonEnd()
    local can_write, guard_error = SaveGuard.CanWrite(self.runtime.state)
    if not can_write then
        Logger:Warn("Development skipped: " .. tostring(guard_error))
        return
    end

    local current_date = GetCurrentDate():ToInt()
    if self.runtime.state.last_processed_date == current_date then
        return
    end

    local players_table = LE.db:GetTable("players")
    local player_ids = GetUserSeniorTeamPlayerIDs()
    local rows = rows_for_players(players_table, player_ids)
    local all_successful = true
    for player_id, _ in pairs(player_ids) do
        local key = tostring(player_id)
        local row = rows[player_id]
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
                if not self:CommitPreparedTransaction(
                    players_table,
                    row,
                    profile,
                    transaction,
                    player_id
                ) then
                    all_successful = false
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
    if event_id == ENUM_CM_EVENT_MSG_INITIAL_USER_ADDED then
        local previous_eligibility = deep_copy(self.runtime.state.eligibility)
        local previous_flags = deep_copy(self.runtime.state.feature_flags)
        local _, eligibility_error = SaveGuard.MarkFreshCareer(
            self.runtime.state,
            "initial_user_added",
            GetCurrentDate():ToInt()
        )
        if eligibility_error ~= nil then
            Logger:Error("New-career activation failed: " .. tostring(eligibility_error))
            return
        end
        local saved, save_error = self.runtime.state_store:Save(self.runtime.state)
        if not saved then
            self.runtime.state.eligibility = previous_eligibility
            self.runtime.state.feature_flags = previous_flags
            Logger:Error("New-career activation checkpoint failed: " .. tostring(save_error))
            return
        end
    elseif event_id == ENUM_CM_EVENT_MSG_DATA_READY
        or event_id == ENUM_CM_EVENT_MSG_POST_LOAD_PREPARE then
        local can_write = SaveGuard.CanWrite(self.runtime.state)
        if can_write then
            self:InitializePlayers()
        end
    elseif event_id == ENUM_CM_EVENT_MSG_END_OF_SEASON_REACHED then
        self:ProcessSeasonEnd()
    end

    local observed = nil
    if TransferObserver.IsObservedEvent(event_id) then
        observed = TransferObserver.Observe(
            self.transfer_observer,
            event_id,
            nil,
            GetCurrentDate():ToInt()
        )
    end
    if observed ~= nil then
        Logger:Info(
            "transfer_event"
                .. " event_id=" .. tostring(observed.event_id)
                .. " kind=" .. tostring(observed.kind)
                .. " boundary=" .. tostring(observed.boundary)
        )
    end
end

return Events
