--[[
@brief  主场景
]]

local scheduler = cc.Director:getInstance():getScheduler()

local MainScene = class("MainScene", app.base.BaseScene)

-- csb·��
MainScene.csbPath = "csb/lobby.csb"

MainScene.clicks = {
    "background"
}

MainScene.touchs = {
    "btn_head_info",
    "btn_gold_add",
    "btn_notice",
    "btn_mail",
    "btn_set",
    "btn_qznn",
    "btn_psz",
    "btn_brnn",
    "btn_lhd",
    "btn_ddz",
    "btn_jdnn",
    "btn_rank",
    "btn_safe",
    "btn_shop"
}

function MainScene:onClick(sender)
    MainScene.super.onClick(self, sender)
    local name = sender:getName()
    
end

function MainScene:onTouch(sender, eventType)
    MainScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        print("button name is:",name) 
    end
end

function MainScene:initUI(gameID, roomMode)
    
end

function MainScene:onEnter()
    self._presenter:onEnter()
end

return MainScene
