
--[[
    @brief  游戏按钮UI基类
]]--


local GameBtnNode  = class("GameBtnNode", app.base.BaseNodeEx)

GameBtnNode.touchs = {
    "btn_qp",
    "btn_bp",
    "btn_kp",
    "btn_jz_on",
    "btn_jz_off",
    "btn_gz",
    "btn_bet_1",
    "btn_bet_2",
    "btn_bet_3",
    "btn_bet_4",
    "btn_bet_5",
    "btn_bet_6"    
}

GameBtnNode.events = {
    "cbx_gdd",
}

function GameBtnNode:onTouch(sender, eventType)
    GameBtnNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_qp" then
            self._presenter:onTouchBtnQipai()
        elseif name == "btn_bp" then
            self._presenter:onTouchBtnBipai()
        elseif name == "btn_kp" then 
            self._presenter:onTouchBtnKanpai()
        elseif name == "btn_jz_on" then 
            self:showExpand(true)
       elseif name == "btn_jz_off" then
            self:showExpand(false)
        elseif name == "btn_gz" then 
            self._presenter:onTouchBtnGenzhu()
        elseif string.find(name, "btn_bet_") then             
            local index = string.split(name, "btn_bet_")[2]
            self._presenter:onTouchBtnBetmult(tonumber(index))
        end
    end
end

function GameBtnNode:onEvent(sender, eventType)
    local name = sender:getName()
    if name == "cbx_gdd" then
        if eventType == ccui.CheckBoxEventType.selected then  
            self:setSelected(true)          
            self._presenter:onEventCbxGendaodi(true)            
        elseif eventType == ccui.CheckBoxEventType.unselected then            
            self:setSelected(false)
            self._presenter:onEventCbxGendaodi(false)            
        end
    end
end

function GameBtnNode:initUI(...)
    local base = app.game.GameConfig.getBase()
    for index=1, 5 do
        local btn = self:seekChildByName("btn_bet_" .. index)
        local txt = btn:getChildByName("txt_num")

        txt:setString(index*2*base)
    end
    self:setDisableByIndex(1)
end

function GameBtnNode:showExpand(flag)
    flag = flag or false
    local expand = self:seekChildByName("img_bet_back")
    local btnon = self:seekChildByName("btn_jz_on")
    local btnoff = self:seekChildByName("btn_jz_off")
    if flag then
        btnon:setVisible(false)
        btnoff:setVisible(true)
        expand:runAction(cc.ScaleTo:create(0.2, 1))
    else
        if btnon:isVisible() then
            return
        end
        btnon:setVisible(true)
        btnoff:setVisible(false)
        expand:runAction(cc.ScaleTo:create(0.2, 0))
    end
end

function GameBtnNode:showBetBtns(visible)
    local nodeTableBtn = self:seekChildByName("node_game_btn")
    nodeTableBtn:setVisible(visible)
    
    if visible then
    	self:showBetBtnEnable(false)
    end
end

function GameBtnNode:showBetBtnEnable(enable,round)
    local btn_qp = self:seekChildByName("btn_qp")
    local btnbp = self:seekChildByName("btn_bp")
    local btnon = self:seekChildByName("btn_jz_on")
    local btnoff = self:seekChildByName("btn_jz_off")
    local btngz = self:seekChildByName("btn_gz")
    
    btn_qp:setEnabled(enable)
    btnbp:setEnabled(enable)
    btnon:setEnabled(enable)
    btnon:setEnabled(enable)
    btngz:setEnabled(enable)
    
    local expand = self:seekChildByName("img_bet_back")
    btnon:setVisible(true)
    btnoff:setVisible(false)
    expand:setScale(0)
    
    if enable and round <= 1 then
        btnbp:setEnabled(false)
    end    
end

function GameBtnNode:setSelected(flag)
    local checkboxGdd = self:seekChildByName("cbx_gdd")
    checkboxGdd:setSelected(flag)
end

function GameBtnNode:isSelected()
    local checkboxGdd = self:seekChildByName("cbx_gdd")
    return checkboxGdd:isSelected()
end

-- index之后的按钮可点击
function GameBtnNode:setDisableByIndex(index)
    for i=1,6 do
        local btn = self:seekChildByName("btn_bet_" .. i)
        local img = btn:getChildByName("img_disable")
        btn:setEnabled(true)
        img:setVisible(false)
    end
    
    if index then
        index = math.ceil(index)
        if index < 1 or index > 6 then
            index = 1
        end      	
        for i=1,index-1 do
            local btn = self:seekChildByName("btn_bet_" .. i)
            local img = btn:getChildByName("img_disable")
            btn:setEnabled(false)
            img:setVisible(true)
        end  
    end 
end

return GameBtnNode