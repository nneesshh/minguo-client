
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

function GameBtnNode:initData()
    self._clockProgress     = nil
end

function GameBtnNode:initUI()
	self:initClockCircle()
end

function GameBtnNode:initClockCircle()
    local spLight = self:seekChildByName("img_load")
    if spLight == nil then
        return
    end
    self._clockProgress = cc.ProgressTimer:create(spLight)
    self._clockProgress:setType(0)
    self._clockProgress:setPosition(cc.p(spLight:getPosition()))
    self._clockProgress:setReverseDirection(true)
    spLight:setVisible(false)

    local pnlClockCircle = self:seekChildByName("pnl_clock")
    pnlClockCircle:addChild(self._clockProgress)
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
        self._presenter:playEffectByName("bankermult") 
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
        self._presenter:playEffectByName("mult") 
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
        for i=1, 4 do        
            self:showCalNum(i, " ")
        end
        self._presenter:openSchedulerCalClock(GameEnum.CAL_TIME)
    else
        self._presenter:closeSchedulerCalClock()
    end
    
    pnlCal:setVisible(visible)
end

function GameBtnNode:showCalTime(strTime, time)
    local txtTime = self:seekChildByName("fnt_clock_num")
    txtTime:setString(strTime)
    
    self._clockProgress:setPercentage(time / GameEnum.CAL_TIME * 100)
end

function GameBtnNode:showCalNum(index, num)
    local fntNum = self:seekChildByName("fnt_num_" .. index)
    fntNum:setString(num)
end

return GameBtnNode