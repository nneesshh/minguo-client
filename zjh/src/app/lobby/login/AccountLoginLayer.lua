
--[[
@brief  账号登录layer
]]

local AccountLoginLayer = class("AccountLoginLayer", app.base.BaseLayer)

-- csb路径
AccountLoginLayer.csbPath = "lobby/csb/account.csb"

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
    local account = self:seekChildByName("tf_account")
    local password = self:seekChildByName("tf_password")
    account:setPlaceHolderColor(cc.c3b(255,255,255))
    password:setPlaceHolderColor(cc.c3b(255,255,255))
end

function AccountLoginLayer:initUI()
    self:seekChildByName("tf_account"):setText("")
    self:seekChildByName("tf_password"):setText("")
end

function AccountLoginLayer:onClick(sender)
    AccountLoginLayer.super.onClick(self, sender)
    local name = sender:getName()    
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

    self._presenter:dealAccountLogin(userid:getString(), pwd:getString())
end

function AccountLoginLayer:onTouchRegister()
    self._presenter:showRegister()
    self:exit()
end

function AccountLoginLayer:onTouchPhone()
    self._presenter:showPhone()
    self:exit()
end

function AccountLoginLayer:scrollHint(msg)
    local hint = self:seekChildByName("img_hint_back")
    local father = hint:getParent()
    local node = hint:clone()
    local text = node:getChildByName("text_hint")
    text:setText(msg)
    node:setPosition(cc.p(331, 240))
    node:setVisible(true)
    father:addChild(node)
    node:runAction(cc.Sequence:create(
        cc.FadeIn:create(0.5),                       
        cc.FadeOut:create(0.5),
        cc.CallFunc:create(function()
            node:removeFromParent(true)
        end)
    ))
end

return AccountLoginLayer