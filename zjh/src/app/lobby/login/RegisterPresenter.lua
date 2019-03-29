
--[[
@brief  注册管理类
]]


local RegisterPresenter   = class("RegisterPresenter", app.base.BasePresenter)

-- UI
RegisterPresenter._ui  = require("app.lobby.login.RegisterLayer")

function RegisterPresenter:getVerify()
    
end

function RegisterPresenter:dealAccountRegister(userid, verify, password)
    if userid == "" or password == "" then        
        return
    end
    
    local po = upconn.upconn:get_packet_obj()
    
    po:writer_reset()
    po:write_string("") -- userName
    po:write_string(cfg_robot.pwd) -- pwd
    po:write_string("") -- nickName
    po:write_string(tostring(cfg_robot.phone)) -- phoneNumber
    po:write_string("") -- imei
    po:write_string("") -- imsi

    po:write_string(cfg_robot.email) -- email
    po:write_string(cfg_robot.addr) -- addr
    po:write_string(cfg_robot.avatar) -- avatar
    po:write_byte(cfg_robot.gender) -- gender

    po:write_int64(cfg_robot.balance) -- balance
    po:write_int32(cfg_robot.state) -- state

    po:write_string(cfg_robot.channel) -- channel
    po:write_string(cfg_robot.subChannel) -- subChannel

    -- 222 is just a faked sessionid for test
    local sessionId = self.sessionId or 222
    self.upconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_REGISTER_REQ)
            
end

return RegisterPresenter