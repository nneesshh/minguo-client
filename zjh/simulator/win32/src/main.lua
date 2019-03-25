
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

-- cclog
local cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    return msg
end

print = release_print

package.cpath = package.cpath .. ";./?.dll;./clibs/?.dll"
local upconn = require "upconn.ZjhUpconn"
upconn.start()

local function main()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    
    require "config"
    require "cocos.init"
    
    require("startup"):start()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
