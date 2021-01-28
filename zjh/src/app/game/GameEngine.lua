--[[
@brief  中间件 处理大厅与游戏区切换
]]
local app = cc.exports.gEnv.app
local GameEngine = class("GameEngine")

GameEngine._instance = nil
GameEngine._callFunc = nil

function GameEngine:getInstance()
    if self._instance == nil then
        self._instance = self.new()
    end
    return self._instance
end

function GameEngine:start(gameID, base, limit)
    app.game.GameConfig.init(gameID, base, limit)
    app.game.GameLoader.loader(gameID)
    app.game.PlayerData.init(app.Game.MaxPlayCnt[gameID])
end

function GameEngine:exit()
    print("game engine exit")    
    app.game.PlayerData.exit()
    
    if app.game.GameData then
        app.game.GameData.restData()
    end
    
    self:onExitGame()

    app.game.GameLoader.unloader()
    app.game.GameConfig.reset()
end

-- 场景切换
function GameEngine:onStartGame()
    if app.lobby.MainPresenter:getInstance():isCurrentUI() then
        app.lobby.MainPresenter:getInstance():exit()
    else
        app.game.GamePresenter:getInstance():exit()
    end
    if app.game.GamePresenter then
        app.game.GamePresenter:getInstance():start()
    end    
end

function GameEngine:onExitGame()
    if not app.lobby.MainPresenter:getInstance():isCurrentUI() then
        app.game.GamePresenter:getInstance():exit()
        app.lobby.MainPresenter:getInstance():start(app.game.GameConfig.getGameID())
    end
end

function GameEngine:isRuning()
    if app.game.GamePresenter then
        return app.game.GamePresenter:getInstance():isCurrentUI()
    end
    return false
end

return GameEngine