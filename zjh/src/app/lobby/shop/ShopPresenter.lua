--[[
@brief  商城管理类
]]

local ShopPresenter = class("ShopPresenter",app.base.BasePresenter)
ShopPresenter._ui = requireLobby("app.lobby.shop.ShopLayer")

return ShopPresenter