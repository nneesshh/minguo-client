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
    elseif gameid == app.Game.GameID.QZNN then
        GameLoader.loadQZNN()
    elseif gameid == app.Game.GameID.LHD then   
        GameLoader.loadLHD() 
    elseif gameid == app.Game.GameID.BRNN then   
        GameLoader.loadBRNN() 
    elseif gameid == app.Game.GameID.DDZ then   
        GameLoader.loadDDZ()     
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

function GameLoader.loadQZNN()
    print("load qznn")
    app.game.GameData           = requireQZNN("app.game.qznn.GameData")    
    app.game.GameEnum           = requireQZNN("app.game.qznn.GameEnum")    
    app.game.GamePresenter      = requireQZNN("app.game.qznn.GamePresenter")
end

function GameLoader.loadLHD()
    print("load LHD")
    app.game.GameData           = requireLHD("app.game.lhd.GameData")    
    app.game.GameEnum           = requireLHD("app.game.lhd.GameEnum")    
    app.game.GamePresenter      = requireLHD("app.game.lhd.GamePresenter")
end

function GameLoader.loadBRNN()
    app.game.GameData           = requireBRNN("app.game.brnn.GameData")    
    app.game.GameEnum           = requireBRNN("app.game.brnn.GameEnum")    
    app.game.GamePresenter      = requireBRNN("app.game.brnn.GamePresenter")
end

function GameLoader.loadDDZ()
    app.game.GameData           = requireDDZ("app.game.ddz.GameData")    
    app.game.GameEnum           = requireDDZ("app.game.ddz.GameEnum")    
    app.game.GamePresenter      = requireDDZ("app.game.ddz.GamePresenter")	
end

return GameLoader