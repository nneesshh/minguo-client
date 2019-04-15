--[[
@brief  公共提示框
]]
local ToolUtils = app.util.ToolUtils

local HintLayer = class("HintLayer", app.base.BaseLayer)

HintLayer.csbPath = "lobby/csb/hint.csb"

HintLayer.clicks = {
    "background",
}

HintLayer.touchs = {
    "btn_close",
    "btn_hint_ok_0",
    "btn_hint_ok_1",
    "btn_hint_cancel_1"
}

-- 定义节点数量(对应不同场合的弹框)
-- 0默认情况,只有确定; 1左去充值右去银行
local minType = 0
local maxType = 1

function HintLayer:initUI(text, type)
    for i = minType,maxType do
        local node = self:seekChildByName("node_btn_"..i)
        if i == type then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
    local content = self:seekChildByName("txt_hint")
    content:setString(ToolUtils.getLineBreakText(text, 42))
end

function HintLayer:onClick(sender)
    HintLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
       -- self._presenter:notifyCallBack(false)
    end
end

function HintLayer:onTouch(sender, eventType)
    HintLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if string.find(name, "btn_hint_cancel_") or name == "btn_close" then
            self._presenter:notifyCallBack(false)
        elseif string.find(name, "btn_hint_ok_") then
            self._presenter:notifyCallBack(true)
        end
    end
end

return HintLayer