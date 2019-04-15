
--[[
@brief  登录管理类
]]

local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = require("app.lobby.login.LoginLayer")

local AccountData = app.data.AccountData

function LoginPresenter:init()
    self:createDispatcher()
    self:dealAutoLogin()
end

function LoginPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_SUCCESS, handler(self, self.onLoginSuccess))    
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_FAIL, handler(self, self.onLoginFail))       
end

function LoginPresenter:onLoginSuccess()
    self:dealLoadingHintExit()
    self._ui:getInstance():exit()    
    app.lobby.login.LoginPresenter:getInstance():exit()  
end


function LoginPresenter:onLoginFail()
    self:dealLoadingHintExit()
     self:dealHintStart("登录失败")
end

function LoginPresenter:testLogin(data)
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        po:writer_reset()

        po:write_int32(data[1])        -- userTicketId
        po:write_string(data[2])       -- phoneNumber as userName
        po:write_string(data[3])       -- pwd
        po:write_string(data[4])       -- imei
        po:write_string(data[5])       -- imsi
        po:write_string(data[6])       -- channel
        po:write_string(data[7])       -- subChannel

        local sessionId = self.sessionId or 222
        upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_LOGIN_REQ)
    end              
end

-- 自动登录
function LoginPresenter:dealAutoLogin()    
    local have, username, password = AccountData.haveAccount()
    if have then
        print("auto login",username, password)
        app.lobby.login.AccountLoginPresenter:getInstance():start()
        self:sendLogin(username, password)  -- 账号登录
    end
end

-- 游客登录
function LoginPresenter:dealGuestLogin()
    local have, username, password = AccountData.haveAccount()
    if have then
        self:sendLogin(username, password)  -- 账号登录
    else        
        self:sendLogin("", "mg123456")      -- 游客登录
    end
end

--账号登录
function LoginPresenter:dealAccountLogin()
    app.lobby.login.AccountLoginPresenter:getInstance():start()
end

function LoginPresenter:sendLogin(username, password)        
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        self:dealLoadingHintStart("正在登录中") 
        
        po:writer_reset()
        po:write_int32(0)                   
        po:write_string(username)           
        po:write_string(password)             
        po:write_string(AccountData.IMEI()) 
        po:write_string(AccountData.IMSI()) 

        po:write_string("")                 
        po:write_string("")

        local sessionId = self.sessionId or 222
        print("send login",username, password)
        upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_LOGIN_REQ)            
    end     
end

return LoginPresenter