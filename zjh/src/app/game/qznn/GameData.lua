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
    banker        = -1,        -- 庄家
    currseat      = -1,        -- 当前押注玩家
    playercount   = 0,         -- 玩家数
    playerseat    = {},        -- 座位号  
    basecoin      = 0,
    isallIn       = false,     -- 是否全压
    cards         = {handcards = {}, cardtype = -1, mult = 1},     -- 手牌数据(jdnn)
    bankermult    = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0}, -- 抢庄倍数
    isgroup       = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0}, -- 是否组牌
    handcards     = {},        -- 手牌 (qznn)
    pbanker       = false,     -- 是否抢庄(防止多次请求) 
    pmult         = false,     -- 是否下注
    pgroup        = false      -- 是否摊牌                             
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
    _selfData.banker      = -1
    _selfData.currseat    = -1
    _selfData.playercount = 0
    _selfData.playerseat  = {}
    _selfData.basecoin    = 0
    _selfData.isallIn     = false
    _selfData.cards       = {handcards = {}, cardtype = -1, mult = 1}
    _selfData.bankermult  = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0}
    _selfData.isgroup     = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0}
    _selfData.handcards   = {}
    _selfData.pbanker     = false
    _selfData.pmult       = false
    _selfData.pgroup      = false
end

function GameData.restDataEx()
    _selfData.banker      = -1
    _selfData.cards       = {handcards = {}, cardtype = -1, mult = 1}
    _selfData.bankermult  = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0}
    _selfData.isgroup     = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0}
    _selfData.pbanker     = false
    _selfData.pmult       = false
    _selfData.pgroup      = false
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

-- 自己的手牌
function GameData.setHeroCards(cards, type, mult)
    _selfData.cards = {handcards = cards, cardtype = type, mult = mult}
end

function GameData.getHeroCards()
    return _selfData.cards
end

-- 抢庄倍数
function GameData.setBankerMult(seat, mult)
    _selfData.bankermult[seat] = mult
end

function GameData.getBankerMult()
    return _selfData.bankermult
end

-- 是否组牌
function GameData.setGroup(seat, flag)
    _selfData.isgroup[seat] = flag
end

function GameData.getGroup()
    return _selfData.isgroup
end

-- 设置手牌
function GameData.setHandCards(cards)
	_selfData.handcards = clone(cards)
end

function GameData.getHandCards()
    return _selfData.handcards
end

-- 标记防止多次请求
function GameData.setPbanker(flag)
    _selfData.pbanker = flag
end

function GameData.getPbanker()
    return _selfData.pbanker
end

function GameData.setPmult(flag)
    _selfData.pmult = flag
end

function GameData.getPmult()
    return _selfData.pmult
end

function GameData.setPgroup(flag)
    _selfData.pgroup = flag
end

function GameData.getPgroup()
    return _selfData.pgroup
end

return GameData