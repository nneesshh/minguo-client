
--[[
@brief  �˺ŵ�¼������
]]

local AccountData = app.data.AccountData
local LoginCenterLogic = app.logic.login.LoginCenterLogic

local AccountLoginPresenter   = class("AccountLoginPresenter", app.base.BasePresenter)

-- UI
AccountLoginPresenter._ui  = require("app.lobby.login.AccountLoginLayer")

function AccountLoginPresenter:dealAccountLogin(userid, password, type)
    if userid == "" or password == "" then
        self:dealHintStart("��¼ʧ��,�˺Ż����벻��Ϊ��")
        return
    end
    self:dealLoadingHintStart("���ڵ�¼��")
    LoginCenterLogic:getInstance():start(handler(self, self.onCallback), type, userid, password)
end

function AccountLoginPresenter:onCallback(bFlag, errMsg)
    self:dealLoadingHintExit()
    if bFlag then
        -- ��¼�ɹ�
        app.lobby.login.LoginPresenter:getInstance():exit()
    else
        -- ��¼ʧ��
        self:dealHintStart(errMsg)
        -- ���ݲɼ�
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