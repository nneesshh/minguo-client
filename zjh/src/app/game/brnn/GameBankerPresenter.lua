
--[[
    @brief  庄家列表
]]--

local GameBankerPresenter    = class("GameBankerPresenter", app.base.BasePresenter)

GameBankerPresenter._ui  = requireBRNN("app.game.brnn.GameBankerLayer")

-- 初始化
function GameBankerPresenter:init(players)    
    self._ui:getInstance():showPlayerList(players)    
end

return GameBankerPresenter