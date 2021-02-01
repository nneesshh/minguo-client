
cc.FileUtils:getInstance():setPopupNotify(false)

require "config"
require "cocos.init"

-- cclog
local cclog = function(...)
    print(string.format(...))
end

-- traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
   
    return msg
end

--
local function main()
	-- require("app.MyApp"):create():run()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    if CC_HOTPATCH then
        -- 大厅热更搜索路径
        cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_lobby/src/", true)
        cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_lobby/res/", true)
        
        require("startup"):start()    
    else
        local starter = require "app.starter"
        starter.init()
        starter.start()
    end    
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
