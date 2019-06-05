local tostring, pairs, ipairs = tostring, pairs, ipairs

local _M = {
    upconn = false,
    --
    nextConnId = 1,
    running = false
}

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."
cfg_game_zjh     = require(cwd .. "config.game_zjh")
zjh_defs         = require(cwd .. "ZjhDefs")
msg_dispatcher   = require(cwd .."ZjhMsgDispatcher")

local uptcpd     = require("network.luasocket_uptcp")
local packet_cls = require("network.byte_stream_packet")
local pubConn    = requireLobby(cwd .. "PublicUpconn")
local jdnnConn   = requireLobby(cwd .. "JdnnUpconn")
local qznnConn   = requireLobby(cwd .. "QznnUpconn")
local lhdConn    = requireLobby(cwd .. "LhdUpconn")
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

function _M.close()    
    _M.upconn:close()
end

local STATE_IDLE         = 0
local STATE_CONNECTING   = 1
local STATE_RECONNECTING = 2
local STATE_CONNECTED    = 3
local STATE_CLEANUP      = 4
local STATE_CLOSED       = 5

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
        if CC_HEART_BEAT then
            app.Connect:getInstance():close()
            app.lobby.login.LoginPresenter:getInstance():reLogin()  
        end
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

local function _readTableInfo(po)
    local info = {}
    info.tableid     = po:read_int32()
    info.status      = po:read_byte()
    info.round       = po:read_byte()
    info.basebet     = po:read_int32()
    
    info.jackpot     = po:read_int64()    
    info.long        = po:read_int64()
    info.hu          = po:read_int64()
    info.he          = po:read_int64()
    info.area4       = po:read_int64()
    
    info.banker      = po:read_int16()
    info.currseat    = po:read_int16()
    info.playercount = po:read_int32()
    info.playerseat  = {}
    for i = 1, info.playercount do
        table.insert(info.playerseat, po:read_int16())
    end
    return info
end

local function _readPlayerAnteUp(po)
    local info = {}
    local gameinfo = {}
    info.playerSeat    = po:read_int16()
    info.playerBet     = po:read_int32()
    info.playerBalance = po:read_int64()
    --
    gameinfo.round     = po:read_byte()
    info.basebet       = po:read_int32()
    gameinfo.jackpot   = po:read_int32()
    gameinfo.currseat  = po:read_int16()
    
    info.isAllIn       = po:read_byte()
    return info, gameinfo
end

local function _readPlayerCompareCard(po)
    local info = {}
    local gameinfo = {}
    
    info.playerSeat    = po:read_int16()
    info.playerBet     = po:read_int32()
    info.playerBalance = po:read_int64()
    --
    info.acceptorSeat  = po:read_int16()
    info.loserSeat     = po:read_int16()
    --
    gameinfo.round     = po:read_byte()
    info.basebet       = po:read_int32()
    gameinfo.jackpot   = po:read_int32()
    gameinfo.currseat  = po:read_int16()
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
    info.winnerSeat = po:read_int16()
    info.tax        = po:read_int32()
    local pCount    = po:read_int32()
   
    for i = 1, pCount do     
        local seat = po:read_int16()
        players[seat] = players[seat] or {}
        
        players[seat].score = po:read_int32() 
                       
        local stringCards = po:read_string()
        local cards = _readCards(stringCards)        
        players[seat].cards = clone(cards)
        
        players[seat].type  = po:read_byte()
        players[seat].balance = po:read_int64()
        players[seat].iswin = po:read_byte()
    end
    return info, players
end

function _M.onPlayerReady(conn, sessionid, msgid)
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    local seat = po:read_int16()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onPlayerReady(seat) 
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
    local now   = po:read_int16()
    local next  = po:read_int16()
    local round = po:read_byte()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onPlayerGiveUp(now, next, round) 
    end    
end

function _M.onGameOverShow(conn, sessionid, msgid)
    print("onGameOverShow")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    local seat = po:read_int16()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onGameOverShow(seat) 
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
    resp.seat = po:read_int16()
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

function _M.onPlayerLastBet(conn, sessionid, msgid)
    print("onPlayerLastBet")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()    
    resp.playerSeat = po:read_int16()
    resp.count = po:read_int32()
    resp.otherSeat = {} 
    for i=1, resp.count do
        resp.otherSeat[i] = po:read_int16()
    end
    resp.win = po:read_byte()   
    resp.nextseat = po:read_int16()  
    
    app.game.GamePresenter:getInstance():onPlayerLastBet(resp) 
end
-- notify
function _M.onGameOver(conn, sessionid, msgid)
    print("onGameOver")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()   
    local info, players = _readGameOver(po)
    
    app.game.GamePresenter:getInstance():onGameOver(info, players) 
