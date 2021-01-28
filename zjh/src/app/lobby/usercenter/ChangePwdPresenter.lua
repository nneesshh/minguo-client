--[[
@brief  修改密码
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local ChangePwdPresenter = class("ChangePwdPresenter", app.base.BasePresenter)

-- UI
ChangePwdPresenter._ui         = requireLobby("app.lobby.usercenter.ChangePwdLayer")

function ChangePwdPresenter:getVerify()

end

function ChangePwdPresenter:reqChangePwd(username, verify, password)  
    print("change pwd", username, verify, password)
end

return ChangePwdPresenter