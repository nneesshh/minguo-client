local tbl_insert = table.insert
local str_sub = string.sub
local tonumber = tonumber

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."
local lcu = lcu

local PER_FRAME_PAGE_SIZE_MAX = 4096
local STREAM_CAPACITY = PER_FRAME_PAGE_SIZE_MAX * 2
local SIZE_OF_FRAME_PAGE_LEADING = 20

----
local _P = {}

local PARSE_HEADER = 0
local PARSE_BODY = 1

--
function _P:decode(data, packet_cb, arg)
    -- cache
    local remain_size = #data
    local remain_data = data
    local free_size, consume_size, consume_data

    while remain_size > 0 and remain_data do
        free_size = self.pkt_r_cache_stream:get_free_size()
        consume_size = (remain_size > PER_FRAME_PAGE_SIZE_MAX) and PER_FRAME_PAGE_SIZE_MAX or remain_size
        consume_size = (consume_size > free_size) and free_size or consume_size
        consume_data = str_sub(remain_data, 1, consume_size)
        remain_size = remain_size - consume_size
        remain_data = str_sub(remain_data, consume_size + 1, consume_size + remain_size)
        self.pkt_r_cache_stream:write_raw(consume_data)

        -- parse loop until no more ready packet
        while true do
            if PARSE_HEADER == self.pkt_r_parser_state then
                -- header
                local content_size = self.pkt_r_cache_stream:get_used_size()
                if content_size < SIZE_OF_FRAME_PAGE_LEADING then
                    break
                end

                -- read header and rewind
                local header = self.pkt_r_cache_stream:read_raw(SIZE_OF_FRAME_PAGE_LEADING)
                self.pkt_r_cache_stream:rewind()

                -- write header to stream
                self.pkt_r_stream:reset()
                self.pkt_r_stream:write_raw(header)

                -- parse header
                local key = self.pkt_r_stream:read_raw(8)
                local size = self.pkt_r_stream:read_int32()
                local sessionId = self.pkt_r_stream:read_int32()
                local msgId = self.pkt_r_stream:read_int16()
                local version = self.pkt_r_stream:read_byte()
                local reserve = self.pkt_r_stream:read_byte()
                --
                self.pkt_r.sessionid = sessionId
                self.pkt_r.msgid = msgId
                self.pkt_r.msgsize = size

                --
                self.pkt_r_parser_state = PARSE_BODY

            elseif PARSE_BODY == self.pkt_r_parser_state then
                -- body
                local content_size = self.pkt_r_cache_stream:get_used_size()
                if content_size < self.pkt_r.msgsize then
                    break
                end
                
                -- read body and rewind
                local body = self.pkt_r_cache_stream:read_raw(self.pkt_r.msgsize)
                self.pkt_r_cache_stream:rewind()

                -- write body to stream
                self.pkt_r_stream:reset()
                self.pkt_r_stream:write_raw(body)

                if packet_cb then
                    packet_cb(arg, self.pkt_r)
                end

                -- continue to parse next packet
                self.pkt_r_parser_state = PARSE_HEADER
            end
        end
    end
end

--
function _P:write(s, sessionid, msgid, msgdata)
    local sent = 0
    local remain_size = #msgdata
    local send_size_max
    local send_size

    -- first page
    send_size_max = PER_FRAME_PAGE_SIZE_MAX - SIZE_OF_FRAME_PAGE_LEADING

    send_size = (remain_size <= send_size_max) and remain_size or send_size_max
    remain_size = remain_size - send_size

    -- check overflow
    if remain_size > 0 then
        error("packet size overflow!!!")
    else
        -- frame leading init
        local key = "\0\1\2\3\4\5\6\7" -- 8 bytes
        local size = send_size
        local sessionId = sessionid
        local msgId = msgid
        local version = 234
        local reserve = 'a'

        -- header
        self.pkt_w_cache_stream:write_raw(key)
        self.pkt_w_cache_stream:write_int32(size)
        self.pkt_w_cache_stream:write_int32(sessionId)
        self.pkt_w_cache_stream:write_int16(msgId)
        self.pkt_w_cache_stream:write_byte(version)
        self.pkt_w_cache_stream:write_byte(reserve)

        -- body
        self.pkt_w_cache_stream:write_raw(str_sub(msgdata, 1, send_size))

        -- send
        local framedata = self.pkt_w_cache_stream:read_raw()
        s:send(framedata)
        sent = sent + SIZE_OF_FRAME_PAGE_LEADING + send_size

        self.pkt_w_cache_stream:reset()
    end

    return sent
