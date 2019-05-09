

local ShopLayer = class("ShopLayer",app.base.BaseLayer)

ShopLayer.csbPath = "lobby/csb/shop.csb"

ShopLayer.touchs = {    
    "btn_close",
    "btn_zfb_rmb3",
    "btn_zfb_rmb10",
    "btn_zfb_rmb30",
    "btn_zfb_rmb50",
    "btn_zfb_rmb100",
    "btn_zfb_rmb500",
    "btn_wx_rmb3",
    "btn_wx_rmb10",
    "btn_wx_rmb30",
    "btn_wx_rmb50",
    "btn_wx_rmb100",
    "btn_wx_rmb500",  
}

ShopLayer.clicks = {
    "background",
    "btn_zfb",
    "btn_wx"
}

ShopLayer._TAB = {}
ShopLayer._TAB.BTN = {
    "btn_zfb",
    "btn_wx"
}
ShopLayer._TAB.PNL = {
    ["btn_zfb"] = "panl_goods_zfb",
    ["btn_wx"]  = "panl_goods_wx"
}

function ShopLayer:onTouch(sender, eventType)
    ShopLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif string.find(name, "btn_zfb_rmb") then  
            local index = string.split(name, "btn_zfb_rmb")[2]
            self._presenter:dealTxtHintStart("正在支付宝购买" .. index .. "rmb金币") 
        elseif string.find(name, "btn_wx_rmb") then   
            local index = string.split(name, "btn_wx_rmb")[2]
            self._presenter:dealTxtHintStart("正在微信购买" .. index .. "rmb金币") 
        end
    end
end

function ShopLayer:onClick(sender)
    ShopLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_zfb" then
        self:onTouchZFB()    
    elseif name == "btn_wx" then
        self:onTouchWX()
    end
end

function ShopLayer:initData()
end

function ShopLayer:initUI()    
    self:onTouchZFB()    
end


function ShopLayer:showTabPanel(btnName)
    for _,name in ipairs(self._TAB.BTN) do
        self:seekChildByName(name):setEnabled(name ~= btnName)
    end
    for name,pnl in pairs(self._TAB.PNL) do
        self:seekChildByName(pnl):setVisible(name == btnName)
    end
end

function ShopLayer:onTouchZFB()
    self:showTabPanel("btn_zfb")
end

function ShopLayer:onTouchWX()
    self:showTabPanel("btn_wx")
end

return ShopLayer