
--[[
@brief  ÕËºÅµÇÂ¼layer
]]

local AccountLoginLayer = class("AccountLoginLayer", app.base.BaseLayer)

-- csbÂ·¾¶
AccountLoginLayer.csbPath = "csb/account.csb"

AccountLoginLayer.clicks = {
    "background",
}

AccountLoginLayer.touchs = {
    "btn_close",
    "btn_login",
    "btn_register",
    "btn_phone"
}

function AccountLoginLayer:onCreate()
    self:seekChildByName("tf_account"):setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    self:seekChildByName("tf_password"):setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
end

function AccountLoginLayer:initUI()
    self:seekChildByName("tf_account"):setText("")
    self:seekChildByName("tf_password"):setText("")
end

function AccountLoginLayer:onClick(sender)
    AccountLoginLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
        self:exit()
    end
end

function AccountLoginLayer:onTouch(sender, eventType)
    AccountLoginLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_login" then
            self:onTouchLogin()
        elseif name == "btn_register" then
            self:onTouchRegister()
        elseif name == "btn_phone" then
            self:onTouchPhone()
        end
    end
end

function AccountLoginLayer:onTouchLogin()
    local userid = self:seekChildByName("tf_account")
    local pwd = self:seekChildByName("tf_password")
    self._presenter:dealAccountLogin(userid:getText(), pwd:getText())
    self:exit()
end

function AccountLoginLayer:onTouchRegister()
    self._presenter:showRegister()
    self:exit()
end

function AccountLoginLayer:onTouchPhone()
    self._presenter:showRetrievePwd()
    self:exit()
end

return AccountLoginLayer