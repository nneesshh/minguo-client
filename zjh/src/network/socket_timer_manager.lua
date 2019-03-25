local pairs = pairs
-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."
local timer_cls = require(cwd .. "socket_timer")

--
local _M = {
    _VERSION = "1.0.0.1",
    _DESCRIPTION = "manage socket timers with name",

    timers = {},
    next_timer_id = 0
}

_M.new = function(...)
    return timer_cls:new(...)
end

function _M.set_expired(timeout_in_ms, cb)
    assert(type(timeout_in_ms) == 'number')
    assert(type(cb) == 'function')
    local timer = _M.new()
    timer:set_interval(timeout_in_ms)
    timer:start()

    _M.next_timer_id = _M.next_timer_id + 1
    _M.timers[_M.next_timer_id] = {
        timer = timer,
        cb = cb,
        countdown = 1
    }
    return _M.next_timer_id
end

function _M.remove(id)
    _M.timers[id] = nil
end

function _M.update()
    for k, v in pairs(_M.timers) do
        if 0 == v.timer:rest() then
            v.cb()

            if v.countdown > 0 then
                v.countdown = v.countdown - 1
            end
            if 0 == v.countdown then
                _M.timers[k] = nil
            end
        end
    end
end

return _M
