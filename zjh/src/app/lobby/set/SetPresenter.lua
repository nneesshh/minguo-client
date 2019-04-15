--[[
@brief  设置管理类
]]

local SetPresenter = class("SetPresenter", app.base.BasePresenter)

-- UI
SetPresenter._ui = require("app.lobby.set.SetLayer")

function SetPresenter:init(name)
  if name == "lobby" then
        self._ui:getInstance():initSet(true)
  elseif name == "game" then
        self._ui:getInstance():initSet(false)
  end
      
end

return SetPresenter