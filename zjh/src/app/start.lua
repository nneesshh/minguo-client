
--[[
@brief 文件结构与外层保持一致
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