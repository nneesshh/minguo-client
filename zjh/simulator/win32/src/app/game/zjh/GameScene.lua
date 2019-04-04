--[[
@brief  游戏主场景UI基类
]]
local GameScene   = class("GameScene", app.base.BaseScene)
local ALLTURN     = 10
-- csb路径
GameScene.csbPath = "game/zjh/csb/gamescene.csb"

GameScene.touchs = {
    "btn_exit",
    
}

GameScene.clicks = {
    "btn_menu",
    "pnl_player_0",
    "pnl_player_1",
    "pnl_player_2",
    "pnl_player_3",
    "pnl_player_4",
}

function GameScene:onTouch(sender, eventType)
    GameScene.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then        
        if name == "btn_exit" then
            self._presenter:sendLeaveRoom()       
        end
    end
end

function GameScene:onClick(sender)
    GameScene.super.onClick(self, sender)
    local name = sender:getName()
    if string.find(name, "pnl_player_") then 
        local localseat = string.split(name, "pnl_player_")[2]
        self._presenter:onTouchPanelBiPai(tonumber(localseat))
    end    
end

function GameScene:exit()
    GameScene.super.exit(self)

    GameScene._instance = nil
end

function GameScene:initData()    
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
end 

function GameScene:showStartEffect()
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect","jiubei_dh", 0, 0)
    self:seekChildByName("node_start_effect"):addChild(effect)
end

function GameScene:showBiPaiEffect()
    local effect = app.util.UIUtils.runEffectOne("game/zjh/effect","vs_dh2", 0, 0)
    self:seekChildByName("node_bipai_effect"):addChild(effect)
end

function GameScene:showDanZhu(num)
    local fntDZ = self:seekChildByName("fnt_dz")
    fntDZ:setString(num)
end

function GameScene:showLunShu(num)
    local strNum = string.format("%d/%d", num, ALLTURN)
    local fntLS = self:seekChildByName("fnt_turn")
    fntLS:setString(strNum)
end

function GameScene:showZongzhu(num)
    local fntZZ = self:seekChildByName("fnt_zz")
    fntZZ:setString(num)
end

function GameScene:showChipAction(index, count, localseat)        
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local size = pnlarea:getContentSize()
        
    local nodechip = self:seekChildByName("node_chip_"..localseat)
    local fx,fy = nodechip:getPosition()    
    local cx, cy = pnlarea:convertToNodeSpace(cc.p(fx, fy))
    
    for i=1,count do
        local tx,ty = math.random(1, size.width) , math.random(1, size.height) 
        local imgChip = ccui.ImageView:create()
        imgChip:loadTexture(string.format("game/zjh/image/img_chip_small_%d.png", index), ccui.TextureResType.plistType)    
        imgChip:setPosition(cc.p(cx, cy))    
        pnlarea:addChild(imgChip)            
        imgChip:runAction(cc.MoveTo:create(0.5, cc.p(tx,ty)))    
    end                
end

function GameScene:showChipBackAction(localseats)
    local pnlarea = self:seekChildByName("pnl_chip_area")
    local childrens = pnlarea:getChildren()
    local total = #localseats
    
    if total > 1 then
        local per = math.floor(#childrens / total)

        for i = 1, total do
            local nodechip = self:seekChildByName("node_chip_"..localseats[i])
            local fx,fy = nodechip:getPosition()    
            local cx, cy = pnlarea:convertToNodeSpace(cc.p(fx, fy))
            
            if i == total then
                for j = per*(i-1)+1, #childrens do                    
                    childrens[j]:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.5, cc.p(cx, cy)),
                        cc.CallFunc:create(
                            function() 
                                childrens[j]:removeFromParent()
                            end)
                        )) 
                end
            else
                for j = 1+per*(i-1), per*i do                   
                    childrens[j]:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.5, cc.p(cx, cy)),
                        cc.CallFunc:create(function() 
                            childrens[j]:removeFromParent() 
                            end)
                        )) 
                end
            end            
        end
    else
        local nodechip = self:seekChildByName("node_chip_"..localseats[1])
        local fx,fy = nodechip:getPosition()    
        local cx, cy = pnlarea:convertToNodeSpace(cc.p(fx, fy))
        for k, child in ipairs(childrens) do
            child:runAction(cc.Sequence:create(
                cc.MoveTo:create(0.5, cc.p(cx, cy)),
                cc.CallFunc:create(function() child:removeFromParent() end)
            ))  
    	end
    end
end

function GameScene:showBiPaiPanel(visible)
    local pnl = self:seekChildByName("pnl_bipai")
    if pnl then
        pnl:setVisible(visible)
    end    
end

function GameScene:isBiPaiPanelVisible()
    local pnl = self:seekChildByName("pnl_bipai")
	return pnl:isVisible()
end

function GameScene:getToPosition()
    local lx,ly = self:seekChildByName("node_left"):getPosition()    
    local lmx,lmy = self:seekChildByName("node_left_m"):getPosition()
    local rmx,rmy = self:seekChildByName("node_right_m"):getPosition()
    local rx,ry = self:seekChildByName("node_right"):getPosition()
    
    return cc.p(lx,ly), cc.p(lmx,lmy), cc.p(rmx,rmy), cc.p(rx,ry) 
end

return GameScene