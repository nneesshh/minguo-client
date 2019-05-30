
--[[
@brief  登录界面
]]

local ok, TestAccount = pcall(function() return require("test.Account") end)
if not ok then TestAccount = require("test.account_template") end

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
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_tourist" then            
            self:onClickBtnGuest()            
        elseif name == "btn_account" then
            self:onClickBtnAccount()           
        elseif string.find(name, "btn_test_") then 
            local index = tonumber(string.split(name, "btn_test_")[2])                          
            self._presenter:testLogin(TestAccount.list[index+1])   
        end
    end
end

function LoginLayer:initUI()
    local debug = self:seekChildByName("debug")
    if debug then
        debug:setVisible(CC_SHOW_LOGIN_DEBUG)
    end  
    self:initTestLoginBtnUI()
end

function LoginLayer:onClickBtnGuest()
    self._presenter:dealGuestLogin()
end

function LoginLayer:onClickBtnAccount()
    self._presenter:dealAccountLogin()
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