local ffi = require "ffi"

local sizeof = ffi.sizeof
local offsetof = ffi.offsetof
local C = ffi.C

local tbl_insert = table.insert
local tbl_concat = table.concat
local str_sub = string.sub
local tonumber = tonumber

local PER_FRAME_PAGE_SIZE_MAX = 4096

ffi.cdef [[

#pragma pack(1)

typedef struct
{
	char			key[8];
	unsigned int	size;
	unsigned int	sessionId;
	unsigned short	msgId;
	unsigned char	version;
	char			reserve[1];
} MSG_HEADER;

#pragma pack()

typedef struct memory_stream_s
{
	size_t  capacity;
	char   *buf;
    char   *cursor_r;
    char   *cursor_w;
} memory_stream_t;

memory_stream_t * create_memory_stream(size_t capacity);
void              destroy_memory_stream(memory_stream_t *stream);

void              memory_stream_reset(memory_stream_t *stream);
void              memory_stream_rewind(memory_stream_t *stream);
void              memory_stream_skip(memory_stream_t *stream, int len);
void              memory_stream_skip_all(memory_stream_t *stream);
int               memory_stream_get_used_size(memory_stream_t *stream);
int               memory_stream_get_free_size(memory_stream_t *stream);
bool              memory_stream_ensure_free_size(memory_stream_t *stream, int size);

int8_t            memory_stream_read_byte(memory_stream_t *stream);
int16_t           memory_stream_read_int16(memory_stream_t *stream);
int32_t           memory_stream_read_int32(memory_stream_t *stream);
int64_t           memory_stream_read_int64(memory_stream_t *stream);
const char *      memory_stream_read_string(memory_stream_t *stream, int16_t *outlen);

void              memory_stream_write_byte(memory_stream_t *stream, int8_t d);
void              memory_stream_write_int16(memory_stream_t *stream, int16_t d2);
void              memory_stream_write_int32(memory_stream_t *stream, int32_t d4);
void              memory_stream_write_int64(memory_stream_t *stream, int64_t d8);
void              memory_stream_write_string(memory_stream_t *stream, const char *str, int16_t len);
void              memory_stream_write_raw(memory_stream_t *stream, unsigned char *src, int len);

]]

local frame_leading_t = ffi.typeof("MSG_HEADER")
local SIZE_OF_FRAME_PAGE_LEADING = sizeof(frame_leading_t, 0)
local ffilib_lcu = ffi.load(ffi.os == "Windows" and "./clibs/lcu.dll" or "lcu")

----
local _P = {}

local PARSE_HEADER = 0
local PARSE_BODY = 1

--
function _P:decode(data, packet_cb, arg)
    -- cache
    local framedata_szie = #data
    local free_size = ffilib_lcu.memory_stream_get_free_size(self.pkt_r_cache_stream)
    if free_size >= framedata_szie then
        local framedata = ffi.cast("unsigned char *", data)
        ffilib_lcu.memory_stream_write_raw(self.pkt_r_cache_stream, framedata, framedata_szie)
    else
        error("reader cache stream overflow!!!")
    end

    -- parse loop until no more ready packet
    while true do
        if PARSE_HEADER == self.pkt_r_parser_state then
            -- header
            local content_size = ffilib_lcu.memory_stream_get_used_size(self.pkt_r_cache_stream)
            if content_size < SIZE_OF_FRAME_PAGE_LEADING then
                break
            end

            -- parse header
            ffi.copy(self.frm_l_r, self.pkt_r_cache_stream.buf, SIZE_OF_FRAME_PAGE_LEADING)
 
            -- packet info
            self.pkt_r.sessionid = self.frm_l_r.sessionId
            self.pkt_r.msgid = self.frm_l_r.msgId
            self.pkt_r.msgsize = self.frm_l_r.size

            -- -- rewind cache
            ffilib_lcu.memory_stream_skip(self.pkt_r_cache_stream, SIZE_OF_FRAME_PAGE_LEADING)
            ffilib_lcu.memory_stream_rewind(self.pkt_r_cache_stream)

            --
            self.pkt_r_parser_state = PARSE_BODY

        elseif PARSE_BODY == self.pkt_r_parser_state then
            -- body
            local content_size = ffilib_lcu.memory_stream_get_used_size(self.pkt_r_cache_stream)
            if content_size < self.pkt_r.msgsize then
                break
            end

            -- parse body
            local bodydata = ffi.cast("unsigned char *", self.pkt_r_cache_stream.buf)

            -- write body to stream
            ffilib_lcu.memory_stream_reset(self.pkt_r_stream)
            ffilib_lcu.memory_stream_write_raw(self.pkt_r_stream, bodydata, self.pkt_r.msgsize)

            -- rewind cache
            ffilib_lcu.memory_stream_skip(self.pkt_r_cache_stream, self.pkt_r.msgsize)
            ffilib_lcu.memory_stream_rewind(self.pkt_r_cache_stream)

            --
            if packet_cb then
                packet_cb(arg, self.pkt_r)
            end

            -- continue to parse next packet
            self.pkt_r_parser_state = PARSE_HEADER
        end
    end
