local SPELL_ID = 1261193
local NUM_TICKS = 4
local SURVIVAL_SPEC_INDEX = 3

local DEFAULT_SOUND_CHANNEL = "Master"

local VALID_CHANNELS = {
    Master = true,
    SFX = true,
    Ambience = true,
    Music = true,
    Dialog = true,
}

local SOUND_FILES = {
    "Interface\\AddOns\\BoomstickGoBoom\\tick1.ogg",
    "Interface\\AddOns\\BoomstickGoBoom\\tick2.ogg",
    "Interface\\AddOns\\BoomstickGoBoom\\tick3.ogg",
    "Interface\\AddOns\\BoomstickGoBoom\\tick4.ogg",
}

local TICK_FRACTIONS = {
    0,
    1 / 3,
    2 / 3,
    1,
}

local FINAL_TICK_GRACE_MS = 200

-- Cheap no-op for non-Hunters.
local _, classFile = UnitClass("player")
if classFile ~= "HUNTER" then
    return
end

local f = CreateFrame("Frame")

local enabled = false
local activeToken = 0
local activeCastGUID = nil
local expectedEndMs = nil
local playedTick = {}

local function applyDefaults()
    if type(BoomstickGoBoomDB) ~= "table" then
        BoomstickGoBoomDB = {}
    end

    if not VALID_CHANNELS[BoomstickGoBoomDB.soundChannel] then
        BoomstickGoBoomDB.soundChannel = DEFAULT_SOUND_CHANNEL
    end
end

local function getSoundChannel()
    return BoomstickGoBoomDB.soundChannel or DEFAULT_SOUND_CHANNEL
end

local function getCurrentSpecIndex()
    return C_SpecializationInfo.GetSpecialization()
end

local function isSurvivalHunter()
    return getCurrentSpecIndex() == SURVIVAL_SPEC_INDEX
end

local function getBoomstickChannel()
    local _, _, _, startTimeMs, endTimeMs, _, _, spellID = UnitChannelInfo("player")

    if spellID == SPELL_ID and startTimeMs and endTimeMs then
        return startTimeMs, endTimeMs
    end
end

local function currentChannelIsBoomstick()
    return getBoomstickChannel() ~= nil
end

local function playTick(token, tickIndex, requireChannel)
    if token ~= activeToken then
        return
    end

    if playedTick[tickIndex] then
        return
    end

    if requireChannel and not currentChannelIsBoomstick() then
        return
    end

    local soundFile = SOUND_FILES[tickIndex]
    if not soundFile then
        return
    end

    playedTick[tickIndex] = true
    PlaySoundFile(soundFile, getSoundChannel())
end

local function scheduleRemainingTicks(token)
    local startTimeMs, endTimeMs = getBoomstickChannel()
    if not startTimeMs then
        return
    end

    expectedEndMs = endTimeMs

    local nowMs = GetTime() * 1000
    local durationMs = endTimeMs - startTimeMs

    for i = 2, NUM_TICKS do
        local tickIndex = i
        if not playedTick[tickIndex] then
            local tickTimeMs = startTimeMs + durationMs * TICK_FRACTIONS[tickIndex]
            local delay = math.max(0, (tickTimeMs - nowMs) / 1000)

            C_Timer.After(delay, function()
                playTick(token, tickIndex, true)
            end)
        end
    end
end

local function resetCastState()
    activeToken = activeToken + 1
    activeCastGUID = nil
    expectedEndMs = nil
    wipe(playedTick)
end

local function startBoomstick(castGUID)
    resetCastState()

    activeCastGUID = castGUID
    local token = activeToken

    -- Tick 1 is immediate.
    playTick(token, 1, false)

    scheduleRemainingTicks(token)
end

local function updateBoomstick(castGUID)
    if castGUID ~= activeCastGUID then
        return
    end

    activeToken = activeToken + 1
    scheduleRemainingTicks(activeToken)
end

local function stopBoomstick(castGUID, interrupted)
    if castGUID ~= activeCastGUID then
        return
    end

    local token = activeToken

    if not interrupted
        and expectedEndMs
        and not playedTick[NUM_TICKS]
        and (GetTime() * 1000) >= (expectedEndMs - FINAL_TICK_GRACE_MS)
    then
        playTick(token, NUM_TICKS, false)
    end

    resetCastState()
end

local function setRuntimeEnabled(shouldEnable)
    if enabled == shouldEnable then
        return
    end

    enabled = shouldEnable

    if enabled then
        f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    else
        f:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        f:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        f:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        f:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        resetCastState()
    end
end

local function updateEnabled()
    setRuntimeEnabled(isSurvivalHunter())
end

local function normalizeChannelName(channel)
    channel = (channel or ""):match("^%s*(.-)%s*$")

    if channel:lower() == "sfx" then
        return "SFX"
    end

    return channel:sub(1, 1):upper() .. channel:sub(2):lower()
end

local function printStatus()
    print(("BoomstickGoBoom: channel=%s"):format(getSoundChannel()))
end

SLASH_BOOMSTICKGOBOOM1 = "/boomstick"
SLASH_BOOMSTICKGOBOOM2 = "/bgb"

SlashCmdList.BOOMSTICKGOBOOM = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$")

    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd or ""
    arg = arg or ""

    if cmd == "channel" then
        local channel = normalizeChannelName(arg)

        if VALID_CHANNELS[channel] then
            BoomstickGoBoomDB.soundChannel = channel
            printStatus()
        else
            print("BoomstickGoBoom: channel must be Master, SFX, Ambience, Music, or Dialog.")
        end

        return
    end

    if cmd == "test" then
        for i = 1, NUM_TICKS do
            local tickIndex = i

            C_Timer.After((tickIndex - 1) * 0.75, function()
                PlaySoundFile(SOUND_FILES[tickIndex], getSoundChannel())
            end)
        end

        return
    end

    print("BoomstickGoBoom commands:")
    print("/bgb channel Master|SFX|Ambience|Music|Dialog")
    print("/bgb test")
    printStatus()
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

f:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if event == "PLAYER_LOGIN" then
        applyDefaults()
        updateEnabled()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit == "player" then
            updateEnabled()
        end
        return
    end

    -- Channel events are only registered while Survival.
    if unit ~= "player" then
        return
    end

    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        if spellID == SPELL_ID then
            startBoomstick(castGUID)
        end

        return
    end

    if event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        updateBoomstick(castGUID)
        return
    end

    if event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        stopBoomstick(castGUID, false)
        return
    end

    if event == "UNIT_SPELLCAST_INTERRUPTED" then
        stopBoomstick(castGUID, true)
    end
end)
