--[[
    @brief  记牌器
]]--

local GameRecordNode  = class("GameRecordNode", app.base.BaseNodeEx)

GameRecordNode.touchs = {
    "btn_record",  
}

function GameRecordNode:onTouch(sender, eventType)
    GameRecordNode.super.onTouch(self, sender, eventType)
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

function GameRecordNode:onClick(sender)
    GameRecordNode.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_menu" then              
        self:onTouchBtnGameMenu() 
    end  
end

function GameRecordNode:init()

end

function GameRecordNode:onTouchBtnGameMenu()
    self:rotateMneu()    
    self:showMenu()
end

function GameRecordNode:onTouchBtnGameSet()   
    app.lobby.set.SetPresenter:getInstance():start(false, app.Game.GameID.DDZ)
end

function GameRecordNode:onTouchBtnChange() 
    self._presenter:sendChangeTable()
end

function GameRecordNode:onTouchBtnHelp()
    app.lobby.help.HelpPresenter:getInstance():start(app.Game.GameID.DDZ)
end

-- 旋转菜单
function GameRecordNode:rotateMneu()
    local btnMenu = self:seekChildByName("btn_menu")  
    local angle = btnMenu:getRotation()
    local rotate = 0
    if angle == 180 then
        rotate = -180
    else 
        rotate = 180
    end  

    local act = cc.RotateBy:create(0.13, rotate)
    act:setTag(1)
    if btnMenu:getActionByTag(1) then
        return
    end    

    btnMenu:runAction(act)
end

-- 显示菜单
function GameRecordNode:showMenu()   
    local imgExpand = self:seekChildByName("img_menu_expand") 
    local btnMenu = self:seekChildByName("btn_menu") 
    local angle = btnMenu:getRotation()
    local x,y = math.modf(angle/360) 

    if y == 0 then        
        imgExpand:runAction(cc.Show:create())
    else
        imgExpand:runAction(cc.Hide:create())
    end
end

return GameRecordNode