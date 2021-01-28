
local app = cc.exports.gEnv.app
local zjh_defs = cc.exports.gEnv.misc_defs.zjh_defs
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local scheduler = cc.Director:getInstance():getScheduler()
local gameConn = requireLobby("upconn.ZjhUpconn")

local _M = {
    heartBeatTime      = 10,
    heartBeatTimeout   = 30,
    receiveTime        = 0,

    _scheduleUpdate    = nil,
    _scheduleHeartBeat = nil,
    _scheduleTimeOut   = nil,

    _gameConn          = gameConn,
}

_M.STATE = {
    IDLE          = 0,
    CONNECTING    = 1,
    RECONNECTING  = 2,
    CONNECTED     = 3,
    CLEANUP       = 4,
    CLOSED        = 5
}

_M.STATENAME = {
    [_M.STATE.IDLE]         = "IDLE",
    [_M.STATE.CONNECTING]   = "CONNECTING",
    [_M.STATE.RECONNECTING] = "RECONNECTING",
    [_M.STATE.CONNECTED]    = "CONNECTED",
    [_M.STATE.CLEANUP]      = "CLEANUP",
    [_M.STATE.CLOSED]       = "CLOSED"
}

_M.state = _M.STATE.IDLE

function _M.start(cb)
    _M.reset()

    --
    _M._gameConn.start(cb)
	_M.openScheduleUpdate(cb)
end

function _M.reset()	
    _M.receiveTime = 0

    _M.updateState(_M.STATE.IDLE)
	_M.closeScheduleUpdate()
	_M.closeScheduleHeartBeat()
	_M.closeScheduleTimeOut()
end

-- 协议发送接收
function _M.openScheduleUpdate(cb)    
    _M.closeScheduleUpdate()
    
    local function updatefunc(dt)
        _M._gameConn.update()         
    end
    
    _M._scheduleUpdate = scheduler:scheduleScriptFunc(updatefunc, 0.1, false)
    _M.openScheduleHeartBeat()
    _M.openScheduleTimeOut()
end

function _M.closeScheduleUpdate()
    if _M._scheduleUpdate then        
        scheduler:unscheduleScriptEntry(_M._scheduleUpdate)
        _M._scheduleUpdate = nil
    end
end

-- 心跳 
function _M.openScheduleHeartBeat()
    _M.closeScheduleHeartBeat()
    
    local function sendfunc()        
        local po = _M._gameConn.upconn:get_packet_obj()
        local sessionid = app.data.UserData.getSession() or 222
        if po ~= nil then        
            po:writer_reset()
            po:write_int32(sessionid)                                     
            _M._gameConn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_HEART_BEAT_REQ)                  
        end
    end
    
    _M._scheduleHeartBeat = scheduler:scheduleScriptFunc(sendfunc, _M.heartBeatTime, false)    
end

function _M.closeScheduleHeartBeat()
    if _M._scheduleHeartBeat then        
        scheduler:unscheduleScriptEntry(_M._scheduleHeartBeat)
        _M._scheduleHeartBeat = nil
    end
end

-- 检测心跳超时
function _M.openScheduleTimeOut()
    _M.closeScheduleTimeOut()
    
    local function timeoutfnc()     
        local nowTime = os.time()
        if nowTime - _M.receiveTime > _M.heartBeatTimeout then 
            print("die le save me")   
            
            if CC_HEART_BEAT then
                _M.close()
                app.lobby.login.LoginPresenter:getInstance():reLogin()          
            end                                           
        end
    end
    
    _M._scheduleTimeOut = scheduler:scheduleScriptFunc(timeoutfnc, _M.heartBeatTime+1, false)
end

function _M.closeScheduleTimeOut()
    if _M._scheduleTimeOut then        
        scheduler:unscheduleScriptEntry(_M._scheduleTimeOut)
        _M._scheduleTimeOut = nil
    end
end

function _M.close()    
    _M._gameConn.close()  
    _M.reset()  
    _M.updateState(_M.STATE.CLOSED)     
end

function _M.respHeartbeat()   
    _M.receiveTime = os.time()    
end

function _M.updateState(state)   
    _M.state = state   
    app.util.DispatcherUtils.dispatchEvent(app.Event.EVENT_CONNECT_STATE)  
end

function _M.getState()
    return _M.STATENAME[_M.state]
end

function _M.getGameStream()
    return _M._gameConn.upconn
end

function _M.reConnect(cb)
    _M._gameConn.close()
    _M.start(cb)
end

return _M