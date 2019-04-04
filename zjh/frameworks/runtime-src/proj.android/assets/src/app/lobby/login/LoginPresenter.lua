
--[[
@brief  登录管理类
]]

local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = require("app.lobby.login.LoginLayer")

function LoginPresenter:dealGuestLogin()    
    
end

function LoginPresenter:init()
    self:createDispatcher()
end

function LoginPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_SUCCESS, handler(self, self.onLoginSuccess))    
end

function LoginPresenter:onLoginSuccess()
    if not self:isCurrentUI() then
        return
    end
    self._ui:getInstance():exit()    
    app.lobby.login.LoginPresenter:getInstance():exit()  
end

function LoginPresenter:dealAccountLogin()
    app.lobby.login.LoginPresenter:getInstance():start()
end

return LoginPresenter