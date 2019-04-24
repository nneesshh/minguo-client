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
    win            = "af_jhwin.mp3",
    pk             = "af_pk.mp3",
    pk_lose        = "af_pk_loss.mp3",
    baozi          = "af_t_baozi.mp3",
    shunjin        = "af_t_shunjin.mp3",
    game           = "bgm_game2.mp3",
    didi           = "didi.mp3",
    chip           = "jh_chip.mp3",
    cd             = "countdown.mp3",  
    
    m_qp           = {"jh_m_qipai1.mp3", "jh_m_qipai2.mp3", "jh_m_qipai3.mp3"},
    m_kp           = "jh_m_kan.mp3",
    m_bp           = "jh_m_pk.mp3",
    m_jz           = "jh_m_jia.mp3",
    m_gz           = {"jh_m_gen1.mp3", "jh_m_gen2.mp3", "jh_m_gen3.mp3"},
    m_qy           = "jh_m_allin.mp3",
    
    w_qp           = {"jh_w_qipai1.mp3", "jh_w_qipai2.mp3", "jh_w_qipai1.mp3"},
    w_kp           = "jh_w_kan.mp3",
    w_bp           = {"jh_w_pk1.mp3", "jh_w_pk2.mp3", "jh_w_pk3.mp3"},
    w_jz           = "jh_w_jia.mp3",
    w_gz           = {"jh_w_gen1.mp3", "jh_w_gen2.mp3", "jh_w_gen3.mp3"},
    w_qy           = {"jh_w_allin1.mp3", "jh_w_allin2.mp3", "jh_w_allin2.mp3"}
}

return GameEnum