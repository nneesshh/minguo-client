
--[[
@brief  用户中心管理类
]]--

local UserCenterPresenter = class("UserCenterPresenter", app.base.BasePresenter)
-- UI
UserCenterPresenter._ui         = require("app.lobby.usercenter.UserCenterLayer")

function UserCenterPresenter:init()
    self:createDispatcher()

    self:initUIUserInfo()
end

----------------------------- 监听者 ------------------------------
function UserCenterPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_USERNAME, handler(self, self.onUsernameUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_NICKNAME, handler(self, self.onNicknameUpdate))    
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_TICKETID, handler(self, self.onIDUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_AVATAR, handler(self, self.onAvatarUpdate))
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
end

function UserCenterPresenter:initUIUserInfo()
    self:onUsernameUpdate()
    self:onNicknameUpdate()
    self:onIDUpdate()
    self:onAvatarUpdate()
    self:onBalanceUpdate()
end

function UserCenterPresenter:onUsernameUpdate()
    if not self:isCurrentUI() then
        return
    end

    local name = app.data.UserData.getUsername()
    self._ui:getInstance():setUsername(name)
end

function UserCenterPresenter:onIDUpdate()
    if not self:isCurrentUI() then
        return
    end

    local id = app.data.UserData.getTicketID()
    self._ui:getInstance():setID(id)
end

function UserCenterPresenter:onNicknameUpdate()
    if not self:isCurrentUI() then
        return
    end

    local nickname = app.data.UserData.getNickname()
    self._ui:getInstance():setNickname(nickname)
end

function UserCenterPresenter:onAvatarUpdate()
    if not self:isCurrentUI() then
        return
    end

    local avator = app.data.UserData.getAvatar()
    local gender = app.data.UserData.getGender()
    self._ui:getInstance():setAvatar(avator, gender)    
end

function UserCenterPresenter:onBalanceUpdate()
    if not self:isCurrentUI() then
        return
    end

    local balance = app.data.UserData.getBalance()
    self._ui:getInstance():setBalance(balance)
end

return UserCenterPresenter