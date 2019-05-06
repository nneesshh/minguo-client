--[[
@brief 账号信息
]]

local AccountData = {}

local luaj

local _selfData = {
    username = "", -- 用户名  
    password = "", -- 密码            
    imei     = "", -- imei
    imsi     = "", -- imsi
 }

function AccountData.setUsername(username)
    _selfData.username = username
    AccountData.saveAccountData(_selfData.username, "USERNAME")
end

function AccountData.setPassword(password)
    _selfData.password = password
    AccountData.saveAccountData(_selfData.password, "PASSWORD")
end

function AccountData.setIMEI(imei)
    _selfData.imei = imei
    AccountData.saveAccountData(_selfData.imei, "IMEI")
end

function AccountData.setIMSI(imsi)
    _selfData.imsi = imsi
    AccountData.saveAccountData(_selfData.imsi, "IMSI")
end

-- 设置账号数据
function AccountData.saveAccountData(data, key)
    if data == "" or data == nil then
    	return
    end
    
    cc.UserDefault:getInstance():setStringForKey(key, data)
end

-- 获取账号数据
function AccountData.getAccountData(key)    
    return cc.UserDefault:getInstance():getStringForKey(key) or ""
end

function AccountData.haveAccount()
    local username = AccountData.getAccountData("USERNAME")
    local password = AccountData.getAccountData("PASSWORD")
    if #username > 0 and #password > 0 then
        return true, username, password
    end
    return false, "", ""
end

function AccountData.IMEI()
    local phoneIMEI = AccountData.getPhoneIMEI()
    local localIMEI = AccountData.getAccountData("IMEI")
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
    local localIMSI = AccountData.getAccountData("IMSI")
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
        if not luaj then
            luaj = require("cocos.cocos2d.luaj")
        end        
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
        if not luaj then
            luaj = require("cocos.cocos2d.luaj")
        end 
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