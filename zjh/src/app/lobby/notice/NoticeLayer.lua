--[[
@brief  公告类
]]

local NoticeLayer = class("NoticeLayer",app.base.BaseLayer)

NoticeLayer.csbPath = "lobby/csb/notice.csb"

NoticeLayer.touchs = {    
    "btn_close"  
}

NoticeLayer.clicks = {
    "background",
    "btn_gftx",
    "btn_xwjbd",
    "btn_fzbgg",
    "btn_czlhb",
}

NoticeLayer._TAB = {}
NoticeLayer._TAB.BTN = {
    "btn_gftx",
    "btn_xwjbd",
    "btn_fzbgg",
    "btn_czlhb",
}
NoticeLayer._TAB.PNL = {
    ["btn_gftx"]  = "panel_gftx",
    ["btn_xwjbd"] = "panel_xwjbd",
    ["btn_fzbgg"] = "panel_fzbgg",
    ["btn_czlhb"] = "panel_czlhb",
}

function NoticeLayer:onTouch(sender, eventType)
    NoticeLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        end
    end
end

function NoticeLayer:onClick(sender)
    NoticeLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "btn_gftx" or name == "btn_xwjbd" or name == "btn_fzbgg" or name == "btn_czlhb" then
        self:showTabPanel(name)    
    end
end

function NoticeLayer:initUI()    
    self:showTabPanel("btn_gftx")    
end

function NoticeLayer:showTabPanel(btnName)
    for _,name in ipairs(self._TAB.BTN) do
        self:seekChildByName(name):setEnabled(name ~= btnName)
    end
    for name,pnl in pairs(self._TAB.PNL) do
        self:seekChildByName(pnl):setVisible(name == btnName)
    end
end

--[[
if data.type == notice.NOTICE then
self._ui:getInstance():updateNotice(data.text)
elseif data.type == notice.READ then
self._ui:getInstance():updateRead(data.text)
elseif data.type == notice.CHEAT then
self._ui:getInstance():updateCheat(data.text)
end
]]

function NoticeLayer:updateNotice(text)
    text = text or "暂无公告"
    local node = self:seekChildByName("txt_gftx")
    node:setString(text)
end

function NoticeLayer:updateRead(text)
    text = text or "暂无公告"
    local node = self:seekChildByName("txt_xwjbd")
    node:setString(text)
end

function NoticeLayer:updateCheat(text)
    text = text or "暂无公告"
    local node = self:seekChildByName("txt_fzbgg")
    node:setString(text)
end

return NoticeLayer