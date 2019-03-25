
--[[
@brief  账号登录layer
]]

local LOGINTYPE = bf.ToolMXY.PlayerConnect.LOGINTYPE
local AccountData = app.data.AccountData

local AccountLoginLayer = class("AccountLoginLayer", app.base.BaseLayer)

-- csb路径
AccountLoginLayer.csbPath = "Lobby/CSB/Login/AccountLoginLayer.csb"

AccountLoginLayer.clicks = {
    "KW_PNL_ACCOUNT_LOGIN_BACK",
}

AccountLoginLayer.touchs = {
    "KW_BTN_ACCOUNT_LOGIN_CLOSE",
    "KW_BTN_ACCOUNT_DOWN",
    "KW_BTN_ACCOUNT_UP",
    "KW_BTN_LOGIN",
    "KW_BTN_LOST_PASSWORD",
}

AccountLoginLayer.events = {
    "KW_LVW_ACCOUNT_PULL_DOWN",
-- "KW_TFLD_ACCOUNT",
-- "KW_TFLD_PASSWORD",
}

local MAX_NUM = 5

function AccountLoginLayer:onCreate()
    self:seekChildByName("KW_TFLD_ACCOUNT"):setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    self:seekChildByName("KW_TFLD_PASSWORD"):setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
end

function AccountLoginLayer:initData()
end

function AccountLoginLayer:initUI()
    local lvw = self:seekChildByName("KW_LVW_ACCOUNT_PULL_DOWN")
    lvw:setScaleY(0)
    self:initLvw()
end

function AccountLoginLayer:onClick(sender)
    AccountLoginLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "KW_PNL_ACCOUNT_LOGIN_BACK" then
        self:exit()
    end
end

function AccountLoginLayer:onTouch(sender, eventType)
    AccountLoginLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "KW_BTN_ACCOUNT_LOGIN_CLOSE" then
            self:exit()
        elseif name == "KW_BTN_ACCOUNT_DOWN" then
            self:showPullDown(true)
        elseif name == "KW_BTN_ACCOUNT_UP" then
            self:showPullDown(false)
        elseif name == "KW_BTN_LOGIN" then
            self:onTouchLogin()
        elseif name == "KW_BTN_LOST_PASSWORD" then
            self:onTouchLost()
        end
    end
end

function AccountLoginLayer:onEvent(sender, eventType)
    local name = sender:getName()
    if name == "KW_LVW_ACCOUNT_PULL_DOWN" then
        if eventType == ccui.ListViewEventType.ONSELECTEDITEM_END then
            local accounts = AccountData.getAccounts(LOGINTYPE.ACCOUNT)
            local index = sender:getCurSelectedIndex()/2 + 1
            if accounts[index] ~= nil then
                local uid = accounts[index].userid
                local pwd = accounts[index].passwd
                self:seekChildByName("KW_TFLD_ACCOUNT"):setText(uid)
                self:seekChildByName("KW_TFLD_PASSWORD"):setText(pwd)
            end
            self:seekChildByName("KW_LVW_ACCOUNT_PULL_DOWN"):runAction(cc.ScaleTo:create(0.2, 1, 0))
            self:seekChildByName("KW_BTN_ACCOUNT_DOWN"):setVisible(true)
            self:seekChildByName("KW_BTN_ACCOUNT_UP"):setVisible(false)
        end
        -- elseif name == "KW_TFLD_ACCOUNT" or name == "KW_TFLD_PASSWORD" then
        --     if device.platform == "ios" then
        --         if eventType == ccui.TextFiledEventType.attach_with_ime then
        --             self:seekChildByName("KW_PNL_ACCOUNT_LOGIN"):runAction(cc.MoveBy:create(0.1, cc.p(0, 300)))
        --         elseif eventType == ccui.TextFiledEventType.detach_with_ime then
        --             self:seekChildByName("KW_PNL_ACCOUNT_LOGIN"):runAction(cc.MoveBy:create(0.1, cc.p(0, -300)))
        --         end
        --     end
    end
end

function AccountLoginLayer:onEditBoxEvent(eventType)
    if device.platform == "ios" then
        if eventType == "began" then
            self:seekChildByName("KW_PNL_ACCOUNT_LOGIN"):runAction(cc.MoveBy:create(0.1, cc.p(0, 200)))
        elseif eventType == "return" then
            self:seekChildByName("KW_PNL_ACCOUNT_LOGIN"):runAction(cc.MoveBy:create(0.1, cc.p(0, -200)))
        end
    end
end

function AccountLoginLayer:onTouchLogin()
    if self._presenter:getAgreement() then
        local userid = self:seekChildByName("KW_TFLD_ACCOUNT")
        local pwd = self:seekChildByName("KW_TFLD_PASSWORD")
        self._presenter:dealAccountLogin(userid:getText(), pwd:getText(), LOGINTYPE.ACCOUNT)
        self:exit()
    else
        self._presenter:dealHintStart("尚未同意用户使用协议！")
    end
end

function AccountLoginLayer:onTouchLost()
    self._presenter:showRetrievePwd()
    self:exit()
end

function AccountLoginLayer:initLvw()
    local lvw = self:seekChildByName("KW_LVW_ACCOUNT_PULL_DOWN")
    local line = self:seekChildByName("KW_IMG_LIST_LINE")
    local userid = self:seekChildByName("KW_TFLD_ACCOUNT")
    local pwd = self:seekChildByName("KW_TFLD_PASSWORD")
    local accounts = AccountData.getAccounts(LOGINTYPE.ACCOUNT)
    if accounts == nil or #accounts == 0 then
        userid:setText("")
        pwd:setText("")
    else
        local uid = accounts[1].userid
        local psd = accounts[1].passwd
        userid:setText(uid)
        pwd:setText(psd)
    end

    lvw:removeAllChildren()
    local nameNum = MAX_NUM
    if #accounts < MAX_NUM then
        nameNum = #accounts
    end
    lvw:setInnerContainerSize(cc.size(lvw:getContentSize().width, 35*nameNum))
    lvw:setContentSize(cc.size(lvw:getContentSize().width, 35*nameNum))
    for k,v in pairs(accounts) do
        if k <= MAX_NUM then
            if k > 1 then
                local lineItem = line:clone()
                local custom_item = ccui.Layout:create()
                custom_item:setContentSize(cc.size(341, 1))
                lineItem:setPosition(cc.p(170, 0.5))
                custom_item:addChild(lineItem)
                lvw:addChild(custom_item)
            end
            local nameText = ccui.Text:create()
            nameText:setString(v.userid)
            nameText:setFontSize(21)
            nameText:setColor(cc.c3b(80, 80, 80))
            nameText:setAnchorPoint(cc.p(0, 0.5))
            local custom_item = ccui.Layout:create()
            custom_item:setContentSize(cc.size(300, 35))
            nameText:setPosition(cc.p(20, custom_item:getContentSize().height / 2.0))
            custom_item:addChild(nameText)
            custom_item:setTouchEnabled(true)
            lvw:addChild(custom_item)
        end
    end
end

function AccountLoginLayer:showPullDown(flag)
    local down = self:seekChildByName("KW_BTN_ACCOUNT_DOWN")
    local up = self:seekChildByName("KW_BTN_ACCOUNT_UP")
    local lvw = self:seekChildByName("KW_LVW_ACCOUNT_PULL_DOWN")
    down:setVisible(not flag)
    up:setVisible(flag)
    if flag then
        lvw:runAction(cc.ScaleTo:create(0.2, 1, 1))
    else
        lvw:runAction(cc.ScaleTo:create(0.2, 1, 0))
    end
end

return AccountLoginLayer