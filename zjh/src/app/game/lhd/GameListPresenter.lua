
--[[
    @brief  游戏玩家列表
]]--
local app = cc.exports.gEnv.app
local requireLHD = cc.exports.gEnv.HotpatchRequire.requireLHD

local GameListPresenter    = class("GameListPresenter", app.base.BasePresenter)

GameListPresenter._ui  = requireLHD("app.game.lhd.GameListLayer")

-- 初始化
function GameListPresenter:init(players)    
    self._ui:getInstance():showPlayerList(players)    
end

return GameListPresenter