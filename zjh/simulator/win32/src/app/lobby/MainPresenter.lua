--[[
@brief  大厅管理类
@by     斯雪峰
]]

local MainPresenter   = class("MainPresenter", app.base.BasePresenter)
local ToolUtils       = app.util.ToolUtils

-- UI
MainPresenter._ui  = require("app.lobby.MainScene")

function MainPresenter:ctor()
    MainPresenter.super.ctor(self)

    self:createDispatcher()
end

function MainPresenter:init(gameid, roomMode)
    self:initScene(gameid, roomMode)
end

function MainPresenter:createDispatcher()
   
end

-- 处理进入场景
function MainPresenter:onEnter()
    if true then
        app.lobby.login.LoginPresenter:getInstance():start()
    end
end

function MainPresenter:initScene(gameid, roomMode)
 
end

return MainPresenter