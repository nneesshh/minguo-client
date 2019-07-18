--[[
@brief  公告管理类
]]

local app = app

local NoticePresenter = class("NoticePresenter",app.base.BasePresenter)
NoticePresenter._ui = requireLobby("app.lobby.notice.NoticeLayer")

local notice = {
    NOTICE = 1,
    READ   = 2,
    CHEAT    = 3
}

function NoticePresenter:init()   
    self:sendGameNews(1)
    self:sendGameNews(2)
    self:sendGameNews(3)
end

function NoticePresenter:sendGameNews(type)
    local gameStream = app.connMgr.getGameStream()
    
    local sessionid = app.data.UserData.getSession() or 222
    local po = gameUpconn:get_packet_obj()
    if po == nil then return end   

    po:writer_reset()
    po:write_byte(type) 
    gameUpconn:send_packet(sessionid, zjh_defs.MsgId.MSGID_GAME_NEWS_REQ)          
end

function NoticePresenter:onNewsData(data)
    if data.type == notice.NOTICE then
        self._ui:getInstance():updateNotice(data.text)
    elseif data.type == notice.READ then
        self._ui:getInstance():updateRead(data.text)
    elseif data.type == notice.CHEAT then
        self._ui:getInstance():updateCheat(data.text)
    end
end

return NoticePresenter