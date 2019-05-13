
--[[
@brief  账号管理类
]]

local AccountLoginPresenter   = class("AccountLoginPresenter", app.base.BasePresenter)

-- UI
AccountLoginPresenter._ui  = requireLobby("app.lobby.login.AccountLoginLayer")

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

function AccountLoginPresenter:init()
    self:createDispatcher()
    _username, _password = "", ""  
end

function AccountLoginPresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_SUCCESS, handler(self, self.onLoginSuccess)) 
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_LOGIN_FAIL, handler(self, self.onLoginFail))       
end

function AccountLoginPresenter:getAccountData()
    local have, username, password = AccountData.haveAccount()
    return username, password
end

function AccountLoginPresenter:onLoginSuccess()
    self:dealLoadingHintExit()
    -- 保存账号密码
    AccountData.setUsername(_username)
    AccountData.setPassword(_password)
    
    self._ui:getInstance():exit()    
    app.lobby.login.LoginPresenter:getInstance():exit()  
end

function AccountLoginPresenter:onLoginFail(errcode)       
    self:dealLoadingHintExit() 
    
    if app.Connect then            
        app.Connect:getInstance():close()    
        if CC_SHOW_LOGIN_DEBUG and errcode == 3 and not self:isCurrentUI() then
            self:dealHintStart("账号未注册,是否自动注册并登录",
                function(bFlag)
                    if bFlag then
                        app.lobby.login.RegisterPresenter:getInstance():dealAccountRegister(_username, "", _password)                                                
                    end
                end
                , 0)
        else
            self:dealTxtHintStart(zjh_defs.ErrorMessage[errcode])    
            _username, _password = "", ""                 
        end              
    end    
end

function AccountLoginPresenter:dealAccountLogin(account, password)  
    print("password is", password, checkPwd(password))  
    local hint = ""
    if account == "" then
        hint = "请输入手机账号！" 
    elseif password == "" then
        hint = "请输入登录密码！"
    elseif not checkPwdLength(password) then
        hint = "密码长度应为6-16位！"
--    elseif not checkPhoneNum(account) then  
--        hint = "手机号格式不正确" 
--    elseif checkPwd(password) then
--        hint = "密码格式不正确！"            
    end

    if hint ~= "" then        
        self:dealTxtHintStart(hint)
        return
    else        
        _username, _password = account, password          
        app.lobby.login.LoginPresenter:getInstance():sendLogin(account, password)
    end
end

function AccountLoginPresenter:showRegister()
    app.lobby.login.RegisterPresenter:getInstance():start()
end

function AccountLoginPresenter:showPhone()
    app.lobby.login.VerifyLoginPresenter:getInstance():start()
end

return AccountLoginPresenter