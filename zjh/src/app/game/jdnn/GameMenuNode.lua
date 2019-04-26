
--[[
    @brief  游戏右上角菜单UI
]]--
local GameMenuNode  = class("GameMenuNode", app.base.BaseNodeEx)

GameMenuNode.touchs = {
    "btn_set",
    "btn_change",
    "btn_help"    
}

GameMenuNode.clicks = {
    "btn_menu",
}

function GameMenuNode:onTouch(sender, eventType)
    GameMenuNode.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then  
        if name == "btn_set" then
            self:onTouchBtnGameSet()
        elseif name == "btn_change" then
            self:onTouchBtnChange()
        elseif name == "btn_help" then
            self:onTouchBtnHelp()
        end
    end
end

function GameMenuNode:onClick(sender)
    GameMenuNode.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_menu" then              
        self:onTouchBtnGameMenu() 
    end  
end

function GameMenuNode:init()
    local imghelp = self:seekChildByName("img_nn_help") 
    imghelp:setVisible(false)
end

function GameMenuNode:onTouchBtnGameMenu()
    self:rotateMneu()    
    self:showMenu()
end

function GameMenuNode:onTouchBtnGameSet()   
    app.lobby.set.SetPresenter:getInstance():start(false)
end

function GameMenuNode:onTouchBtnChange() 
    self._presenter:sendChangeTable()
end

function GameMenuNode:onTouchBtnHelp()
    local imghelp = self:seekChildByName("img_nn_help") 
    
    imghelp:setVisible(not imghelp:isVisible())
end

-- 旋转菜单
function GameMenuNode:rotateMneu()
    local btnMenu = self:seekChildByName("btn_menu")    
    local act = cc.RotateBy:create(0.13, 180)
    act:setTag(1)
    if btnMenu:getActionByTag(1) then
        return
    end    
    
    btnMenu:runAction(act)
end

-- 显示菜单
function GameMenuNode:showMenu()   
    local imgExpand = self:seekChildByName("img_menu_expand") 
    local btnMenu = self:seekChildByName("btn_menu") 
    local angle = btnMenu:getRotation()
    local x,y = math.modf(angle/360) 

    if y == 0 then        
        imgExpand:runAction(cc.Show:create())
    else
        imgExpand:runAction(cc.Hide:create())
        
        local imghelp = self:seekChildByName("img_nn_help") 
        imghelp:setVisible(false)
    end
end

return GameMenuNode