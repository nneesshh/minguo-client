--[[
@brief  游戏枚举
]]--

local GameEnum = {}

GameEnum.HERO_LOCAL_SEAT           = 1

GameEnum.CARDBACK                  = 0
GameEnum.CARDGRAY                  = 888

GameEnum.soundType = {
    m_by           = {"man/Man_buyao1.mp3", "man/Man_buyao2.mp3", "man/Man_buyao3.mp3", "man/Man_buyao4.mp3"},
    w_by           = {"women/Woman_buyao1.mp3", "women/Woman_buyao2.mp3", "women/Woman_buyao3.mp3","women/Woman_buyao4.mp3"},    
    m_jb           = "man/Man_jiabei.mp3",
    m_bjb          = "man/Man_bujiabei.mp3",    
    w_jb           = "women/Woman_jiabei.mp3",
    w_bjb          = "women/Woman_bujiabei.mp3",
    m_s0           = "man/Man_ScoreNoOrder.mp3",
    m_s1           = "man/Man_ScoreOrder1.mp3",
    m_s2           = "man/Man_ScoreOrder2.mp3",
    m_s3           = "man/Man_ScoreOrder3.mp3",    
    w_s0           = "women/Woman_ScoreNoOrder.mp3",
    w_s1           = "women/Woman_ScoreOrder1.mp3",
    w_s2           = "women/Woman_ScoreOrder2.mp3",
    w_s3           = "women/Woman_ScoreOrder3.mp3",    
    out            = {"SpecSelectCard1.mp3", "SpecSelectCard2.mp3"},
    m_1            = "man/Man_baojing1.mp3",
    m_2            = "man/Man_baojing2.mp3",    
    w_1            = "women/Woman_baojing1",
    w_2            = "women/Woman_baojing2",
    alert          = "Special_alert.mp3",
    boom           = "Special_Bomb.mp3",  
    bwang          = "Special_Bomb_wang.mp3",
    win            = "MusicEx_Win.mp3",
    lose           = "MusicEx_Lose.mp3", 
    chuntian       = "Special_Chuntian.mp3",
    mult           = "Special_Multiply.mp3",
    plan           = "Special_plane.mp3",
    banker         = "Special_querendizhu.mp3"
}

GameEnum.bgType = {
    bg             = {"MusicEx_Normal.mp3", "MusicEx_Normal2.mp3"},
    bg_less8       = "MusicEx_Exciting.mp3",
    bg_boom        = "MusicEx_wangBomb.mp3",
}

GameEnum.bankBidState = {
    DDZ_BANKER_BID_STATE_IDLE         = 0,
    DDZ_BANKER_BID_STATE_TURN         = 1,
    DDZ_BANKER_BID_STATE_READY        = 2,
    DDZ_BANKER_BID_STATE_RANDOM_READY = 3,
    DDZ_BANKER_BID_STATE_RESTART      = 4,
}

return GameEnum