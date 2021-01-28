--[[
@brief  状态
]]
local app = cc.exports.gEnv.app
local DebugLayer = class("DebugLayer", app.base.BaseLayer)

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."

DebugLayer.csbPath = "lobby/csb/debug.csb"


function DebugLayer:initUI()    
    local txtip = self:seekChildByName("txt_ip")
    local txtport = self:seekChildByName("txt_port")

    local cfg_game_zjh = cc.exports.gEnv.misc_defs.cfg_game_zjh
    txtip:setString("ip:" .. cfg_game_zjh.servers[1].host)
    txtport:setString("port:" .. cfg_game_zjh.servers[1].port)
end

function DebugLayer:updateState(state)
    local txtstate = self:seekChildByName("txt_state")

    txtstate:setString(state)
end

return DebugLayer