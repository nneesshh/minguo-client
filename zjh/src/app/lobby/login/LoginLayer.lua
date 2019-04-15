
--[[
@brief  登录界面
]]

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
}

local logindata = {
    [0] = {0,"12345678901","a123123","imei00007","imsi00007","",""},
    [1] = {0,"12345678902","a123123","imei00002","imsi00002","",""},
    [2] = {0,"12345678903","a123123","imei00003","imsi00003","",""},
    [3] = {0,"12345678904","a123123","imei00004","imsi00004","",""},
    [4] = {0,"12345678905","a123123","imei00005","imsi00005","",""},
    [5] = {0,"12345678906","a123123","imei00006","imsi00006","",""}
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
            self._presenter:testLogin(logindata[index])   
        end
    end
end

function LoginLayer:initUI()
    local txtip = self:seekChildByName("txt_ip")
    local txtport = self:seekChildByName("txt_port")
    
    txtip:setString("ip:" .. cfg_game_zjh.servers[1].host)
    txtport:setString("port:" .. cfg_game_zjh.servers[1].port)
end

function LoginLayer:onClickBtnGuest()
    self._presenter:dealGuestLogin()
end

function LoginLayer:onClickBtnAccount()
    self._presenter:dealAccountLogin()
end

return LoginLayer