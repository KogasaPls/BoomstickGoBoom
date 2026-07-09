local function newHarness()
    local harness = {
        now = 0,
        channel = nil,
        sounds = {},
        timers = {},
    }

    local frame = { events = {} }

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:UnregisterEvent(event)
        self.events[event] = nil
    end

    function frame:SetScript(_, handler)
        self.handler = handler
    end

    _G.BoomstickGoBoomDB = nil
    _G.SlashCmdList = {}
    _G.C_SpecializationInfo = {
        GetSpecialization = function()
            return 3
        end,
    }
    _G.C_Timer = {
        After = function(delay, callback)
            table.insert(harness.timers, {
                delay = delay,
                callback = callback,
            })
        end,
    }

    _G.CreateFrame = function()
        return frame
    end

    _G.GetTime = function()
        return harness.now
    end

    _G.PlaySoundFile = function(sound)
        table.insert(harness.sounds, sound)
    end

    _G.UnitChannelInfo = function()
        if not harness.channel then
            return nil
        end

        return "Boomstick", "Boomstick", nil, harness.channel.startMs,
            harness.channel.endMs, false, false, 1261193
    end

    _G.UnitClass = function()
        return "Hunter", "HUNTER"
    end

    _G.wipe = function(t)
        for key in pairs(t) do
            t[key] = nil
        end
    end

    local chunk = assert(loadfile("BoomstickGoBoom.lua"))
    chunk()
    frame.handler(frame, "PLAYER_LOGIN")

    function harness:fire(event, castGUID, spellID)
        frame.handler(frame, event, "player", castGUID or "cast-1", spellID or 1261193)
    end

    function harness:runTimer(index)
        local timer = table.remove(self.timers, index or 1)
        assert(timer, "expected a pending timer")
        timer.callback()
        return timer
    end

    harness.frame = frame
    return harness
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function testChannelUpdatesAreRegistered()
    local harness = newHarness()
    assertEqual(
        harness.frame.events.UNIT_SPELLCAST_CHANNEL_UPDATE,
        true,
        "channel update event registration"
    )
end

local function testChannelUpdateInvalidatesAndReschedulesTimers()
    local harness = newHarness()
    harness.channel = { startMs = 0, endMs = 3000 }
    harness:fire("UNIT_SPELLCAST_CHANNEL_START")

    assertEqual(#harness.sounds, 1, "immediate tick count")
    assertEqual(#harness.timers, 3, "initial scheduled timer count")

    harness.now = 0.5
    harness.channel.endMs = 6000
    harness:fire("UNIT_SPELLCAST_CHANNEL_UPDATE")

    assertEqual(#harness.timers, 6, "timers retained and rescheduled")
    assertEqual(harness.timers[4].delay, 1.5, "updated second tick delay")

    harness:runTimer(1)
    assertEqual(#harness.sounds, 1, "invalidated timer sound count")

    harness:runTimer(3)
    assertEqual(#harness.sounds, 2, "rescheduled timer sound count")
end

local function testStaleStopDoesNotCancelActiveCast()
    local harness = newHarness()
    harness.channel = { startMs = 0, endMs = 3000 }
    harness:fire("UNIT_SPELLCAST_CHANNEL_START", "active-cast")

    harness:fire("UNIT_SPELLCAST_CHANNEL_STOP", "stale-cast")
    harness:runTimer()

    assertEqual(#harness.sounds, 2, "sound count after stale stop")
end

local function testChannelUpdateOnlyReschedulesUnplayedTicks()
    local harness = newHarness()
    harness.channel = { startMs = 0, endMs = 3000 }
    harness:fire("UNIT_SPELLCAST_CHANNEL_START")
    harness:runTimer()

    harness.now = 1.2
    harness.channel.endMs = 6000
    harness:fire("UNIT_SPELLCAST_CHANNEL_UPDATE")

    assertEqual(#harness.timers, 4, "pending timer count after late update")
end

local function testInterruptionInvalidatesPendingTicks()
    local harness = newHarness()
    harness.channel = { startMs = 0, endMs = 3000 }
    harness:fire("UNIT_SPELLCAST_CHANNEL_START")

    harness:fire("UNIT_SPELLCAST_INTERRUPTED")
    harness:runTimer()

    assertEqual(#harness.sounds, 1, "sound count after interruption")
end

local function testChannelStopWithinGracePlaysFinalTick()
    local harness = newHarness()
    harness.channel = { startMs = 0, endMs = 3000 }
    harness:fire("UNIT_SPELLCAST_CHANNEL_START")

    harness.now = 2.9
    harness:fire("UNIT_SPELLCAST_CHANNEL_STOP")

    assertEqual(#harness.sounds, 2, "sound count after near-end stop")
    assertEqual(
        harness.sounds[2],
        "Interface\\AddOns\\BoomstickGoBoom\\tick4.ogg",
        "near-end stop sound"
    )
end

testChannelUpdatesAreRegistered()
print("ok - channel updates are registered")
testChannelUpdateInvalidatesAndReschedulesTimers()
print("ok - channel updates invalidate and reschedule timers")
testStaleStopDoesNotCancelActiveCast()
print("ok - stale stop does not cancel active cast")
testChannelUpdateOnlyReschedulesUnplayedTicks()
print("ok - channel update only reschedules unplayed ticks")
testInterruptionInvalidatesPendingTicks()
print("ok - interruption invalidates pending ticks")
testChannelStopWithinGracePlaysFinalTick()
print("ok - channel stop within grace plays final tick")
