
--[[
    @brief  庄家列表
]]--

local GameBankerPresenter    = class("GameBankerPresenter", app.base.BasePresenter)

GameBankerPresenter._ui  = requireBRNN("app.game.brnn.GameBankerLayer")

-- 初始化
function GameBankerPresenter:init(players)    
    self._ui:getInstance():showPlayerList(players)    
end

function GameBankerPresenter:sendGobanker()
    print("send go banker")
    local po = upconn.upconn:get_packet_obj()
    if po ~= nil then
        local sessionid = app.data.UserData.getSession() or 222
        po:writer_reset()
         
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_LEAVE_ROOM_REQ)  
    end
end

return GameBankerPresenter