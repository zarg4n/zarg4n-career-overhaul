local TransferObserver = {}

local EVENT_KINDS = {
    [64] = "contract_negotiation",
    [74] = "cpu_transfer_info",
    [85] = "move_about_to_complete",
    [86] = "move_complete",
    [87] = "presigned_contract",
    [94] = "bid_rejected",
    [95] = "bid_retracted",
    [96] = "counter_offer",
    [97] = "counter_offer_rejected",
    [103] = "loan_to_buy_opened",
    [104] = "loan_to_buy_updated",
    [105] = "loan_to_buy_rejected",
    [106] = "loan_to_buy_accepted",
    [107] = "loan_to_buy_completed",
    [172] = "transfer_message",
}

local DIALOGUE_TAGS = {
    contract_negotiation = { "negotiation" },
    cpu_transfer_info = { "transfer_message" },
    move_about_to_complete = { "about_to_complete" },
    move_complete = { "complete" },
    presigned_contract = { "about_to_complete" },
    bid_rejected = { "rejected" },
    bid_retracted = { "retracted" },
    counter_offer = { "counter_offer" },
    counter_offer_rejected = { "rejected" },
    loan_to_buy_opened = { "loan" },
    loan_to_buy_updated = { "loan" },
    loan_to_buy_rejected = { "rejected" },
    loan_to_buy_accepted = { "loan" },
    loan_to_buy_completed = { "complete" },
    transfer_message = { "transfer_message" },
}

local function prune_seen(observer, boundary)
    local numeric_boundary = tonumber(boundary)
    if numeric_boundary then
        observer.current_boundary = math.max(observer.current_boundary or numeric_boundary, numeric_boundary)
        local cutoff = observer.current_boundary - observer.max_boundary_age
        for key, entry in pairs(observer.seen) do
            if entry.boundary and entry.boundary < cutoff then
                observer.seen[key] = nil
            end
        end
    end

    local entries = {}
    for key, entry in pairs(observer.seen) do
        entries[#entries + 1] = { key = key, order = entry.order }
    end
    table.sort(entries, function(left, right)
        return left.order < right.order
    end)
    for index = 1, math.max(0, #entries - observer.max_seen) do
        observer.seen[entries[index].key] = nil
    end
end

function TransferObserver.New(max_seen, max_boundary_age)
    return {
        seen = {},
        max_seen = math.max(1, math.floor(tonumber(max_seen) or 128)),
        max_boundary_age = math.max(1, math.floor(tonumber(max_boundary_age) or 32)),
        sequence = 0,
        current_boundary = nil,
    }
end

function TransferObserver.IsObservedEvent(event_id)
    return EVENT_KINDS[tonumber(event_id)] ~= nil
end

function TransferObserver.Observe(observer, event_id, _, boundary)
    assert(type(observer) == "table" and type(observer.seen) == "table", "invalid observer")

    local numeric_id = tonumber(event_id)
    local kind = EVENT_KINDS[numeric_id]
    if not kind then
        return nil
    end

    local event_boundary = tostring(boundary or "")
    local dedupe_key = tostring(numeric_id) .. ":" .. event_boundary
    prune_seen(observer, boundary)
    local numeric_boundary = tonumber(boundary)
    if
        numeric_boundary
        and observer.current_boundary
        and numeric_boundary < observer.current_boundary - observer.max_boundary_age
    then
        return nil
    end
    if observer.seen[dedupe_key] then
        return nil
    end
    observer.sequence = observer.sequence + 1
    observer.seen[dedupe_key] = {
        boundary = numeric_boundary,
        order = observer.sequence,
    }
    prune_seen(observer, boundary)

    return {
        event_id = numeric_id,
        boundary = boundary,
        kind = kind,
        dialogue_family = "transfer_observer",
        dialogue_seed = dedupe_key,
        dialogue_tags = DIALOGUE_TAGS[kind],
    }
end

return TransferObserver
