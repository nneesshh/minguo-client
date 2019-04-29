--[[
@brief  状态
]]

local DebugLayer = class("DebugLayer", app.base.BaseLayer)

DebugLayer.csbPath = "lobby/csb/debug.csb"


function DebugLayer:initUI()    
    local txtip = self:seekChildByName("txt_ip")
    local txtport = self:seekChildByName("txt_port")

    txtip:setString("ip:" .. cfg_game_zjh.servers[1].host)
    txtport:setString("port:" .. cfg_game_zjh.servers[1].port)
end

function DebugLayer:updateState(state)
    local txtstate = self:seekChildByName("txt_state")

    txtstate:setString(state)
end

return DebugLayer