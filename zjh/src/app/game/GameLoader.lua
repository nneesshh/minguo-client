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
    app.game.GameData           = requireZJH("app.game.zjh.GameData")    
    app.game.GameEnum           = requireZJH("app.game.zjh.GameEnum")    
    app.game.GamePresenter      = requireZJH("app.game.zjh.GamePresenter")
end

function GameLoader.loadJDNN()
    app.game.GameData           = requireJDNN("app.game.jdnn.GameData")    
    app.game.GameEnum           = requireJDNN("app.game.jdnn.GameEnum")    
    app.game.GamePresenter      = requireJDNN("app.game.jdnn.GamePresenter")
end

return GameLoader