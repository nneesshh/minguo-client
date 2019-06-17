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

local function _readCards(stringCards)
    local cards = {}
    for i=1, string.len(stringCards) do
        local card = string.byte(stringCards, i, i)
        table.insert(cards, card)
    end
    return cards
end

local function _readSeatPlayerInfo(po)
    local info = {}
    info.ticketid   = po:read_int32()
    info.nickname   = po:read_string()
    info.avatar     = po:read_string()
    info.gender     = po:read_byte()
    info.balance    = po:read_int64()
    info.status     = po:read_byte()
    info.seat       = po:read_int16()
    info.bet        = po:read_int32()
    
    info.long       = po:read_int32()
    info.hu         = po:read_int32()
    info.he         = po:read_int32()
    info.area4      = po:read_int32()
    
    info.bankermult = po:read_int32()
    info.mult       = po:read_int32()  
    info.isshow     = po:read_byte()
    
    info.display    = po:read_byte() -- 明牌(斗地主)
    if info.display == 1 then
        info.cards  = _readCards(po:read_string())
    else
        info.cardsnum = po:read_byte()
    end
    
    return info
end

-- 游戏准备
function _M.onLhdGamePrepare(conn, sessionid, msgid) 
    print("onLhdGamePrepare")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdGamePrepare() 
    end    
end

-- 游戏开始
function _M.onLhdGameStart(conn, sessionid, msgid)
    print("onLhdGameStart")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    local basecoin   = po:read_int32()
    local tabInfo    = _readTableInfo(po)
    tabInfo.basecoin = basecoin
    
    if app.game.GameData then
        app.game.GameData.setTableInfo(tabInfo)
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdGameStart() 
    end    
end

-- 游戏结束
function _M.onLhdGameOver(conn, sessionid, msgid) 
    print("onLhdGameOver")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    
    local overs = {}
    overs.seqid     = po:read_int64()
    overs.cardtype  = po:read_byte()   
    overs.cards     = _readCards(po:read_string())
      
    overs.gamenum20 = po:read_byte()
    overs.betnum20  = po:read_int32()
    overs.ticketid  = po:read_int32()
    overs.seat      = po:read_int16()
    overs.longnum   = po:read_int32()
    overs.hunum     = po:read_int32()
    overs.henum     = po:read_int32()
    overs.bouns     = po:read_int32()
    
    overs.balance   = po:read_int64()
    
    local players = {}
    players.playercnt = po:read_int32()
    for i=1, players.playercnt do
        players[i] = players[i] or {}
        players[i].gamenum20 = po:read_byte()
        players[i].betnum20  = po:read_int32()
        players[i].ticketid  = po:read_int32()
        players[i].seat      = po:read_int16()
        players[i].longnum   = po:read_int32()
        players[i].hunum     = po:read_int32()
        players[i].henum     = po:read_int32()
        players[i].bouns     = po:read_int32()
        
        players[i].seatinfo  = _readSeatPlayerInfo(po)  
    end

    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdGameOver(overs, players) 
    end    
end

-- 历史数据 
function _M.onLhdHistory(conn, sessionid, msgid) 
    print("onLhdHistory")
    local po = upconn.upconn:get_packet_obj() 
    if po == nil then return end   
    local gamenum20 = po:read_byte()
    local betnum20  = po:read_int32()
    local count     = po:read_int32()
    
    local lists = {}
    for i=1, count do
        lists[i] = lists[i] or {}
        lists[i].seqid    = po:read_int64()
        lists[i].cardtype = po:read_byte()
        lists[i].cards    = _readCards(po:read_string())  
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdHistory(lists)    
    end   
end

-- 玩家列表
function _M.onLhdTopSeat(conn, sessionid, msgid) 
    print("onLhdTopSeat", app.data.UserData.getTicketID())
    local po = upconn.upconn:get_packet_obj() 
    if po == nil then return end   
    
    local players = {}
    players.playercnt = po:read_int32()
    for i=1, players.playercnt do
        players[i] = players[i] or {}
        players[i].gamenum20 = po:read_byte()
        players[i].betnum20  = po:read_int32()
        players[i].ticketid  = po:read_int32()
        players[i].seat      = po:read_int16()
        players[i].longnum   = po:read_int32()
        players[i].hunum     = po:read_int32()
        players[i].henum     = po:read_int32()
        players[i].bouns     = po:read_int32()

        players[i].seatinfo  = _readSeatPlayerInfo(po)
    end
           
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdTopSeat(players) 
    else
        print("app.game.GamePresenter is nil")    
    end    
end

-- 准备
function _M.onLhdPlayerReady(conn, sessionid, msgid) 
    print("onLhdPlayerReady")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    local seat = po:read_int16()
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdPlayerReady(seat)         
    end 
end

-- 押注
function _M.onLhdBet(conn, sessionid, msgid) 
    print("onLhdBet")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local bets = {}
    bets.seat    = po:read_int16()
    bets.long    = po:read_int32()
    bets.hu      = po:read_int32()
    bets.he      = po:read_int32()
    bets.balance = po:read_int64()
    bets.longsum = po:read_int64()
    bets.husum   = po:read_int64()
    bets.hesum   = po:read_int64()
    
    if app.game.GamePresenter then
       app.game.GamePresenter:getInstance():onLhdBet(bets) 
    end
end

function _M.onLhdBetFull(conn, sessionid, msgid)
    print("onLhdBetFull")   
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onLhdBetFull() 
    end 
end

return _M