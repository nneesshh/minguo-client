--[[
@brief  邮件
]]
local app = cc.exports.gEnv.app
local MailDetailLayer = class("MailDetailLayer",app.base.BaseLayer)

MailDetailLayer.csbPath = "lobby/csb/maildetail.csb"

MailDetailLayer.touchs = {    
    "btn_close",
    "btn_del",
    "btn_back"  
}

MailDetailLayer.clicks = {
    "background",
}

function MailDetailLayer:onTouch(sender, eventType)
    MailDetailLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_del" then
            self:onTouchDel()
        elseif name == "btn_back" then
            self:onTouchBack()
        end
    end
end

function MailDetailLayer:showMailDetail(mail)
    local context = self:seekChildByName("txt_mail_detail") 
    context:setString(mail.title)
end

function MailDetailLayer:onTouchDel()
	print("del mail")
end

function MailDetailLayer:onTouchBack()
    self:exit()
    print("back mail")
end

return MailDetailLayer