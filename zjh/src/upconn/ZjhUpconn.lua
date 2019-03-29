local tostring, pairs, ipairs = tostring, pairs, ipairs

local _M = {
    upconn = false,
    --
    nextConnId = 1,
    running = false
}

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."
cfg_game_zjh = require(cwd .. "config.game_zjh")
zjh_defs = require(cwd .. "ZjhDefs")
msg_dispatcher = require(cwd .."ZjhMsgDispatcher")

local uptcpd = require("network.luasocket_uptcp")
local packet_cls = require("network.byte_stream_packet")

--
function _M.createUpconn()
    --
    local nextConnId = _M.nextConnId
    _M.nextConnId = _M.nextConnId + 1
    _M.upconn = uptcpd:new(nextConnId)
    return _M.upconn
end

--
function _M.destroyUpconn(s)

end

--
function _M.update()
    _M.upconn:update()
end

local function _readRoomInfo(po)
    local info       = {}
    info.roomid      = po:read_int32()
    info.lower       = po:read_int32()
    info.upper       = po:read_int32()
    info.base        = po:read_int32()
    info.usercount   = po:read_int32()
    return info
end

local function _readUserInfo(po)
    local info       = {}
    info.ticketid    = po:read_int32()
    info.username    = po:read_string()
    info.nickname    = po:read_string()
    info.avatar      = po:read_string()
    info.gender      = po:read_byte()
    info.balance     = po:read_int64()
    return info
end

local function _readTableInfo(po)
    local info       = {}
    info.tableid     = po:read_int32()
    info.status      = po:read_byte()
    info.round       = po:read_byte()
    info.basebet     = po:read_int32()
    info.jackpot     = po:read_int32()
    info.banker      = po:read_byte()
    info.currseat    = po:read_byte()
    info.playercount = po:read_int32()
    info.playerseat  = {}
    for i = 1, info.playercount do
        table.insert(info.playerseat, po:read_byte())
    end
    return info
end

local function _readSeatPlayerInfo(po)
    local info       = {}
    info.ticketid    = po:read_int32()
    info.nickname    = po:read_string()
    info.avatar      = po:read_string()
    info.gender      = po:read_byte()
    info.balance     = po:read_int64()
    info.status      = po:read_byte()
    info.seat        = po:read_byte()
    info.bet         = po:read_int32()
    return info
end

function _M.onLogin(conn, sessionid, msgid)    
    local resp     = {}   
    local po       = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    resp.version   = po:read_string()
    resp.host      = po:read_string()
    resp.onlineCnt = po:read_int32()
    resp.roomCount = po:read_byte()

    -- room info
    for i = 1, resp.roomCount do
        local info = _readRoomInfo(po)
        app.data.PlazaData.setPlazaList(info, app.Game.GameID.ZJH, i)
    end

    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        -- user info
        local userInfo = {}
        userInfo = _readUserInfo(po)
        userInfo.session = sessionid
        -- recover flag
        userInfo.gaming = po:read_byte()
        
        -- 保存个人数据
        app.data.UserData.setUserData(userInfo)
        -- 分发登录成功消息
        app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_LOGIN_SUCCESS)
        
        app.data.UserData.setLoginState(1)
    else
        -- error
        app.data.UserData.setLoginState(-1)
        print("login failed -- !!!!, errcode=" .. tostring(resp.errorCode) .. ", " .. resp.errorMsg)
    end    
end

function _M.onEnterRoom(conn, sessionid, msgid)
    local resp     = {}
    local po       = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        -- table info
        local tabInfo = _readTableInfo(po)
        app.game.GameData.setGameData(tabInfo)
        
        -- seat in-gaming player info     
        local playerCount = po:read_int32()
        for i = 1, playerCount do
            -- seat player info
            local player = _readSeatPlayerInfo(po)
            app.game.PlayerData.onPlayerInfo(player)
        end
        
        app.game.GameEngine:getInstance():onStartGame()                    
    else
        app.game.GameEngine:getInstance():exit()  
    end
end

function _M.onLeaveRoom(conn, sessionid, msgid)
    local resp     = {}
    local po       = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        print("leave yes yes yes ")
    else
        print("leave fail fail fail ")
    end
end

--
function _M.doRegisterMsgCallbacks()
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_REGISTER_RESP, _M.onRegister)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LOGIN_RESP, _M.onLogin)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ENTER_ROOM_RESP, _M.onEnterRoom)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LEAVE_ROOM_RESP, _M.onLeaveRoom)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_CHANGE_TABLE_RESP, _M.onChangeTable)

    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_START_NOTIFY, _M.onGameStart)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_OVER_NOTIFY, _M.onGameOver)

    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_SIT_DOWN_NOTIFY, _M.onPlayerSitDown)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_READY_NOTIFY, _M.onPlayerReady)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ANTE_UP_NOTIFY, _M.onPlayerAnteUp)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_SHOW_CARD_NOTIFY, _M.onPlayerShowCard)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_COMPARE_CARD_NOTIFY, _M.onPlayerCompareCard)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GIVE_UP_NOTIFY, _M.onPlayerGiveUp)
end

--
function _M.start()
    --
    _M.doRegisterMsgCallbacks()

    local connected_cb = function(self)
        print("connected_cb, connid=" .. tostring(self.id))
    end

    local disconnected_cb = function(self)
        print("disconnected_cb, connid=" .. tostring(self.id))
    end

    local error_cb = function(self, errstr)
        print("error_cb, connid=" .. tostring(self.id) .. ", err:" .. errstr)
    end

    local got_packet_cb = function(self, pkt)
        msg_dispatcher.dispatch(self, pkt.sessionid, pkt.msgid)
    end

    local server = cfg_game_zjh.servers[1]

    --
    local opts = {
        server = server,
        packet_cls = packet_cls,
        connected_cb = connected_cb,
        disconnected_cb = disconnected_cb,
        error_cb = error_cb,
        got_packet_cb = got_packet_cb
    }
    _M.upconn = _M.createUpconn()
    _M.upconn:run(opts)

    --
    _M.running = true
end

return _M