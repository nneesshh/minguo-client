
--[[
@brief  注册管理类
]]


local RegisterPresenter   = class("RegisterPresenter", app.base.BasePresenter)

-- UI
RegisterPresenter._ui  = require("app.lobby.login.RegisterLayer")

function RegisterPresenter:getVerify()


end

function RegisterPresenter:dealAccountRegister(userid, verify, password)
    if userid == "" or password == "" then
        
        return
    end
    print("userid",userid)
    print("verify",verify)
    print("password",password)
end

return RegisterPresenter