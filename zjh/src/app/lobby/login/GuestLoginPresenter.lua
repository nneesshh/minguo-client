
--[[
@brief  账号登录管理类
]]

local AccountData = app.data.AccountData
local LoginCenterLogic = app.logic.login.LoginCenterLogic

local AccountLoginPresenter   = class("AccountLoginPresenter", app.base.BasePresenter)

-- UI
AccountLoginPresenter._ui  = require("app.lobby.login.AccountLoginLayer")

function AccountLoginPresenter:dealAccountLogin(userid, password, type)
    if userid == "" or password == "" then
        self:dealHintStart("登录失败,账号或密码不能为空")
        return
    end
    self:dealLoadingHintStart("正在登录中")
    LoginCenterLogic:getInstance():start(handler(self, self.onCallback), type, userid, password)
end

function AccountLoginPresenter:onCallback(bFlag, errMsg)
    self:dealLoadingHintExit()
    if bFlag then
        -- 登录成功
        app.lobby.login.LoginPresenter:getInstance():exit()
    else
        -- 登录失败
        self:dealHintStart(errMsg)
        -- 数据采集
        -- app.util.DataCollectUtils.exceptionEventCollect(105)
    end
end

function AccountLoginPresenter:showRetrievePwd()
    app.lobby.login.RetrievePwdPresenter:getInstance():start()
end

function AccountLoginPresenter:setAgreement(flag)
    AccountData.setAgreement(bFlag)
end

function AccountLoginPresenter:getAgreement()
    return AccountData.getAgreement()
end

return AccountLoginPresenter