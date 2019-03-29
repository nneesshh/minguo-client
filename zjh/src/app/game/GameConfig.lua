--[[
@brief  游戏配置数据
]]--

local GameConfig = {}

GameConfig._gameID      = nil

function GameConfig.reset()
    GameConfig._gameID      = nil
end

function GameConfig.init(gameid)
    GameConfig._gameID = gameid
end

function GameConfig.getGameID()
    return GameConfig._gameID
end
	
return GameConfig