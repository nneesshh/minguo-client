
--[[
@brief 程序启动
]]

print = release_print

local start = {}

function start.init()    
    requireLobby("app.init")	
end

function start.start()
    app.Connect:getInstance():start()  
    app.util.FrontBackListener:getInstance():start()         
    app.lobby.MainPresenter:getInstance():start()
end

return start