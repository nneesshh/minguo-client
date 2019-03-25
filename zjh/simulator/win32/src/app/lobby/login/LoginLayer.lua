
--[[
@brief  登录layer
]]

local LoginLayer = class("LoginLayer", app.base.BaseLayer)

-- csb路径
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

---------------------------- 点击事件 --------------------------------
function LoginLayer:onClickBtnGuest()
    self._presenter:dealGuestLogin()
end

function LoginLayer:onClickBtnAccount()
    self._presenter:dealAccountLogin()
end

return LoginLayer