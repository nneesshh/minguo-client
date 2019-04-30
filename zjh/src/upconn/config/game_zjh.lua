local cwd = (...):gsub("%.[^%.]+$", "") .. "."
local cfg_mgzjh_robot = require(cwd .. "config_mgzjh_robot")

--[[
  {
        id = 1001, 
        type = 1, -- 'upstream type : 1 = game, 2 = chat',
        name = '游戏服务器1', -- '名称',
        host = '127.0.0.1',
        port = 8861,
        visibility = 1, -- '可见性，1=正式服，2=测试服，3=审核服',
        white_peerip = '', -- '白名单peer ip，服务器强制可见 -- "ip : mask | ..."',
        enable = 1 -- '是否启用，0 = 禁用， 1 = 启用',
  },
]]
local _M = {
    servers = {
        {
            id = 1000,
            type = 1,
            name = "Zjh服务器1",
            --host = "139.162.27.138", port = 8860, -- 外网
            --host = "192.168.200.101", port = 8860, -- 内网
            --host = "192.168.209.129", port = 8860, -- 209.129, 8860
            host = "192.168.200.111", port = 8861, -- 111, 8861
            visibility = 1,
            white_peerip = "",
            enable = true
        }
    },
    --
    robots = {}
}

-- init and sort robots
local __tmp_tbl__ = cfg_mgzjh_robot.ConfigRobot
for _, v in pairs(__tmp_tbl__) do
    table.insert(_M.robots, v)
end
table.sort(
    _M.robots,
    function(a, b)
        return a.userid < b.userid
    end
)

return _M
