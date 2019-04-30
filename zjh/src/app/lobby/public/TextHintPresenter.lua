--[[
@brief  提示框管理
]]
local TextHintPresenter = class("TextHintPresenter", app.base.BasePresenter)

TextHintPresenter._ui   = requireLobby("app.lobby.public.TextHintLayer")

return TextHintPresenter