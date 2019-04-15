
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
    self:setDisableByIndex(0)
end

function GameBtnNode:setSelected(flag)
    self:seekChildByName("cbx_gdd"):setSelected(flag)
end

function GameBtnNode:isSelected()
    return self:seekChildByName("cbx_gdd"):isSelected()
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

function GameBtnNode:showBetNode(visible)
    local nodeTableBtn = self:seekChildByName("node_game_btn")
    nodeTableBtn:setVisible(visible)
    self:setSelected(false)
end
--[[
    自己回合
    1.全部可点击
    2.比牌不可
    3.看牌不可
    4.比牌看牌不可
]]--

-- name1:可点击  name2:不可点击
function GameBtnNode:setEnableByName(name1, name2)
    local btnqp = self:seekChildByName("btn_qp")
    local btnbp = self:seekChildByName("btn_bp")
    local btnkp = self:seekChildByName("btn_kp")
    local btnon = self:seekChildByName("btn_jz_on")
    local btnoff = self:seekChildByName("btn_jz_off")
    local btngz = self:seekChildByName("btn_gz")
    local expand = self:seekChildByName("img_bet_back")
    btnon:setVisible(true)
    btnoff:setVisible(false)
    expand:setScale(0)
    
    for i, name in ipairs(name1) do
        if name == "qp" then
            btnqp:setEnabled(true)
    	elseif name == "bp" then
            btnbp:setEnabled(true)
    	elseif name == "kp" then
            btnkp:setEnabled(true)
        elseif name == "jz" then
            btnon:setEnabled(true)
        elseif name == "gz" then 
            btngz:setEnabled(true)       
    	end
    end
    
    for i, name in ipairs(name2) do
        if name == "qp" then
            btnqp:setEnabled(false)
        elseif name == "bp" then
            btnbp:setEnabled(false)
        elseif name == "kp" then
            btnkp:setEnabled(false)
        elseif name == "jz" then
            btnon:setEnabled(false)
        elseif name == "gz" then 
            btngz:setEnabled(false)       
        end
    end 
end

-- index之后的筹码可点击
function GameBtnNode:setDisableByIndex(index, flag)
    for i=1,6 do
        local btn = self:seekChildByName("btn_bet_" .. i)
        local img = btn:getChildByName("img_disable")
        btn:setEnabled(true)
        img:setVisible(false)
    end
    
    -- 全压
    if flag then
        local btn = self:seekChildByName("btn_bet_" .. 6)
        local img = btn:getChildByName("img_disable")
        btn:setEnabled(false)
        img:setVisible(true)
    end 
    
    if index then
        index = math.ceil(index)
        if index < 1 or index > 6 then
            return
        end      	
        for i=1,index do
            local btn = self:seekChildByName("btn_bet_" .. i)
            local img = btn:getChildByName("img_disable")
            btn:setEnabled(false)
            img:setVisible(true)
        end  
    end
end

return GameBtnNode