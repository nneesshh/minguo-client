--[[
@brief  SetLayer 设置界面
@by     鲁诗瀚
]]

local SetLayer = class("SetLayer", app.base.BaseLayer)

SetLayer.csbPath = "lobby/csb/set.csb"

SetLayer.clicks = {
    "background",
}

SetLayer.touchs = {
    "btn_close",
    "btn_on",
    "btn_off",
    "btn_switch_account"
}

SetLayer.events = {
    "sld_music",
    "sld_effect",   
}

function SetLayer:onClick(sender)
    SetLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
    	self:exit()
    end
    print("name is", name)
end

function SetLayer:onTouch(sender, eventType)
    SetLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        end
        print("name is", name)
    end
end

function SetLayer:onEvent(sender, eventType)
    local name = sender:getName()
    print("name is", name)
end

return SetLayer