--[[
    @brief  游戏结算控制类基类
]]--
local app = cc.exports.gEnv.app
local zjh_defs = cc.exports.gEnv.misc_defs.zjh_defs
local GameResultPresenter    = class("GameResultPresenter", app.base.BasePresenter)

GameResultPresenter._ui  = require("app.game.ddz.GameResultLayer")

-- 初始化
function GameResultPresenter:init(players)
    self._ui:getInstance():showResult(players)
end

-- 准备
function GameResultPresenter:sendPlayerReady()
    local gameStream = app.connMgr.getGameStream()

    if not app.game.GamePresenter then
        print("not in game")
        return
    end

    if app.game.GameData.getReady() then
        print("have ready")
        return
    end

    local hero = app.game.PlayerData.getHero()   
    local po = gameStream:get_packet_obj()
    local limit = app.game.GameConfig.getLimit()
    if hero and not hero:isLeave() and hero:getBalance() > limit and po then        
        print("send ready", hero:getSeat())
        local sessionid = app.data.UserData.getSession() or 222        
        po:writer_reset()
        po:write_int64(sessionid)
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_DDZ_READY_REQ)
    end    
end

function GameResultPresenter:playEffectByName(name)
    local soundPath = "game/ddz/sound/"
    local strRes = ""
    for alias, path in pairs(app.game.GameEnum.soundType) do
        if alias == name then
            if type(path) == "table" then
                local index = math.random(1, #path)
                strRes = path[index]
            else
                strRes = path
            end
        end
    end

    app.util.SoundUtils.playEffect(soundPath .. strRes)   
end

return GameResultPresenter