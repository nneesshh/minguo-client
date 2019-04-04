--[[
@brief  设置管理类
]]

local SetPresenter = class("SetPresenter", app.base.BasePresenter)

-- UI
SetPresenter._ui = require("app.lobby.set.SetLayer")

function SetPresenter:init()
  
    
end

return SetPresenter