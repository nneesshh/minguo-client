
local Connect = class("Connect")

local scheduler = cc.Director:getInstance():getScheduler()

Connect._instance = nil

Connect.heartBeatTime      = 10
Connect.heartBeatTimeout   = 10
Connect.receiveTime        = 0

Connect._scheduleUpdate    = nil
Connect._scheduleHeartBeat = nil
Connect._scheduleTimeOut   = nil

Connect.STATE = {
    IDLE          = 0,
    CONNECTING    = 1,
    RECONNECTING  = 2,
    CONNECTED     = 3,
    CLEANUP       = 4,
    CLOSED        = 5
}

Connect.STATENAME = {
    [Connect.STATE.IDLE]         = "IDLE",
    [Connect.STATE.CONNECTING]   = "CONNECTING",
    [Connect.STATE.RECONNECTING] = "RECONNECTING",
    [Connect.STATE.CONNECTED]    = "CONNECTED",
    [Connect.STATE.CLEANUP]      = "CLEANUP",
    [Connect.STATE.CLOSED]       = "CLOSED"
}

Connect.state     = Connect.STATE.IDLE

function Connect:getInstance()
    if self._instance == nil then
        self._instance = self.new()
    end
    return self._instance
end

function Connect:start()
	self:reset()
	self:openScheduleUpdate()
end

function Connect:reset()	
	self.receiveTime       = 0

    self:updateState(Connect.STATE.IDLE)
	self:closeScheduleUpdate()
	self:closeScheduleHeartBeat()
	self:closeScheduleTimeOut()
end

-- 协议发送接收
function Connect:openScheduleUpdate()    
    self:closeScheduleUpdate()
    
    local function updatefunc(dt)
        upconn.update()         
    end
    
    upconn.start() 
    self._scheduleUpdate = scheduler:scheduleScriptFunc(updatefunc, 0.1, false)
    self:openScheduleHeartBeat()
    self:openScheduleTimeOut()
end

function Connect:closeScheduleUpdate()
    if self._scheduleUpdate then        
        scheduler:unscheduleScriptEntry(self._scheduleUpdate)
        self._scheduleUpdate = nil
    end
end

-- 心跳 
function Connect:openScheduleHeartBeat()
    self:closeScheduleHeartBeat()
    
    local function sendfunc()        
        local po = upconn.upconn:get_packet_obj()
        local sessionid = app.data.UserData.getSession() or 222
        if po ~= nil then        
            po:writer_reset()
            po:write_int32(sessionid)                                     
            upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_HEART_BEAT_REQ)                  
        end
    end
    
    self._scheduleHeartBeat = scheduler:scheduleScriptFunc(sendfunc, self.heartBeatTime, false)    
end

function Connect:closeScheduleHeartBeat()
    if self._scheduleHeartBeat then        
        scheduler:unscheduleScriptEntry(self._scheduleHeartBeat)
        self._scheduleHeartBeat = nil
    end
end

-- 检测心跳超时
function Connect:openScheduleTimeOut()
    self:closeScheduleTimeOut()
    
    local function timeoutfnc()     
        local nowTime = os.time()
        if nowTime - self.receiveTime > self.heartBeatTimeout then 
            print("die le")                       
            --self:close()
        else    
            print("beat")                        
        end
    end
    
    self._scheduleTimeOut = scheduler:scheduleScriptFunc(timeoutfnc, self.heartBeatTime+1, false)
end

function Connect:closeScheduleTimeOut()
    if self._scheduleTimeOut then        
        scheduler:unscheduleScriptEntry(self._scheduleTimeOut)
        self._scheduleTimeOut = nil
    end
end

function Connect:close()    
    upconn.close()      
    self:reset()  
    self:updateState(Connect.STATE.CLOSED) 
    app.lobby.login.LoginPresenter:getInstance():reLogin()   
end

function Connect:respHeartbeat()    
    self.receiveTime = os.time()    
end

function Connect:updateState(state)   
    self.state = state   
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_CONNECT_STATE)  
end

function Connect:getState()
    return Connect.STATENAME[self.state]
end

return Connect