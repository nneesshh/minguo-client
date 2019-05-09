--[[
@brief  公告管理类
]]

local NoticePresenter = class("NoticePresenter",app.base.BasePresenter)
NoticePresenter._ui = requireLobby("app.lobby.notice.NoticeLayer")

return NoticePresenter