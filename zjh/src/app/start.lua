
--[[
@brief 程序启动
]]

print = release_print

local start = {}

function start.init()    
    require("app.init")
    
    print("enter start")
    
    require("app.path")	
end

function start.start()
    app.util.FrontBackListener:getInstance():start()         
    app.lobby.MainPresenter:getInstance():start()
end

return start