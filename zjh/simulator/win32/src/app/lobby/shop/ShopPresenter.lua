--[[
@brief  商城管理类
]]

local ShopPresenter = class("ShopPresenter",app.base.BasePresenter)
ShopPresenter._ui = require("app.lobby.shop.ShopLayer")

return ShopPresenter