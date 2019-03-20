local _M = {
    _VERSION = "1.0.0.1",
    _DESCRIPTION = "wrapper of lua socket tcp upstream"
}

local tbl_insert = table.insert
local setmetatable, getmetatable = setmetatable, getmetatable
local tostring, pairs, ipairs = tostring, pairs, ipairs
local str_sub = string.sub
local math_ceil = math.ceil

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."
local async_socket = require(cwd .. "async_socket")
local timer = require(cwd .. "socket_timer")

-- constant
local STATE_IDLE = 0
local STATE_CONNECTING = 1
local STATE_RECONNECTING = 2
local STATE_CONNECTED = 3
local STATE_CLEANUP = 4
local STATE_CLOSED = 5

--
local mt = {__index = _M}

function _M.new(self, id)
    return setmetatable(
        {
            --
            id = id,
            --
            upstream = false,
            state = STATE_IDLE,
            --
            enable_reconnect = true,
            reconnect_delay_seconds = 10.001,
            reconnect_timer = false,
            --
            is_connecting = false,
        },
        mt
    )
end

--
function _M.get_packet_obj(self)
    if self.packet_obj and self.upstream then
        return self.packet_obj
    end
end

--
function _M.send_raw(self, data)
    local conn = self.conn
    return self.conn:send(data)
end

--
function _M.send_packet(self, ...)
    local packet_obj = self.packet_obj
    local sock = self.upstream
    return packet_obj:send_packet(sock, ...)
end

--
function _M.cleanup(self) 
    local sock = self.upstream
    if not sock then
        return nil, "not initialized"
    end
    sock:close()
    self.upstream = false
    self.state = STATE_CLEANUP
end        

--
function _M.close(self)
    self:cleanup()
    self.state = STATE_CLOSED
end

--
function _M.reconnect(self, opts, last_error)
    if self.state ~= STATE_CLOSED and self.enable_reconnect and self.reconnect_delay_seconds > 0 then
        -- try reconnect
        if self.state ~= STATE_RECONNECTING then
            if not self.reconnect_timer then
                self.reconnect_timer = timer:new()
                self.reconnect_timer:set_interval(self.reconnect_delay_seconds * 1000)
                self.reconnect_timer:start()
            else
                self.reconnect_timer:restart()
            end

            --
            print("connid=" .. tostring(self.id) .. ", reconnect after(s): " .. tostring(self.reconnect_delay_seconds))

            --
            self.state = STATE_RECONNECTING
        end
    else
        return nil, last_error
    end
end

--
function _M.init(self, opts)
    -- opts
    self.opts = opts

    -- append timeouts
    self.opts.timeouts = {
        connect_timeout_in_ms = 10 * 1000,
        send_timeout_in_ms = 100,
        read_idle_timeout_in_ms = 1800 * 1000,
    }
end

local function __on_connect(self)
    -- packet obj
    self.packet_obj = self.opts.packet_cls.new()

    --
    local cb = self.opts.connected_cb
    if cb then
        cb(self)
    end
end

local function __on_connect_failed(self, errstr)
    --
    local cb = self.opts.error_cb
    if cb then
        cb(self, errstr)
    end

    -- reconnect
    return self:reconnect(self.opts, errstr)
end

local function __on_receive_failed(self, errstr)
    --
    local cb = self.opts.error_cb
    if cb then
        cb(self, errstr)
    end

    -- reconnect
    return self:reconnect(self.opts, errstr)
end

--
function _M.connect(self)
    --
    local host = self.opts.server.host
    local port = self.opts.server.port or 8860

    --
    local function __readcb(sock, data)
        print(sock, data)
    end

    -- new async socket tcp
    local as_tcp = async_socket.tcp_client(__readcb)
    as_tcp:settimeouts(
        self.opts.timeouts.connect_timeout_in_ms,
        self.opts.timeouts.send_timeout_in_ms,
        self.opts.timeouts.read_idle_timeout_in_ms)

    --
    local flag = as_tcp:connect(host, port, 1000)
    print("CONNECT:", flag)
    if flag < 0 then 
        as_tcp:close()
        self.state = STATE_CLEANUP

    else
        self.upstream = as_tcp
        if 0 == flag then 
            self.state = STATE_CONNECTING
        else
            self.state = STATE_CONNECTED
            __on_connect(self)
        end
    end
end

--
function _M.read_packet(self)
    if self.opts and self.packet_obj and self.upstream then
        -- read packet loop
        local pkt, err, err_
        while true do
            pkt, err, err_ = self.packet_obj:read(self.upstream)
            if pkt then
                if self.opts.got_packet_cb then
                    -- packet dispatcher
                    self.opts.got_packet_cb(self, pkt)
                end
                return pkt, true
            elseif err ~= "timeout" then
                --
                if self.opts.disconnected_cb then
                    self.opts.disconnected_cb(self)
                end

                -- cleanup
                self:cleanup()
                return nil, "read_packet: failed, connid=" .. tostring(self.id) .. ", " .. err .. " -- " .. err_
            end
        end
    end
    return nil, "read_packet: not connected yet!!!"
end

--
local last_reconnect_cd = 0

--
function _M.update(self)
    if self.state == STATE_CONNECTING then
        --
        local ok, err = self.upstream:check_connecting()
        if ok then
            self.state = STATE_CONNECTED
            __on_connect(self)
        elseif err ~= "EAGAIN" then
            __on_connect_failed(self, err)
        end
    elseif self.state == STATE_RECONNECTING then
        local rest = self.reconnect_timer:rest()
        if 0 == rest then
            return self:connect()
        else
            local cd = math_ceil(rest/1000)
            if cd ~= last_reconnect_cd then
                print("reconnect countdown(s):" .. tostring(cd))
                last_reconnect_cd = cd
            end
        end
    elseif self.state == STATE_CONNECTED then
        -- receive
        local data, err = self.upstream:receive()
        if data then
            self.packet_obj:decode(data, self.opts.got_packet_cb, self)
        elseif err ~= "EAGAIN" then
            __on_receive_failed(self, err)
        end
    else
       --
       print("idle")
    end
end

function _M.run(self, opts)
    --
    self:init(opts)

    -- connect first time
    self:connect()
end

return _M
