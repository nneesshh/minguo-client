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