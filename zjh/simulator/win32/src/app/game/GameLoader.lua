--[[
@brief 加载游戏区	
@by
]]
local GameLoader = {}

function GameLoader.loader(gameid)
	print("GameLoader", gameid)
    if gameid == app.Game.GameID.ZJH then
		GameLoader.loadZJH()
	end
end

function GameLoader.unloader()
	app.game.GamePresenter = nil
	
	collectgarbage("collect")
end

function GameLoader.loadZJH(roomMode)
    app.game.GamePresenter      = require("app.game.zjh.GamePresenter")
    app.game.GameData           = require("app.game.zjh.GameData")
end

return GameLoader