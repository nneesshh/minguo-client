--[[
@brief  邮件
]]

local MailDetailPresenter = class("MailDetailPresenter",app.base.BasePresenter)
MailDetailPresenter._ui = requireLobby("app.lobby.mail.MailDetailLayer")

function MailDetailPresenter:init(mail)
    self._ui:getInstance():showMailDetail(mail)
end

return MailDetailPresenter