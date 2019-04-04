
--[[
@brief  用户中心管理类
]]--

local UserCenterPresenter = class("UserCenterPresenter", app.base.BasePresenter)
-- UI
UserCenterPresenter._ui         = require("app.lobby.usercenter.UserCenterLayer")

function UserCenterPresenter:init()
    --self:createDispatcher()

    --self:initUIUserInfo()
end

----------------------------- 监听者 ------------------------------
function UserCenterPresenter:createDispatcher()
    
end

return UserCenterPresenter