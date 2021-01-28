
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = true

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

-- for module display
CC_DESIGN_RESOLUTION = {
    width = 1334,
    height = 750,
    autoscale = "FIXED_HEIGHT",
    callback = function(framesize)
        local ratio = framesize.width / framesize.height
        if ratio <= 1334/750 then
            -- iPad 768*1024(1536*2048) is 4:3 screen
            return {autoscale = "FIXED_WIDTH"}
        end
    end
}

-- hotpatch
CC_HOTPATCH = false

-- show login debug
CC_SHOW_LOGIN_DEBUG = true

-- auto login
CC_AUTO_LOGIN = false

-- heart beat
CC_HEART_BEAT = false

-- server addr list
local SERVER_ADDR_LIST = {
    {host = "3.113.138.76",  port = 8860}, -- 1 
    {host = "192.168.200.101", port = 8860}, -- 2 
    {host = "192.168.50.194", port = 8861}, -- 3 
    {host = "192.168.111.111",   port = 8861}, -- 4 
    {host = "127.0.0.1",   port = 8861}, -- 5 localhost
}

CC_SERVER_ADDR = SERVER_ADDR_LIST[5]
