local Json = require "imports/external/json"
local Config = require "zarg4n_config"

local StateStore = {}
StateStore.__index = StateStore

local function state_path(save_uid)
    local user_profile = os.getenv("USERPROFILE") or "."
    return string.format(
        "%s\\Desktop\\%s%s.json",
        user_profile,
        Config.state_file_prefix,
        save_uid
    )
end

function StateStore.new(logger)
    return setmetatable({ logger = logger }, StateStore)
end

function StateStore:Load(save_uid)
    if save_uid == nil or save_uid == "" then
        return nil, "empty save uid"
    end

    local file = io.open(state_path(save_uid), "r")
    if file == nil then
        return {
            schema_version = 1,
            save_uid = save_uid,
            initialized = false,
            last_processed_date = 0,
            players = {},
        }, nil
    end

    local content = file:read("*a")
    file:close()

    local ok, decoded = pcall(Json.decode, content)
    if not ok or type(decoded) ~= "table" or decoded.save_uid ~= save_uid then
        self.logger:Warn("State corrupted or belongs to another save; starting clean")
        return {
            schema_version = 1,
            save_uid = save_uid,
            initialized = false,
            last_processed_date = 0,
            players = {},
        }, nil
    end

    decoded.players = decoded.players or {}
    return decoded, nil
end

function StateStore:Save(state)
    if type(state) ~= "table" or state.save_uid == nil or state.save_uid == "" then
        return false, "invalid state"
    end

    local file, error_message = io.open(state_path(state.save_uid), "w")
    if file == nil then
        return false, error_message or "unable to open state file"
    end

    local ok, encoded = pcall(Json.encode, state)
    if not ok then
        file:close()
        return false, encoded
    end

    file:write(encoded)
    file:close()
    return true, nil
end

return StateStore
