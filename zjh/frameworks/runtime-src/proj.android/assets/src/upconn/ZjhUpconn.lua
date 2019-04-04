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

local function _readRoomInfo(po)
    local info = {}
    info.roomid    = po:read_int32()
    info.lower     = po:read_int32()
    info.upper     = po:read_int32()
    info.base      = po:read_int32()
    info.allin     = po:read_int32()
    info.usercount = po:read_int32()
    return info
end

local function _readUserInfo(po)
    local info = {}
    info.ticketid = po:read_int32()
    info.username = po:read_string()
    info.nickname = po:read_string()
    info.avatar   = po:read_string()
    info.gender   = po:read_byte()
    info.balance  = po:read_int64()
    return info
end

local function _readTableInfo(po)
    local info = {}
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
    local info = {}
    info.ticketid = po:read_int32()
    info.nickname = po:read_string()
    info.avatar   = po:read_string()
    info.gender   = po:read_byte()
    info.balance  = po:read_int64()
    info.status   = po:read_byte()
    info.seat     = po:read_byte()
    info.bet      = po:read_int32()
    info.isshow   = po:read_int32()
    return info
end

local function _readPlayerAnteUp(po)
    local info = {}
    local gameinfo = {}
    info.playerSeat    = po:read_byte()
    info.playerBet     = po:read_int32()
    info.playerBalance = po:read_int64()
    --
    gameinfo.round     = po:read_byte()
    gameinfo.basebet   = po:read_int32()
    gameinfo.jackpot   = po:read_int32()
    gameinfo.currseat  = po:read_byte()

    info.isLastBet     = po:read_byte()
    info.lastBetWin    = po:read_byte()
    return info, gameinfo
end

local function _readPlayerCompareCard(po)
    local info = {}
    local gameinfo = {}
    
    info.playerSeat    = po:read_byte()
    info.playerBet     = po:read_int32()
    info.playerBalance = po:read_int64()
    --
    info.acceptorSeat  = po:read_byte()
    info.loserSeat     = po:read_byte()
    --
    gameinfo.round     = po:read_byte()
    gameinfo.basebet   = po:read_int32()
    gameinfo.jackpot   = po:read_int32()
    gameinfo.currseat  = po:read_byte()
    return info ,gameinfo
end

local function _readCards(stringCards)
    local cards = {}
    for i=1, string.len(stringCards) do
        local card = string.byte(stringCards, i, i)
        table.insert(cards, card)
    end
    return cards
end

local function _readGameOver(po)
    local info = {}
    local players = {}    
    info.winnerSeat = po:read_byte()
    info.tax        = po:read_int32()
    local pCount    = po:read_int32()
   
    for i = 1, pCount do     
        local seat = po:read_byte()
        players[seat] = players[seat] or {}
        
        players[seat].score = po:read_int32() 
                       
        local stringCards = po:read_string()
        local cards = _readCards(stringCards)        
        players[seat].cards = clone(cards)
        
        players[seat].type  = po:read_byte()
        players[seat].balance = po:read_int64()
        players[seat].isp  = po:read_byte()
    end
    return info, players
end

function _M.onLogin(conn, sessionid, msgid)    
    local resp = {}   
    local po = upconn.upconn:get_packet_obj()
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
        local gaming = po:read_byte()  
        
        print("onenter is gaming",gaming)     
        -- 保存个人数据
        app.data.UserData.setUserData(userInfo)
        -- 分发登录成功消息
        app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_LOGIN_SUCCESS)
        
        app.data.UserData.setLoginState(1)      
        
        if gaming ~= 0 then
            local roomid =  po:read_int32()
            local tabInfo = _readTableInfo(po)
            tabInfo.basecoin = 0
            app.game.GameData.setTableInfo(tabInfo)
            local base = app.data.PlazaData.getBaseByRoomid(app.Game.GameID.ZJH, roomid)
            app.game.GameEngine:getInstance():start(app.Game.GameID.ZJH,base)
            app.game.GameEngine:getInstance():onStartGame()
            
            local playerCount = po:read_int32()
            local ids = {}
            for i = 1, playerCount do
                -- seat player info
                local info = _readSeatPlayerInfo(po)
                table.insert(ids,info.ticketid)
                app.game.PlayerData.onPlayerInfo(info)
            end            
            for k, id in ipairs(ids) do
                local player = app.game.PlayerData.getPlayerByNumID(id)
                if not player then                    
                    return
                end            
                app.game.GamePresenter:getInstance():onPlayerEnter(player)       
            end
            local stringCards = po:read_string()
            local cards = _readCards(stringCards)        
            app.game.GamePresenter:getInstance():onRelinkEnter(cards)
        end             
    else
        -- error
        app.data.UserData.setLoginState(-1)
        print("login failed -- !!!!, errcode=" .. tostring(resp.errorCode) .. ", " .. resp.errorMsg)
    end    
end

