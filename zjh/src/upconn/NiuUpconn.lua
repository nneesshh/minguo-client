local _M = {}

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
        players[seat].iswin = po:read_byte()
    end
    return info, players
end

-- 进入房间
function _M.onNiuEnterRoom(conn, sessionid, msgid)
    print("onNiuEnterRoom")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()

    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        app.lobby.MainPresenter:getInstance():loadingHintExit()
        -- enter gamescene
        app.game.GameEngine:getInstance():onStartGame()

        -- table info
        local tabInfo = _readTableInfo(po)       
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
                return
            end            
            app.game.GamePresenter:getInstance():onPlayerEnter(player) 
            if app.data.UserData.getTicketID() == id then               
                _M.sendPlayerReady()
            end                    
        end
    else
        app.game.GameEngine:getInstance():exit()
        app.lobby.MainPresenter:getInstance():showErrorMsg(resp.errorCode)
    end
end

-- 离开房间
function _M.onNiuLeaveRoom(conn, sessionid, msgid)
    print("onNiuLeaveRoom")
    local resp = {}
    local po   = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        if app.game.GamePresenter then
            app.game.GamePresenter:getInstance():onLeaveRoom()
        end            
    end
end

-- 换桌
function _M.onNiuChangeTable(conn, sessionid, msgid)
    print("onNiuChangeTable")
    local resp = {}
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()

    if resp.errorCode == zjh_defs.ErrorCode.ERR_SUCCESS then
        -- enter gamescene       
        local gameid = po:read_int32()
        local roomid = po:read_int32()
        local base = app.data.PlazaData.getBaseByRoomid(gameid, roomid)
        local limit = app.data.PlazaData.getLimitByBase(gameid, base)
        app.game.GameEngine:getInstance():start(gameid, base, limit)            
        app.game.GameEngine:getInstance():onStartGame()

        app.game.GamePresenter:getInstance():onChangeTable()        

        -- table info
        local tabInfo = _readTableInfo(po)
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

                return
            end                  
            app.game.GamePresenter:getInstance():onPlayerEnter(player)
            if app.data.UserData.getTicketID() == id then                
                _M.sendPlayerReady()
            end         
        end
    else
        app.game.GameEngine:getInstance():exit()  
    end
end

-- 游戏准备
function _M.onNiuGamePrepare(conn, sessionid, msgid) 
    print("onNiuGamePrepare")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onGamePrepare() 
    end    
end

-- 游戏开始
function _M.onNiuGameStart(conn, sessionid, msgid)
    print("onNiuGameStart")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    local basecoin   = po:read_int32()
    local tabInfo    = _readTableInfo(po)
    tabInfo.basecoin = basecoin
    app.game.GameData.setTableInfo(tabInfo)

    app.game.GamePresenter:getInstance():onGameStart() 
end

-- 游戏结束
function _M.onNiuGameOver(conn, sessionid, msgid) 
    print("onNiuGameOver")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    local playercont = po:read_int32()
    print("playercont is",playercont)
    local players = {}
    for i=1, playercont do
        players[i] = players[i] or {}
        players[i].seat     = po:read_byte()
        players[i].score    = po:read_int32()
        local strcards      = po:read_string()    
        players[i].cards    = _readCards(strcards)  
        players[i].cardtype = po:read_byte()   
        players[i].balance  = po:read_int64()
    end
    
    dump(players)
    
    app.game.GamePresenter:getInstance():onNiuGameOver(players)  
end

-- 定庄 
function _M.onNiuConfirmBanker(conn, sessionid, msgid) 
    print("onNiuConfirmBanker")
    local po = upconn.upconn:get_packet_obj() 
    if po == nil then return end   
    local banker = {}
    banker.banker     = po:read_byte()
    banker.bankerMult = po:read_int32()
    print("banker.bankerMult",banker.bankerMult)
    local players = {}
    local playercont = po:read_int32()
    for i=1,playercont do
        players[i] = players[i] or {}
        players[i].seat    = po:read_byte()
        players[i].mult    = po:read_int32()
        players[i].balance = po:read_int64()
        print("player mult", players[i].mult)
    end
    
    app.game.GamePresenter:getInstance():onNiuConfirmBanker(banker, players)    
end

-- 比牌加倍结束
function _M.onNiuConfirmMult(conn, sessionid, msgid) 
    print("onNiuConfirmMult")
    local po = upconn.upconn:get_packet_obj() 
    if po == nil then return end   
    
    local hero = {}
    local strcards = po:read_string()    
    hero.cards     = _readCards(strcards)    
    hero.cardtype  = po:read_byte()
    hero.cardmult  = po:read_int32()    
         
    local players = {}
    local banker = app.game.GameData.getBanker()    
    local playercont = po:read_int32()
    
    for i=1, playercont do
        players[i] = players[i] or {}
        players[i].seat = po:read_byte()
        if players[i].seat ~= banker then
            players[i].mult = po:read_int32()
            players[i].balance = po:read_int64()
        else
            players[i].mult    = po:read_int32()
            players[i].balance = po:read_int64()
        end
    end

    app.game.GamePresenter:getInstance():onNiuConfirmMult(hero, players) 
end

-- 准备
function _M.onNiuPlayerReady(conn, sessionid, msgid) 
    print("onNiuPlayerReady")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    local seat = po:read_byte()
end

-- 抢庄加倍
function _M.onNiuBankerBid(conn, sessionid, msgid) 
    print("onNiuBankerBid")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local seat = po:read_byte()
    local mult = po:read_int32()
    print("mult is",mult)
    app.game.GamePresenter:getInstance():onNiuBankerBid(seat, mult) 
end

-- 比牌加倍
function _M.onNiuCompareBid(conn, sessionid, msgid) 
    print("onNiuCompareBid")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local seat = po:read_byte()
    local mult = po:read_int32()

    app.game.GamePresenter:getInstance():onNiuCompareBid(seat, mult) 
end

-- 比牌
function _M.onNiuCompareCard(conn, sessionid, msgid)
    print("onNiuCompareCard")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local player = {}
    player.seat      = po:read_byte()
    local strcards   = po:read_string()    
    player.cards     = _readCards(strcards)    
    player.cardtype  = po:read_byte()
    player.cardmult  = po:read_int32() 

    app.game.GamePresenter:getInstance():onNiuCompareCard(player)  
end

-- 请求准备
function _M.sendPlayerReady(self)
    print("sendPlayerReady")
    local sessionid = app.data.UserData.getSession() or 222
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    po:writer_reset()
    po:write_int64(sessionid) -- test token
    upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_NIU_READY_REQ)
end
return _M