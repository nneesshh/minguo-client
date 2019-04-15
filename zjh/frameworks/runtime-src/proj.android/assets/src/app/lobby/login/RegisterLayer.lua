
--[[
@brief  注册layer
]]

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
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_verify" then
            self:onTouchGetVerify()
        elseif name == "btn_sure" then
            self:onTouchRegister()
        end
    end
end

function RegisterLayer:onTouchGetVerify()
    self._presenter:getVerify()
    self:exit()
end

function RegisterLayer:onTouchRegister()
    local userid = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_verify")
    local pwd = self:seekChildByName("tf_new_password")

    self._presenter:dealAccountRegister(userid:getString(), verify:getString(), pwd:getString())
end

function RegisterLayer:scrollHint(msg)
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

return RegisterLayer