end

-- byte stream packet
_P.new = function()
    -- reader stream
    local function _reader_stream_rewind(self)
        return self.pkt_r_stream:rewind()
    end

    local function _reader_stream_skip(self, len)
        return self.pkt_r_stream:skip(len)
    end

    local function _reader_stream_get_content_size(self)
        self.pkt_r_stream:rewind()
        return self.pkt_r_stream:get_used_size()
    end

    local function _reader_stream_get_free_size(self)
        return self.pkt_r_stream:get_free_size()
    end

    local function _reader_stream_read_byte(self)
        return self.pkt_r_stream:read_byte()
    end

    local function _reader_stream_read_int16(self)
        return self.pkt_r_stream:read_int16()
    end

    local function _reader_stream_read_int32(self)
        return self.pkt_r_stream:read_int32()
    end

    local function _reader_stream_read_int64(self)
        return self.pkt_r_stream:read_int64()
    end

    local function _reader_stream_read_string(self)
        return self.pkt_r_stream:read_string()
    end

    -- writer stream
    local function _writer_stream_reset(self)
        return self.pkt_w_stream:reset()
    end

    local function _writer_stream_get_content_size(self)
        self.pkt_r_stream:rewind()
        return self.pkt_w_stream:get_used_size()
    end

    local function _writer_stream_get_free_size(self)
        return self.pkt_w_stream:get_free_size()
    end

    local function _writer_stream_write_byte(self, d1)
        return self.pkt_w_stream:write_byte(d1)
    end

    local function _writer_stream_write_int16(self, d2)
        return self.pkt_w_stream:write_int16(d2)
    end

    local function _writer_stream_write_int32(self, d4)
        return self.pkt_w_stream:write_int32(d4)
    end

    local function _writer_stream_write_int64(self, d8)
        return self.pkt_w_stream:write_int64(d8)
    end

    local function _writer_stream_write_string(self, str)
        return self.pkt_w_stream:write_string(str, #str)
    end

    local function _send_packet(self, sock, sessionid, msgid)
        local msgdata = self.pkt_w_stream:read_raw()
        return self:write(sock, sessionid, msgid, msgdata)
    end

    --
    local function __create_stream(self)
        return lcu.create_memory_stream(STREAM_CAPACITY)
    end

    local self = {
        -- read
        pkt_r_cache_stream = __create_stream(), -- for full frame data cache
        pkt_r_stream = __create_stream(), -- for packet parser
        pkt_r_parser_state = 0, -- packet parser state
        pkt_r = {
            sessionid = 0,
            msgid = 0,
            msgsize = 0
        },
        --
        reader_rewind = _reader_stream_rewind,
        reader_skip = _reader_stream_skip,
        reader_get_content_size = _reader_stream_get_content_size,
        reader_get_free_size = _reader_stream_get_free_size,
        read_byte = _reader_stream_read_byte,
        read_int16 = _reader_stream_read_int16,
        read_int32 = _reader_stream_read_int32,
        read_int64 = _reader_stream_read_int64,
        read_string = _reader_stream_read_string,
        -- write
        pkt_w_cache_stream = __create_stream(), -- for full frame data cache
        pkt_w_stream = __create_stream(),
        --
        writer_reset = _writer_stream_reset,
        writer_get_content_size = _writer_stream_get_content_size,
        writer_get_free_size = _writer_stream_get_free_size,
        write_byte = _writer_stream_write_byte,
        write_int16 = _writer_stream_write_int16,
        write_int32 = _writer_stream_write_int32,
        write_int64 = _writer_stream_write_int64,
        write_string = _writer_stream_write_string,
        --
        send_packet = _send_packet
    }

    return setmetatable(
        self,
        {
            __index = _P
        }
    )
end

return _P