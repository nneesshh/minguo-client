--[[
    @brief  游戏数据
]]--
local GameData = {}

local _selfData = {
    tableid       = -1,            
    status        = 0,         -- 状态
    round         = 0,         -- 当前回合
    basebet       = 0,         -- 最少押注
    jackpot       = 0,         -- 总注
    banker        = -1,        -- 庄家
    currseat      = -1,        -- 当前押注玩家
    playercount   = 0,         -- 玩家数
    playerseat    = {},        -- 座位号  
    basecoin      = 0,
}

function GameData.setTableInfo(info)
    _selfData.tableid     = info.tableid
    _selfData.status      = info.status
    _selfData.round       = info.round
    _selfData.basebet     = info.basebet
    _selfData.jackpot     = info.jackpot
    _selfData.banker      = info.banker
    _selfData.currseat    = info.currseat
    _selfData.playercount = info.playercount
    _selfData.playerseat  = info.playerseat   
    _selfData.basecoin    = info.basecoin or 0
end

function GameData.setGameInfo(info)
    _selfData.round       = info.round
    _selfData.basebet     = info.basebet
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
    _selfData.basebet     = 0
    _selfData.jackpot     = 0
    _selfData.banker      = -1
    _selfData.currseat    = -1
    _selfData.playercount = 0
    _selfData.playerseat  = {}
    _selfData.basecoin    = 0
end

function GameData.setStatus(status)
    _selfData.status = status 
end

function GameData.getStatus()
    return _selfData.status
end

function GameData.setRound(round)
    _selfData.round = round 
end

function GameData.getRound()
    return _selfData.round
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

function GameData.setBasecoin(basecoin)
    _selfData.basecoin = basecoin
end

function GameData.getBasecoin()
    return _selfData.basecoin or 0
end

return GameData