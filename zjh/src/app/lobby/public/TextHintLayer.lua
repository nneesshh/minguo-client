--[[
@brief  公共提示框
]]

local TextHintLayer = class("TextHintLayer", app.base.BaseLayer)

TextHintLayer.csbPath = "lobby/csb/hint2.csb"

function TextHintLayer:initUI(text, time, pos)
    time = time or 1
    pos = pos or cc.p(667, 375)
    local hint = self:seekChildByName("img_hint_back")
    local father = hint:getParent()
    local node = hint:clone()
    local text = node:getChildByName("text_hint")
    text:setText(text)
    node:setPosition(pos)
    node:setVisible(true)
    father:addChild(node)
    node:runAction(cc.Sequence:create(
        cc.FadeIn:create(0.5),                       
        cc.FadeOut:create(0.5),
        cc.CallFunc:create(function()
            node:removeFromParent(true)
        end)
    ))
end

return TextHintLayer