
--[[
@brief  登录界面
]]

local TestAccount = require("test.TestAccount")
local LoginLayer = class("LoginLayer", app.base.BaseLayer)

-- csbPath
LoginLayer.csbPath = "lobby/csb/login.csb"

LoginLayer.touchs = {
    "btn_tourist",
    "btn_account",
    "btn_test_0",
    "btn_test_1",
    "btn_test_2",
    "btn_test_3",
    "btn_test_4",
    "btn_test_5",
    "btn_test_6",
    "btn_test_7",
}

function LoginLayer:onTouch(sender, eventType)
    LoginLayer.super.onTouch(self, sender, eventType)

    --
    if eventType == ccui.TouchEventType.ended then
        self._presenter:onLogin(sender)
    end
end

function LoginLayer:initUI()
    local debug = self:seekChildByName("debug")
    if debug then
        debug:setVisible(CC_SHOW_LOGIN_DEBUG)
    end  
    self:initTestLoginBtnUI()
end

function LoginLayer:initTestLoginBtnUI()
    local logindata = TestAccount.list
    local debug = self:seekChildByName("debug")
    for key, var in ipairs(debug:getChildren()) do
        if logindata and logindata[key] then
            var:setTitleText(logindata[key][2])
        end
    end
end

return LoginLayer