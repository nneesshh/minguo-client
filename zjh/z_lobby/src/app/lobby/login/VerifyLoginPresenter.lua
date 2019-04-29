
--[[
@brief  验证登录管理类
]]


local VerifyLoginPresenter   = class("VerifyLoginPresenter", app.base.BasePresenter)

-- UI
VerifyLoginPresenter._ui  = require("app.lobby.login.VerifyLoginLayer")

function VerifyLoginPresenter:dealAccountLogin(account, verify)
    
    print("account",account)
    print("verify",verify)
end

function VerifyLoginPresenter:getVerify()
  
    
end

return VerifyLoginPresenter