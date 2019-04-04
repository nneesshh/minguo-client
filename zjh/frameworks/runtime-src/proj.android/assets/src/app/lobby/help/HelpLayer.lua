--[[
@brief  帮助Layer
]]

local HelpLayer = class("HelpLayer", app.base.BaseLayer)

HelpLayer.csbPath = "lobby/csb/help.csb"
HelpLayer.clicks = {
    "background",
}
HelpLayer.touchs = {
    "btn_close",
}

function HelpLayer:onCreate()
    self:seekChildByName("svw_psz"):setScrollBarEnabled(false)    
end

function HelpLayer:onClick(sender)
    HelpLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
        self:exit()
    end
end

function HelpLayer:onTouch(sender, eventType)
    HelpLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()                     
        end
    end
end

return HelpLayer