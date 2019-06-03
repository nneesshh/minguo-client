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

HelpLayer.svws = {
    "svw_1",
    "svw_2",
    "svw_3",
    "svw_4",
    "svw_5"
}

function HelpLayer:onCreate()
    for i=1, #self.svws do
        self:seekChildByName("svw_" .. i):setScrollBarEnabled(false)    
    end    
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

function HelpLayer:init(gameid)
	self:showOnlySvw(gameid)
end

function HelpLayer:showOnlySvw(gameid)
    for i, var in ipairs(self.svws) do
        local id = tonumber(string.split(var, "svw_")[2]) 
        self:seekChildByName(var):setVisible(id == gameid)
    end    
end

return HelpLayer