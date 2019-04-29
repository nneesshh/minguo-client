--[[
@brief 账号信息
]]

local AccountData = {}

local _selfData = {
    username = "", -- 用户名  
    password = "", -- 密码            
    imei     = "", -- imei
    imsi     = "", -- imsi
 }

function AccountData.setUsername(username)
    _selfData.username = username
    AccountData.saveAccountData(_selfData)
end

function AccountData.setPassword(password)
    _selfData.password = password
    AccountData.saveAccountData(_selfData)
end

function AccountData.setIMEI(imei)
    _selfData.imei = imei
    AccountData.saveAccountData(_selfData)
end

function AccountData.setIMSI(imsi)
    _selfData.imsi = imsi
    AccountData.saveAccountData(_selfData)
end

-- 设置账号数据
function AccountData.saveAccountData(data)
    local strAccount = app.util.ToolUtils.serialize(data)
    cc.UserDefault:getInstance():setStringForKey("ACCOUNT", strAccount)
end

-- 获取账号数据
function AccountData.getAccountData(type)
    local strdata = cc.UserDefault:getInstance():getStringForKey("ACCOUNT") or {}
    local udata = app.util.ToolUtils.unserialize(strdata)
    if udata and udata[type] and string.len(udata[type]) > 0 then
        return udata[type]
    end    
    return ""
end

function AccountData.haveAccount()
    local username = AccountData.getAccountData("username")
    local password = AccountData.getAccountData("password")
    if #username > 0 and #password > 0 then
        return true, username, password
    end
    return false, "", ""
end

function AccountData.IMEI()
    local phoneIMEI = AccountData.getPhoneIMEI()
    local localIMEI = AccountData.getAccountData("imei")
    if #phoneIMEI > 0 then
        AccountData.setIMEI(phoneIMEI)
        return phoneIMEI    
    else
        if #localIMEI > 0 then
            return localIMEI   
        else
            local uuid = app.util.uuid()
            AccountData.setIMEI(uuid)
            return uuid
        end    	
    end
end

function AccountData.IMSI()
    local phoneIMSI = AccountData.getPhoneIMSI()
    local localIMSI = AccountData.getAccountData("imsi")
    if #phoneIMSI > 0 then
        AccountData.setIMSI(phoneIMSI)
        return phoneIMSI    
    else
        if #localIMSI > 0 then
            return localIMSI   
        else
            local uuid = app.util.uuid()
            AccountData.setIMSI(uuid)
            return uuid
        end     
    end
end

-- 获取手机imei
function AccountData.getPhoneIMEI()
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == targetPlatform then
        local args = {}
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local ok ,ret = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity","getIMEI",args,sig)
        if not ok then
            return ""
        else
            return ret
        end
    else 
        return ""
    end
end

-- 获取手机imsi
function AccountData.getPhoneIMSI()
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == targetPlatform then
        local args = {}
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local ok ,ret = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity","getIMSI",args,sig)
        if not ok then
            return ""
        else
            return ret
        end
    else 
        return ""
    end
end

return AccountData