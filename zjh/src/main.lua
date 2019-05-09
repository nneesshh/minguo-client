
cc.FileUtils:getInstance():setPopupNotify(false)

CC_HOTPATCH = true

if CC_HOTPATCH then
    -- lobby
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_lobby/src/", true)
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_lobby/res/", true)

    -- zjh
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_zjh/src/", true)
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_zjh/res/", true)
    -- jdnn
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_jdnn/src/", true)
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_jdnn/res/", true)
end

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
HotpatchController = require("hotpatch.HotpatchController")

requireLobby = HotpatchRequire.requireLobby
requireZJH   = HotpatchRequire.requireZJH
requireJDNN  = HotpatchRequire.requireJDNN

local function main()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    
    require "config"
    require "cocos.init"
    
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if 3 == targetPlatform or 4 == targetPlatform or 5 == targetPlatform then
        requireLobby("startup"):start()    
    else       
        if CC_HOTPATCH then
            requireLobby("startup"):start()    
        else
            local start = requireLobby "app.start"
            start.init()
            start.start()
        end
    end
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
