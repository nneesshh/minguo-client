
--[[
@brief 程序启动
]]

local starter = {}

function starter.init()    
    require("app.init")
    print("enter start")
    require("app.path")	
end

function starter.start()
    local app = cc.exports.gEnv.app
    app.util.FrontBackListener:getInstance():start()         
    app.lobby.MainPresenter:getInstance():start()
end

return starter