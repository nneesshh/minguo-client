--[[
@brief  游戏配置数据
]]--

local GameConfig = {}

GameConfig._gameID = nil
GameConfig._base   = nil

function GameConfig.reset()
    print("gameconfig reset")
    GameConfig._gameID = nil
    GameConfig._base   = nil
    GameConfig._limit  = nil 
end

function GameConfig.init(gameid, base, limit)
    GameConfig._gameID = gameid
    GameConfig._base   = base
    GameConfig._limit  = limit
end

function GameConfig.getGameID()
    return GameConfig._gameID
end
	
function GameConfig.getBase()
    return GameConfig._base or 1
end

function GameConfig.getLimit()
    return GameConfig._limit or 1
end

return GameConfig