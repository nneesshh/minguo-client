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
    NIU_TYPE_NIU_WU         = 0,   -- 无牛
    NIU_TYPE_NIU_1          = 1,   -- 牛一
    NIU_TYPE_NIU_2          = 2,   -- 牛二
    NIU_TYPE_NIU_3          = 3,   -- 牛三
    NIU_TYPE_NIU_4          = 4,   -- 牛四
    NIU_TYPE_NIU_5          = 5,   -- 牛五
    NIU_TYPE_NIU_6          = 6,   -- 牛六
    NIU_TYPE_NIU_7          = 7,   -- 牛七
    NIU_TYPE_NIU_8          = 8,   -- 牛八
    NIU_TYPE_NIU_9          = 9,   -- 牛九
    NIU_TYPE_NIU_NIU        = 10,  -- 牛牛
    NIU_TYPE_BOMB           = 11,  -- 炸弹牛
    NIU_TYPE_FIVE_JQK       = 12,  -- 五花牛
    NIU_TYPE_FIVE_LITTLE    = 13,  -- 五小牛
}

GameEnum.hintType = {
    LHD_WAIT       = 1,   -- 等待
    LHD_LESS       = 2,   -- 低于5000   
    LHD_BOTH       = 3,   -- 均展示
}

GameEnum.soundType = {
    bet            = "bet.mp3",
    countdown      = "countdown.mp3",
    winall         = "banker_win_all.mp3",
    fly            = "se_chips.mp3",    
    game           = "bgm_game.mp3",    
    w_niu_0        = "niu_0_w.mp3",
    w_niu_1        = "niu_1_w.mp3",
    w_niu_2        = "niu_2_w.mp3",
    w_niu_3        = "niu_3_w.mp3",
    w_niu_4        = "niu_4_w.mp3",
    w_niu_5        = "niu_5_w.mp3",
    w_niu_6        = "niu_6_w.mp3",
    w_niu_7        = "niu_7_w.mp3",
    w_niu_8        = "niu_8_w.mp3",
    w_niu_9        = "niu_9_w.mp3",
    w_niu_10       = "niu_10_w.mp3",
    w_niu_11       = "niu_sizha_w.mp3",
    w_niu_12       = "niu_wuhua_w.mp3",
    w_niu_13       = "niu_5_s_w.mp3",
    start          = "start.mp3",
    stop           = "stop.mp3",
    win            = "niu_win.mp3",
    lose           = "niu_lose.mp3",
    send           = "sendcard.mp3",
    e_start        = "ef_start.mp3"               
}

return GameEnum