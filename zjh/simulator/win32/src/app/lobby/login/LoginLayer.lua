
--[[
@brief  登录界面
]]

local LoginLayer = class("LoginLayer", app.base.BaseLayer)

-- csbPath
LoginLayer.csbPath = "csb/login.csb"

LoginLayer.touchs = {
    "btn_tourist",
    "btn_account",
}

function LoginLayer:onTouch(sender, eventType)
    LoginLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_tourist" then
            self:onClickBtnGuest()
        elseif name == "btn_account" then
            self:onClickBtnAccount()
        end
    end
end

function LoginLayer:initUI()
end

function LoginLayer:onClickBtnGuest()
    self._presenter:dealGuestLogin()
end

function LoginLayer:onClickBtnAccount()
    self._presenter:dealAccountLogin()
end

return LoginLayer