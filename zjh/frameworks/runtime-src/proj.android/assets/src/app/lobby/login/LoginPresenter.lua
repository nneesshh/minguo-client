
--[[
@brief  登录管理类
]]

local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = require("app.lobby.login.LoginLayer")
local ToolUtils = app.util.ToolUtils

function LoginPresenter:init()
    self:createDispatcher()
end

function LoginPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_SUCCESS, handler(self, self.onLoginSuccess))    
end

function LoginPresenter:onLoginSuccess()
    if not self:isCurrentUI() then
        return
    end
    self._ui:getInstance():exit()    
    app.lobby.login.LoginPresenter:getInstance():exit()  
end

function LoginPresenter:dealGuestLogin()    
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        po:writer_reset()
        po:write_int32(0)                   -- userTicketId
        po:write_string("")                 -- userName
        po:write_string("mg123456")         -- pwd  
        po:write_string(ToolUtils.IMEI())   -- imei  uuid
        po:write_string(ToolUtils.IMSI())   -- imsi  uuid

        po:write_string("")                 -- channel
        po:write_string("")                 -- subChannel

        local sessionId = self.sessionId or 222
        upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_LOGIN_REQ)        
    end     
end

function LoginPresenter:dealAccountLogin()
    app.lobby.login.AccountLoginPresenter:getInstance():start()
end

return LoginPresenter