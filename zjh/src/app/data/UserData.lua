--[[
@brief 玩家自己的数据
]]  

local UserData = {}

local _state = {
    nologin = -2,  -- 没尝试登入过
    fail    = -1,  -- 登入失败
    success = 1    -- 登入成功
}

local _selfData = {
    ticketid    = 0,
    username    = "",             -- 帐号
    nickname    = "",             -- 昵称
    avatar      = "avatar",       -- 头像
    gender      = 0,              -- 性别
    balance     = 0,              -- 财富
    session     = "0",            -- 用户session  
    state       = _state.nologin, -- 登录状态
    safebalance = 0               -- 保险箱 
}

function UserData.setUserData(tPlayerData)
    UserData.setTicketID(tPlayerData.ticketid)
    UserData.setUsername(tPlayerData.username)
    UserData.setNickname(tPlayerData.nickname)
    UserData.setAvatar(tPlayerData.avatar)
    UserData.setGender(tPlayerData.gender)
    UserData.setBalance(tPlayerData.balance)   
    UserData.setSession(tPlayerData.session)
    UserData.setSafeBalance(tPlayerData.safebalance)   
end

function UserData.getUserData()
    return _selfData
end

function UserData.setTicketID(ticketid)
    _selfData.ticketid = ticketid
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_TICKETID) 
end

function UserData.getTicketID()
    return _selfData.ticketid
end

function UserData.setUsername(username)
    _selfData.username = username
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_USERNAME)    
end

function UserData.getUsername()
    if _selfData.username == "" then
        return "无"
    end
    return _selfData.username
end

function UserData.setNickname(nickname)
    _selfData.nickname = nickname
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_NICKNAME)
end

function UserData.getNickname()
    if _selfData.nickname == "" then
        if _selfData.username ~= "" then
            return "用户" .. _selfData.ticketid
        else
            return "用户" .. _selfData.ticketid
        end       
    end
    return _selfData.nickname
end

function UserData.setAvatar(avatar)
    local avatar = tonumber(avatar)
    if avatar == nil or avatar < 0 or avatar > 5 then
    	return
    end   
    _selfData.avatar = avatar
    
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_AVATAR)
end

function UserData.getAvatar()
    local avatar = tonumber(_selfData.avatar)    
    if avatar == nil or avatar < 0 or avatar > 5 then
    	return 0
    end
    return avatar
end

-- 0:女 1:男 
function UserData.setGender(gender)
    _selfData.gender = gender
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_AVATAR)    
end

function UserData.getGender()
    local gender = tonumber(_selfData.gender)    
    if gender == nil or gender < 0 or gender > 1 then
        return 0
    end
   
    return gender
end

function UserData.setBalance(balance)
    _selfData.balance = balance
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_BALANCE)
end

function UserData.getBalance()
    return _selfData.balance or 0
end

function UserData.setSession(session)
    _selfData.session = session
end

function UserData.getSession()
    return _selfData.session
end

function UserData.setLoginState(state)
    _selfData.state = state
end

function UserData.getLoginState()
    return _selfData.state or _state.nologin
end

function UserData.setSafeBalance(num)
    _selfData.safebalance = num
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_BANK) 
end

function UserData.getSafeBalance()
    return _selfData.safebalance
end

return UserData