local Logger = {}

local function stringify(value)
    if type(value) == "string" then
        return value
    end
    return tostring(value)
end

function Logger:Info(message)
    Log("[zarg4n] " .. stringify(message), 1)
end

function Logger:Warn(message)
    Log("[zarg4n][WARN] " .. stringify(message), 2)
end

function Logger:Error(message)
    Log("[zarg4n][ERROR] " .. stringify(message), 3)
end

function Logger:Protected(label, callback)
    local ok, result = pcall(callback)
    if not ok then
        self:Error(label .. ": " .. tostring(result))
        return false, nil
    end
    return true, result
end

return Logger
