
cc.FileUtils:getInstance():setPopupNotify(false)
-- lobby
cc.FileUtils:getInstance():addSearchPath("patch_lobby/src/", true)
cc.FileUtils:getInstance():addSearchPath("patch_lobby/res/", true)

-- zjh
cc.FileUtils:getInstance():addSearchPath("patch_zjh/src/", true)
cc.FileUtils:getInstance():addSearchPath("patch_zjh/res/", true)
-- jdnn
cc.FileUtils:getInstance():addSearchPath("patch_jdnn/src/", true)
cc.FileUtils:getInstance():addSearchPath("patch_jdnn/res/", true)

-- default
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

HotpatchRequire = require("hotpatch.HotpatchRequire")
requireLobby = HotpatchRequire.requireLobby
requireZJH   = HotpatchRequire.requireZJH
requireJDNN  = HotpatchRequire.requireJDNN

local function main()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    
    require "config"
    require "cocos.init"
    
    requireLobby("startup"):start()    
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
