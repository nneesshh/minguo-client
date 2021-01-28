--[[
@brief  邮件
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local MailPresenter = class("MailPresenter",app.base.BasePresenter)
MailPresenter._ui = requireLobby("app.lobby.mail.MailLayer")

-- 返回日期
local function timeFormat(time)
    local array = string.split(time, " ")
    local ymd = string.split(array[1], "-")
    local hms = string.split(array[2], ":")
    return {
        year = tonumber(ymd[1]),
        month = tonumber(ymd[2]),
        day = tonumber(ymd[3]),
        hour = tonumber(hms[1]),
        min = tonumber(hms[2])
    }
end

--传入日期 返回时间戳
local function getTimeStamp(timeTable)
    local year = timeTable.year or 2000
    local month  = timeTable.month or 1
    local day = timeTable.day or 1
    local hour = timeTable.hour or 0
    local min = timeTable.min or 0
    return os.time({year=year, month=month, day=day, hour=hour, min=min, sec=0})
end

function MailPresenter:init()   
    local maillist = self:getMailList()
    self._ui:getInstance():showMailList(maillist)
end

-- 邮件列表
function MailPresenter:getMailList()
    --MailListHttp:getInstance():start(handler(self, self.onMailList))
    local mailList = {}
    for i=1, 10 do        
        local mail = {}
        mail.id    = i
        mail.title = "测试邮件数据" ..  i
        mail.time  = string.format("2019-%d-%d %d:%d", i, i*2, i, i*3)
        mail.stamp = getTimeStamp(timeFormat(mail.time)) or 0
        mail.read  = i%2   	
        table.insert(mailList, mail)
    end
    
    local sortlist = self:sortMailList(mailList) or {}
    return sortlist  
end

function MailPresenter:sortMailList(mailList)
    for j=1,#mailList do
        for i = 1 ,#mailList - j do
            local time1 = mailList[i].stamp or 0
            local time2 = mailList[i+1].stamp or 0            
            if time1 ~= nil or time2 ~= nil then
                if time1 < time2 then
                    mailList[i+1], mailList[i] = mailList[i], mailList[i+1]
                end
            end 
        end
    end
    return mailList
end

function MailPresenter:showMailDetail(mailid)
    local maillist = self:getMailList()
    for i, mail in ipairs(maillist) do
        if mail.id == mailid then
            app.lobby.mail.MailDetailPresenter:getInstance():start(mail)
    	end
    end    
end

return MailPresenter