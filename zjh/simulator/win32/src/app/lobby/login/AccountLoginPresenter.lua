
--[[
@brief  账号管理类
]]


local AccountLoginPresenter   = class("AccountLoginPresenter", app.base.BasePresenter)

-- UI
AccountLoginPresenter._ui  = require("app.lobby.login.AccountLoginLayer")

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

function AccountLoginPresenter:dealAccountLogin(userid, password)
    if userid == "" or password == "" then
        
        return
    end
    print("userid",userid)
    print("password",password)
end

function AccountLoginPresenter:showRegister()
    print("register")
    app.lobby.login.RegisterPresenter:getInstance():start()
end

function AccountLoginPresenter:showPhone()
    print("phone")
    app.lobby.login.VerifyLoginPresenter:getInstance():start()
end

return AccountLoginPresenter