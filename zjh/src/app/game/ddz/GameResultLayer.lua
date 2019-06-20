--[[
    @brief  游戏结算UI基类
]]--
local GameResultLayer    = class("GameResultLayer", app.base.BaseLayer)

GameResultLayer.csbPath = "game/ddz/csb/result.csb"

GameResultLayer.touchs = {
    "btn_close",
    "btn_continue",
}

function GameResultLayer:onTouch(sender, eventType)
    GameResultLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_continue" then
            self:exit()
        end
    end
end

function GameResultLayer:showResult(players)
    local win = self:seekChildByName("img_title_win")
    local lose = self:seekChildByName("img_title_lose")
    
    for i=1, #players do
        local item  = self:seekChildByName("result_player_" .. players[i].seat) 
        local back  = item:getChildByName("img_back")
        local bank  = item:getChildByName("txt_banker")         
        local name  = item:getChildByName("txt_nickname") 
        local base  = item:getChildByName("txx_base") 
        local mult  = item:getChildByName("txt_mult") 
        local score = item:getChildByName("txt_result") 
        
        local playerObj = app.game.PlayerData.getPlayerByServerSeat(players[i].seat)
        local heroseat = app.game.PlayerData.getHeroSeat()
        
        if players[i].seat == heroseat then
            win:setVisible(players[i].bouns >= 0)
            lose:setVisible(players[i].bouns < 0)
        end
                       
        back:setVisible(players[i].bouns > 0)
        bank:setVisible(players[i].seat == players.banker)
        
        bank:setColor(cc.c3b(255,255,255))
        name:setColor(cc.c3b(255,255,255))
        base:setColor(cc.c3b(255,255,255))
        mult:setColor(cc.c3b(255,255,255))
        score:setColor(cc.c3b(255,255,255))   
        
        if players[i].seat == players.banker then
            bank:setColor(cc.c3b(249,221,118))
            name:setColor(cc.c3b(249,221,118))
            base:setColor(cc.c3b(249,221,118))
            mult:setColor(cc.c3b(249,221,118))
            score:setColor(cc.c3b(249,221,118))                           
        end

        name:setString(playerObj:getNickname())        
        base:setString(players.base)    
        mult:setString("x" .. players[i].mult)
    	
        if players[i].bouns > 0 then
            score:setString("+" .. players[i].bouns)
    	else
            score:setString(players[i].bouns)
    	end
    end
end

return GameResultLayer