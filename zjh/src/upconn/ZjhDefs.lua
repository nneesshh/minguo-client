local ErrorCode = {
    ERR_SUCCESS                 = 0x00, --
    ERR_UNKNOWN                 = 0x01, --
    ERR_USERNAME_INVALID        = 0x02, --
    ERR_USER_NOT_FOUND          = 0x03, --
    ERR_WRONG_PASSWORD          = 0x04, --
    ERR_ACCOUNT_RESTRICTION     = 0x05, --
    ERR_OUT_OF_LIMIT            = 0x06, --
    ERR_NO_FREE_TABLE           = 0x07, --
    ERR_ROOM_OR_TABLE_INVALID   = 0x08, 
    ERR_LEAVE_LOCK              = 0x09, 
    ERR_RELOGIN                 = 0x0A,
}

local ErrorMessage = {
    [0] = "登录成功",
    [1] = "未知错误",
    [2] = "请输入手机账号！",
    [3] = "该账号尚未注册！",
    [4] = "账号密码错误！",
    [5] = "账号限制",
}

--// 桌子状态
local TableStatus = {
    TS_IDLE         = 0,
    TS_PREPARE      = 1, --准备
    TS_BANKER       = 2, --抢庄
    TS_DEALING      = 3, -- 发牌
    TS_PLAYING      = 4, -- 游戏中
    TS_ENDING       = 5, -- 游戏结束
    TS_CLOSED       = 6, -- 游戏停服，桌子已经关闭
}

