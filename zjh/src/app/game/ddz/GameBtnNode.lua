--[[
    @brief  游戏按钮UI基类
]]--

local GameBtnNode    = class("GameBtnNode", app.base.BaseNodeEx)

GameBtnNode.touchs = {
    "btn_call_0",
    "btn_call_1",
    "btn_call_2",
    "btn_call_3",
    "btn_mult_0",
    "btn_mult_1",
    "btn_banker_play_ming",
    "btn_banker_play_hint",
    "btn_banker_play_out",
    "btn_first_play_hint",
    "btn_first_play_out",
    "btn_play_cancel",
    "btn_play_hint",
    "btn_play_out",
    "btn_play_cancel"    
}

function GameBtnNode:onTouch(sender, eventType)
    GameBtnNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_banker_play_ming" then
            self:onTouchBtnBankerMing()
        elseif name == "btn_banker_play_hint" then
            self:onTouchBtnBankerHint()
        elseif name == "btn_banker_play_out" then
            self:onTouchBtnBankerOut()
            
        elseif name == "btn_first_play_hint" then
            self:onTouchBtnFirstHint()
        elseif name == "btn_first_play_out" then
            self:onTouchBtnFirstOut()
            
        elseif name == "btn_play_hint" then
            self:onTouchBtnPlayHint()
        elseif name == "btn_play_out" then
            self:onTouchBtnPlayOut()
        elseif name == "btn_play_cancel" then
            self:onTouchBtPlayCancel()
            
        elseif string.find(name, "btn_call_") then             
            local index = string.split(name, "btn_call_")[2]
            self:onTouchBtnCall(index)
            
        elseif string.find(name, "btn_mult_") then             
            local index = string.split(name, "btn_mult_")[2]
            self:onTouchBtnMult(index)
        end
    end
end

----------------------------------------onTouchEvent----------------------------------------
function GameBtnNode:onTouchBtnBankerMing()
    print("onTouchBtnBankerMing")
   
end

function GameBtnNode:onTouchBtnBankerHint()
    print("onTouchBtnBankerHint")
    
end

function GameBtnNode:onTouchBtnBankerOut()
    print("onTouchBtnBankerOut")
   
end

function GameBtnNode:onTouchBtnFirstHint()
    print("onTouchBtnFirstHint")
    
end

function GameBtnNode:onTouchBtnFirstOut()
    print("onTouchBtnFirstOut")    
end

function GameBtnNode:onTouchBtnPlayHint()
    print("onTouchBtnPlayHint")
end

function GameBtnNode:onTouchBtnPlayOut()
    print("onTouchBtnPlayOut")
end

function GameBtnNode:onTouchBtPlayCancel()
    print("onTouchBtPlayCancel")
end

function GameBtnNode:onTouchBtnCall(index)
    print("onTouchBtnOutHint",index)

end

function GameBtnNode:onTouchBtnMult(index)
    print("onTouchBtnMult",index)    
end

--------------------------------TableBtn---------------------------------------------
function GameBtnNode:showCallPanl(visible)
    local nodeTableBtn = self:seekChildByName("pnl_btn_call")
    
    if nodeTableBtn then
        nodeTableBtn:setVisible(visible)
    end   
end

function GameBtnNode:setCallBtnEnable(index, enable)
    local nodeCallBtn = self:seekChildByName("btn_call_" .. index)
    
    if nodeCallBtn then
        nodeCallBtn:setEnabled(enable)
    end    
end

function GameBtnNode:showMultPanl(visible)
    local nodeTableBtn = self:seekChildByName("pnl_btn_mult")

    if nodeTableBtn then
        nodeTableBtn:setVisible(visible)
    end  
end

function GameBtnNode:showBankerPlayPanl(visible)
    local nodeTableBtn = self:seekChildByName("pnl_btn_banker_play")

    if nodeTableBtn then
        nodeTableBtn:setVisible(visible)
    end
end

function GameBtnNode:setBankerPlayOutEnable(enable)
    local nodeTableBtn = self:seekChildByName("btn_banker_play_out")

    if nodeTableBtn then
        nodeTableBtn:setEnabled(enable)
    end
end

function GameBtnNode:showFirstPlayPanl(visible)
    local nodeTableBtn = self:seekChildByName("pnl_btn_first_play")

    if nodeTableBtn then
        nodeTableBtn:setVisible(visible)
    end
end

function GameBtnNode:setFirstPlayOutEnable(enable)
    local nodeTableBtn = self:seekChildByName("btn_first_play_out")

    if nodeTableBtn then
        nodeTableBtn:setEnabled(enable)
    end
end

function GameBtnNode:showPlayPanl(visible)
    local nodeTableBtn = self:seekChildByName("pnl_btn_play")

    if nodeTableBtn then
        nodeTableBtn:setVisible(visible)
    end
end

function GameBtnNode:setPlayOutEnable(enable)
    local nodeTableBtn = self:seekChildByName("btn_play_out")

    if nodeTableBtn then
        nodeTableBtn:setEnabled(enable)
    end
end

function GameBtnNode:showCantOutPanl(visible)
    local nodeTableBtn = self:seekChildByName("pnl_btn_cant")

    if nodeTableBtn then
        nodeTableBtn:setVisible(visible)
    end
end

function GameBtnNode:showTableBtn(type)
    self:showCallPanl(type == "call")
    self:showMultPanl(type == "mult")
    self:showBankerPlayPanl(type == "bankerplay")
    self:showFirstPlayPanl(type == "firstplay")
    self:showPlayPanl(type == "play")
    self:showCantOutPanl(type == "cant")
end

function GameBtnNode:setOutBtnEnable(enable)
    self:setBankerPlayOutEnable(enable)
    self:setFirstPlayOutEnable(enable)
    self:setPlayOutEnable(enable)    
end

return GameBtnNode