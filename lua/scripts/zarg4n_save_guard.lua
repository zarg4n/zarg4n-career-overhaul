local Migrations = require "zarg4n_migrations"

local SaveGuard = {}
local INITIAL_USER_MARKER = "initial_user_added"

local function valid_fresh_state(state)
    return type(state) == "table"
        and state.schema_version == Migrations.CURRENT_SCHEMA_VERSION
        and state.state_origin == Migrations.FRESH_STATE_ORIGIN
        and Migrations.IsValidSaveUid(state.save_uid)
        and type(state.players) == "table"
        and type(state.lifecycle) == "table"
        and type(state.feature_flags) == "table"
        and type(state.eligibility) == "table"
end

function SaveGuard.CanWrite(state)
    if not valid_fresh_state(state) then
        return false, "invalid, legacy, or unsupported state"
    end
    if state.lifecycle.awaiting_initial_user_added ~= false
        or state.eligibility.explicit ~= true
        or state.eligibility.source ~= "career_event"
        or state.eligibility.marker ~= INITIAL_USER_MARKER then
        return false, "fresh career activation marker is missing"
    end
    if state.feature_flags.database_writes ~= true then
        return false, "database writes are disabled"
    end
    return true, nil
end

function SaveGuard.MarkFreshCareer(state, event_marker, marked_at)
    if not valid_fresh_state(state) then
        return nil, "invalid, legacy, or unsupported state"
    end
    if event_marker ~= INITIAL_USER_MARKER then
        return nil, "invalid fresh career event"
    end
    if state.lifecycle.awaiting_initial_user_added ~= true
        or state.eligibility.explicit == true then
        return nil, "fresh career activation is not pending"
    end

    state.lifecycle.awaiting_initial_user_added = false
    state.lifecycle.activated_at = tonumber(marked_at) or 0
    state.eligibility = {
        explicit = true,
        source = "career_event",
        marker = INITIAL_USER_MARKER,
        marked_at = tonumber(marked_at) or 0,
    }
    state.feature_flags.database_writes = true
    return state, nil
end

return SaveGuard
