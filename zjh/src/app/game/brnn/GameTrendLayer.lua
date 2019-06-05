--[[
    @brief  游戏结果趋势ui
]]--

local GameTrendLayer    = class("GameTrendLayer", app.base.BaseLayer)

GameTrendLayer.csbPath = "game/brnn/csb/trend.csb"

GameTrendLayer.touchs = {    
    "btn_close",
}

function GameTrendLayer:onTouch(sender, eventType)
    GameTrendLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then            
            self:exit()
        end
    end
end

function GameTrendLayer:initUI()
    app.util.UIUtils.openWindow(self:seekChildByName("container"))
end

function GameTrendLayer:updateTrend(list)
    if not list then return end
    
    local pnl = self:seekChildByName("pnl_trend")
    pnl:removeAllChildren() 

    local item = self:seekChildByName("img_result")
    local iw = 92
    for i, var in ipairs(list) do
    	for j, v in ipairs(var) do
            local cit = item:clone()
            local res = string.format("game/brnn/image/img_%d.png", v)   
            cit:ignoreContentAdaptWithSize(true)    
            cit:loadTexture(res, ccui.TextureResType.plistType)   	            
            cit:setPosition((i-1)*iw+iw/2,( 4-j)*iw+iw/2)
            pnl:addChild(cit)     
    	end
    end           
end

return GameTrendLayer