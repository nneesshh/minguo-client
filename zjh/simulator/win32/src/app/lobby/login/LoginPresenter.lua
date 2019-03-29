
--[[
@brief  登录管理类
]]

local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = require("app.lobby.login.LoginLayer")

function LoginPresenter:dealGuestLogin()    
    app.lobby.login.LoginPresenter:getInstance():exit()
end

function LoginPresenter:dealAccountLogin()
    app.lobby.login.AccountLoginPresenter:getInstance():start()
end

return LoginPresenter