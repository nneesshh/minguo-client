local socket = require "socket"
local IS_WINDOWS = (package.config:sub(1, 1) == "\\")

local function s_sleep(ms)
    return socket.sleep(ms / 1000)
end

---
-- get UTC((time relative to January 1, 1970)) time in ms
local function s_gettime()
    return socket.gettime() * 1000
end

local function __getelapsed(t)
    return s_gettime() - t
end

---
-- timer
--
local timer = {}

function timer:new(...)
    local t = setmetatable({}, {__index = self})
    return t:init(...)
end

function timer:init()
    self.private_ = {}
    return self
end

---
-- 
function timer:set_interval(interval)
    assert("number")
    self.private_.interval = interval
    return self
end

function timer:reset()
    self.private_.start_tick = nil
    self.private_.interval = nil
end

function timer:interval()
    return self.private_.interval
end

---
-- 
function timer:start()
    self.private_.start_tick = s_gettime()
    self.private_.fire_interval = self.private_.interval
    return self
end

---
-- 
function timer:started()
    return self.private_.start_tick and true or false
end

---
-- 
function timer:stop()
    local elapsed = self:elapsed()
    self.private_.start_tick = nil
    self.private_.fire_interval = nil
    return elapsed
end

---
--
function timer:restart()
    local result = self:stop()
    self:start()
    return result
end

---
-- get elapsed time
function timer:elapsed()
    assert(self:started())
    return __getelapsed(self.private_.start_tick)
end

---
-- get remains time in ms
function timer:rest()
    assert(self:started())
    local rest = self.private_.fire_interval - self:elapsed()
    return rest > 0 and rest or 0
end

local M = {}

M.sleep = s_sleep
M.gettime = s_gettime
M.getelapsed = __getelapsed

M.new = function(...)
    return timer:new(...)
end

return M
