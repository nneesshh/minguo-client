--[[
@brief  事件统一枚举
]]

local Event = {}

Event = {
    EVENT_LOGIN_SUCCESS = "EVENT_LOGIN_SUCCESS", -- 登录成功
    EVENT_LOGIN_FAIL    = "EVENT_LOGIN_FAIL",    -- 登录失败
    EVENT_USERNAME      = "EVENT_USERNAME",      -- 用户名更新
    EVENT_TICKETID      = "EVENT_TICKETID",      -- ID更新   
    EVENT_NICKNAME      = "EVENT_NICKNAME",      -- 昵称更新
    EVENT_AVATAR        = "EVENT_AVATAR",        -- 头像更新
    EVENT_BALANCE       = "EVENT_BALANCE",       -- 财富更新   
    EVENT_GENDER        = "EVENT_GENDER",        -- 性别更新
}

return Event