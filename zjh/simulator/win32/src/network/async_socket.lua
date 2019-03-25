local tbl_insert = table.insert
local tbl_concat = table.concat
local tostring = tostring

--
local socket = require("socket")

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."
local timer = require(cwd .. "socket_timer")

--
local _M = {
    _VERSION = "1.0.0.1",
    _DESCRIPTION = "wrapper of async lua socket"
}

----------------------------------------------
-- base class for transport layer
----------------------------------------------
local BASE_TRANSPORT = {}
do
    BASE_TRANSPORT.__index = BASE_TRANSPORT

    function BASE_TRANSPORT:new()
        local t =
            setmetatable(
            {
                private_ = {
                    local_param = {},
                    remote_param = {},
                    connected = nil
                }
            },
            self
        )
        return t
    end

    function BASE_TRANSPORT:close()
        if self.private_.sock then
            self.private_.sock:close()
            self.private_.sock = nil
            self.private_.connected = nil
        end
    end

    function BASE_TRANSPORT:is_closed()
        return self.private_.sock == nil
    end

    function BASE_TRANSPORT:is_connected()
        return self.private_.connected == true
    end

    local function get_host_port(self, fn)
        if not self.private_.sock then
            return nil, "closed"
        end
        local ok, err = self.private_.sock[fn](self.private_.sock)
        if not ok then
            if err == "closed" then
                self:close()
            end
            return nil, err
        end
        return ok, err
    end

    function BASE_TRANSPORT:local_host()
        if self:is_closed() then
            return nil, "closed"
        end
        if not self.private_.local_param.host then
            local host, port = get_host_port(self, "getsockname")
            if not host then
                return nil, port
            end
            self.private_.local_param.host = host
            self.private_.local_param.port = port
        end
        return self.private_.local_param.host
    end

    function BASE_TRANSPORT:local_port()
        if self:is_closed() then
            return nil, "closed"
        end
        if not self.private_.local_param.host then
            local host, port = get_host_port(self, "getsockname")
            if not host then
                return nil, port
            end
            self.private_.local_param.host = host
            self.private_.local_param.port = port
        end
        return self.private_.local_param.port
    end

    function BASE_TRANSPORT:remote_host()
        if self:is_closed() then
            return nil, "closed"
        end
        if not self.private_.remote_param.host then
            local host, port = get_host_port(self, "getpeername")
            if not host then
                return nil, port
            end
            self.private_.remote_param.host = host
            self.private_.remote_param.port = port
        end
        return self.private_.remote_param.host
    end

    function BASE_TRANSPORT:remote_port()
        if self:is_closed() then
            return nil, "closed"
        end
        if not self.private_.remote_param.host then
            local host, port = get_host_port(self, "getpeername")
            if not host then
                return nil, port
            end
            self.private_.remote_param.host = host
            self.private_.remote_param.port = port
        end
        return self.private_.remote_param.port
    end

    function BASE_TRANSPORT:on_closed()
        return self:disconnect()
    end
end

----------------------------------------------
-- tcp transport layer
----------------------------------------------
local TCP_TRANSPORT =
    setmetatable(
    {
        is_connecting = false,
        is_connected = false,
        connect_timer = false,
        send_timer = false,
        read_idle_timer = false
    },
    BASE_TRANSPORT
)
do
    TCP_TRANSPORT.__index = TCP_TRANSPORT

    local function init_socket(self)
        if self.private_.sock then
            return self.private_.sock
        end
        local sock, err = socket.tcp()
        if not sock then
            return nil, err
        end
        -- nonblocking
        local ok, err = sock:settimeout(0)
        if not ok then
            sock:close()
            return nil, err
        end
        self.private_.sock = sock
        return sock
    end

    function TCP_TRANSPORT:bind(host, port)
        local sock, err = init_socket(self)
        if not sock then
            return nil, err
        end

        local ok, err = sock:bind(host or "*", port)
        if not ok then
            self:close()
            return nil, err
        end

        self.private_.local_param.host = nil
        self.private_.local_param.port = nil

        return true
    end

    function TCP_TRANSPORT:settimeouts(connect_timeout_in_ms, send_timeout_in_ms, read_idle_timeout_in_ms)
        -- connect timer
        connect_timeout_in_ms = connect_timeout_in_ms or 3600 * 1000
        self.connect_timer = timer:new()
        self.connect_timer:set_interval(connect_timeout_in_ms)
        self.connect_timer:start()

        -- send timer
        send_timeout_in_ms = send_timeout_in_ms or 3600 * 1000
        self.send_timer = timer:new()
        self.send_timer:set_interval(send_timeout_in_ms)
        self.send_timer:start()

        -- read idle timer
        read_idle_timeout_in_ms = read_idle_timeout_in_ms or 3600 * 1000
        self.read_idle_timer = timer:new()
        self.read_idle_timer:set_interval(read_idle_timeout_in_ms)
        self.read_idle_timer:start()
    end

    function TCP_TRANSPORT:connect(host, port)
        --
        local sock, err = init_socket(self)
        if not sock then
            return nil, err
        end

        -- backup
        self.host = tostring(host)
        self.port = tostring(port)

        --
        local ok, err = sock:connect(self.host, self.port)
        if ok then
            return 1
        elseif err == "timeout" then
            return 0
        else
            return -1
        end
    end

    --
    function TCP_TRANSPORT:check_connecting()
        -- check by select
        local sock = self.private_.sock
        local rfds = {sock}
        local wrds = {sock}
        -- check once
        local r, w, err = socket.select(rfds, wrds, 0)
        if w[1] or r[1] then
            -- check by connect again
            local ok, err2 = sock:connect(self.host, self.port)
            if not ok and err2 == "already connected" then
                return true
            end
        end
        if err == "timeout" then
            local rest = self.connect_timer:rest()
            if 0 == rest then
                self:close()
                return nil, "TIMEOUT"
            end
            local opterr = sock:getoption("error")
            if opterr then
                return nil, opterr
            end
        end
        return nil, "EAGAIN"
    end

    function TCP_TRANSPORT:disconnect()
        return self:close()
    end

    function TCP_TRANSPORT:send(msg, i, j)
        if self:is_closed() then
            return nil, "closed"
        end

        --
        i, j = i or 1, j or #msg

        -- start new send
        self.send_timer:restart()

        -- just do sync send for convenience
        while true do
            local sock = self.private_.sock
            local ok, err, last_i = sock:send(msg, i, j)
            if last_i then
                assert((last_i >= i and last_i <= j) or (last_i == i - 1))
            else
                assert(ok == j)
            end
            if ok then
                return ok
            elseif err == "timeout" then
                local rest = self.send_timer:rest()
                if 0 == rest then
                    -- send timeout
                    self:close()
                    return nil, "TIMEOUT", last_i
                end
                -- go on to send
                i = last_i + 1
            else
                if err == "closed" then
                    self:on_closed()
                end
                return nil, err, j
            end
        end
    end

    function TCP_TRANSPORT:receive(spec)
        if self:is_closed() then
            return nil, "closed"
        end
        --
        spec = spec or "*a"
        local sock = self.private_.sock
        local data, err, partial
        local pieces = {}

        -- loop until no more data
        local has_more_data = true
        while has_more_data do
            -- receive
            data, err, partial = sock:receive(spec)
            if data then
                tbl_insert(pieces, data)
                has_more_data = false
            else
                if err == "timeout" then
                    -- check partial
                    if partial and #partial > 0 then
                        tbl_insert(pieces, partial)
                    else
                        has_more_data = false
                    end
                else
                    if err == "closed" then
                        self:on_closed()
                    end
                    return nil, err
                end
            end
        end

        -- check read idle
        local rest = self.read_idle_timer:rest()
        if 0 == rest then
            self:close()
            return nil, "TIMEOUT"
        end

        if #pieces > 0 then
            self.read_idle_timer:restart()
            return tbl_concat(pieces)
        else
            return nil, "EAGAIN"
        end
    end
