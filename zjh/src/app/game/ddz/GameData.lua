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
    lastComb      = {serverSeat = -1 ,comb = app.game.CardRule.CardComb:new()},
    hintComb      = {},
    startHintIndex= 1,
    handCards     = {[0] = {}, [1] = {}, [2] = {}}
--    mult          = {[0] = 1,}
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
    _selfData.lastComb    = {serverSeat = -1 ,comb = app.game.CardRule.CardComb:new()} 
    _selfData.hintComb    = {}
    _selfData.startHintIndex = 1
    _selfData.handCards   = {[0] = {}, [1] = {}, [2] = {}}
end

function GameData.restDataEx()
    _selfData.lastComb    = {serverSeat = -1 ,comb = app.game.CardRule.CardComb:new()} 
    _selfData.hintComb    = {}
    _selfData.startHintIndex = 1
    _selfData.handCards   = {[0] = {}, [1] = {}, [2] = {}}
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

-- 设置最后一幅有效牌型
function GameData.setLastComb(serverseat,comb)
    _selfData.lastComb = {serverSeat = serverseat ,comb = comb}
end

-- 获取最后一幅有效牌型
function GameData.getLastComb()
    return _selfData.lastComb.serverSeat, _selfData.lastComb.comb
end

-- 提示相关
function GameData.setHintComb(hintComb)
    _selfData.hintComb = hintComb
end 

function GameData.getHintComb()
    return _selfData.hintComb
end

function GameData.setStartHintIndex(startHintIndex)
    _selfData.startHintIndex = startHintIndex
end 

function GameData.getStartHintIndex()
    return _selfData.startHintIndex
end

-- 设置某个位置某人的手牌
function GameData.setHandCards(serverSeat, cards)
    _selfData.handCards[serverSeat] = clone(cards)
end
 
function GameData.setBackCards(serverSeat, count)
    local cards = {}    
    for i = 1, count do
        cards[i] = 0
    end

    GameData.setHandCards(serverSeat, cards)
end

-- 获取某个位置某人的手牌
function GameData.getHandCards(serverseat)
    return _selfData.handCards[serverseat]
end

function GameData.getAllHandCard()
    return _selfData.handCards
end

return GameData