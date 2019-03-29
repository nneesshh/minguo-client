--[[
@brief  游戏主场景控制基类
]]

local GamePresenter = class("GamePresenter", app.base.BasePresenter)

GamePresenter._ui   = require("app.game.zjh.GameScene")

local HERO_LOCAL_SEAT = 1
-- 初始化
function GamePresenter:init( ... )
    
end


-------------------------------request-------------------------------
function GamePresenter:sendLeaveRoom()
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
        po:write_int32(sessionid)  
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)
    end 
end

-------------------------------rule-------------------------------
function GamePresenter:getCardColor(id)
    return  bit._rshift(bit._and(id, 0xf0), 4) 
end

function GamePresenter:getCardNum(id)
    return bit._and(id, 0x0f)
end

return GamePresenter