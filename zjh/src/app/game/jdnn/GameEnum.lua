--[[
@brief  游戏枚举
]]

local GameEnum = {}

GameEnum.HERO_LOCAL_SEAT           = 1
GameEnum.BANKER_TIME               = 5
GameEnum.BET_TIME                  = 5
GameEnum.CAL_TIME                  = 5
GameEnum.CARDBACK                  = 0
GameEnum.CARDGRAY                  = 888

GameEnum.CARD_NUM                  = 5
GameEnum.LINE_CARD_NUM             = 5

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

GameEnum.playerStatus = {
    zjh_idle       = 0,
    zjh_sit        = 1    ,
    zjh_ready      = 2,
    zjh_playing    = 3,
    zjh_waiting    = 4,
    zjh_giveup     = 5,
    zjh_lost       = 6    
}

GameEnum.soundType = {
    lose           = "af_lose.mp3",
    win            = "niu_win.mp3",
    bankerwin      = "banker_win_all.mp3",
    fly            = "se_chips.mp3",
    game           = "bgm_game.mp3",
    bankermult     = "ef_xuanzhuang.mp3",
    mult           = "xia_zhu_1.mp3",    
    banker         = "zhuang.mp3",
    m_niu_0        = "niu_0_m.mp3",
    m_niu_1        = "niu_1_m.mp3",
    m_niu_2        = "niu_2_m.mp3",
    m_niu_3        = "niu_3_m.mp3",
    m_niu_4        = "niu_4_m.mp3",
    m_niu_5        = "niu_5_m.mp3",
    m_niu_6        = "niu_6_m.mp3",
    m_niu_7        = "niu_7_m.mp3",
    m_niu_8        = "niu_8_m.mp3",
    m_niu_9        = "niu_9_m.mp3",
    m_niu_10       = "niu_10_m.mp3",
    m_niu_11       = "niu_sizha_m.mp3",
    m_niu_12       = "niu_wuhua_m.mp3",
    m_niu_13       = "niu_5_s_m.mp3",
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
}

return GameEnum