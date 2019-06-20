--[[
    @brief  游戏结算控制类基类
]]--

local GameResultPresenter    = class("GameResultPresenter", app.base.BasePresenter)

GameResultPresenter._ui  = require("app.game.ddz.GameResultLayer")

-- 初始化
function GameResultPresenter:init(players)
    self._ui:getInstance():showResult(players)
end

return GameResultPresenter