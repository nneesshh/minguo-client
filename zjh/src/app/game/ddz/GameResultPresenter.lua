--[[
    @brief  游戏结算控制类基类
]]--

local GameResultPresenter    = class("GameResultPresenter", app.base.BasePresenter)

GameResultPresenter._ui  = require("app.game.ddz.GameResultLayer")

-- 初始化
function GameResultPresenter:init(players)
    self._ui:getInstance():showResult(players)
end

-- 准备
function GameResultPresenter:sendPlayerReady()
    if not app.game.GamePresenter then
        print("not in game")
        return
    end

    if app.game.GameData.getReady() then
        print("have ready")
        return
    end

    local hero = app.game.PlayerData.getHero()   
    local po = upconn.upconn:get_packet_obj()
    local limit = app.game.GameConfig.getLimit()
    if hero and not hero:isLeave() and hero:getBalance() > limit and po then        
        print("send ready", hero:getSeat())
        local sessionid = app.data.UserData.getSession() or 222        
        po:writer_reset()
        po:write_int64(sessionid)
        upconn.upconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_READY_REQ)
    end    
end

return GameResultPresenter