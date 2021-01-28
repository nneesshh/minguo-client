--[[
    @brief  记牌器
]]--
local app = cc.exports.gEnv.app
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

function GameRecordNode:setRecordVisible(visible)
    local imgRecord = self:seekChildByName("img_record") 

    if imgRecord then        
        imgRecord:setVisible(visible)
    end    
end

function GameRecordNode:showRecordList(list)
    local imgRecord = self:seekChildByName("img_record") 

    if not imgRecord then        
        return
    end    
    
	for i = 2, 16 do
        local txtNum = imgRecord:getChildByName("txt_" .. i)
        txtNum:setString(list[i])
	end
end

return GameRecordNode