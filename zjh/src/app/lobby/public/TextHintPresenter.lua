--[[
@brief  提示框管理
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local TextHintPresenter = class("TextHintPresenter", app.base.BasePresenter)

TextHintPresenter._ui   = requireLobby("app.lobby.public.TextHintLayer")

return TextHintPresenter