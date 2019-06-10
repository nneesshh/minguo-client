
--[[
    @brief  庄家列表UI
]]--
local GameBankerLayer    = class("GameBankerLayer", app.base.BaseLayer)

GameBankerLayer.csbPath = "game/brnn/csb/bankerlist.csb"

GameBankerLayer.touchs = {    
    "btn_close",
    "btn_go_banker",    
    "btn_cancel"
}

function GameBankerLayer:onTouch(sender, eventType)
    GameBankerLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then            
            self:exit()
        elseif name == "btn_go_banker" then
            self._presenter:sendGobanker(1) 
        elseif name == "btn_cancel" then
            self._presenter:sendGobanker(2)  
        end
    end
end

function GameBankerLayer:initUI()
    app.util.UIUtils.openWindow(self:seekChildByName("container"))
    self:showHint()
end

function GameBankerLayer:showBtnBanker(list)
    local btnGo   = self:seekChildByName("btn_go_banker") 
    local btnDown = self:seekChildByName("btn_cancel")
    local flag = false 
    if list then
        for i = 1,#list do 
            if list[i].ticketid == app.data.UserData.getTicketID() then
                flag = true
            end   
        end
    end
	
    btnGo:setVisible(not flag)
    btnDown:setVisible(flag)
end

function GameBankerLayer:showPlayerList(list)
    local pnl = self:seekChildByName("svw_player_list") 
    local itm = self:seekChildByName("item_list_self") 
    pnl:removeAllChildren()

    local pnlsize = pnl:getContentSize()
    local itmsize = itm:getContentSize()
    local INTERVAL = 10
    local pnlHight = itmsize.height * (#list) + INTERVAL * ((#list)+1)     
    if pnlHight < pnlsize.height then
        pnlHight = pnlsize.height
    end    
    pnl:setInnerContainerSize(cc.size(pnlsize.width, pnlHight))    
    for i = 1,#list do        
        local item = itm:clone()
        local banker = item:getChildByName("img_banker")         
        local f_rank = item:getChildByName("fnt_rank_num")        
        local head   = item:getChildByName("img_head")
        local id     = item:getChildByName("txt_id")        
        local gold   = item:getChildByName("txt_gold")        
        local cur    = item:getChildByName("txt_cur_times")
        local count  = item:getChildByName("txt_player_count")
        
        if list[i].seqid <= 1 then
            banker:setVisible(true)
            f_rank:setVisible(false)
        else
            banker:setVisible(false)
            f_rank:setVisible(true)
            f_rank:setString(list[i].seqid - 1)
        end
                
        if list[i].avatar == "" then
        	list[i].avatar = 1
        end
        local resPath = string.format("lobby/image/head/img_head_%d_%d.png", tonumber(list[i].gender) , tonumber(list[i].avatar))
        head:loadTexture(resPath, ccui.TextureResType.plistType)
        
        if tonumber(list[i].ticketid) then
            id:setString("ID:" .. list[i].ticketid)
        else
            id:setString(list[i].ticketid)    
        end

        gold:setString(list[i].balance)
        
        if list[i].bankernum >= 0 then
        	cur:setString(list[i].bankernum)
            cur:setVisible(true)
        else
            cur:setVisible(false)
        end
        
        
        count:setVisible(false)
        if i == #list then
            count:setVisible(true)
            count:setString("排队人数：" .. #list-1)
        end
        
        item:setPosition(pnlsize.width/2, pnlHight-(itmsize.height+ INTERVAL)*i)
        pnl:addChild(item)
    end   
end

function GameBankerLayer:showHint(type)
    local nodeCancel = self:seekChildByName("img_hint_cancel")
    local nodeBanker = self:seekChildByName("img_hint_banker")
    local btnGo   = self:seekChildByName("btn_go_banker") 
    local btnDown = self:seekChildByName("btn_cancel")
    nodeCancel:stopAllActions()
    nodeBanker:stopAllActions()

    nodeBanker:setVisible(type == 1)
    nodeCancel:setVisible(type == 2)

    if type == 1 then
        nodeBanker:runAction(cc.Sequence:create(
            cc.FadeIn:create(0.5),                       
            cc.FadeOut:create(1)
        ))               
    elseif type == 2 then  
        nodeCancel:runAction(cc.Sequence:create(
            cc.FadeIn:create(0.5),                       
            cc.FadeOut:create(1)
        ))            
    end
    btnGo:setVisible(not(type == 1))
    btnDown:setVisible(not(type == 2))
end

return GameBankerLayer