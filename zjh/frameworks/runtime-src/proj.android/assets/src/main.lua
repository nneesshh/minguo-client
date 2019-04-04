
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

-- cclog
local cclog = function(...)
    print(string.format(...))
end

local function writeDump(txtName,info)
    
    if info == nil then
        info = "nil"
    elseif type(info) == "userdata" then
        info = "userdata"
    elseif type(info) == "table" then
        info = "table value"
    end
    local buff = ""

    local date = os.date("*t",os.time())

    buff = buff .. "\n" .. date.year .. "/" .. date.month .. "/" .. date.day .. "   " .. date.hour..":"..date.min..":"..date.sec.. "\n"

    local path = txtName
    if cc.Application:getInstance():getTargetPlatform() ~= cc.PLATFORM_OS_WINDOWS then
        path = cc.FileUtils:getInstance():getWritablePath() .. path
    end
    local file = io.open(path, "a")
    buff = buff .. info
    file:write(buff)
    file:close()
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    local trac = debug.traceback()
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(trac)
    --writeDump("dump.txt",msg)
    --writeDump("dump.txt",trac)
    
    return msg
end

print = release_print

--package.cpath = package.cpath .. ";./?.dll;./clibs/?.dll"
--upconn = require "upconn.ZjhUpconn"
--upconn.start()



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
