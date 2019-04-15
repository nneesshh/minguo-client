--[[
@brief  游戏枚举
]]
local Game = {}

Game.GameID = {   
    ZJH   = 1,
    JDNN  = 2,
}

Game.GameName = {
    [Game.GameID.ZJH]    = "拼三张",    
}

Game.MaxPlayCnt = {
    [Game.GameID.ZJH]    = 5,
}

return Game