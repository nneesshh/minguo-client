
--[[
@brief 程序启动
]]

print = release_print

local start = {}

function start.init()    
	require("app.init")	
end

function start.start()
    app.lobby.MainPresenter:getInstance():start()
end

return start