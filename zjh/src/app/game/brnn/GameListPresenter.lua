
--[[
    @brief  游戏玩家列表
]]--
local app = cc.exports.gEnv.app
local requireBRNN = cc.exports.gEnv.HotpatchRequire.requireBRNN

local GameListPresenter    = class("GameListPresenter", app.base.BasePresenter)

GameListPresenter._ui  = requireBRNN("app.game.brnn.GameListLayer")

-- 初始化
function GameListPresenter:init(players)    
    self._ui:getInstance():showPlayerList(players)    
end

return GameListPresenter