function _M.onEnterRoom(conn, sessionid, msgid)
    print("onEnterRoom")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        -- enter gamescene
        app.game.GameEngine:getInstance():onStartGame()
        
        -- table info
        local tabInfo = _readTableInfo(po)
        print("wq--table id",tabInfo.tableid)
        tabInfo.basecoin = 0
        app.game.GameData.setTableInfo(tabInfo)
        
        -- seat in-gaming player info     
        local playerCount = po:read_int32()
        local ids = {}
        for i = 1, playerCount do
            -- seat player info
            local info = _readSeatPlayerInfo(po)
            
            table.insert(ids,info.ticketid)
            app.game.PlayerData.onPlayerInfo(info)
        end
        
        -- enter room
        for k, id in ipairs(ids) do
            local player = app.game.PlayerData.getPlayerByNumID(id)
            if not player then
                print("player is nil")
                return
            end            
            app.game.GamePresenter:getInstance():onPlayerEnter(player)       
        end
    else
        app.game.GameEngine:getInstance():exit()  
    end
end

function _M.onPlayerSitDown(conn, sessionid, msgid)    
    print("onPlayerSitDown")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    
    local info = _readSeatPlayerInfo(po)
    app.game.PlayerData.onPlayerInfo(info)
    
    local player = app.game.PlayerData.getPlayerByNumID(info.ticketid)
    if not player then
        return
    end  
    
    if app.game.GamePresenter then
    	app.game.GamePresenter:getInstance():onPlayerEnter(player)    
    end          
         
    if app.data.UserData.getTicketID() == info.ticketid then
        print("send ready!!!!")
        _M.sendPlayerReady()
    end      
end

function _M.onPlayerReady(conn, sessionid, msgid)
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    local seat = po:read_byte()
    
    app.game.GamePresenter:getInstance():onPlayerReady(seat)
end

function _M.onLeaveRoom(conn, sessionid, msgid)
    local resp = {}
    local po   = upconn.upconn:get_packet_obj()
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        app.game.GamePresenter:getInstance():onLeaveRoom()
    end
end

function _M.onGamePrepare(conn, sessionid, msgid)
    print("onGamePrepare")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()   
   
    if app.game.GamePresenter then
    	app.game.GamePresenter:getInstance():onGamePrepare() 
    end
    
end

function _M.onGameStart(conn, sessionid, msgid)
    print("onGameStart")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    
    local basecoin   = po:read_int32()
    local tabInfo    = _readTableInfo(po)
    tabInfo.basecoin = basecoin
    app.game.GameData.setTableInfo(tabInfo)
    
    app.game.GamePresenter:getInstance():onGameStart() 
end

function _M.onPlayerGiveUp(conn, sessionid, msgid)
    print("onPlayerGiveUp")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    local now   = po:read_byte()
    local next  = po:read_byte()
    local round = po:read_int32()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onPlayerGiveUp(now, next, round) 
    end    
end

function _M.onPlayerCompareCard(conn, sessionid, msgid)
    print("onPlayerCompareCard")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    local info ,gameinfo = _readPlayerCompareCard(po)
    app.game.GameData.setGameInfo(gameinfo)

    app.game.GamePresenter:getInstance():onPlayerCompareCard(info) 
end

function _M.onPlayerShowCard(conn, sessionid, msgid)
    print("onPlayerShowCard") 
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    resp.seat = po:read_byte()
    resp.cards = po:read_string()
    resp.cardtype = po:read_byte()
    local cards = {}
    for i=1, string.len(resp.cards) do
        local item = string.byte(resp.cards, i, i)
        table.insert(cards, item)
    end
    
    app.game.GamePresenter:getInstance():onPlayerShowCard(resp.seat, cards, resp.cardtype)
end

function _M.onPlayerAnteUp(conn, sessionid, msgid)
    print("onPlayerAnteUp")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()    
    local anteupinfo ,gameinfo = _readPlayerAnteUp(po)
    
    app.game.GameData.setGameInfo(gameinfo)    
    app.game.GamePresenter:getInstance():onPlayerAnteUp(anteupinfo) 
end

-- notify
function _M.onGameOver(conn, sessionid, msgid)
    print("onGameOver")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()   
    local info, players = _readGameOver(po)
    app.game.GamePresenter:getInstance():onGameOver(info, players) 
end

function _M.onPlayerStatus(conn, sessionid, msgid)
    local resp = {}
    local po = upconn.upconn:get_packet_obj()     
    resp.ticketid = po:read_int32()
    resp.status = po:read_byte()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onPlayerStatus(resp)
    else
        print("onPlayerStatus is nil")    
    end
    
end

-- request
function _M.sendPlayerReady(self)
    print("sendPlayerReady")
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    po:writer_reset()
    po:write_int64(sessionid) -- test token
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_READY_REQ)
end

--
function _M.doRegisterMsgCallbacks()
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_REGISTER_RESP, _M.onRegister)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LOGIN_RESP, _M.onLogin)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ENTER_ROOM_RESP, _M.onEnterRoom)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LEAVE_ROOM_RESP, _M.onLeaveRoom)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_CHANGE_TABLE_RESP, _M.onChangeTable)
    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_PREPARE_NOTIFY, _M.onGamePrepare)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_START_NOTIFY, _M.onGameStart)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_OVER_NOTIFY, _M.onGameOver)

    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_SIT_DOWN_NOTIFY, _M.onPlayerSitDown)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_READY_NOTIFY, _M.onPlayerReady)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ANTE_UP_NOTIFY, _M.onPlayerAnteUp)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_SHOW_CARD_NOTIFY, _M.onPlayerShowCard)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_COMPARE_CARD_NOTIFY, _M.onPlayerCompareCard)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GIVE_UP_NOTIFY, _M.onPlayerGiveUp) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_USER_STATUS_NOTIFY, _M.onPlayerStatus)       
   
end

return _M