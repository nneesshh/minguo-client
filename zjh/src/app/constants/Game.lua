--[[
@brief  游戏枚举
]]
local Game = {}

Game.GameID = {   
    LOBBY = 0,
    ZJH   = 1,
    JDNN  = 2,
    QZNN  = 3,
    LHD   = 4,
    BRNN  = 5,
    DDZ   = 6
}

Game.GameName = {
    [Game.GameID.ZJH]    = "拼三张", 
    [Game.GameID.JDNN]   = "经典牛牛",
    [Game.GameID.QZNN]   = "抢庄牛牛",  
    [Game.GameID.LHD]    = "龙虎斗",  
    [Game.GameID.BRNN]   = "百人牛牛",
    [Game.GameID.DDZ]    = "斗地主",    
}

Game.patchManifest = {
    [Game.GameID.ZJH]    = "patch_zjh/project.manifest", 
    [Game.GameID.JDNN]   = "patch_jdnn/project.manifest",
    [Game.GameID.QZNN]   = "patch_qznn/project.manifest",  
    [Game.GameID.LHD]    = "patch_lhd/project.manifest",
    [Game.GameID.BRNN]   = "patch_brnn/project.manifest", 
    [Game.GameID.DDZ]    = "patch_ddz/project.manifest", 
}

Game.localVersion = {
    [Game.GameID.LOBBY]  = "patch/lobby/version.manifest", 
    [Game.GameID.ZJH]    = "patch/zjh/version.manifest", 
    [Game.GameID.JDNN]   = "patch/jdnn/version.manifest",
    [Game.GameID.QZNN]   = "patch/qznn/version.manifest",  
    [Game.GameID.LHD]    = "patch/lhd/version.manifest",
    [Game.GameID.BRNN]   = "patch/brnn/version.manifest",
    [Game.GameID.DDZ]    = "patch/ddz/version.manifest",          
}

Game.patchVersion = {
    [Game.GameID.LOBBY]  = "patch_lobby/version.manifest",
    [Game.GameID.ZJH]    = "patch_zjh/version.manifest", 
    [Game.GameID.JDNN]   = "patch_jdnn/version.manifest",
    [Game.GameID.QZNN]   = "patch_qznn/version.manifest",  
    [Game.GameID.LHD]    = "patch_lhd/version.manifest",
    [Game.GameID.BRNN]   = "patch_brnn/version.manifest",   
    [Game.GameID.DDZ]    = "patch_ddz/version.manifest",               
}

Game.MaxPlayCnt = {
    [Game.GameID.ZJH]    = 5,
    [Game.GameID.JDNN]   = 5,
    [Game.GameID.QZNN]   = 5,
    [Game.GameID.LHD]    = 7,
    [Game.GameID.BRNN]   = 8,
    [Game.GameID.DDZ]    = 3,
}

return Game