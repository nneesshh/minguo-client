
--[[
    @brief  游戏按钮UI基类
]]--

local GameBtnNode  = class("GameBtnNode", app.base.BaseNodeEx)
local GameEnum  = app.game.GameEnum

GameBtnNode.touchs = {
    "btn_banker_0",
    "btn_banker_1",
    "btn_banker_2",
    "btn_banker_3",
    "btn_banker_4",
    
    "btn_mult_5",
    "btn_mult_10",
    "btn_mult_15",
    "btn_mult_20",
    "btn_mult_25",
    
    "btn_cal_sure"    
}

function GameBtnNode:onTouch(sender, eventType)
    GameBtnNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if string.find(name, "btn_banker_") then             
            local index = string.split(name, "btn_banker_")[2]
            self._presenter:onTouchBankerMult(index)
        elseif string.find(name, "btn_mult_") then             
            local index = string.split(name, "btn_mult_")[2]
            self._presenter:onTouchMult(index)
        elseif name == "btn_cal_sure" then
            self._presenter:onTouchCalCard()        
        end
    end
end

-- 1抢庄 2加倍 3计算牌 4隐藏所有
function GameBtnNode:showTableBtn(type)
    if type == "banker" then
        self:showBankerPanel(true)
        self:showBetPanel(false)
        self:showCalPanel(false)
    elseif type == "bet" then
        self:showBankerPanel(false)
        self:showBetPanel(true)
        self:showCalPanel(false)
    elseif type == "cal" then	
        self:showBankerPanel(false)
        self:showBetPanel(false)
        self:showCalPanel(true)
    else
        self:showBankerPanel(false)
        self:showBetPanel(false)
        self:showCalPanel(false)
    end
end

-- 抢庄
function GameBtnNode:showBankerPanel(visible)
    local pnlbanker = self:seekChildByName("pnl_btn_select_banker")
    
    if visible then
        self._presenter:openSchedulerBankerClock(GameEnum.BANKER_TIME)
    else
        self._presenter:closeSchedulerBankerClock()
    end
   
    pnlbanker:setVisible(visible)
end

function GameBtnNode:showBankerTime(time)
    local txtTime = self:seekChildByName("txt_banker_time")
    
    txtTime:setString(time)
end

-- 加倍
function GameBtnNode:showBetPanel(visible)
    local pnlBet = self:seekChildByName("pnl_btn_mult")
    
    if visible then
        self._presenter:openSchedulerBetClock(GameEnum.BET_TIME)
    else
        self._presenter:closeSchedulerBetClock()
    end
    
    pnlBet:setVisible(visible)
end

function GameBtnNode:showBetTime(time)
    local txtTime = self:seekChildByName("txt_bet_time")

    txtTime:setString(time)
end

-- 计算牌型
function GameBtnNode:showCalPanel(visible)
    local pnlCal = self:seekChildByName("pnl_btn_cal")

    if visible then
        self._presenter:openSchedulerCalClock(GameEnum.CAL_TIME)
    else
        self._presenter:closeSchedulerCalClock()
    end
    
    pnlCal:setVisible(visible)
end

function GameBtnNode:showCalTime(time)
    local txtTime = self:seekChildByName("fnt_clock_num")

    txtTime:setString(time)
end

function GameBtnNode:showCalNum(index, num)
    local fntNum = self:seekChildByName("fnt_num_" .. index)
    fntNum:setString(num)
end

return GameBtnNode