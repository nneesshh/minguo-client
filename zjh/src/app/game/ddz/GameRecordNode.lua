--[[
    @brief  记牌器
]]--

local GameRecordNode  = class("GameRecordNode", app.base.BaseNodeEx)

GameRecordNode.touchs = {
    "btn_record",  
}

function GameRecordNode:onTouch(sender, eventType)
    GameRecordNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then  
        if name == "btn_record" then
           self:showRecord()   
        end
    end
end

function GameRecordNode:showRecord()   
    local imgRecord = self:seekChildByName("img_record") 
    
    if imgRecord then        
        imgRecord:setVisible(not imgRecord:isVisible())
    end    
end

return GameRecordNode