--[[
@brief  工程初始化
]]--

app = app or {}

----------------------------------- 工具类 ------------------------------------
app.util = app.util or {}
app.util.Queue                          = require("app.util.Queue")
app.util.ToolUtils                      = require("app.util.ToolUtils")
app.util.UIUtils                        = require("app.util.UIUtils")
-------------------------------------------------------------------------------
------------------------------------ 基类 -------------------------------------
app.base = app.base or {}
app.base.BaseLayer                      = require("app.base.BaseLayer")
app.base.BasePresenter                  = require("app.base.BasePresenter")
app.base.BaseScene                      = require("app.base.BaseScene")

-------------------------------------------------------------------------------
------------------------------------ 数据 -------------------------------------
-------------------------------------------------------------------------------
---------------------------------- 业务逻辑 -----------------------------------

------------------------------------ 大厅 -------------------------------------
app.lobby = app.lobby or {}
app.lobby.MainPresenter                 = require("app.lobby.MainPresenter")

app.lobby.login = app.lobby.login or {}
app.lobby.login.LoginPresenter          = require("app.lobby.login.LoginPresenter")

