--[[
@brief  提示框管理
]]
local TextHintPresenter = class("TextHintPresenter", app.base.BasePresenter)

TextHintPresenter._ui   = require("app.lobby.public.TextHintLayer")

return TextHintPresenter