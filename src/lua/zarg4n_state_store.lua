local Json = require "imports/external/json"
local Config = require "zarg4n_config"
local Migrations = require "zarg4n_migrations"

local StateStore = {}
StateStore.__index = StateStore

local function state_path(save_uid)
    local data_root = LE_DATA_PATH or "."
    return string.format(
        "%s\\%s%s.json",
        data_root,
        Config.state_file_prefix,
        save_uid
    )
end

local function empty_state(save_uid)
    return Migrations.NewState(save_uid)
end

local function validate_state(state, save_uid)
    local ok, validated, validation_error = pcall(
        Migrations.ValidateCurrent,
        state,
        save_uid
    )
    if not ok then
        return nil, "state validation failed"
    end
    return validated, validation_error
end

local function decode_state(path, save_uid)
    local file = io.open(path, "r")
    if file == nil then
        return nil
    end
    local content = file:read("*a")
    file:close()
    local ok, decoded = pcall(Json.decode, content)
    if not ok or type(decoded) ~= "table" or decoded.save_uid ~= save_uid then
        return nil
    end
    return decoded
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file == nil then
        return false
    end
    file:close()
    return true
end

function StateStore.new(logger)
    return setmetatable({ logger = logger }, StateStore)
end

function StateStore:Load(save_uid)
    if not Migrations.IsValidSaveUid(save_uid) then
        return nil, "invalid save uid"
    end

    local path = state_path(save_uid)
    local primary_exists = file_exists(path)
    local backup_exists = file_exists(path .. ".bak")
    local state = decode_state(path, save_uid)
    if state ~= nil then
        local validated, validation_error = validate_state(state, save_uid)
        if validated ~= nil then
            return validated, nil
        end
        self.logger:Warn("Primary career state failed validation: "
            .. tostring(validation_error))
    end

    local backup = decode_state(path .. ".bak", save_uid)
    if backup ~= nil then
        local validated, validation_error = validate_state(backup, save_uid)
        if validated ~= nil then
            self.logger:Warn("Recovered career state from backup")
            return validated, nil
        end
        self.logger:Warn("Backup career state failed validation: "
            .. tostring(validation_error))
    end

    if primary_exists or backup_exists then
        return nil, "state file is corrupted and no valid backup is available"
    end

    return empty_state(save_uid)
end

function StateStore:Save(state)
    if type(state) ~= "table"
        or not Migrations.IsValidSaveUid(state.save_uid) then
        return false, "invalid state"
    end

    local ok, encoded = pcall(Json.encode, state)
    if not ok then
        return false, encoded
    end

    local path = state_path(state.save_uid)
    local temporary_path = path .. ".tmp"
    local backup_path = path .. ".bak"
    local file, error_message = io.open(temporary_path, "w")
    if file == nil then
        return false, error_message or "unable to open temporary state file"
    end
    local written, write_error = file:write(encoded)
    if written == nil then
        file:close()
        os.remove(temporary_path)
        return false, write_error or "unable to write temporary state file"
    end
    file:flush()
    file:close()

    os.remove(backup_path)
    local existing = io.open(path, "r")
    if existing ~= nil then
        existing:close()
        local backed_up, backup_error = os.rename(path, backup_path)
        if not backed_up then
            os.remove(temporary_path)
            return false, backup_error or "unable to rotate state backup"
        end
    end

    local replaced, replace_error = os.rename(temporary_path, path)
    if not replaced then
        os.rename(backup_path, path)
        os.remove(temporary_path)
        return false, replace_error or "unable to replace state file"
    end
    return true, nil
end

return StateStore
