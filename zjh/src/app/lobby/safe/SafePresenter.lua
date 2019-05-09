--[[
@brief  商城管理类
]]

local SafePresenter = class("SafePresenter",app.base.BasePresenter)
SafePresenter._ui = requireLobby("app.lobby.safe.SafeLayer")

function SafePresenter:init()
    self:createDispatcher()

    self:initBankInfo()
end

function SafePresenter:createDispatcher()
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BANK, handler(self, self.onBankUpdate))    
    app.util.DispatcherUtils.addEventListenerSafe(app.Event.EVENT_BALANCE, handler(self, self.onBalanceUpdate))
end

function SafePresenter:initBankInfo()
    self:onBankUpdate()
    self:onBalanceUpdate()	
end

function SafePresenter:onBankUpdate()
    if not self:isCurrentUI() then
        return
    end

    local bank = app.data.UserData.getBank()
    self._ui:getInstance():setBank(bank)
end

function SafePresenter:onBalanceUpdate()
    if not self:isCurrentUI() then
        return
    end

    local balance = app.data.UserData.getBalance()
    self._ui:getInstance():setBalance(balance)
end

function SafePresenter:getMaxGold(type)
	if type == "put" then
        return app.data.UserData.getBalance()
	elseif type == "out" then
        return app.data.UserData.getBank()	
	end
end

function SafePresenter:putBank(num)
    app.data.UserData.setBank(num)
    self:dealTxtHintStart("存入" .. num)
    self._ui:getInstance():resetEnterNum()
end

function SafePresenter:outBank(num)
    local bank = app.data.UserData.getBank(num)
    app.data.UserData.setBank(bank-num)
    self:dealTxtHintStart("取出" .. num)
    self._ui:getInstance():resetEnterNum()
end
    
return SafePresenter