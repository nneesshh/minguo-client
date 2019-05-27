--[[
    @brief  游戏数据
]]--
local GameData = {}

local _selfData = {
    tableid       = -1,            
    status        = 0,         -- 状态
    round         = 0,         -- 当前回合
    basebet       = 1,         -- 最少押注
    jackpot       = 0,         -- 总注
    long          = 0,         -- 龙 
    hu            = 0,         -- 虎 
    he            = 0,         -- 和
    area4         = 0,         -- 
    banker        = -1,        -- 庄家
    currseat      = -1,        -- 当前押注玩家
    playercount   = 0,         -- 玩家数
    playerseat    = {},        -- 座位号  
    basecoin      = 0,
    isallIn       = false,     -- 是否全压
    leaveseats    = {},        -- 游戏过程中收到要退出玩家的本地座位
    handcards     = {},        -- 手牌 
    isready       = false,     -- 自己是否准备  
    cardsdata     = {},        -- 所有人手牌数据
    compareseats  = {},        -- 与自己进行比牌的座位号 
    showseats     = {},        -- 选择亮牌的座位号 
}

function GameData.setTableInfo(info)
    _selfData.tableid     = info.tableid
    _selfData.status      = info.status
    _selfData.round       = info.round
    _selfData.basebet     = info.basebet
    _selfData.jackpot     = info.jackpot
    _selfData.long        = info.long
    _selfData.hu          = info.hu
    _selfData.he          = info.he
    _selfData.area4       = info.area4    
    _selfData.banker      = info.banker
    _selfData.currseat    = info.currseat
    _selfData.playercount = info.playercount
    _selfData.playerseat  = info.playerseat   
    _selfData.basecoin    = info.basecoin or 0
end

function GameData.setGameInfo(info)
    _selfData.round       = info.round
    _selfData.jackpot     = info.jackpot
    _selfData.currseat    = info.currseat
end

function GameData.getGameData()
    return _selfData
end

function GameData.restData()
    _selfData.tableid     = -1
    _selfData.status      = 0
    _selfData.round       = 0
    _selfData.basebet     = 1
    _selfData.jackpot     = 0
    _selfData.long        = 0
    _selfData.hu          = 0
    _selfData.he          = 0
    _selfData.area4       = 0
    _selfData.banker      = -1
    _selfData.currseat    = -1
    _selfData.playercount = 0
    _selfData.playerseat  = {}
    _selfData.basecoin    = 0
    _selfData.isallIn     = false
    _selfData.leaveseats  = {}
    _selfData.handcards   = {}
    _selfData.isready     = false    
    _selfData.cardsdata     = {}
    _selfData.compareseats= {}
    _selfData.showseats   = {}
end

function GameData.resetDataEx()
    _selfData.handcards   = {}
    _selfData.isallIn     = false
    _selfData.isready     = false
    _selfData.cardsdata   = {}
    _selfData.compareseats= {}
    _selfData.showseats   = {}
end

function GameData.setTableStatus(status)
    _selfData.status = status 
end

function GameData.getTableStatus()
    return _selfData.status
end

function GameData.setRound(round)
    _selfData.round = round 
end

function GameData.getRound()
    return _selfData.round or 0
end

function GameData.setBasebet(basebet)
    _selfData.basebet = basebet
end

function GameData.getBasebet()
    return _selfData.basebet
end

function GameData.setJackpot(jackpot)
    _selfData.jackpot = jackpot
end

function GameData.getJackpot()
    return _selfData.jackpot
end

function GameData.setBanker(banker)
    _selfData.banker = banker
end

function GameData.getBanker()
    return _selfData.banker
end

function GameData.setCurrseat(currseat)
    _selfData.currseat = currseat
end

function GameData.getCurrseat()
    return _selfData.currseat
end

function GameData.setPlayercount(playercount)
    _selfData.playercount = playercount
end

function GameData.getPlayercount()
    return _selfData.playercount
end

function GameData.setPlayerseat(playerseat)
    _selfData.playerseat = playerseat
end

function GameData.getPlayerseat()
    return _selfData.playerseat
end

function GameData.removePlayerseat(seat)
    local tempseat = {}
    for k, v in ipairs(_selfData.playerseat) do
    	if v ~= seat then
            table.insert(tempseat, v)
    	end
    end
    _selfData.playerseat = tempseat
end

function GameData.setBasecoin(basecoin)
    _selfData.basecoin = basecoin
end

function GameData.getBasecoin()
    return _selfData.basecoin or 0
end

function GameData.setAllIn(status)
    _selfData.isallIn = status
end

function GameData.getAllIn()
    return _selfData.isallIn
end

--_selfData.leaveseats
function GameData.setLeaveSeats(localseat)
    if localseat >= 0 and localseat <= 4 then
        table.insert(_selfData.leaveseats, localseat)
    end
end

function GameData.getLeaveSeats()
    return _selfData.leaveseats
end

function GameData.resetLeaveSeats()
    _selfData.leaveseats = {}
end

function GameData.setHandcards(cards)
    _selfData.handcards = {}
    _selfData.handcards = cards
end

function GameData.resetHandcards()
    _selfData.handcards = {}
end

function GameData.getHandcards()
    return _selfData.handcards
end

function GameData.setHeroReady(flag)
	_selfData.isready = flag
end

function GameData.getHeroReady()
	return _selfData.isready
end

function GameData.setCompareSeat(seat)
    table.insert(_selfData.compareseats, seat)
end

function GameData.getCompareSeat()
    return _selfData.compareseats
end

function GameData.setCardsData(data)
    _selfData.cardsdata = data or {}
end

function GameData.getCardsData()
    return _selfData.cardsdata
end

function GameData.setShowSeat(seat)
    table.insert(_selfData.showseats, seat)
end

function GameData.getShowSeat()
    return _selfData.showseats or {}    
end

return GameData