local ErrorCode = {
    ERR_SUCCESS                 = 0x00, --
    ERR_UNKNOWN                 = 0x01, --
    ERR_USERNAME_INVALID        = 0x02, --
    ERR_USER_NOT_FOUND          = 0x03, --
    ERR_WRONG_PASSWORD          = 0x04, --
    ERR_ACCOUNT_RESTRICTION     = 0x05, --
    ERR_OUT_OF_LIMIT            = 0x06, --
    ERR_NO_FREE_TABLE           = 0x07,  --
    ERR_ROOM_OR_TABLE_INVALID   = 0x08, 
    ERR_LEAVE_LOCK              = 0x09, 
    ERR_RELOGIN                 = 0x0A,
}

local MsgId = {
    --// lobby
    MSGID_HEART_BEAT_REQ		= 0x1001,		--//心跳 4097
    MSGID_HEART_BEAT_RESP		= 0x1002,		--//心跳 4098
    MSGID_LOGIN_REQ				= 0x1003,		--//登录请求 4099
    MSGID_LOGIN_RESP			= 0x1004,		--//登录回应 4100
    MSGID_REGISTER_REQ			= 0x1005,		--//登录请求 4101
    MSGID_REGISTER_RESP			= 0x1006,		--//登录回应 4102
        
    MSGID_CHANGE_USER_INFO_REQ  = 0x1101,       --//修改用户信息请求 4353 
    MSGID_CHANGE_USER_INFO_RESP = 0x1102,       --//修改用户信息回应 4354 

    --// room
    MSGID_ENTER_ROOM_REQ		= 0x1007,		--//进入房间请求 4103
    MSGID_ENTER_ROOM_RESP		= 0x1008,		--//进入房间回应 4104
    MSGID_LEAVE_ROOM_REQ		= 0x1009,		--//离开房间请求 4105
    MSGID_LEAVE_ROOM_RESP		= 0x100A,		--//离开房间回应 4106
    MSGID_CHANGE_TABLE_REQ		= 0x100B,		--//换桌请求 4107
    MSGID_CHANGE_TABLE_RESP		= 0x100C,		--//换桌回应 4108
    
    MSGID_RELOGIN_NOTIFY_NEW    = 0x888,         --//其他用户登录通知 2184 
    MSGID_PLAYER_STATUS_NOTIFY_NEW = 0x889,      --//玩家状态改变通知 2185 
    MSGID_SIT_DOWN_NOTIFY_NEW   = 0x88A,         --//坐下通知 2186
    
    --// game
    MSGID_READY_REQ				= 0x2001,		--//准备请求 8193
    MSGID_CHANGE_TABLE			= 0x2002,		--//换桌 8194
    MSGID_ANTE_UP_REQ			= 0x2003,		--//押注 8195
    MSGID_SHOW_CARD_REQ			= 0x2004,		--//看牌 8196
    MSGID_COMPARE_CARD_REQ		= 0x2005,		--//比牌 8197
    MSGID_GIVE_UP_REQ			= 0x2006,		--//弃牌 8198

    MSGID_GAME_PREPARE_NOTIFY   = 0x2021,       --//游戏准备通知 8225
    MSGID_GAME_START_NOTIFY     = 0x2022,       --//游戏开始通知 8226
    MSGID_GAME_OVER_NOTIFY      = 0x2023,       --//游戏结束通知 8227
    MSGID_USER_STATUS_NOTIFY    = 0x2024,       --//用户状态改变通知 8228
    MSGID_SIT_DOWN_NOTIFY       = 0x2025,       --//坐下通知 8229
    MSGID_READY_NOTIFY          = 0x2026,       --//准备通知 8230
    MSGID_ANTE_UP_NOTIFY        = 0x2027,       --//押注通知（含孤注一掷通知）8231
    MSGID_LAST_BET_NOTIFY       = 0x2028,       --//孤注一掷通知 8232
    MSGID_SHOW_CARD_NOTIFY      = 0x2029,       --//看牌 8233
    MSGID_COMPARE_CARD_NOTIFY   = 0x202A,       --//比牌 8234
    MSGID_GIVE_UP_NOTIFY        = 0x202B,       --//弃牌 8235
    MSGID_RELOGIN_NOTIFY        = 0x202C,       --//其他用户登录 8236

    MSGID_CLOSE_CONNECTION		= 0x03,		--//
    MSGID_CREATE_HANDLER		= 0x04,		--//
    MSGID_CLOSE_HANDLER			= 0x05,		--//
}

return {
    ErrorCode = ErrorCode,
    MsgId = MsgId
}
