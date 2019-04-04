--[[
@brief  游戏枚举
]]
local Game = {}

Game.GameID = {   
    ZJH   = 4001,
}

Game.GameName = {
    [Game.GameID.ZJH]    = "拼三张",    
}

Game.MaxPlayCnt = {
    [Game.GameID.ZJH]    = 5,
}

return Game