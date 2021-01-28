
--[[
@brief  帮助管理类
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local HelpPresenter = class("HelpPresenter", app.base.BasePresenter)

-- UI
HelpPresenter._ui = requireLobby("app.lobby.help.HelpLayer")

return HelpPresenter