--[[
@brief  游戏枚举
]]

local GameEnum = {}

GameEnum.HERO_LOCAL_SEAT           = 1

GameEnum.CARDBACK                  = 0
GameEnum.CARDGRAY                  = 888

-- 牌型信息
GameEnum.cardType = {
    CTID_NONE        = 0,    --无
    CTID_YI_ZHANG    = 1,    --单张
    CTID_ER_ZHANG    = 2,    --对子
    CTID_SAN_ZHANG   = 3,    --三张
    CTID_SI_ZHANG    = 4,    --四张
    CTID_WU_ZHANG    = 5,    --五张
    CTID_LIU_ZHANG   = 6,    --六张
    CTID_QI_ZHANG    = 7,    --七张
    CTID_BA_ZHANG    = 8,    --八张
    CTID_YI_SHUN     = 9,    --单顺
    CTID_ER_SHUN     = 10,   --双顺
    CTID_SAN_SHUN    = 11,   --三顺
    CTID_SI_SHUN     = 12,   --四顺
    CTID_WU_SHUN     = 13,   --五顺
    CTID_LIU_SHUN    = 14,   --六顺
    CTID_QI_SHUN     = 15,   --七顺
    CTID_BA_SHUN     = 16,   --八顺
    CTID_HUO_JIAN    = 17,   --火箭
    CTID_FEI_JI      = 18,   --飞机带翅膀
    CTID_SAN_DAI_YI  = 19,   --三带一
    CTID_SI_DAI_ER   = 20,   --四带二
    CTID_SAN_DAI_ER  = 21,   --三带二
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