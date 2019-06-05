--[[
@brief  游戏枚举
]]

local GameEnum = {}

GameEnum.HERO_LOCAL_SEAT           = 1

GameEnum.CARDBACK                  = 0
GameEnum.CARDGRAY                  = 888

GameEnum.HISTORY_NUM               = 20
GameEnum.MAX_NUM                   = 48

-- 牌型信息
GameEnum.cardsType = {
    LHD_LONG       = 1,   -- 龙
    LHD_HU         = 2,   -- 虎
    LHD_HE         = 3,   -- 和    
}

GameEnum.hintType = {
    LHD_WAIT       = 1,   -- 等待
    LHD_LESS       = 2,   -- 低于5000   
    LHD_BOTH       = 3,   -- 均展示
}

GameEnum.soundType = {
    bet            = "bet.mp3",
    countdown      = "countdown.mp3",
    flipcard       = "flipcard.mp3",
    lh_vs          = "lh_vs.mp3",
    n01            = "n01.mp3",
    n02            = "n02.mp3",
    n03            = "n03.mp3",    
    n04            = "n04.mp3",
    n05            = "n05.mp3",
    n06            = "n06.mp3",
    n07            = "n07.mp3",
    n08            = "n08.mp3",
    n09            = "n09.mp3",
    n10            = "n10.mp3",
    n11            = "n11.mp3",
    n12            = "n12.mp3",
    n13            = "n13.mp3",
    start          = "start.mp3",
    stop           = "stop.mp3",
    win_bet        = "win_bet.mp3",
    win_1          = "win_long.mp3",
    win_2          = "win_hu.mp3",
    win_3          = "win_he.mp3",
}

return GameEnum