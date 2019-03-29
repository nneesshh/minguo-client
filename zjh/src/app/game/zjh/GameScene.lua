--[[
@brief  游戏主场景UI基类
]]
local GameScene = class("GameScene", app.base.BaseScene)

-- csb路径
GameScene.csbPath = "game/zjh/csb/gamescene.csb"

GameScene.touchs = {
    "btn_exit",
    
}

GameScene.clicks = {
    "btn_menu",
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_exit" then
                   
        end
    end
end

function GameScene:onClick(sender)
    GameScene.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_menu" then
        self:rotateMneu()
    end
end

function GameScene:rotateMneu()
    local btnMenu = self:seekChildByName("btn_menu")    
    local act = cc.RotateBy:create(0.1, 180)
    act:setTag(1)
    if btnMenu:getActionByTag(1) then
    	return
    end    
    btnMenu:runAction(act)
end


return GameScene