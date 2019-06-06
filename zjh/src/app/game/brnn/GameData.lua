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
    area1         = 0,         -- 黑 
    area2         = 0,         -- 红 
    area3         = 0,         -- 梅
    area4         = 0,         -- 方    
    banker        = -1,        -- 庄家
    currseat      = -1,        -- 当前押注玩家
    playercount   = 0,         -- 玩家数
    playerseat    = {},        -- 座位号  
    basecoin      = 0,
    hislists      = {},        -- 记录列表     
    playerlists   = {},        -- 玩家列表
    sitplayers    = {},        -- 有座位的玩家   
    betarea1      = 0,          
    betarea2      = 0,          
    betarea3      = 0,   
    betarea4      = 0,
    ready         = false,     -- 是否准备 
    full          = false,
    bankerlist    = {},        -- 上庄玩家列表 
    bankerid      = -1         -- 庄家id 
}

function GameData.setTableInfo(info)
    _selfData.tableid     = info.tableid
    _selfData.status      = info.status
    _selfData.round       = info.round
    _selfData.basebet     = info.basebet
    _selfData.jackpot     = info.jackpot    
    _selfData.area1       = info.long
    _selfData.area2       = info.hu
    _selfData.area3       = info.he
    _selfData.area4       = info.area4        
    _selfData.banker      = info.banker
    _selfData.currseat    = info.currseat
    _selfData.playercount = info.playercount
    _selfData.playerseat  = info.playerseat   
    _selfData.basecoin    = info.basecoin or 0
end

function GameData.getTableInfo()
    return _selfData
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
    _selfData.area1       = 0
    _selfData.area2       = 0
    _selfData.area3       = 0
    _selfData.area4       = 0
    _selfData.banker      = -1
    _selfData.currseat    = -1
    _selfData.playercount = 0
    _selfData.playerseat  = {}
    _selfData.basecoin    = 0
    _selfData.hislists    = {}
    _selfData.playerlists = {}
    _selfData.sitplayers  = {}
    _selfData.betarea1    = 0          
    _selfData.betarea2    = 0          
    _selfData.betarea3    = 0 
    _selfData.betarea4    = 0     
    _selfData.ready       = false
    _selfData.full        = false
    _selfData.bankerlist  = {}
    _selfData.bankerid    = -1
end

function GameData.restDataEx()
    _selfData.betarea1    = 0          
    _selfData.betarea2    = 0          
    _selfData.betarea3    = 0 
    _selfData.betarea4    = 0
    _selfData.full        = false
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

-- 记录列表
function GameData.setHisLists(data)
    _selfData.hislists = {}
    _selfData.hislists = data
end

function GameData.getHisLists()
    return _selfData.hislists
end

function GameData.setHistory(area1, area2, area3, area4)    
    local temp = {area1, area2, area3, area4}    
    _selfData.hislists = _selfData.hislists or {}    
    table.insert(_selfData.hislists, temp)
end

-- 玩家列表
function GameData.setPlayerLists(data)
    _selfData.playerlists = {}
    _selfData.playerlists = data
end

function GameData.getPlayerLists()
    return _selfData.playerlists
end

-- 有座位的玩家列表
function GameData.setSitplayers(k, player)    
    _selfData.sitplayers[k] = player
end

function GameData.getSitplayers()
    return _selfData.sitplayers
end

function GameData.resetSitPlayers()
	_selfData.sitplayers = {}
end

function GameData.getLocalseatByServerseat(seat)
    for k, player in ipairs(_selfData.sitplayers) do
        if player:getSeat() == seat then
            return k
        end
    end      
    return -1
end

function GameData.setBetArea1(bet)
    _selfData.betarea1 = _selfData.betarea1 + bet
end

function GameData.getBetArea1()
    return _selfData.betarea1
end

function GameData.setBetArea2(bet)
    _selfData.betarea2 = _selfData.betarea2 + bet
end

function GameData.getBetArea2()
    return _selfData.betarea2
end

function GameData.setBetArea3(bet)
    _selfData.betarea3 = _selfData.betarea3 + bet
end

function GameData.getBetArea3()
    return _selfData.betarea3
end

function GameData.setBetArea4(bet)
    _selfData.betarea4 = _selfData.betarea4 + bet
end

function GameData.getBetArea4()
    return _selfData.betarea4
end

function GameData.setReady(flag)
	_selfData.ready = flag
end

function GameData.getReady()
    return _selfData.ready 
end

function GameData.setFull(flag)
	_selfData.full = flag
end

function GameData.getFull()
   return _selfData.full 
end

-- 庄家列表
function GameData.setBankerLists(data)
    _selfData.bankerlist = {}
    _selfData.bankerlist = data
end

function GameData.getBankerLists()
    return _selfData.bankerlist
end

-- 庄家id
function GameData.setBankerID(id)
    _selfData.bankerid    = id
end

function GameData.getBankerID()
    return _selfData.bankerid
end

return GameData