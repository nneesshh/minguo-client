
--[[
    @brief  玩家列表UI
]]--
local GameListLayer    = class("GameListLayer", app.base.BaseLayer)

GameListLayer.csbPath = "game/lhd/csb/playerlist.csb"

GameListLayer.touchs = {    
    "btn_close",
}

function GameListLayer:onTouch(sender, eventType)
    GameListLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then            
            self:exit()
        end
    end
end

function GameListLayer:showPlayerList(list)
    local pnl = self:seekChildByName("svw_player_list") 
    local itm = self:seekChildByName("item_list_self") 
    pnl:removeAllChildren()

    if #list == 0 then
        print("no player")        
        return   
    end

    local pnlsize = pnl:getContentSize()
    local itmsize = itm:getContentSize()
    local INTERVAL = 20
    local pnlHight = itmsize.height * (#list) + INTERVAL * ((#list)+1)     
    if pnlHight < pnlsize.height then
        pnlHight = pnlsize.height
    end    
    pnl:setInnerContainerSize(cc.size(pnlsize.width, pnlHight))    

    for i = 1,#list do
        if list[i].ticketid == app.data.UserData.getTicketID() then
        	self:showSelfList(list[i])
        end
        local item = itm:clone()
        local back   = item:getChildByName("img_rank_back")
        local s_back = item:getChildByName("img_rank_back_self")
        local i_rank = item:getChildByName("img_rank_num")
        local f_rank = item:getChildByName("fnt_rank_num")        
        local head   = item:getChildByName("img_head")
        local id     = item:getChildByName("txt_id")        
        local gold   = item:getChildByName("txt_gold")        
        local bet    = item:getChildByName("fnt_bet_gold")
        local round  = item:getChildByName("fnt_round")
        
        back:setVisible(true)
        s_back:setVisible(false)
        
        if list[i].seqid <= 6 then            
            f_rank:setVisible(false)
            i_rank:setVisible(true)
            i_rank:ignoreContentAdaptWithSize(true)
            i_rank:loadTexture(string.format("game/lhd/image/img_rank_%d.png", list[i].seqid), ccui.TextureResType.plistType)
        else
            i_rank:setVisible(false)
            f_rank:setVisible(true)
            f_rank:setString(list[i].seqid)
        end  
        
        local resPath = string.format("lobby/image/head/img_head_%d_%d.png", list[i].gender, list[i].avatar)
        head:loadTexture(resPath, ccui.TextureResType.plistType)

        id:setString("ID:" .. list[i].ticketid)
        
        gold:setString(list[i].balance)

        bet:setString(list[i].betnum20)
        round:setString(list[i].gamenum20)    

        item:setPosition(pnlsize.width/2, pnlHight-(itmsize.height+ INTERVAL)*i)
        pnl:addChild(item)
    end   
end

function GameListLayer:showSelfList(list)    
    local item = self:seekChildByName("item_list_self") 
    local back   = item:getChildByName("img_rank_back")
    local s_back = item:getChildByName("img_rank_back_self")
    local i_rank = item:getChildByName("img_rank_num")
    local f_rank = item:getChildByName("fnt_rank_num")        
    local head   = item:getChildByName("img_head")
    local id     = item:getChildByName("txt_id")        
    local gold   = item:getChildByName("txt_gold")        
    local bet    = item:getChildByName("fnt_bet_gold")
    local round  = item:getChildByName("fnt_round")
	
    back:setVisible(false)
    s_back:setVisible(true)

    if list.seqid <= 6 then            
        f_rank:setVisible(false)
        i_rank:setVisible(true)
        i_rank:ignoreContentAdaptWithSize(true)
        i_rank:loadTexture(string.format("game/lhd/image/img_rank_%d.png", list.seqid), ccui.TextureResType.plistType)
    else
        i_rank:setVisible(false)
        f_rank:setVisible(true)
        f_rank:setString(list.seqid)
    end  

    local resPath = string.format("lobby/image/head/img_head_%d_%d.png", list.gender, list.avatar)
    head:loadTexture(resPath, ccui.TextureResType.plistType)

    id:setString("ID:" .. list.ticketid)

    gold:setString(list.balance)

    bet:setString(list.betnum20)
    round:setString(list.gamenum20) 	
end

return GameListLayer