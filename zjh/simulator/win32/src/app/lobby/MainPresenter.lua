--[[
@brief  主场景管理类
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

function MainPresenter:onEnter()
    if true then
        app.lobby.login.LoginPresenter:getInstance():start()
    end
end

function MainPresenter:initScene(gameid, roomMode)
 
end

return MainPresenter