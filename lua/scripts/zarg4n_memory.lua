local Memory = {}

local function prune_expired(memory, boundary)
    for id, entry in pairs(memory.entries) do
        if boundary >= entry.expires_at or entry.intensity <= 0 then
            memory.entries[id] = nil
        end
    end
end

local function trim_to_capacity(memory)
    local entries = {}
    for _, entry in pairs(memory.entries) do
        entries[#entries + 1] = entry
    end
    table.sort(entries, function(left, right)
        if left.created_at == right.created_at then
            return left.id < right.id
        end
        return left.created_at < right.created_at
    end)
    for index = 1, math.max(0, #entries - memory.max_entries) do
        memory.entries[entries[index].id] = nil
    end
end

function Memory.New(max_event_age, max_entries)
    local age = math.max(1, math.floor(tonumber(max_event_age) or 6))
    return {
        max_event_age = age,
        max_entries = math.max(1, math.floor(tonumber(max_entries) or 64)),
        current_boundary = nil,
        entries = {},
    }
end

function Memory.Advance(memory, boundary)
    assert(type(memory) == "table" and type(memory.entries) == "table", "invalid memory")

    local next_boundary = math.floor(tonumber(boundary) or 0)
    local previous = memory.current_boundary
    if previous == nil then
        memory.current_boundary = next_boundary
        prune_expired(memory, next_boundary)
        return memory
    end
    if next_boundary <= previous then
        prune_expired(memory, previous)
        return memory
    end

    local elapsed = next_boundary - previous
    for _, entry in pairs(memory.entries) do
        entry.intensity = math.max(0, entry.intensity - elapsed)
    end
    memory.current_boundary = next_boundary
    prune_expired(memory, next_boundary)
    return memory
end

function Memory.Remember(memory, event, boundary)
    assert(type(memory) == "table" and type(memory.entries) == "table", "invalid memory")
    assert(type(event) == "table" and event.id ~= nil, "memory event requires an id")

    local event_boundary = math.floor(tonumber(boundary) or 0)
    if memory.current_boundary == nil or event_boundary > memory.current_boundary then
        Memory.Advance(memory, event_boundary)
    end
    local reference_boundary = memory.current_boundary or event_boundary
    local age = math.max(0, reference_boundary - event_boundary)
    local entry = {
        id = tostring(event.id),
        kind = tostring(event.kind or "generic"),
        intensity = math.max(0, math.floor(tonumber(event.intensity) or 1) - age),
        created_at = event_boundary,
        expires_at = event_boundary + memory.max_event_age,
        metadata = event.metadata,
    }

    if reference_boundary < entry.expires_at and entry.intensity > 0 then
        memory.entries[entry.id] = entry
    end
    prune_expired(memory, reference_boundary)
    trim_to_capacity(memory)
    return entry
end

function Memory.Active(memory, boundary)
    Memory.Advance(memory, boundary)
    local active = {}
    for _, entry in pairs(memory.entries) do
        active[#active + 1] = entry
    end
    table.sort(active, function(left, right)
        if left.created_at == right.created_at then
            return left.id < right.id
        end
        return left.created_at < right.created_at
    end)
    return active
end

return Memory
