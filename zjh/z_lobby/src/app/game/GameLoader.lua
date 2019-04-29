--[[
@brief 加载游戏区	
@by
]]
local GameLoader = {}

function GameLoader.loader(gameid)
	print("GameLoader", gameid)
    if gameid == app.Game.GameID.ZJH then
		GameLoader.loadZJH()
	elseif gameid == app.Game.GameID.JDNN then
        GameLoader.loadJDNN()
	end
end

function GameLoader.unloader()
	app.game.GamePresenter = nil
	app.game.GameData = nil
    app.game.GameEnum = nil
	
	collectgarbage("collect")
end

function GameLoader.loadZJH()
    app.game.GameData           = require("app.game.zjh.GameData")    
    app.game.GameEnum           = require("app.game.zjh.GameEnum")    
    app.game.GamePresenter      = require("app.game.zjh.GamePresenter")
end

function GameLoader.loadJDNN()
    app.game.GameData           = require("app.game.jdnn.GameData")    
    app.game.GameEnum           = require("app.game.jdnn.GameEnum")    
    app.game.GamePresenter      = require("app.game.jdnn.GamePresenter")
end

return GameLoader