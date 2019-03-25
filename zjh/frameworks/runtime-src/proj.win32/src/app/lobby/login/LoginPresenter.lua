
--[[
@brief  µ«¬ºπ‹¿Ì¿‡
]]

local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = require("app.lobby.login.LoginLayer")

function LoginPresenter:dealGuestLogin()

end

function LoginPresenter:dealAccountLogin()
    
end

return LoginPresenter