_addon.name = 'AutoWS'
_addon.author = 'Most likely ripped by other Github repos from ChatGPT'
_addon.version = '1.1'

_addon.commands = {'aw', 'autows'}

local enabled = false
local WS_NAME = 'Victory Smite'
local WS_THRESHOLD = 1000
local AM3_WS_NAME = nil
local AM3_TP_THRESHOLD = 3000
local last_ws = 0
local WS_RETRY_DELAY = 0.75

local function try_weapon_skill()
    if not enabled then
        return
    end

    local player = windower.ffxi.get_player()
    if not player or player.status ~= 1 then
        return
    end

    if not player.vitals then
        return
    end

    -- If an AM3 setup is configured, use its designated WS at 3000 TP
    -- until the Aftermath: Lv.3 status is active.
    local am3_active = false
    if player.buffs then
        for _, buff_id in ipairs(player.buffs) do
            -- Aftermath: Lv.3 is buff ID 272.
            if buff_id == 272 then
                am3_active = true
                break
            end
        end
    end

    local selected_ws = WS_NAME
    local selected_threshold = WS_THRESHOLD

    if AM3_WS_NAME and not am3_active then
        selected_ws = AM3_WS_NAME
        selected_threshold = AM3_TP_THRESHOLD
    end

    if player.vitals.tp < selected_threshold then
        return
    end

    local now = os.clock()
    if now - last_ws < WS_RETRY_DELAY then
        return
    end

    windower.chat.input('/ws "' .. selected_ws .. '" <t>')
    last_ws = now
end

windower.register_event('prerender', try_weapon_skill)

local function print_usage()
    windower.add_to_chat(158, '[AutoWS] Commands:')
    windower.add_to_chat(158, '//aw on | off | toggle | status')
    windower.add_to_chat(158, '//aw ws <weapon skill name>')
    windower.add_to_chat(158, '//aw am3 <AM3 setup weapon skill name | off>')
    windower.add_to_chat(158, '//aw threshold <1000-3000>')
end

windower.register_event('addon command', function(...)
    local args = {...}
    local command = args[1] and args[1]:lower() or ''

    if command == 'on' then
        enabled = true
        windower.add_to_chat(158, string.format(
            '[AutoWS] ON | WS=%s | threshold=%d TP | AM3 WS=%s',
            WS_NAME,
            WS_THRESHOLD,
            AM3_WS_NAME or 'off'
        ))

    elseif command == 'off' then
        enabled = false
        windower.add_to_chat(158, '[AutoWS] OFF')

    elseif command == 'toggle' then
        enabled = not enabled
        windower.add_to_chat(158, '[AutoWS] ' .. (enabled and 'ON' or 'OFF'))

    elseif command == 'ws' then
        if not args[2] then
            windower.add_to_chat(123, '[AutoWS] Usage: //aw ws <weapon skill name>')
            return
        end

        local parts = {}
        for i = 2, #args do
            parts[#parts + 1] = args[i]
        end

        WS_NAME = table.concat(parts, ' '):gsub('^"(.*)"$', '%1')
        windower.add_to_chat(158, '[AutoWS] Weapon skill set to: ' .. WS_NAME)

    elseif command == 'am3' then
        if not args[2] then
            windower.add_to_chat(123, '[AutoWS] Usage: //aw am3 <weapon skill name | off>')
            return
        end

        if args[2]:lower() == 'off' then
            AM3_WS_NAME = nil
            windower.add_to_chat(158, '[AutoWS] AM3 opener disabled.')
        else
            local parts = {}
            for i = 2, #args do
                parts[#parts + 1] = args[i]
            end

            AM3_WS_NAME = table.concat(parts, ' '):gsub('^"(.*)"$', '%1')
            windower.add_to_chat(158, '[AutoWS] AM3 opener set to: ' .. AM3_WS_NAME .. ' at 3000 TP; normal WS resumes when Aftermath: Lv.3 is active.')
        end

    elseif command == 'threshold' then
        local value = tonumber(args[2])

        if value and value >= 1000 and value <= 3000 then
            WS_THRESHOLD = math.floor(value)
            windower.add_to_chat(158, string.format(
                '[AutoWS] TP threshold set to %d.',
                WS_THRESHOLD
            ))
        else
            windower.add_to_chat(123, '[AutoWS] Usage: //aw threshold <1000-3000>')
        end

    elseif command == 'status' then
        local player = windower.ffxi.get_player()
        local tp = player and player.vitals and player.vitals.tp or 0
        local engaged = player and player.status == 1

        windower.add_to_chat(158, string.format(
            '[AutoWS] %s | WS=%s | threshold=%d | AM3 WS=%s | TP=%d | engaged=%s',
            enabled and 'ON' or 'OFF',
            WS_NAME,
            WS_THRESHOLD,
            AM3_WS_NAME or 'off',
            tp,
            engaged and 'yes' or 'no'
        ))

    elseif command == 'help' or command == '' then
        print_usage()
    end
end)

windower.register_event('load', function()
    windower.add_to_chat(158, '[AutoWS] Loaded v' .. _addon.version)
    windower.add_to_chat(158, '[AutoWS] //aw on')
end)
