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
function _M.onNiuGamePrepare(conn, sessionid, msgid) 
    print("onNiuGamePrepare")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuGamePrepare() 
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
    
    if app.game.GameData then
        app.game.GameData.setTableInfo(tabInfo)
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuGameStart() 
    end    
end

-- 游戏结束
function _M.onNiuGameOver(conn, sessionid, msgid) 
    print("onNiuGameOver")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    
    local overs = {}
    overs.seqid     = po:read_int64()
    -- 庄家
    overs.bcardtype = po:read_byte()   
    overs.bcards    = _readCards(po:read_string())
    -- 4个区域牌型
    overs.area1type = po:read_byte()
    overs.area2type = po:read_byte()
    overs.area3type = po:read_byte()
    overs.area4type = po:read_byte()   
    -- 手牌
    overs.areacards = _readCards(po:read_string())
    -- 4个区域输赢  
    overs.winlose1  = po:read_byte()
    overs.winlose2  = po:read_byte()
    overs.winlose3  = po:read_byte()
    overs.winlose4  = po:read_byte()   
    -- 4个区域倍数
    overs.mult1     = po:read_int32()
    overs.mult2     = po:read_int32()
    overs.mult3     = po:read_int32()
    overs.mult4     = po:read_int32()
    
    overs.gamenum20 = po:read_byte()
    overs.betnum20  = po:read_int32()
    overs.ticketid  = po:read_int32()
    overs.seat      = po:read_int16()
    overs.area1     = po:read_int32()
    overs.area2     = po:read_int32()
    overs.area3     = po:read_int32()
    overs.area4     = po:read_int32()    
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
        players[i].area1     = po:read_int32()
        players[i].area2     = po:read_int32()
        players[i].area3     = po:read_int32()
        players[i].area4     = po:read_int32()
        players[i].bouns     = po:read_int32()
        
        players[i].seatinfo  = _readSeatPlayerInfo(po)  
    end

    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuGameOver(overs, players) 
    end    
end

function _M.onNiuBankerBid(conn, sessionid, msgid)
    print("onNiuBankerBid")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end
    
    local count = po:read_int32()
    local lists = {}
    for i=1, count do
        lists[i] = lists[i] or {}
        lists[i].isSys     = po:read_byte()
        lists[i].bankernum = po:read_byte()
        if lists[i].isSys == 0 then
            lists[i].seatinfo = _readSeatPlayerInfo(po)  
        end
    end
    
    local info = {}
    info.tipid    = po:read_byte()
    info.ticketid = po:read_int32()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuBankerBid(lists, info) 
    end
end

function _M.onNiuBetFull(conn, sessionid, msgid)
    print("onNiuBetFull")   
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuBetFull() 
    end 
end

-- 历史数据 
function _M.onNiuHistory(conn, sessionid, msgid) 
    print("onNiuHistory")
    local po = upconn.upconn:get_packet_obj() 
    if po == nil then return end   
    local gamenum20 = po:read_byte()
    local betnum20  = po:read_int32()
    local count     = po:read_int32()
    
    local lists = {}
    for i=1, count do
        lists[i] = lists[i] or {}
        lists[i].seqid     = po:read_int64()
        -- 庄家
        lists[i].bcardtype = po:read_byte()   
        lists[i].bcards    = _readCards(po:read_string())
        -- 4个区域牌型
        lists[i].area1type = po:read_byte()
        lists[i].area2type = po:read_byte()
        lists[i].area3type = po:read_byte()
        lists[i].area4type = po:read_byte()   
        -- 手牌
        lists[i].areacards = _readCards(po:read_string())
        -- 4个区域输赢  
        lists[i].winlose1  = po:read_byte()
        lists[i].winlose2  = po:read_byte()
        lists[i].winlose3  = po:read_byte()
        lists[i].winlose4  = po:read_byte()
        -- 4个区域倍数
        lists[i].mult1     = po:read_int32()
        lists[i].mult2     = po:read_int32()
        lists[i].mult3     = po:read_int32()
        lists[i].mult4     = po:read_int32()
    end
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuHistory(lists)    
    end   
end

-- 玩家列表
function _M.onNiuTopSeat(conn, sessionid, msgid) 
    print("onNiuTopSeat", app.data.UserData.getTicketID())
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
        players[i].area1num  = po:read_int32()
        players[i].area2num  = po:read_int32()
        players[i].area3num  = po:read_int32()
        players[i].area4num  = po:read_int32()
        players[i].bouns     = po:read_int32()

        players[i].seatinfo  = _readSeatPlayerInfo(po)
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuTopSeat(players)        
    end    
end

-- 准备
function _M.onNiuPlayerReady(conn, sessionid, msgid) 
    print("onNiuPlayerReady")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    local seat = po:read_int16()
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuPlayerReady(seat)         
    end 
end

-- 押注
function _M.onNiuBet(conn, sessionid, msgid) 
    print("onNiuBet")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local bets = {}
    bets.seat     = po:read_int16()
    bets.betarea1 = po:read_int32()
    bets.betarea2 = po:read_int32()
    bets.betarea3 = po:read_int32()
    bets.betarea4 = po:read_int32()
    
    bets.balance  = po:read_int64()
    
    bets.sumarea1 = po:read_int64()
    bets.sumarea2 = po:read_int64()
    bets.sumarea3 = po:read_int64()
    bets.sumarea4 = po:read_int64()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuBet(bets) 
    end
end

function _M.onNiuBankerResp(conn, sessionid, msgid)
    print("onNiuBankerResp")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end 
    local resp = {}
    resp.errorCode = po:read_int32()
    resp.errorMsg  = po:read_string()
    
    resp.type = po:read_int32()
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuBankerResp(resp) 
    end  
end


return _M