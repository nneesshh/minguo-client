--[[
@brief 修改头像界面

]]
local ChangeHeadLayer   = class("ChangeHeadLayer", app.base.BaseLayer)

ChangeHeadLayer.csbPath = "lobby/csb/head.csb"

ChangeHeadLayer.touchs = {
    "btn_close",
    "btn_sure",
    "head_0_0",
    "head_0_1",
    "head_0_2",
    "head_0_3",
    "head_0_4",
    "head_1_0",
    "head_1_1",
    "head_1_2",
    "head_1_3",
    "head_1_4",
}

function ChangeHeadLayer:onTouch(sender, eventType)
    ChangeHeadLayer.super.onTouch(self, sender, eventType)
    if eventType == ccui.TouchEventType.ended then
        local name = sender:getName()
        if name == "btn_close" then
            self:onTouchClose()
        elseif name == "btn_sure" then
            self:onTouchBtnOK()
        elseif string.find(name, "head_") then 
            local data = string.split(name, "_")
            self:selected(tonumber(data[2]), tonumber(data[3]))   
        end
    end
end

function ChangeHeadLayer:init()
    self.gender = 0
    self.avatar = 0
end

function ChangeHeadLayer:onTouchClose()
    self:exit()         
    app.lobby.usercenter.UserCenterPresenter:getInstance():start()
end

function ChangeHeadLayer:onTouchBtnOK()
    self._presenter:reqChangeHead(self.gender, self.avatar)
end

function ChangeHeadLayer:selected(gender, avatar)
    local pnl = self:seekChildByName("png_head") 
    local childs = pnl:getChildren()
    for i,btn in ipairs(childs) do
        if string.find(btn:getName(), "head_") then
        	btn:setEnabled(true)
        end       
    end

    local btnSelect = self:seekChildByName(string.format("head_%d_%d", gender, avatar))
    local imgSelect = self:seekChildByName("img_select")
    if btnSelect and imgSelect then
    	btnSelect:setEnabled(false)
        imgSelect:setPosition(btnSelect:getPosition())
    end 
    
    self.gender = gender
    self.avatar = avatar
end

return ChangeHeadLayer
