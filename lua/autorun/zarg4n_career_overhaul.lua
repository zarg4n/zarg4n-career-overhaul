local source_path = debug.getinfo(1, "S").source
if string.sub(source_path, 1, 1) == "@" then
    local script_directory = string.match(string.sub(source_path, 2), "^(.*[\\/])")
    if script_directory ~= nil then
        local lua_root = string.match(script_directory, "^(.*[\\/])autorun[\\/]$")
        local module_directory = lua_root and (lua_root .. "scripts/") or script_directory
        package.path = module_directory .. "?.lua;" .. package.path
    end
end

require "imports/career_mode/helpers"
require "imports/other/helpers"
require "imports/core/live_editor"

local Config = require "zarg4n_config"
local Logger = require "zarg4n_logger"
local StateStore = require "zarg4n_state_store"
local Events = require "zarg4n_events"
local SaveGuard = require "zarg4n_save_guard"
local Migrations = require "zarg4n_migrations"

local runtime = {
    author = Config.author,
    state = nil,
    state_store = nil,
    events = nil,
    player_development_manager = nil,
    development_manager_ready = false,
}

local function clear_active_save()
    runtime.state = nil
    runtime.events = nil
    runtime.player_development_manager = nil
    runtime.development_manager_ready = false
end

local function safe_error(message)
    pcall(function()
        Logger:Error(tostring(message))
    end)
end

local function load_save(save_uid)
    runtime.state_store = runtime.state_store or StateStore.new(Logger)
    local state, error_message = runtime.state_store:Load(save_uid)
    if state == nil then
        clear_active_save()
        safe_error("State load failed: " .. tostring(error_message))
        return false
    end

    runtime.state = state
    runtime.player_development_manager = LE.player_development_manager
    runtime.development_manager_ready = false
    runtime.events = Events.new(runtime)
    Logger:Info(
        "Loaded " .. Config.author
            .. " runtime v" .. Config.version
            .. " for " .. Config.target_title_update
    )
    return true
end

local function bootstrap()
    if not IsInCM() then
        Logger:Info("Career mode not active; runtime disabled")
        return
    end

    local save_uid = GetSaveUID()
    if not Migrations.IsValidSaveUid(save_uid) then
        clear_active_save()
        safe_error("Invalid save UID; runtime disabled")
        return
    end

    load_save(save_uid)
end

local function on_career_event(_, event_id, event)
    if runtime.events == nil then
        bootstrap()
    end
    if runtime.events ~= nil and IsInCM() then
        local save_uid = GetSaveUID()
        if not Migrations.IsValidSaveUid(save_uid) then
            clear_active_save()
            safe_error("Career event ignored because save UID is invalid")
            return
        end
        if runtime.state == nil or runtime.state.save_uid ~= save_uid then
            if not load_save(save_uid) then
                return
            end
        end
        runtime.events:OnCareerEvent(_, event_id, event)
    end
end

function Zarg4nCareerOnEvent(...)
    local arguments = { ... }
    local ok, error_message = xpcall(function()
        on_career_event(table.unpack(arguments))
    end, function(runtime_error)
        return debug.traceback(tostring(runtime_error), 2)
    end)
    if not ok then
        safe_error("Career event failed safely: " .. tostring(error_message))
    end
end

if not _G.ZARG4N_CAREER_RUNTIME_LOADED then
    AddEventHandler("post__CareerModeEvent", Zarg4nCareerOnEvent)
    _G.ZARG4N_CAREER_RUNTIME_LOADED = true
    bootstrap()
end
