
--[[
@brief  µ«¬ºπ‹¿Ì¿‡
]]

local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = require("app.lobby.login.LoginLayer")

function LoginPresenter:init(bChangeAccount)
    
end

function LoginPresenter:dealGuestLogin()

    print("1111111111111")
    
end

function LoginPresenter:dealAccountLogin(userid, password)
    print("2222222222222222")
end

return LoginPresenter