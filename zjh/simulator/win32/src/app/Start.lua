
--[[
@brief �ļ��ṹ����㱣��һ��
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