local MsgId = {
    --// lobby
    MSGID_HEART_BEAT_REQ		                = 0x1001,		--//心跳 4097
    MSGID_HEART_BEAT_RESP		                = 0x1002,		--//心跳 4098
    MSGID_LOGIN_REQ				                = 0x1003,		--//登录请求 4099
    MSGID_LOGIN_RESP			                = 0x1004,		--//登录回应 4100
    MSGID_REGISTER_REQ			                = 0x1005,		--//注册请求 4101
    MSGID_REGISTER_RESP			                = 0x1006,		--//注册回应 4102        
    MSGID_CHANGE_USER_INFO_REQ                  = 0x1101,       --//修改用户信息请求 4353 
    MSGID_CHANGE_USER_INFO_RESP                 = 0x1102,       --//修改用户信息回应 4354 
    
    MSGID_DEPOSIT_CASH_REQ                      = 0x1103,       --//存款请求 4355
    MSGID_DEPOSIT_CASH_RESP                     = 0x1104,       --//存款回应 4356

    MSGID_RELOGIN_NOTIFY_NEW                    = 0x888,        --//其他用户登录通知 2184 
    MSGID_PLAYER_STATUS_NOTIFY_NEW              = 0x889,        --//玩家状态改变通知 2185 
    MSGID_SIT_DOWN_NOTIFY_NEW                   = 0x88A,        --//坐下通知 2186

    --// room
    MSGID_ENTER_ROOM_REQ		                = 0x1007,		--//进入房间请求 4103
    MSGID_ENTER_ROOM_RESP		                = 0x1008,		--//进入房间回应 4104
    MSGID_LEAVE_ROOM_REQ		                = 0x1009,		--//离开房间请求 4105
    MSGID_LEAVE_ROOM_RESP		                = 0x100A,		--//离开房间回应 4106
    MSGID_CHANGE_TABLE_REQ		                = 0x100B,		--//换桌请求 4107
    MSGID_CHANGE_TABLE_RESP		                = 0x100C,		--//换桌回应 4108
    
    --// game
    MSGID_READY_REQ				                = 0x2001,		--//准备请求 8193
    MSGID_CHANGE_TABLE			                = 0x2002,		--//换桌 8194
    MSGID_ANTE_UP_REQ			                = 0x2003,		--//押注 8195
    MSGID_SHOW_CARD_REQ			                = 0x2004,		--//看牌 8196
    MSGID_COMPARE_CARD_REQ		                = 0x2005,		--//比牌 8197
    MSGID_GIVE_UP_REQ			                = 0x2006,		--//弃牌 8198
    MSGID_ZJH_GAME_OVER_SHOW_REQ                = 0x2007,       --//结束游戏时亮牌 8199

    MSGID_GAME_PREPARE_NOTIFY                   = 0x2021,       --//游戏准备通知 8225
    MSGID_GAME_START_NOTIFY                     = 0x2022,       --//游戏开始通知 8226
    MSGID_GAME_OVER_NOTIFY                      = 0x2023,       --//游戏结束通知 8227
    MSGID_USER_STATUS_NOTIFY                    = 0x2024,       --//用户状态改变通知 8228
    MSGID_SIT_DOWN_NOTIFY                       = 0x2025,       --//坐下通知 8229
    MSGID_READY_NOTIFY                          = 0x2026,       --//准备通知 8230
    MSGID_ANTE_UP_NOTIFY                        = 0x2027,       --//押注通知（含孤注一掷通知）8231
    MSGID_LAST_BET_NOTIFY                       = 0x2028,       --//孤注一掷通知 8232
    MSGID_SHOW_CARD_NOTIFY                      = 0x2029,       --//看牌 8233
    MSGID_COMPARE_CARD_NOTIFY                   = 0x202A,       --//比牌 8234
    MSGID_GIVE_UP_NOTIFY                        = 0x202B,       --//弃牌 8235
    MSGID_ZJH_GAME_OVER_SHOW_NOTIFY             = 0x202C,       --//结束游戏时亮牌通知 8236       
    
    -- niu -- 0x2200
    MSGID_NIU_ENTER_ROOM_REQ                    = 0x2201,       --牛牛--进入房间请求 8705
    MSGID_NIU_ENTER_ROOM_RESP                   = 0x2202,       --牛牛--进入房间回应 8706
    MSGID_NIU_LEAVE_ROOM_REQ                    = 0x2203,       --牛牛--离开房间请求 8707
    MSGID_NIU_LEAVE_ROOM_RESP                   = 0x2204,       --牛牛--离开房间回应 8708
    MSGID_NIU_CHANGE_TABLE_REQ                  = 0x2205,       --牛牛--换桌请求 8709
    MSGID_NIU_CHANGE_TABLE_RESP                 = 0x2206,       --牛牛--换桌回应 8710
    
    MSGID_NIU_READY_REQ                         = 0x2211,       --牛牛--准备请求 8721
    -- MSGID_NIU_CHANGE_XXX                     = 0x2212        --8722
    MSGID_NIU_BANKER_BID_REQ                    = 0x2213,       --牛牛--抢庄加倍 8723
    MSGID_NIU_COMPARE_BID_REQ                   = 0x2214,       --牛牛--比牌加倍 8724
    MSGID_NIU_COMPARE_CARD_REQ                  = 0x2215,       --牛牛--比牌 8725
    
    MSGID_NIU_GAME_PREPARE_NOTIFY               = 0x2231,       --牛牛通知--游戏准备 8753
    MSGID_NIU_GAME_START_NOTIFY                 = 0x2232,       --牛牛通知--游戏开始 8754
    MSGID_NIU_GAME_OVER_NOTIFY                  = 0x2233,       --牛牛通知--游戏结束 8755
    MSGID_NIU_GAME_CONFIRM_BANKER_NOTIFY        = 0x2234,       --牛牛通知--定庄 8756
    MSGID_NIU_GAME_COMPARE_BID_OVER_NOTIFY      = 0x2235,       --牛牛通知--比牌加倍结束 8757
     
    MSGID_NIU_READY_NOTIFY                      = 0x2241,       --牛牛通知--准备 8769
    MSGID_NIU_BANKER_BID_NOTIFY                 = 0x2242,       --牛牛通知--抢庄加倍 8770
    MSGID_NIU_COMPARE_BID_NOTIFY                = 0x2243,       --牛牛通知--比牌加倍 8771
    MSGID_NIU_COMPARE_CARD_NOTIFY               = 0x2244,       --牛牛通知--比牌 8772

    -- niu compete 4 + 1 -- = 0x2400
    MSGID_NIU_C41_READY_REQ                     = 0x2411,       --牛牛--准备请求 9233
    -- MSGID_NIU_C41_CHANGE_XXX                 = 0x2412        --9234
    MSGID_NIU_C41_BANKER_BID_REQ                = 0x2413,       --牛牛--抢庄加倍 9235
    MSGID_NIU_C41_COMPARE_BID_REQ               = 0x2414,       --牛牛--比牌加倍 9236
    MSGID_NIU_C41_COMPARE_CARD_REQ              = 0x2415,       --牛牛--比牌 9237
    MSGID_NIU_C41_GAME_PREPARE_NOTIFY           = 0x2431,       --牛牛通知--游戏准备 9265
    MSGID_NIU_C41_GAME_START_NOTIFY             = 0x2432,       --牛牛通知--游戏开始 9266
    MSGID_NIU_C41_GAME_OVER_NOTIFY              = 0x2433,       --牛牛通知--游戏结束 9267
    MSGID_NIU_C41_GAME_CONFIRM_BANKER_NOTIFY    = 0x2434,       --牛牛通知--定庄 9268
    MSGID_NIU_C41_GAME_COMPARE_BID_OVER_NOTIFY  = 0x2435,       --牛牛通知--比牌加倍结束 9269
    MSGID_NIU_C41_READY_NOTIFY                  = 0x2441,       --牛牛通知--准备 9281
    MSGID_NIU_C41_BANKER_BID_NOTIFY             = 0x2442,       --牛牛通知--抢庄加倍 9282
    MSGID_NIU_C41_COMPARE_BID_NOTIFY            = 0x2443,       --牛牛通知--比牌加倍 9283
    MSGID_NIU_C41_COMPARE_CARD_NOTIFY           = 0x2444,       --牛牛通知--比牌 9284
    
    -- dragon vs tiger -- 0x2600
    MSGID_DRAGON_VS_TIGER_READY_REQ             = 0x2611,      --龙虎斗--准备请求 9745
    MSGID_DRAGON_VS_TIGER_BET_REQ               = 0x2612,      --龙虎斗--抢庄押注 9746
    MSGID_DRAGON_VS_TIGER_GAME_PREPARE_NOTIFY   = 0x2631,      --龙虎斗通知--游戏准备 9777
    MSGID_DRAGON_VS_TIGER_GAME_START_NOTIFY     = 0x2632,      --龙虎斗通知--游戏开始 9778
    MSGID_DRAGON_VS_TIGER_GAME_OVER_NOTIFY      = 0x2633,      --龙虎斗通知--游戏结束 9779
    MSGID_DRAGON_VS_TIGER_GAME_HISTORY_NOTIFY   = 0x2644,      --龙虎斗通知--游戏历史数据 9796
    MSGID_DRAGON_VS_TIGER_TOP_SEAT_NOTIFY       = 0x2645,      --龙虎斗通知--游戏排名玩家数据 9797
    MSGID_DRAGON_VS_TIGER_READY_NOTIFY          = 0x2661,      --龙虎斗通知--准备 9825
    MSGID_DRAGON_VS_TIGER_BET_NOTIFY            = 0x2662,      --龙虎斗通知--押注 9826

    MSGID_CLOSE_CONNECTION		                = 0x03,		    --//
    MSGID_CREATE_HANDLER		                = 0x04,		    --//
    MSGID_CLOSE_HANDLER			                = 0x05,		    --//
}

return {
    ErrorCode    = ErrorCode,
    ErrorMessage = ErrorMessage,
    MsgId        = MsgId,
    TableStatus  = TableStatus
}
