
--[[
@brief  注册管理类
]]

local RegisterPresenter   = class("RegisterPresenter", app.base.BasePresenter)

-- UI
RegisterPresenter._ui  = require("app.lobby.login.RegisterLayer")

local AccountData = app.data.AccountData
local _username, _password = "", ""

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

function RegisterPresenter:init()
    _username, _password = "", ""  
end

function RegisterPresenter:getVerify()
    
end

function RegisterPresenter:dealAccountRegister(username, verify, password)  
    local hint = ""
    if username == "" then
        hint = "请输入手机账号！"    
    elseif password == "" then
        hint = "请输入登陆密码！"
    elseif not checkPwdLength(password) then
        hint = "密码长度应为6-16位！"
--    elseif not checkPhoneNum(userid) then  
--        hint = "手机号格式不正确！"  
--    elseif checkPwd(password) then
--        hint = "密码格式不正确！"            
    end
    
    if hint ~= "" then        
        self._ui:getInstance():scrollHint(hint)
        return
    else             
        local po = upconn.upconn:get_packet_obj()
        if po ~= nil then
            po:writer_reset()
            po:write_string(username)           -- userName
            po:write_string(password)           -- pwd
            po:write_string("")                 -- nickName
            po:write_string(username)           -- phoneNumber
            po:write_string(AccountData.IMEI()) -- imei
            po:write_string(AccountData.IMSI()) -- imsi

            po:write_string("")                 -- email
            po:write_string("")                 -- addr
            po:write_string("1")                -- avatar
            po:write_byte(1)                    -- gender
            po:write_int64(0)                   -- balance
            po:write_int32(0)                   -- state
            po:write_string("")                 -- channel
            po:write_string("")                 -- subChannel
            
            print("send register")
            _username, _password = username, password
               
            local sessionId = self.sessionId or 222
            upconn.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_REGISTER_REQ)
        end              
    end       
end

function RegisterPresenter:RegisterSuccess()  
    if not self:isCurrentUI() then
        return
    end
    -- 保存账号密码
    AccountData.setUsername(_username)
    AccountData.setPassword(_password)
    
    self._ui:getInstance():scrollHint("注册成功")
    
    self._ui:getInstance():exit()
    app.lobby.login.LoginPresenter:getInstance():sendLogin(_username, _password)
end

function RegisterPresenter:RegisterFail()  
    if not self:isCurrentUI() then
        return
    end
    _username, _password = "", ""      
    self._ui:getInstance():scrollHint("注册失败")
end

return RegisterPresenter