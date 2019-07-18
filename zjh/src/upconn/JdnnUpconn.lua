local app = app

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

-- 游戏准备
function _M.onNiuGamePrepare(conn, sessionid, msgid) 
    print("onNiuGamePrepare")

    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onGamePrepare() 
    end    
end

-- 游戏开始
function _M.onNiuGameStart(conn, sessionid, msgid)
    local gameStream = app.connMgr.getGameStream()

    print("onNiuGameStart")
    local po = gameStream:get_packet_obj()
    if po == nil then return end   
    local basecoin   = po:read_int32()
    local tabInfo    = _readTableInfo(po)
    tabInfo.basecoin = basecoin
    
    if app.game.GameData then
        app.game.GameData.setTableInfo(tabInfo)
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onGameStart() 
    end    
end

-- 游戏结束
function _M.onNiuGameOver(conn, sessionid, msgid) 
    local gameStream = app.connMgr.getGameStream()

    print("onNiuGameOver")
    local po = gameStream:get_packet_obj()   
    if po == nil then return end   
    local playercont = po:read_int32()
    
    local players = {}
    for i=1, playercont do
        players[i] = players[i] or {}
        players[i].seat     = po:read_int16()
        players[i].score    = po:read_int32()
        local strcards      = po:read_string()    
        players[i].cards    = _readCards(strcards)  
        players[i].cardtype = po:read_byte()   
        players[i].balance  = po:read_int64()
    end
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuGameOver(players) 
    end     
end

-- 定庄 
function _M.onNiuConfirmBanker(conn, sessionid, msgid) 
    local gameStream = app.connMgr.getGameStream()

    print("onNiuConfirmBanker")
    local po = gameStream:get_packet_obj() 
    if po == nil then return end   
    local banker = {}
    banker.banker     = po:read_int16()
    banker.bankerMult = po:read_int32()
    print("banker.bankerMult",banker.bankerMult, banker.banker)
    local players = {}
    local playercont = po:read_int32()
    for i=1,playercont do
        players[i] = players[i] or {}
        players[i].seat    = po:read_int16()
        players[i].mult    = po:read_int32()
        players[i].balance = po:read_int64()
        print("player mult", players[i].mult, players[i].seat )
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuConfirmBanker(banker, players)    
    end   
end

-- 比牌加倍结束
function _M.onNiuConfirmMult(conn, sessionid, msgid) 
    local gameStream = app.connMgr.getGameStream()

    print("onNiuConfirmMult")
    local po = gameStream:get_packet_obj() 
    if po == nil then return end   
    
    local hero = {}
    local strcards = po:read_string()    
    hero.cards     = _readCards(strcards)    
    hero.cardtype  = po:read_byte()
    hero.cardmult  = po:read_int32()    
         
    local players = {}
    local playercont = po:read_int32()
    
    for i=1, playercont do
        players[i] = players[i] or {}
        players[i].seat = po:read_int16()
        
        players[i].mult = po:read_int32()
        players[i].balance = po:read_int64()       
    end
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuConfirmMult(hero, players) 
    end    
end

-- 准备
function _M.onNiuPlayerReady(conn, sessionid, msgid) 
    local gameStream = app.connMgr.getGameStream()

    print("onNiuPlayerReady")
    local po = gameStream:get_packet_obj()
    if po == nil then return end   
    local seat = po:read_int16()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuPlayerReady(seat) 
    end
end

-- 抢庄加倍
function _M.onNiuBankerBid(conn, sessionid, msgid) 
    local gameStream = app.connMgr.getGameStream()

    print("onNiuBankerBid")    
    local po = gameStream:get_packet_obj()
    if po == nil then return end   
    
    local seat = po:read_int16()
    local mult = po:read_int32()
    print("mult is",mult)
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuBankerBid(seat, mult) 
    end    
end

-- 比牌加倍
function _M.onNiuCompareBid(conn, sessionid, msgid) 
    local gameStream = app.connMgr.getGameStream()

    print("onNiuCompareBid")    
    local po = gameStream:get_packet_obj()
    if po == nil then return end   
    
    local seat = po:read_int16()
    local mult = po:read_int32()

    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuCompareBid(seat, mult) 
    end    
end

-- 比牌
function _M.onNiuCompareCard(conn, sessionid, msgid)
    local gameStream = app.connMgr.getGameStream()
    
    print("onNiuCompareCard")
    local po = gameUpconn:get_packet_obj()
    if po == nil then return end   
    
    local player = {}
    player.seat      = po:read_int16()
    local strcards   = po:read_string()    
    player.cards     = _readCards(strcards)    
    player.cardtype  = po:read_byte()
    player.cardmult  = po:read_int32() 
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onNiuCompareCard(player)  
    end    
end

return _M