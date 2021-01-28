--[[
@brief  邮件
]]
local app = cc.exports.gEnv.app
local MailLayer = class("MailLayer", app.base.BaseLayer)

MailLayer.csbPath = "lobby/csb/mail.csb"

MailLayer.touchs = {    
    "btn_close",
    "btn_del_read",
    "btn_del_all"  
}

MailLayer.clicks = {
    "background",
    "pnl_item_mail"
}

function MailLayer:onTouch(sender, eventType)
    MailLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_del_read" then
            self:onTouchDelRead()
        elseif name == "btn_del_all" then
            self:onTouchDelAll()
        end
    end
end

function MailLayer:onClick(sender)
    MailLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "pnl_item_mail" then
        local mailid = sender:getTag()
        self._presenter:showMailDetail(mailid)        
    end
end

function MailLayer:onCreate()
    self:seekChildByName("svw_mail"):setScrollBarEnabled(false)    
end

function MailLayer:showMailList(maillist)
    local mailPnl = self:seekChildByName("svw_mail") 
    local mailItm = self:seekChildByName("pnl_item_mail") 
    mailPnl:removeAllChildren()
        
    if #maillist == 0 then
        self:showDelBtn(false)
    	return   
    end
    
    self:showDelBtn(true)
    
    local pnlsize = mailPnl:getContentSize()
    local itmsize = mailItm:getContentSize()
    local INTERVAL = 20
    local pnlHight = itmsize.height * (#maillist) + INTERVAL * ((#maillist)+1)     
    if pnlHight < pnlsize.height then
        pnlHight = pnlsize.height
    end    
    mailPnl:setInnerContainerSize(cc.size(pnlsize.width, pnlHight))    
                 
    for i = 1,#maillist do
        local item = mailItm:clone()
        local back0 = item:getChildByName("img_item_back_0")
        local back1 = item:getChildByName("img_item_back_1")
        local icon  = item:getChildByName("img_mail_icon")
        local title = item:getChildByName("txt_mail_title")
        local time  = item:getChildByName("txt_mail_time")
        local read  = item:getChildByName("img_isread")
        
        back0:setVisible(maillist[i].read == 0)
        back1:setVisible(maillist[i].read == 1)
        
        icon:ignoreContentAdaptWithSize(true)
        read:ignoreContentAdaptWithSize(true)
        
        icon:loadTexture(string.format("lobby/image/mail/img_mail_%d.png", maillist[i].read), ccui.TextureResType.plistType)
        title:setString(maillist[i].title)
        time:setString(maillist[i].time)
        read:loadTexture(string.format("lobby/image/mail/img_read_%d.png", maillist[i].read), ccui.TextureResType.plistType)

        item:setTag(maillist[i].id)
        item:setPosition(pnlsize.width/2, pnlHight-INTERVAL-(itmsize.height+ INTERVAL)*(i-1))
        mailPnl:addChild(item)
    end   
end

function MailLayer:onTouchDelRead()
	print("删除已读")
end

function MailLayer:onTouchDelAll()
    print("删除所有")
end

function MailLayer:showDelBtn(visible)
	self:seekChildByName("btn_del_read"):setVisible(visible)
    self:seekChildByName("btn_del_all"):setVisible(visible)
end

return MailLayer