--[[
@brief 个人中心界面
]]

local UserCenterLayer               = class("UserCenterLayer", app.base.BaseLayer)

UserCenterLayer.csbPath = "lobby/csb/usercenter.csb"
UserCenterLayer.touchs = {
    "btn_close",
    "btn_change_head",
    "btn_change_password",    
}
UserCenterLayer.clicks = {
    "background",
}

function UserCenterLayer:onCreate()

end

function UserCenterLayer:initData()

end

function UserCenterLayer:initUI()
    
end

function UserCenterLayer:onTouch(sender, eventType)
    UserCenterLayer.super.onTouch(self, sender, eventType)
    if eventType == ccui.TouchEventType.ended then
        local name = sender:getName()
        if name == "btn_close" then
            self:exit()    
        end
    end
end

function UserCenterLayer:onClick(sender)
    UserCenterLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
        self:exit()
    end
end

return UserCenterLayer