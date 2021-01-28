
local app = cc.exports.gEnv.app
local SafeLayer = class("SafeLayer",app.base.BaseLayer)

SafeLayer.csbPath = "lobby/csb/safe.csb"

SafeLayer.touchs = {    
    "btn_close",
    "btn_put_clear",
    "btn_put_all",
    "btn_put_in",
    
    "btn_out_clear",
    "btn_out_all",
    "btn_out_in"  
}

SafeLayer.clicks = {
    "background",
    "btn_put",
    "btn_out"
}

SafeLayer.events = {
    "sld_put_gold_put",
    "sld_out_gold_put",
    "tf_put_enter_num",
    "tf_out_enter_num"
}

SafeLayer._TAB = {}
SafeLayer._TAB.BTN = {
    "btn_put",
    "btn_out"
}
SafeLayer._TAB.PNL = {
    ["btn_put"] = "panel_put",
    ["btn_out"] = "panel_out"
}

function SafeLayer:onTouch(sender, eventType)
    SafeLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_put_clear" then
            self:resetEnterNum()
        elseif name == "btn_out_clear" then 
            self:resetEnterNum()
        elseif name == "btn_put_all" then
            self:onTouchPutAll()
        elseif name == "btn_put_in" then
            self:onTouchPutIn()
        elseif name == "btn_out_all" then
            self:onTouchOutAll()
        elseif name == "btn_out_in" then
            self:onTouchOutIn()
        end
    end
end

function SafeLayer:onClick(sender)
    SafeLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_put" or name == "btn_out" then
        self:showTabPanel(name)    
    end
end

function SafeLayer:onEvent(sender,eventType)
    SafeLayer.super.onEvent(self,sender,eventType)
    local name = sender:getName()
    if name == "sld_put_gold_put" and eventType == ccui.SliderEventType.percentChanged then
        self:sliderPut()        
    elseif name == "sld_out_gold_put" and eventType == ccui.SliderEventType.percentChanged then
        self:sliderOut()
    elseif name == "tf_put_enter_num" and eventType == ccui.TextFiledEventType.detach_with_ime then
        self:sliderMovePut()
    elseif name == "tf_out_enter_num" and eventType == ccui.TextFiledEventType.detach_with_ime then
        self:sliderMoveOut()
    end
end

function SafeLayer:onCreate()
    local put = self:seekChildByName("tf_put_enter_num")
    local out = self:seekChildByName("tf_out_enter_num")
    
    put:setPlaceHolderColor(cc.c3b(255,255,255))
    out:setPlaceHolderColor(cc.c3b(255,255,255))
   
    put:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    out:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
  
    put:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    out:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)    
end

function SafeLayer:initUI()    
    self:showTabPanel("btn_put")   
end

function SafeLayer:resetEnterNum()
    local putenter = self:seekChildByName("tf_put_enter_num")
    putenter:setString(0)
    self:setPutPercent(0)
    local outenter = self:seekChildByName("tf_out_enter_num")
    outenter:setString(0)
    self:setOutPercent(0)
end

function SafeLayer:showTabPanel(btnName)
    for _,name in ipairs(self._TAB.BTN) do
        self:seekChildByName(name):setEnabled(name ~= btnName)
    end
    for name,pnl in pairs(self._TAB.PNL) do
        self:seekChildByName(pnl):setVisible(name == btnName)
    end
    
    self:initEffect(btnName)  
    self:resetEnterNum()  
end

function SafeLayer:sliderPut()
    local percent = self:seekChildByName("sld_put_gold_put"):getPercent()
    local max = self._presenter:getMaxGold("put")
    self:setPutNum(math.floor(max * percent / 100))
end

function SafeLayer:sliderOut()
    local percent = self:seekChildByName("sld_out_gold_put"):getPercent()
    local max = self._presenter:getMaxGold("out")
    self:setOutNum(math.floor(max * percent / 100))
end

