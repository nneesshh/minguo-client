--[[
    @brief  游戏结果趋势
]]--

local GameTrendPresenter    = class("GameTrendPresenter", app.base.BasePresenter)

GameTrendPresenter._ui  = requireBRNN("app.game.brnn.GameTrendLayer")

local MAX_COUNT = 8

function GameTrendPresenter:init(list)
    local tmp = self:calHistoryList(list)
    
    self._ui:getInstance():updateTrend(tmp) 
end

function GameTrendPresenter:calHistoryList(list)
    local count = #list    
    local limit = 1
    local temp = {}
    if count > MAX_COUNT then
        limit = count - (MAX_COUNT - 1)
    end
    for k = count, limit, -1 do
        table.insert(temp, list[k])         
    end
    
    return temp
end

return GameTrendPresenter