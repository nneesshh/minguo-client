
--[[
@brief  帮助管理类
]]

local HelpPresenter = class("HelpPresenter", app.base.BasePresenter)

-- UI
HelpPresenter._ui = require("app.lobby.help.HelpLayer")

return HelpPresenter