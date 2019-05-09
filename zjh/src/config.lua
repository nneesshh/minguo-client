
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 0

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = false

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = false

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

-- IP
local IP_LIST = {
    {host = "139.162.27.138",  port = 8860},
    {host = "192.168.200.101", port = 8860},
    {host = "192.168.209.129", port = 8860},
    {host = "192.168.200.111", port = 8861},    
}

CC_IP = IP_LIST[2]
