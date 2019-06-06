
--[[
    @brief  庄家列表UI
]]--
local GameBankerLayer    = class("GameBankerLayer", app.base.BaseLayer)

GameBankerLayer.csbPath = "game/brnn/csb/bankerlist.csb"

GameBankerLayer.touchs = {    
    "btn_close",
    "btn_go_banker"
}

function GameBankerLayer:onTouch(sender, eventType)
    GameBankerLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then            
            self:exit()
        elseif name == "btn_go_banker" then
            self._presenter:sendGobanker()  
        end
    end
end

function GameBankerLayer:initUI()
    app.util.UIUtils.openWindow(self:seekChildByName("container"))
end

function GameBankerLayer:showPlayerList(list)
    local pnl = self:seekChildByName("svw_player_list") 
    local itm = self:seekChildByName("item_list_self") 
    pnl:removeAllChildren()

    if #list == 0 then
        print("no player")        
        return   
    end
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
        local f_rank = item:getChildByName("fnt_rank_num")        
        local head   = item:getChildByName("img_head")
        local id     = item:getChildByName("txt_id")        
        local gold   = item:getChildByName("txt_gold")        
        local cur    = item:getChildByName("txt_cur_times")
        local count  = item:getChildByName("txt_player_count")
        
        f_rank:setString(list[i].seqid)
        
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

return GameBankerLayer