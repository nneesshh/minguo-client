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
    return {}
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
    local uuid = app.util.uuid()
    local imei = AccountData.getAccountData("imei")
    if #imei > 0 then
        return imei
    end    
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if 3 == targetPlatform or 4 == targetPlatform or 5 == targetPlatform then
        AccountData.setIMEI(uuid)
        return uuid
    else
        AccountData.setIMEI(uuid)
        return uuid
    end
end

function AccountData.IMSI()
    local uuid = app.util.uuid()
    local imsi = AccountData.getAccountData("imsi")
    if #imsi > 0 then
        return imsi
    end   
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if 3 == targetPlatform or 4 == targetPlatform or 5 == targetPlatform then
        AccountData.setIMSI(uuid)
        return uuid
    else
        AccountData.setIMSI(uuid)
        return uuid
    end
end

return AccountData