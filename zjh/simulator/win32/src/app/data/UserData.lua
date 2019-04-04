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
    ticketid = 0,
    username = "0",             -- 帐号
    nickname = "0",             -- 昵称
    avatar   = "0",             -- 头像
    gender   = 1,               -- 性别
    balance  = 100,             -- 标签
    session  = "0",             -- 用户session  
    state    = _state.nologin   -- 登录状态
}

function UserData.setUserData(tPlayerData)
    UserData.setTicketID(tPlayerData.ticketid)
    UserData.setUsername(tPlayerData.username)
    UserData.setNickname(tPlayerData.nickname)
    UserData.setAvatar(tPlayerData.avatar)
    UserData.setGender(tPlayerData.gender)
    UserData.setBalance(tPlayerData.balance)   
    UserData.setSession(tPlayerData.session)
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
    return _selfData.username
end

function UserData.setNickname(nickname)
    _selfData.nickname = nickname
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_NICKNAME)
end

function UserData.getNickname()
    return _selfData.nickname
end

function UserData.setAvatar(avatar)
    _selfData.avatar = avatar
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_AVATAR)
end

function UserData.getAvatar()
    return _selfData.avatar or 1
end

function UserData.setGender(gender)
    _selfData.gender = gender
end

function UserData.getGender()
    return _selfData.gender or 1
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

return UserData