end

----------------------------------------------
-- udp transport layer
----------------------------------------------
local UDP_TRANSPORT = setmetatable({}, BASE_TRANSPORT)
do
    UDP_TRANSPORT.__index = UDP_TRANSPORT

    local function init_socket(self)
        if self.private_.sock then
            return self.private_.sock
        end
        local sock, err = socket.udp()
        if not sock then
            return nil, err
        end
        -- nonblocking
        local ok, err = sock:settimeout(0)
        if not ok then
            sock:close()
            return nil, err
        end
        self.private_.sock = sock
        return sock
    end

    function UDP_TRANSPORT:bind(host, port)
        if self:is_connected() then
            local ok, err = self:disconnect()
            if not ok then
                return nil, err
            end
        end

        local sock, err = init_socket(self)
        if not sock then
            return nil, err
        end

        self.private_.sock = sock

        local ok, err = sock:setsockname(host or "*", port or 0)
        if not ok then
            self:close()
            return nil, err
        end
        -- nonblocking
        ok, err = sock:settimeout(0)
        if not ok then
            self:close()
            return nil, err
        end

        return true
    end

    function UDP_TRANSPORT:connect(host, port)
        if self:is_connected() then
            local ok, err = self:disconnect()
            if not ok then
                return nil, err
            end
        end

        local sock, err = init_socket(self)
        if not sock then
            return nil, err
        end

        local ok, err = self.private_.sock:setpeername(host, port)
        if not ok then
            return nil, err
        end
        self.private_.remote_param.host = nil
        self.private_.remote_param.port = nil
        self.private_.connected = true
        return true
    end

    function UDP_TRANSPORT:disconnect()
        local ok, err = self.private_.sock:setpeername("*")
        if not ok then
            return nil, err
        end
        self.private_.remote_param.host = nil
        self.private_.remote_param.port = nil
        self.private_.connected = nil
        return true
    end

    function UDP_TRANSPORT:sendto(msg, ...)
        if self:is_closed() then
            return nil, "closed"
        end
        -- In UDP, the send method never blocks and the only way it can fail is if the
        -- underlying transport layer refuses to send a message to the
        -- specified address (i.e. no interface accepts the address).
        local sock = self.private_.sock
        local ok, err = sock["sendto"](sock, msg, ...)
        if ok then
            return ok
        end
        if err == "closed" then
            self:on_closed()
        end
        return nil, err
    end

    function UDP_TRANSPORT:recvfrom(spec)
        if self:is_closed() then
            return nil, "closed"
        end
        --
        local sock = self.private_.sock
        local ok, err, param = sock[method](sock, size)
        if ok then
            if err then
                return ok, err, param
            end
            return ok
        elseif err == "timeout" then
            return nil, "EAGAIN"
        else
            if err == "closed" then
                self:on_closed()
            end
            return nil, err
        end
    end
end

----------------------------------------------
_M.tcp_client = function(...)
    return TCP_TRANSPORT:new(...)
end
_M.udp_client = function(...)
    return UDP_TRANSPORT:new(...)
end

return _M
