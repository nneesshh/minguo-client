--[[
@brief  游戏枚举
]]
local Game = {}

Game.GameID = {   
    ZJH   = 1,
    JDNN  = 2,
    QZNN  = 3,
    LHD   = 4,
    BRNN  = 5,
}

Game.GameName = {
    [Game.GameID.ZJH]    = "拼三张", 
    [Game.GameID.JDNN]   = "经典牛牛",
    [Game.GameID.QZNN]   = "抢庄牛牛",  
    [Game.GameID.LHD]    = "龙虎斗",  
    [Game.GameID.BRNN]   = "百人牛牛",    
}

Game.patchManifest = {
    [Game.GameID.ZJH]    = "patch_zjh/project.manifest", 
    [Game.GameID.JDNN]   = "patch_jdnn/project.manifest",
    [Game.GameID.QZNN]   = "patch_qznn/project.manifest",  
    [Game.GameID.LHD]    = "patch_lhd/project.manifest",
    [Game.GameID.BRNN]   = "patch_brnn/project.manifest",         
}

Game.MaxPlayCnt = {
    [Game.GameID.ZJH]    = 5,
    [Game.GameID.JDNN]   = 5,
    [Game.GameID.QZNN]   = 5,
    [Game.GameID.LHD]    = 7,
    [Game.GameID.BRNN]   = 8,
}

return Game