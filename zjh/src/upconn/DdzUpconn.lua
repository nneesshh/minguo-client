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
function _M.onDdzGamePrepare(conn, sessionid, msgid) 
    print("onDdzGamePrepare")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzGamePrepare() 
    end    
end

-- 游戏开始
function _M.onDdzGameStart(conn, sessionid, msgid)
    print("onDdzGameStart")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    local basecoin   = po:read_int32()
    local tabInfo    = _readTableInfo(po)
    tabInfo.basecoin = basecoin
    local cards      = _readCards(po:read_string())
    
    if app.game.GameData then
        app.game.GameData.setTableInfo(tabInfo)
    end
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzGameStart(cards) 
    end    
end

-- 游戏结束
function _M.onDdzGameOver(conn, sessionid, msgid) 
    print("onDdzGameOver")
    local po = upconn.upconn:get_packet_obj()   
    if po == nil then return end   

    local players = {}
    players.playercnt = po:read_int32()
    for i=1, players.playercnt do
        players[i] = players[i] or {}
        players[i].seat      = po:read_int16()    
        players[i].mult      = po:read_int32()    
        players[i].bouns     = po:read_int32()        
        players[i].cards     = _readCards(po:read_string())
        players[i].balance   = po:read_int64()        
    end
    players.spring           = po:read_byte()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzGameOver(players) 
    end    
end

-- 准备
function _M.onDdzPlayerReady(conn, sessionid, msgid) 
    print("onDdzPlayerReady")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local seat = po:read_int16()
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzPlayerReady(seat)         
    end 
end

function _M.onDdzCompareBidOver(conn, sessionid, msgid)
    print("onDdzCompareBid")   
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end

    local info = {}    
    info.bankmult = po:read_int32()
    info.count    = po:read_int32()
    local players = {}
    for i=1, info.count do
        players[i] = players[i] or {}
        players[i].seat    = po:read_int16()
        players[i].mult    = po:read_int32()
        players[i].balance = po:read_int64()  
    end
    
    dump(players)
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzCompareBidOver(info, players) 
    end 
end

-- 叫地主
function _M.onDdzBankerBid(conn, sessionid, msgid)
    print("onDdzBankerBid")
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end
    
    local info = {}
    info.seat     = po:read_int16()
    info.mult     = po:read_int32()
    info.curseat  = po:read_int16()
    info.bankmult = po:read_int32()    
    info.bidstate = po:read_byte()    
    if info.bidstate == 2 then
        info.bankseat = po:read_int16()
        info.cards    = _readCards(po:read_string())
    end
   
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzBankerBid(info) 
    end
end

function _M.onDdzCompareBid(conn, sessionid, msgid)
    print("onDdzCompareBid")   
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end

    local info = {}    
    info.seat     = po:read_int16()
    info.mult     = po:read_int32()
    info.bankmult = po:read_int32()
    
    dump(info)
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzCompareBid(info) 
    end 
end

-- 明牌 
function _M.onDdzDisplay(conn, sessionid, msgid) 
    print("onDdzDisplay")
    local po = upconn.upconn:get_packet_obj() 
    if po == nil then return end
       
    local info = {}  
    info.seat      = po:read_int16()
    info.cards     = _readCards(po:read_string())
    info.bankmult  = po:read_int32()
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzDisplay(info)    
    end   
end

-- 托管
function _M.onDdzAutoHint(conn, sessionid, msgid) 
    print("onDdzAutoHint")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end   
    
    local seat = po:read_int16()    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzAutoHint(seat) 
    end
end

function _M.onDdzHitCard(conn, sessionid, msgid)
    print("onDdzHitCard")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end 
    
    local info = {}
    info.seat       = po:read_int16()
    info.cards      = _readCards(po:read_string())
    info.cardtype   = po:read_byte()
    info.mult       = po:read_int32()
    info.curseat    = po:read_int16()
    info.bankmult   = po:read_int32()   
    
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzHitCard(info) 
    end  
end

function _M.onDdzPass(conn, sessionid, msgid)
    print("onDdzPass")    
    local po = upconn.upconn:get_packet_obj()
    if po == nil then return end 
    
    local info = {}
    info.seat    = po:read_int16()
    info.curseat = po:read_int16() 
           
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():onDdzPass(info) 
    end  
end

return _M