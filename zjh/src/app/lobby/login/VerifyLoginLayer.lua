
--[[
@brief  验证码登录layer
]]
local app = cc.exports.gEnv.app
local VerifyLoginLayer = class("VerifyLoginLayer", app.base.BaseLayer)

-- csb路径
VerifyLoginLayer.csbPath = "lobby/csb/verifylogin.csb"

VerifyLoginLayer.clicks = {
    "background",
}

VerifyLoginLayer.touchs = {
    "btn_close",
    "btn_verify",
    "btn_login"
}

function VerifyLoginLayer:onCreate()
    local account = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_verify")
    account:setPlaceHolderColor(cc.c3b(255,255,255))
    verify:setPlaceHolderColor(cc.c3b(255,255,255))
    
    account:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    verify:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    account:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    verify:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
end

function VerifyLoginLayer:initUI()
    self:seekChildByName("tf_account"):setText("")
    self:seekChildByName("tf_verify"):setText("")
end

function VerifyLoginLayer:onClick(sender)
    VerifyLoginLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
        -- self:exit()
    end
end

function VerifyLoginLayer:onTouch(sender, eventType)
    VerifyLoginLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
            app.lobby.login.AccountLoginPresenter:getInstance():start()
        elseif name == "btn_verify" then
            self:onTouchGetVerify()
        elseif name == "btn_login" then
            self:onTouchLogin()
        end
    end
end

function VerifyLoginLayer:onTouchGetVerify()
    self._presenter:getVerify()
end

function VerifyLoginLayer:onTouchLogin()
    local account = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_verify")

    self._presenter:dealAccountLogin(account:getString(), verify:getString())
end

return VerifyLoginLayer