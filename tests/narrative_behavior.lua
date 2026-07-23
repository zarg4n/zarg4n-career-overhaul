package.path = "src/lua/?.lua;" .. package.path

local Personality = require "zarg4n_personality"
local Memory = require "zarg4n_memory"
local Dialogue = require "zarg4n_dialogue"
local TransferObserver = require "zarg4n_transfer_observer"

local function assert_equal(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local first = Personality.Create(1907, "career-a")
local repeated = Personality.Create(1907, "career-a")
local other = Personality.Create(1908, "career-a")

assert_equal(first.impulsive, repeated.impulsive, "personality must be deterministic")
assert_equal(first.calm, repeated.calm, "calm dimension must be deterministic")
assert_equal(first.carefree, repeated.carefree, "carefree dimension must be deterministic")
assert(first.impulsive >= 0 and first.impulsive <= 100, "impulsive must be bounded")
assert(first.calm >= 0 and first.calm <= 100, "calm must be bounded")
assert(first.carefree >= 0 and first.carefree <= 100, "carefree must be bounded")
assert(
    first.impulsive ~= other.impulsive
        or first.calm ~= other.calm
        or first.carefree ~= other.carefree,
    "different players should not all receive the same personality"
)

local impulsive = { impulsive = 88, calm = 18, carefree = 20, ambition = 72, confidence = 55 }
local calm = { impulsive = 12, calm = 90, carefree = 25, ambition = 68, confidence = 60 }
local carefree = { impulsive = 20, calm = 58, carefree = 92, ambition = 35, confidence = 66 }

local impulsive_challenge = Personality.Respond(impulsive, "challenge", { form = 1 })
local calm_criticism = Personality.Respond(calm, "criticism", { form = -1 })
local carefree_criticism = Personality.Respond(carefree, "criticism", { form = -1 })
local calm_praise = Personality.Respond(calm, "praise", { form = 1 })
local symmetric_rounding = Personality.Respond(
    { impulsive = 50, calm = 50, carefree = 50, ambition = 0, confidence = 50 },
    "challenge",
    { form = 0 }
)

assert(impulsive_challenge.effects.sharpness > 0, "impulsive players should be energized by a challenge")
assert(calm_criticism.effects.trust >= carefree_criticism.effects.trust, "calm players should absorb criticism better")
assert(carefree_criticism.effects.morale > calm_criticism.effects.morale, "carefree players should shrug off criticism")
assert(calm_praise.effects.morale > 0, "praise should produce a pure morale response")
assert(impulsive_challenge.effects.applied == nil, "responses must not claim effects were applied")
assert_equal(symmetric_rounding.effects.morale, -1, "negative effects must round symmetrically")

local memory = Memory.New(3)
Memory.Remember(memory, { id = "promise-1", kind = "promise", intensity = 5 }, 10)
assert_equal(#Memory.Active(memory, 10), 1, "new memory must be active")
Memory.Advance(memory, 11)
assert_equal(Memory.Active(memory, 11)[1].intensity, 4, "one event must decay memory once")
Memory.Advance(memory, 11)
assert_equal(Memory.Active(memory, 11)[1].intensity, 4, "same event boundary must not decay twice")
Memory.Advance(memory, 14)
assert_equal(#Memory.Active(memory, 14), 0, "memory must expire at its event boundary")

local bounded_memory = Memory.New(3, 3)
Memory.Remember(bounded_memory, { id = "current", intensity = 5 }, 100)
Memory.Remember(bounded_memory, { id = "already-expired", intensity = 5 }, 1)
assert_equal(#Memory.Active(bounded_memory, 100), 1, "out-of-order expired memories must be discarded")
for boundary = 101, 104 do
    Memory.Remember(bounded_memory, { id = "event-" .. boundary, intensity = 10 }, boundary)
end
local bounded_active = Memory.Active(bounded_memory, 104)
assert_equal(#bounded_active, 3, "memory entry count must remain bounded")
assert_equal(bounded_active[1].id, "event-102", "memory must retain the newest bounded entries")

local all_dialogue_tags = {
    "impact",
    "score_contribution",
    "cameo",
    "pressing",
    "poor",
    "goal",
    "defensive",
    "rushed",
    "pressure",
    "strong",
    "rejected",
    "counter_offer",
    "negotiation",
    "retracted",
    "loan",
    "about_to_complete",
    "complete",
    "transfer_message",
}

for _, family in ipairs({ "post_match", "promise", "press", "transfer_observer" }) do
    local seen = {}
    for seed = 1, 30 do
        local key = Dialogue.SelectKey(family, seed, { tags = all_dialogue_tags })
        assert(key:match("^" .. family .. "%.%d%d$"), "dialogue key must belong to requested family")
        seen[key] = true
    end
    local count = 0
    for _ in pairs(seen) do
        count = count + 1
    end
    assert_equal(count, 10, family .. " must expose ten deterministic variants")
end

for seed = 1, 20 do
    local generic_post_match = Dialogue.SelectKey("post_match", seed)
    assert(
        generic_post_match ~= "post_match.03" and generic_post_match ~= "post_match.06",
        "cameo and goal lines must require matching post-match tags"
    )
    assert_equal(
        Dialogue.SelectKey("post_match", seed, { tags = { "cameo" } }),
        "post_match.03",
        "cameo context must select a cameo-eligible line"
    )
end

local observer = TransferObserver.New()
local poison_pointer = setmetatable({}, {
    __index = function()
        error("observer dereferenced event pointer")
    end,
})
local first_event = TransferObserver.Observe(observer, 94, poison_pointer, 500)
local duplicate = TransferObserver.Observe(observer, 94, poison_pointer, 500)
local next_event = TransferObserver.Observe(observer, 96, poison_pointer, 501)
local unrelated = TransferObserver.Observe(observer, 999, poison_pointer, 502)

assert_equal(first_event.kind, "bid_rejected", "known transfer event must be classified")
assert_equal(first_event.dialogue_family, "transfer_observer", "observer must return narration metadata")
for seed = 1, 20 do
    local rejected_key = Dialogue.SelectKey("transfer_observer", seed, { tags = first_event.dialogue_tags })
    assert(
        rejected_key == "transfer_observer.01" or rejected_key == "transfer_observer.02",
        "rejected bids must not select counter-offer or completed-transfer text"
    )
    local counter_key = Dialogue.SelectKey("transfer_observer", seed, { tags = next_event.dialogue_tags })
    assert(
        counter_key == "transfer_observer.03" or counter_key == "transfer_observer.04",
        "counter offers must select counter-offer text"
    )
end
local completed_event = TransferObserver.Observe(observer, 86, poison_pointer, 503)
assert_equal(
    Dialogue.SelectKey("transfer_observer", 1, { tags = completed_event.dialogue_tags }),
    "transfer_observer.09",
    "completed transfers must select completed-transfer text"
)
assert(duplicate == nil, "same event id and boundary must be deduplicated")
assert_equal(next_event.kind, "counter_offer", "different transfer event must be observed")
assert(unrelated == nil, "unrelated event ids must be ignored")
assert(first_event.effects == nil, "observer must not apply or invent game effects")

local bounded_observer = TransferObserver.New(3, 2)
for boundary = 1, 5 do
    TransferObserver.Observe(bounded_observer, 94, poison_pointer, boundary)
end
local seen_count = 0
for _ in pairs(bounded_observer.seen) do
    seen_count = seen_count + 1
end
assert(seen_count <= 3, "observer seen cache must remain bounded")
assert(
    TransferObserver.Observe(bounded_observer, 94, poison_pointer, 5) == nil,
    "observer must retain dedupe for recent events"
)
local stale_observer = TransferObserver.New(10, 2)
TransferObserver.Observe(stale_observer, 94, poison_pointer, 10)
assert(
    TransferObserver.Observe(stale_observer, 96, poison_pointer, 1) == nil,
    "observer must ignore events older than its retained boundary window"
)

print("PASS: narrative behavior")
