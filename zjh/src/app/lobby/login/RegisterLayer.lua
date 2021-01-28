
--[[
@brief  注册layer
]]
local app = cc.exports.gEnv.app
local RegisterLayer = class("RegisterLayer", app.base.BaseLayer)

-- csb路径
RegisterLayer.csbPath = "lobby/csb/register.csb"

RegisterLayer.clicks = {
    "background",
}

RegisterLayer.touchs = {
    "btn_close",
    "btn_verify",
    "btn_sure"
}

function RegisterLayer:onCreate()
    local account = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_verify")
    local password = self:seekChildByName("tf_new_password")
    
    account:setPlaceHolderColor(cc.c3b(255,255,255))
    verify:setPlaceHolderColor(cc.c3b(255,255,255))
    password:setPlaceHolderColor(cc.c3b(255,255,255))
    
    account:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    verify:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    password:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    
    account:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    verify:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    password:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
end

function RegisterLayer:initUI()
    self:seekChildByName("tf_account"):setText("")
    self:seekChildByName("tf_verify"):setText("")
    self:seekChildByName("tf_new_password"):setText("")
end

function RegisterLayer:onClick(sender)
    RegisterLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
        -- self:exit()
    end
end

function RegisterLayer:onTouch(sender, eventType)
    RegisterLayer.super.onTouch(self, sender, eventType)
    
    --
    if eventType == ccui.TouchEventType.ended then
        local name = sender:getName()
        if name == "btn_close" then
            self:exit()
            app.lobby.login.AccountLoginPresenter:getInstance():start()
        elseif name == "btn_verify" then
            self:onTouchGetVerify()
        elseif name == "btn_sure" then
            self:onTouchRegister()
        end
    end
end

function RegisterLayer:onTouchGetVerify()
    self._presenter:getVerify()
end

function RegisterLayer:onTouchRegister()
    local username = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_verify")
    local password = self:seekChildByName("tf_new_password")

    self._presenter:onRegisterAccount(username:getString(), verify:getString(), password:getString())
end

return RegisterLayer