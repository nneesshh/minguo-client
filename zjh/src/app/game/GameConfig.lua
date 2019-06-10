--[[
@brief  游戏配置数据
]]--

local GameConfig = {}

GameConfig._gameID = nil
GameConfig._base   = nil
GameConfig._limit  = nil 
GameConfig._roomid  = nil 

function GameConfig.reset()    
    GameConfig._gameID = nil
    GameConfig._base   = nil
    GameConfig._limit  = nil
    GameConfig._roomid  = nil 
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

function GameConfig.setRoomID(roomid)
    GameConfig._roomid = roomid
end

function GameConfig.getRoomID()
    return GameConfig._roomid
end

return GameConfig