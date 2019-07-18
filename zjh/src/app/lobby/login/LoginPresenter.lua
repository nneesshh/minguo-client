
--[[
@brief  登录管理类
]]

local app = app


local LoginPresenter   = class("LoginPresenter", app.base.BasePresenter)

-- UI
LoginPresenter._ui  = requireLobby("app.lobby.login.LoginLayer")

local scheduler = cc.Director:getInstance():getScheduler()
local AccountData = app.data.AccountData
local _username, _password = "", ""

function LoginPresenter:init(flag)    
    self:createDispatcher()
    
    -- 暂停走马灯
    app.lobby.notice.BroadCastNode:stopActions()

    _username, _password = "", ""  
    
    if flag then
        self:performWithDelayGlobal(
            function()
                app.connMgr.reConnect()
            end, 0.2)
    end
end

function LoginPresenter:exit()
    app.lobby.MainPresenter:getInstance():showLobby()
    
    self._ui:getInstance():exit()
end

function LoginPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_SUCCESS, handler(self, self.onLoginSuccess))    
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_FAIL, handler(self, self.onLoginFail))       
end

function LoginPresenter:onLoginSuccess()
    self:dealLoadingHintExit()
    -- 保存账号密码
    AccountData.setUsername(_username)
    AccountData.setPassword(_password)
    
    self:exit()        
end

function LoginPresenter:onLoginFail(errcode)       
    self:dealLoadingHintExit()        

    --
    app.connMgr.close()    
    if CC_SHOW_LOGIN_DEBUG and errcode == 3 and not app.lobby.login.AccountLoginPresenter:isCurrentUI() then
        self:dealHintStart("账号未注册,是否自动注册并登录",
            function(bFlag)
                if bFlag then
                    print("_username",_username)
                    print("_password",_password)
                    
                    app.lobby.login.RegisterPresenter:getInstance():dealAccountRegister(_username, " ", _password)                                                
                end
            end
            , 0)
    else
        _username, _password = "", ""      
        self:dealTxtHintStart(zjh_defs.ErrorMessage[errcode]) 
    end              
end

function LoginPresenter:testLogin(data)
    if not data then
        return
    end
    
    self:performWithDelayGlobal(
        function()
            local po = gameUpconn:get_packet_obj()
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
                gameUpconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_LOGIN_REQ)

                _username, _password = data[2], data[3]
            else
                print("test po is nil")              
            end                          
        end, 0.2)
end

-- 自动登录
function LoginPresenter:dealAutoLogin()
    self:performWithDelayGlobal(
        function()
            local po = gameUpconn:get_packet_obj()    
            local have, username, password, imei = AccountData.haveAccount()
            print("wq-login", have, username, password, imei)
            local loginstate = app.data.UserData.getLoginState()
            if have and loginstate ~= 1 then                
                app.lobby.login.AccountLoginPresenter:getInstance():start()
                if imei then
                    self:sendLogin("", "mg123456")      -- 游客自动登录
                else
                    self:sendLogin(username, password)  -- 账号自动登录                	
                end                
            end
        end, 0.2)
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

-- 账号登录
function LoginPresenter:dealAccountLogin()
    app.lobby.login.AccountLoginPresenter:getInstance():start()
end

function LoginPresenter:sendLogin(username, password)        
    local po = gameUpconn:get_packet_obj()    
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
        gameUpconn:send_packet(sessionId, zjh_defs.MsgId.MSGID_LOGIN_REQ)   
    else
        print("wq - login po is nil")             
    end     
end

-- 
function LoginPresenter:reLogin(hint)
    if not self:isCurrentUI() then
        hint = hint or "连接异常,请重新登录！"
        self:dealHintStart(hint,
            function(bFlag)               
                app.game.GameEngine:getInstance():exit()

                self:performWithDelayGlobal(
                    function()
                        app.lobby.login.LoginPresenter:getInstance():start(true) 
                        self:dealAccountLogin()
                    end, 0.05)                 
            end
            ,0)        
    end
end

return LoginPresenter