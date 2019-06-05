--[[
    @brief  游戏结果趋势
]]--

local GameTrendPresenter    = class("GameTrendPresenter", app.base.BasePresenter)

GameTrendPresenter._ui  = requireLHD("app.game.lhd.GameTrendLayer")

--local GameEnum = app.game.GameEnum 
local GameEnum = {}
GameEnum.HISTORY_NUM = 20
GameEnum.MAX_NUM     = 48

function GameTrendPresenter:init(list)
    self._ui:getInstance():updateTrend(list) 
end

function GameTrendPresenter:updateTrendOne(result, list)
    self._ui:getInstance():updateTrendOne(result, list) 
end

function GameTrendPresenter:calRecordForTop(list)
    local count = #list    
    local limit = 1
    local temp = {}
    if count > GameEnum.HISTORY_NUM then
        limit = count - (GameEnum.HISTORY_NUM - 1)
    end
    for k = count, limit, -1 do
        table.insert(temp, 1, list[k])         
    end
    
    return temp
end

function GameTrendPresenter:calRecordForLeft(list)
    local count = #list    
    local limit = 1
    local temp = {}
    if count > GameEnum.MAX_NUM then
        limit = count - (GameEnum.MAX_NUM - 1)
    end
    for k = count, limit, -1 do
        table.insert(temp, 1, list[k])         
    end

    return temp
end

function GameTrendPresenter:calRecordForRight(data)
    local cnt = 0
    local pre = 0
    local ktype = {}
    local beg3 = true    

    local list = {}    
    for i=1,#data do
        if data[i] == 3 and beg3 then            
        else
            beg3 = false
            table.insert(list,data[i])
        end
    end    

    for i = 1, #list do                          
        if list[i] ~= pre and list[i] ~= 3 then
            cnt = cnt + 1                
            ktype[cnt] = ktype[cnt] or {}   
            table.insert(ktype[cnt], list[i])
            pre = list[i]
        else                          
            if list[i] == 3 then                                                 
                local next = #ktype[cnt]+1                    
                if type(ktype[cnt][next-1]) == "table" and ktype[cnt][next-1][1] == 3 then
                    table.insert(ktype[cnt][next-1], list[i]) 
                else
                    ktype[cnt][next] = ktype[cnt][next] or {}   
                    table.insert(ktype[cnt][next], list[i])  
                end
            else
                table.insert(ktype[cnt], list[i]) 
            end                                    
        end                       
    end
    
    return ktype   
end

function GameTrendPresenter:calPercent(list)
    local count = #list  
    local limit = 1
    if count > GameEnum.MAX_NUM then
        limit = count - (GameEnum.MAX_NUM - 1)
    end
    local long, hu, he, perl, perh = {}, {}, {}, 0, 0
    for i = count, limit, -1 do
        if list[i] == 1 then
            table.insert(long, list[i])
        elseif list[i] == 2 then
            table.insert(hu, list[i])
        elseif list[i] == 3 then
            table.insert(he, list[i])
        end     
    end
    
    if #long + #hu ~= 0 then
        local fm = #long + #hu    
        perl = math.ceil(#long / fm * 100) 
        perh = 100 - perl
    end

    return long, hu, he, perl, perh
end

return GameTrendPresenter