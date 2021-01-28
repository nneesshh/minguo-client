--[[
@brief  商城管理类
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local ShopPresenter = class("ShopPresenter",app.base.BasePresenter)
ShopPresenter._ui = requireLobby("app.lobby.shop.ShopLayer")

return ShopPresenter