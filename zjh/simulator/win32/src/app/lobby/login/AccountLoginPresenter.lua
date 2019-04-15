
--[[
@brief  账号管理类
]]

local AccountLoginPresenter   = class("AccountLoginPresenter", app.base.BasePresenter)

-- UI
AccountLoginPresenter._ui  = require("app.lobby.login.AccountLoginLayer")

local AccountData = app.data.AccountData

local function checkPhoneNum(sphoneNum)
    return string.match(sphoneNum,"[1][3,4,5,7,8]%d%d%d%d%d%d%d%d%d") == sphoneNum
end

local function checkPwdLength(pwd)
    local shortestLength = 6
    local longestLength = 16
    if(#pwd < shortestLength or #pwd > longestLength) then
        return false
    else
        return true
    end               
end

local function checkPwd(pwd)
    return app.util.VaildUtils.isAlNum(pwd)
end

function AccountLoginPresenter:init()
    self:createDispatcher()
end

function AccountLoginPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_SUCCESS, handler(self, self.onLoginSuccess))    
end

function AccountLoginPresenter:onLoginSuccess()
    if not self:isCurrentUI() then
        return
    end
    self._ui:getInstance():exit()    
    app.lobby.login.LoginPresenter:getInstance():exit()  
end

function AccountLoginPresenter:dealAccountLogin(account, password)    
    local hint = ""
    if account == "" then
        hint = "请输入手机账号！" 
    elseif account ~= "" and password == "" then
        hint = "请输入登陆密码！"
    elseif not checkPwdLength(password) then
        hint = "密码长度应为6-16位！"
--    elseif not checkPhoneNum(account) then  
--        hint = "手机号格式不正确！" 
--    elseif checkPwd(password) then
--        hint = "密码格式不正确！"            
    end

    if hint ~= "" then        
        self._ui:getInstance():scrollHint(hint)
        return
    else             
        local po = upconn.upconn:get_packet_obj()
        if po == nil then
            self._ui:getInstance():scrollHint("网络连接失败，请检查网络信号！")
        else
            po:writer_reset()
            po:write_int32(0)                      -- userTicketId
            po:write_string(tostring(account))     -- phoneNumber as userName
            po:write_string(password)              -- pwd
            po:write_string(AccountData.IMEI())      -- imei
            po:write_string(AccountData.IMSI())      -- imsi
            po:write_string("")                    -- channel
            po:write_string("")                    -- subChannel
        
            local sessionId = self.sessionId or 222
            upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_LOGIN_REQ)
        end              
    end
end

function AccountLoginPresenter:showRegister()
    app.lobby.login.RegisterPresenter:getInstance():start()
end

function AccountLoginPresenter:showPhone()
    app.lobby.login.VerifyLoginPresenter:getInstance():start()
end

return AccountLoginPresenter