end

--
function _P:write(s, sessionid, msgid, msgdata)
    local sent = 0
    local remain_size = #msgdata
    local send_size_max
    local send_size
    local pkt_w

    -- first page
    send_size_max = PER_FRAME_PAGE_SIZE_MAX - SIZE_OF_FRAME_PAGE_LEADING

    pkt_w = {}
    send_size = (remain_size <= send_size_max) and remain_size or send_size_max
    remain_size = remain_size - send_size

    -- check overflow
    if remain_size > 0 then
        error("packet size overflow!!!")
    else
        -- frame leading init
        ffi.copy(self.frm_l_w.key, "\0\1\2\3\4\5\6\7") -- 8 bytes
        self.frm_l_w.size = send_size
        self.frm_l_w.sessionId = sessionid
        self.frm_l_w.msgId = msgid
        self.frm_l_w.version = 234
        self.frm_l_w.reserve = "a"

        -- header
        tbl_insert(pkt_w, ffi.string(self.frm_l_w, SIZE_OF_FRAME_PAGE_LEADING))

        -- body
        tbl_insert(pkt_w, str_sub(msgdata, 1, send_size))
 
        s:send(tbl_concat(pkt_w))
        sent = sent + SIZE_OF_FRAME_PAGE_LEADING + send_size
    end

    return sent
end

-- byte stream packet
_P.new = function()
    -- reader stream
    local function _reader_stream_rewind(self)
        return ffilib_lcu.memory_stream_rewind(self.pkt_r_stream)
    end

    local function _reader_stream_skip(self, len)
        return ffilib_lcu.memory_stream_skip(self.pkt_r_stream, len)
    end

    local function _reader_stream_get_content_size(self)
        ffilib_lcu.memory_stream_rewind(self.pkt_r_stream)
        return ffilib_lcu.memory_stream_get_used_size(self.pkt_r_stream)
    end

    local function _reader_stream_get_free_size(self)
        return ffilib_lcu.memory_stream_get_free_size(self.pkt_r_stream)
    end

    local function _reader_stream_read_byte(self)
        return ffilib_lcu.memory_stream_read_byte(self.pkt_r_stream)
    end

    local function _reader_stream_read_int16(self)
        return ffilib_lcu.memory_stream_read_int16(self.pkt_r_stream)
    end

    local function _reader_stream_read_int32(self)
        return ffilib_lcu.memory_stream_read_int32(self.pkt_r_stream)
    end

    local function _reader_stream_read_int64(self)
        return tonumber(ffilib_lcu.memory_stream_read_int64(self.pkt_r_stream))
    end

    local function _reader_stream_read_string(self)
        local stream_buffer = ffilib_lcu.memory_stream_read_string(self.pkt_r_stream, self.pkt_r_stream_string_len)
        return ffi.string(stream_buffer, self.pkt_r_stream_string_len[0])
    end

    -- writer stream
    local function _writer_stream_reset(self)
        return ffilib_lcu.memory_stream_reset(self.pkt_w_stream)
    end

    local function _writer_stream_get_content_size(self)
        ffilib_lcu.memory_stream_rewind(self.pkt_w_stream)
        return ffilib_lcu.memory_stream_get_used_size(self.pkt_w_stream)
    end

    local function _writer_stream_get_free_size(self)
        return ffilib_lcu.memory_stream_get_free_size(self.pkt_w_stream)
    end

    local function _writer_stream_write_byte(self, d1)
        return ffilib_lcu.memory_stream_write_byte(self.pkt_w_stream, d1)
    end

    local function _writer_stream_write_int16(self, d2)
        return ffilib_lcu.memory_stream_write_int16(self.pkt_w_stream, d2)
    end

    local function _writer_stream_write_int32(self, d4)
        return ffilib_lcu.memory_stream_write_int32(self.pkt_w_stream, d4)
    end

    local function _writer_stream_write_int64(self, d8)
        return ffilib_lcu.memory_stream_write_int64(self.pkt_w_stream, ffi.new("int64_t", d8))
    end

    local function _writer_stream_write_string(self, str)
        return ffilib_lcu.memory_stream_write_string(self.pkt_w_stream, str, #str)
    end

    local function _send_packet(self, sock, sessionid, msgid)
        local buflen = ffilib_lcu.memory_stream_get_used_size(self.pkt_w_stream)
        local msgdata = ffi.string(self.pkt_w_stream.buf, buflen)
        return self:write(sock, sessionid, msgid, msgdata)
    end

    --
    local function __create_stream(self)
        return ffilib_lcu.create_memory_stream(PER_FRAME_PAGE_SIZE_MAX)
    end

    local self = {
        -- read
        frm_l_r = frame_leading_t(),
        pkt_r_cache_stream = __create_stream(), -- for full frame data cache
        pkt_r_stream = __create_stream(), -- for packet parser
        pkt_r_stream_string_len = ffi.new("int16_t[1]", 0),
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
        frm_l_w = frame_leading_t(),
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
