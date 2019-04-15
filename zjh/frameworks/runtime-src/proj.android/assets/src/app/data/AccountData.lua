--[[
@brief 账号信息
]]
local AccountData = {}

local _selfData = {
    username = "", -- 用户名  
    password = "", -- 密码            
    type     = 1 , -- 账户类型 0游客1手机 
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

return AccountData