
--[[
@brief  验证登录管理类
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local VerifyLoginPresenter   = class("VerifyLoginPresenter", app.base.BasePresenter)

-- UI
VerifyLoginPresenter._ui  = requireLobby("app.lobby.login.VerifyLoginLayer")

function VerifyLoginPresenter:dealAccountLogin(account, verify)
    
    print("account",account)
    print("verify",verify)
end

function VerifyLoginPresenter:getVerify()
  
    
end

return VerifyLoginPresenter