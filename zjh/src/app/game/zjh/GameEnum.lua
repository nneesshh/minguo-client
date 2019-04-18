--[[
@brief  游戏枚举
]]

local GameEnum = {}

GameEnum.HERO_LOCAL_SEAT           = 1
GameEnum.ALLROUND                  = 20
GameEnum.CARDBACK                  = 0
GameEnum.CARDGRAY                  = 888

-- 牌型信息
GameEnum.cardsType = {
    zjh_null       = 0,    -- 乌龙
    zjh_sanpai     = 1,    -- 散牌
    zjh_duizi      = 2,    -- 对子
    zjh_shunzi     = 3,    -- 顺子
    zjh_jinhua     = 4,    -- 金花
    zjh_shunjin    = 5,    -- 顺金
    zjh_baozi      = 6     -- 豹子
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