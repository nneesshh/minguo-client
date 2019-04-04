--[[
@brief 游戏场信息
]]--

local PlazaData        = {}

PlazaData._plazaList   = {} 

--[[
plazaList = {
    [gameid] = {
        [1] = {
            roomid,
            lower,
            upper,
            base,
            usercount        
        },        
    }
}
]]-- 

function PlazaData.setPlazaList(plazaList, gameid, index)
    PlazaData._plazaList[gameid] = PlazaData._plazaList[gameid] or {}
    PlazaData._plazaList[gameid][index] = PlazaData._plazaList[gameid][index] or {}    
    PlazaData._plazaList[gameid][index] = plazaList
end

function PlazaData.getPlazaList(gameid)    
    return PlazaData._plazaList[gameid]
end

-- 根据金币获取当前可以进入的plazaid
function PlazaData.getSuitPlazaInfo(gameid, balance)
    local plazaInfo = PlazaData.getPlazaList(gameid)
    local suitPlazaInfo = nil
    for i=1, #plazaInfo do
        local lower = tonumber(plazaInfo[i].lower)
        local upper = tonumber(plazaInfo[i].upper)
        if balance >= lower and (balance <= upper or upper == 0) then
            suitPlazaInfo =  plazaInfo[i]
        end
    end
    return suitPlazaInfo
end

return PlazaData