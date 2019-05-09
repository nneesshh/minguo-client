

local RankLayer = class("RankLayer",app.base.BaseLayer)

RankLayer.csbPath = "lobby/csb/rank.csb"

RankLayer.touchs = {    
    "btn_close"  
}

RankLayer.clicks = {
    "background",
    "btn_rich",
    "btn_win"
}

RankLayer._TAB = {}
RankLayer._TAB.BTN = {
    "btn_rich",
    "btn_win"
}
RankLayer._TAB.PNL = {
    ["btn_rich"] = "pnl_rank_rich",
    ["btn_win"]  = "pnl_rank_win"
}

function RankLayer:onTouch(sender, eventType)
    RankLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        end
    end
end

function RankLayer:onClick(sender)
    RankLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_rich" or name == "btn_win" then       
        self:showTabPanel(name)
    end
end

function RankLayer:initUI()    
    self:showTabPanel("btn_rich")
end

function RankLayer:showTabPanel(btnName)
    for _,name in ipairs(self._TAB.BTN) do
        self:seekChildByName(name):setEnabled(name ~= btnName)
    end
    for name,pnl in pairs(self._TAB.PNL) do
        self:seekChildByName(pnl):setVisible(name == btnName)
    end
end

function RankLayer:showRankList(richlist, winlist)
    self:initRichList(richlist)
    self:initWinList(winlist)
end

function RankLayer:initRichList(list)
    local richPnl = self:seekChildByName("svw_rank_rich") 
    local rankItm = self:seekChildByName("item_rank") 
    richPnl:removeAllChildren()

    if #list == 0 then        
        return   
    end

    local pnlsize = richPnl:getContentSize()
    local itmsize = rankItm:getContentSize()
    local INTERVAL = 20
    local pnlHight = itmsize.height * (#list) + INTERVAL * ((#list)+1)     
    if pnlHight < pnlsize.height then
        pnlHight = pnlsize.height
    end    
    richPnl:setInnerContainerSize(cc.size(pnlsize.width, pnlHight))    

    for i = 1,#list do
        local item = rankItm:clone()
        local head   = item:getChildByName("img_head")
        local id     = item:getChildByName("txt_id")
        local gold   = item:getChildByName("txt_gold")
        local imgnum = item:getChildByName("img_rank_num")
        local txtnum = item:getChildByName("fnt_rank_num")
               
        local resPath = string.format("lobby/image/head/img_head_%d_%d.png", list[i].gender, list[i].avator)
        head:loadTexture(resPath, ccui.TextureResType.plistType)
        
        id:setString("ID:" .. list[i].userid)
        gold:setString(list[i].gold)
        
        if list[i].id <= 3 then            
            txtnum:setVisible(false)
            imgnum:setVisible(true)
            imgnum:ignoreContentAdaptWithSize(true)
            imgnum:loadTexture(string.format("lobby/image/rank/img_rank_%d.png", list[i].id), ccui.TextureResType.plistType)
        else
            imgnum:setVisible(false)
            txtnum:setVisible(true)
            txtnum:setString(list[i].id)
        end       

        item:setPosition(pnlsize.width/2, pnlHight-INTERVAL-(itmsize.height+ INTERVAL)*(i-1))
        richPnl:addChild(item)
    end   
end

function RankLayer:initWinList(list)
    local winPnl = self:seekChildByName("svw_rank_win") 
    local rankItm = self:seekChildByName("item_rank") 
    winPnl:removeAllChildren()

    if #list == 0 then        
        return   
    end

    local pnlsize = winPnl:getContentSize()
    local itmsize = rankItm:getContentSize()
    local INTERVAL = 20
    local pnlHight = itmsize.height * (#list) + INTERVAL * ((#list)+1)     
    if pnlHight < pnlsize.height then
        pnlHight = pnlsize.height
    end    
    winPnl:setInnerContainerSize(cc.size(pnlsize.width, pnlHight))    

    for i = 1,#list do
        local item = rankItm:clone()
        local head   = item:getChildByName("img_head")
        local id     = item:getChildByName("txt_id")
        local gold   = item:getChildByName("txt_gold")
        local imgnum = item:getChildByName("img_rank_num")
        local txtnum = item:getChildByName("fnt_rank_num")

        local resPath = string.format("lobby/image/head/img_head_%d_%d.png", list[i].gender, list[i].avator)
        head:loadTexture(resPath, ccui.TextureResType.plistType)

        id:setString("ID:" .. list[i].userid)
        gold:setString(list[i].gold)

        if list[i].id <= 3 then            
            txtnum:setVisible(false)
            imgnum:setVisible(true)
            imgnum:ignoreContentAdaptWithSize(true)
            imgnum:loadTexture(string.format("lobby/image/rank/img_rank_%d.png", list[i].id), ccui.TextureResType.plistType)
        else
            imgnum:setVisible(false)
            txtnum:setVisible(true)
            txtnum:setString(list[i].id)
        end       

        item:setPosition(pnlsize.width/2, pnlHight-INTERVAL-(itmsize.height+ INTERVAL)*(i-1))
        winPnl:addChild(item)
    end   
end

return RankLayer