--[[
@brief  ���̳�ʼ��
]]--

app = app or {}

----------------------------------- ������ ------------------------------------
app.util = app.util or {}
app.util.Queue                          = require("app.util.Queue")
app.util.ToolUtils                      = require("app.util.ToolUtils")
app.util.UIUtils                        = require("app.util.UIUtils")
-------------------------------------------------------------------------------
------------------------------------ ���� -------------------------------------
app.base = app.base or {}
app.base.BaseLayer                      = require("app.base.BaseLayer")
app.base.BasePresenter                  = require("app.base.BasePresenter")
app.base.BaseScene                      = require("app.base.BaseScene")

-------------------------------------------------------------------------------
------------------------------------ ���� -------------------------------------
-------------------------------------------------------------------------------
---------------------------------- ҵ���߼� -----------------------------------

------------------------------------ ���� -------------------------------------
app.lobby = app.lobby or {}
app.lobby.MainPresenter                 = require("app.lobby.MainPresenter")

app.lobby.login = app.lobby.login or {}
app.lobby.login.LoginPresenter          = require("app.lobby.login.LoginPresenter")