end

--
function _M.doRegisterMsgCallbacks()
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_HEART_BEAT_RESP, pubConn.onHeartBeat)        
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_REGISTER_RESP, pubConn.onRegister)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LOGIN_RESP, pubConn.onLogin)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_CHANGE_USER_INFO_RESP, pubConn.onUserInfo)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_RELOGIN_NOTIFY_NEW, pubConn.onRelogin)    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DEPOSIT_CASH_RESP, pubConn.onDepositCash)
        
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_PLAYER_BALANCE_NOTIFY, pubConn.onPlayerBalance)
    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_ANNOUNCEMENT_NOTIFY, pubConn.onAnnouncement)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_MAIL_NOTIFY, pubConn.onMail)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_NEWS_RESP, pubConn.onGameNews)
        
    -- 玩家动作
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_PLAYER_STATUS_NOTIFY_NEW, pubConn.onPlayerStatus)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_SIT_DOWN_NOTIFY_NEW, pubConn.onPlayerSitDown)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ENTER_ROOM_RESP, pubConn.onEnterRoom)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LEAVE_ROOM_RESP, pubConn.onLeaveRoom)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_CHANGE_TABLE_RESP, pubConn.onChangeTable)
    
    -- 拼三张相关
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_PREPARE_NOTIFY, _M.onGamePrepare)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_START_NOTIFY, _M.onGameStart)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GAME_OVER_NOTIFY, _M.onGameOver)    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_READY_NOTIFY, _M.onPlayerReady)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ANTE_UP_NOTIFY, _M.onPlayerAnteUp)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_LAST_BET_NOTIFY, _M.onPlayerLastBet)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_SHOW_CARD_NOTIFY, _M.onPlayerShowCard)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_COMPARE_CARD_NOTIFY, _M.onPlayerCompareCard)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_GIVE_UP_NOTIFY, _M.onPlayerGiveUp) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_ZJH_GAME_OVER_SHOW_NOTIFY, _M.onGameOverShow) 
    
    -- 经典牛牛相关
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_GAME_PREPARE_NOTIFY, jdnnConn.onNiuGamePrepare)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_GAME_START_NOTIFY, jdnnConn.onNiuGameStart)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_GAME_OVER_NOTIFY, jdnnConn.onNiuGameOver)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_GAME_CONFIRM_BANKER_NOTIFY, jdnnConn.onNiuConfirmBanker)    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_GAME_COMPARE_BID_OVER_NOTIFY, jdnnConn.onNiuConfirmMult) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_READY_NOTIFY, jdnnConn.onNiuPlayerReady) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_BANKER_BID_NOTIFY, jdnnConn.onNiuBankerBid) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_COMPARE_BID_NOTIFY, jdnnConn.onNiuCompareBid) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_COMPARE_CARD_NOTIFY, jdnnConn.onNiuCompareCard)   
    
    -- 抢庄牛牛相关
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_GAME_PREPARE_NOTIFY, qznnConn.onNiuGamePrepare)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_GAME_START_NOTIFY, qznnConn.onNiuGameStart)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_GAME_OVER_NOTIFY, qznnConn.onNiuGameOver)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_GAME_CONFIRM_BANKER_NOTIFY, qznnConn.onNiuConfirmBanker)    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_GAME_COMPARE_BID_OVER_NOTIFY, qznnConn.onNiuConfirmMult) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_READY_NOTIFY, qznnConn.onNiuPlayerReady) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_BANKER_BID_NOTIFY, qznnConn.onNiuBankerBid) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_COMPARE_BID_NOTIFY, qznnConn.onNiuCompareBid) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_NIU_C41_COMPARE_CARD_NOTIFY, qznnConn.onNiuCompareCard)
    
    -- 龙虎斗相关
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_GAME_PREPARE_NOTIFY, lhdConn.onLhdGamePrepare)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_GAME_START_NOTIFY, lhdConn.onLhdGameStart)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_GAME_OVER_NOTIFY, lhdConn.onLhdGameOver)
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_GAME_HISTORY_NOTIFY, lhdConn.onLhdHistory)    
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_TOP_SEAT_NOTIFY, lhdConn.onLhdTopSeat)     
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_READY_NOTIFY, lhdConn.onLhdPlayerReady) 
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_BET_NOTIFY, lhdConn.onLhdBet)      
    msg_dispatcher.registerCb(zjh_defs.MsgId.MSGID_DRAGON_VS_TIGER_GAME_BET_FULL_NOTIFY,lhdConn.onLhdBetFull)
end

return _M