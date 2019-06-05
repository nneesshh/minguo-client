--[[
    @brief  游戏按钮UI基类
]]--

local GameBtnNode  = class("GameBtnNode", app.base.BaseNodeEx)

GameBtnNode.touchs = {
    "btn_bet_1",
    "btn_bet_2",
    "btn_bet_3",
    "btn_bet_4",
    "btn_bet_5",
    "btn_bet_6" 
}

function GameBtnNode:onTouch(sender, eventType)
    GameBtnNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if string.find(name, "btn_bet_") then             
            local bet = string.split(name, "btn_bet_")[2]
            --self._presenter:onTouchBet(tonumber(bet))  
            print("bet",bet)        
        end
    end
end

function GameBtnNode:setBetBtnEnable(i, enable)
    local btn = self:seekChildByName("btn_bet_" .. i) 
    if btn then
        btn:setEnabled(enable)       
    end
end

function GameBtnNode:setBetBtnLight(index)
	for i=1, 6 do
        local btn = self:seekChildByName("btn_bet_" .. i) 
        local light = btn:getChildByName("img_light")
        light:setVisible(i == index)
	end	
end

function GameBtnNode:setTxtHint(visible)
    local txt = self:seekChildByName("img_balance_less") 
    if txt then
        txt:setVisible(visible)       
    end
end

return GameBtnNode