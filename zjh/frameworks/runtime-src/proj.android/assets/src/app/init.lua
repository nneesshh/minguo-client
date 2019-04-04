--[[
@brief  工程初始化
]]--

app = app or {}

----------------------------------- network ----------------------------------
upconn                                      = upconn or {}
cfg_game_zjh                                = cfg_game_zjh or {}
zjh_defs                                    = zjh_defs or {}
msg_dispatcher                              = msg_dispatcher or {}

------------------------------------ 常量 -------------------------------------
app.Event                                   = require("app.constants.Event")
app.Game                                    = require("app.constants.Game")

----------------------------------- 工具类 ------------------------------------
app.util = app.util or {}
app.util.bit                                = require("app.util.bit")
app.util.DispatcherUtils                    = require("app.util.DispatcherUtils")
app.util.Queue                              = require("app.util.Queue")
app.util.ToolUtils                          = require("app.util.ToolUtils")
app.util.UIUtils                            = require("app.util.UIUtils")
app.util.VaildUtils                         = require("app.util.VaildUtils")

------------------------------------ 基类 -------------------------------------
app.base = app.base or {}
app.base.BaseLayer                          = require("app.base.BaseLayer")
app.base.BasePresenter                      = require("app.base.BasePresenter")
app.base.BaseScene                          = require("app.base.BaseScene")
app.base.BaseNode                           = require("app.base.BaseNode")
app.base.BaseNodeEx                         = require("app.base.BaseNodeEx")
------------------------------------ 数据 -------------------------------------
app.data = app.data or {}
app.data.PlazaData                          = require("app.data.PlazaData")
app.data.UserData                           = require("app.data.UserData")

------------------------------------ 大厅 -------------------------------------
app.lobby = app.lobby or {}
app.lobby.MainPresenter                     = require("app.lobby.MainPresenter")

app.lobby.login = app.lobby.login or {}
app.lobby.login.LoginPresenter              = require("app.lobby.login.LoginPresenter")
app.lobby.login.AccountLoginPresenter       = require("app.lobby.login.AccountLoginPresenter")
app.lobby.login.RegisterPresenter           = require("app.lobby.login.RegisterPresenter")
app.lobby.login.VerifyLoginPresenter        = require("app.lobby.login.VerifyLoginPresenter")

app.lobby.usercenter = app.lobby.usercenter or {}
app.lobby.usercenter.UserCenterPresenter    = require("app.lobby.usercenter.UserCenterPresenter")

app.lobby.help = app.lobby.help or {}
app.lobby.help.HelpPresenter                = require("app.lobby.help.HelpPresenter")

app.lobby.shop = app.lobby.shop or {}
app.lobby.shop.ShopPresenter                = require("app.lobby.shop.ShopPresenter")

app.lobby.set = app.lobby.set or {}
app.lobby.set.SetPresenter                  = require("app.lobby.set.SetPresenter")

-- 游戏文件
app.game = app.game or {}
app.game.GameConfig                               = require("app.game.GameConfig")
app.game.GameEngine                               = require("app.game.GameEngine")
app.game.GameLoader                               = require("app.game.GameLoader")
app.game.Player                                   = require("app.game.Player")
app.game.PlayerData                               = require("app.game.PlayerData")

