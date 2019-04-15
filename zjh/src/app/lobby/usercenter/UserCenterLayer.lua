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

function UserCenterLayer:onTouch(sender, eventType)
    UserCenterLayer.super.onTouch(self, sender, eventType)
    if eventType == ccui.TouchEventType.ended then
        local name = sender:getName()
        if name == "btn_close" then
            self:exit()  
        elseif name == "btn_change_head" then
            self:exit() 
            app.lobby.usercenter.ChangeHeadPresenter:start()
        elseif name == "btn_change_password" then
                  
        end
    end
end

function UserCenterLayer:onClick(sender)
    UserCenterLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
        --self:exit()
    end
end

-- 账号
function UserCenterLayer:setUsername(name)
    local txtname = self:seekChildByName("name")
    txtname:setString(name)
end

-- 更新用户ID
function UserCenterLayer:setID(name)
    local ID = self:seekChildByName("id")
    ID:setString(name)
end

-- 更新昵称
function UserCenterLayer:setNickname(nickname)
    local txtNickname = self:seekChildByName("nickname")
    txtNickname:setString(nickname)
end

--更新财富
function UserCenterLayer:setBalance(balance)
    local txtBalance = self:seekChildByName("gold")
    txtBalance:setString(balance)
end

function UserCenterLayer:setAvatar(avator, gender)
    local imgHead = self:seekChildByName("img_head")
    local resPath = string.format("lobby/image/head/img_head_%d_%d.png", gender, avator)
    imgHead:loadTexture(resPath, ccui.TextureResType.plistType)
end

return UserCenterLayer