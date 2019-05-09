--[[
@brief 修改密码界面

]]
local ChangePwdLayer   = class("ChangePwdLayer", app.base.BaseLayer)

ChangePwdLayer.csbPath = "lobby/csb/password.csb"

ChangePwdLayer.touchs = {
    "btn_close",
    "btn_sure",
    "btn_vertify"
}

function ChangePwdLayer:onTouch(sender, eventType)
    ChangePwdLayer.super.onTouch(self, sender, eventType)
    if eventType == ccui.TouchEventType.ended then
        local name = sender:getName()
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_sure" then
            self:onTouchBtnOK()
        elseif name == "btn_vertify" then 
            self:onTouchGetVerify()
        end
    end
end

function ChangePwdLayer:onCreate()
    local account = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_vertify")
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

function ChangePwdLayer:initUI()
    self:seekChildByName("tf_account"):setText("")
    self:seekChildByName("tf_vertify"):setText("")
    self:seekChildByName("tf_new_password"):setText("")
end

function ChangePwdLayer:onTouchBtnOK()
    local userid = self:seekChildByName("tf_account")
    local verify = self:seekChildByName("tf_vertify")
    local pwd = self:seekChildByName("tf_new_password")

    self._presenter:reqChangePwd(userid:getString(), verify:getString(), pwd:getString())
end

function ChangePwdLayer:onTouchGetVerify()
    self._presenter:getVerify()
end

return ChangePwdLayer