function SafeLayer:sliderMovePut()
    local num = self:seekChildByName("tf_put_enter_num"):getString()
    local max = self._presenter:getMaxGold("put")
    
    if tonumber(num) then
        if tonumber(num) > max then
            self:setPutNum(max)            
            if max > 0 then
                self:setPutPercent(100)
            else
                self:setPutPercent(0)
            end            
        else
            self:setPutPercent(num / max * 100)                
        end
    else
        self:setPutPercent(0)
    end
end

function SafeLayer:sliderMoveOut()
    local num = self:seekChildByName("tf_out_enter_num"):getString()
    local max = self._presenter:getMaxGold("out")
    
    if tonumber(num) then
        if tonumber(num) > max then
            self:setOutNum(max)
            if max > 0 then
                self:setOutPercent(100)
            else
                self:setOutPercent(0)
            end
        else
            self:setOutPercent(num / max * 100)                
        end
    else
        self:setOutPercent(0)   
    end
end

function SafeLayer:onTouchPutAll()
    local max = self._presenter:getMaxGold("put")	
    self:setPutNum(max)            
    if max > 0 then
        self:setPutPercent(100)
    else
        self:setPutPercent(0)
    end   
end

function SafeLayer:onTouchOutAll()
    local max = self._presenter:getMaxGold("out")
    self:setOutNum(max)
    if max > 0 then
        self:setOutPercent(100)
    else
        self:setOutPercent(0)
    end
end

function SafeLayer:onTouchPutIn()
    local num = self:seekChildByName("tf_put_enter_num"):getString()
    local max = self._presenter:getMaxGold("put")
    if tonumber(num) and tonumber(num) >= 0 then
    	if tonumber(num) > max then
            self._presenter:reqPut(max)
        else        
            self._presenter:reqPut(tonumber(num))
    	end
    end
end

function SafeLayer:onTouchOutIn()
    local num = self:seekChildByName("tf_out_enter_num"):getString()
    local max = self._presenter:getMaxGold("out")
    if tonumber(num) and tonumber(num) >= 0 then
        if tonumber(num) > max then
            self._presenter:reqOut(max)
        else        
            self._presenter:reqOut(tonumber(num))
        end
    end
end

-- update ui
function SafeLayer:initEffect(name)
    local put = self:seekChildByName("node_put_arrow")  
    put:removeAllChildren()
    put:stopAllActions()
    local out = self:seekChildByName("node_out_arrow")
    out:removeAllChildren()
    out:stopAllActions()
    if name == "btn_put" then
        local effect = app.util.UIUtils.runEffect("lobby/effect","jiantou", 0, 0)
        put:addChild(effect)    
    elseif name == "btn_out" then
        local effect = app.util.UIUtils.runEffect("lobby/effect","jiantou", 0, 0)
        out:addChild(effect) 
    end
end

function SafeLayer:setBalance(balance)
    local put_gold = self:seekChildByName("txt_put_cur_gold")
    local out_gold = self:seekChildByName("txt_out_cur_gold")

    put_gold:setString(balance)
    out_gold:setString(balance)
end

function SafeLayer:setBank(bank)
    local put_bank = self:seekChildByName("txt_put_safe_gold")
    local out_bank = self:seekChildByName("txt_out_safe_gold")

    put_bank:setString(bank)
    out_bank:setString(bank)
end

function SafeLayer:setPutNum(num)
    local putenter = self:seekChildByName("tf_put_enter_num")
    putenter:setString(num)    
end

function SafeLayer:setOutNum(num)    
    local outenter = self:seekChildByName("tf_out_enter_num")
    outenter:setString(num)
end

function SafeLayer:setPutPercent(per)
    local sld = self:seekChildByName("sld_put_gold_put")
    sld:setPercent(per)
end

function SafeLayer:setOutPercent(per)
    local sld = self:seekChildByName("sld_out_gold_put")
    sld:setPercent(per)
end

return SafeLayer