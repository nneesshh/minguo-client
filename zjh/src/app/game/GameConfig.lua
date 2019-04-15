--[[
@brief  游戏配置数据
]]--

local GameConfig = {}

GameConfig._gameID = nil
GameConfig._base   = nil

function GameConfig.reset()
    GameConfig._gameID = nil
    GameConfig._base   = nil
end

function GameConfig.init(gameid, base)
    GameConfig._gameID = gameid
    GameConfig._base   = base
end

function GameConfig.getGameID()
    return GameConfig._gameID
end
	
function GameConfig.getBase()
    return GameConfig._base or 1
end

return GameConfig