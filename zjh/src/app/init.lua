--[[
@brief  工程初始化
]]--

app = app or {}

----------------------------------- require ----------------------------------
HotpatchRequire                             = require("hotpatch.HotpatchRequire")
requireLobby                                = HotpatchRequire.requireLobby
requireZJH                                  = HotpatchRequire.requireZJH
requireJDNN                                 = HotpatchRequire.requireJDNN
requireQZNN                                 = HotpatchRequire.requireQZNN

----------------------------------- network ----------------------------------
cfg_game_zjh                                = cfg_game_zjh or {}
zjh_defs                                    = zjh_defs or {}
msg_dispatcher                              = msg_dispatcher or {}

upconn                                      = requireLobby "upconn.ZjhUpconn"
app.Connect                                 = requireLobby("app.connect.Connect")

------------------------------------ 常量 -------------------------------------
app.Event                                   = requireLobby("app.constants.Event")
app.Game                                    = requireLobby("app.constants.Game")
app.Account                                 = requireLobby("app.constants.Account")

----------------------------------- 工具类 ------------------------------------
app.util = app.util or {}
app.util.bit                                = requireLobby("app.util.bit")
app.util.DispatcherUtils                    = requireLobby("app.util.DispatcherUtils")
app.util.Queue                              = requireLobby("app.util.Queue")
app.util.ToolUtils                          = requireLobby("app.util.ToolUtils")
app.util.UIUtils                            = requireLobby("app.util.UIUtils")
app.util.VaildUtils                         = requireLobby("app.util.VaildUtils")
app.util.SoundUtils                         = requireLobby("app.util.SoundUtils")
app.util.uuid                               = requireLobby("app.util.uuid")
app.util.FrontBackListener                  = requireLobby("app.util.FrontBackListener")
------------------------------------ 基类 -------------------------------------
app.base = app.base or {}
app.base.BaseLayer                          = requireLobby("app.base.BaseLayer")
app.base.BasePresenter                      = requireLobby("app.base.BasePresenter")
app.base.BaseScene                          = requireLobby("app.base.BaseScene")
app.base.BaseNode                           = requireLobby("app.base.BaseNode")
app.base.BaseNodeEx                         = requireLobby("app.base.BaseNodeEx")

------------------------------------ 数据 -------------------------------------
app.data = app.data or {}
app.data.PlazaData                          = requireLobby("app.data.PlazaData")
app.data.UserData                           = requireLobby("app.data.UserData")
app.data.SetData                            = requireLobby("app.data.SetData")
app.data.AccountData                        = requireLobby("app.data.AccountData")

------------------------------------ 大厅 -------------------------------------
app.lobby = app.lobby or {}
app.lobby.MainPresenter                     = requireLobby("app.lobby.MainPresenter")

app.lobby.login = app.lobby.login or {}
app.lobby.login.LoginPresenter              = requireLobby("app.lobby.login.LoginPresenter")
app.lobby.login.AccountLoginPresenter       = requireLobby("app.lobby.login.AccountLoginPresenter")
app.lobby.login.RegisterPresenter           = requireLobby("app.lobby.login.RegisterPresenter")
app.lobby.login.VerifyLoginPresenter        = requireLobby("app.lobby.login.VerifyLoginPresenter")

app.lobby.usercenter = app.lobby.usercenter or {}
app.lobby.usercenter.UserCenterPresenter    = requireLobby("app.lobby.usercenter.UserCenterPresenter")
app.lobby.usercenter.ChangeHeadPresenter    = requireLobby("app.lobby.usercenter.ChangeHeadPresenter")
app.lobby.usercenter.ChangePwdPresenter     = requireLobby("app.lobby.usercenter.ChangePwdPresenter")

app.lobby.help = app.lobby.help or {}
app.lobby.help.HelpPresenter                = requireLobby("app.lobby.help.HelpPresenter")

app.lobby.shop = app.lobby.shop or {}
app.lobby.shop.ShopPresenter                = requireLobby("app.lobby.shop.ShopPresenter")

app.lobby.set = app.lobby.set or {}
app.lobby.set.SetPresenter                  = requireLobby("app.lobby.set.SetPresenter")

app.lobby.public = app.lobby.public or {}
app.lobby.public.HintPresenter              = requireLobby("app.lobby.public.HintPresenter")
app.lobby.public.LoadingHintPresenter       = requireLobby("app.lobby.public.LoadingHintPresenter")
app.lobby.public.TextHintPresenter          = requireLobby("app.lobby.public.TextHintPresenter")

app.lobby.mail = app.lobby.mail or {}
app.lobby.mail.MailPresenter                = requireLobby("app.lobby.mail.MailPresenter")
app.lobby.mail.MailDetailPresenter          = requireLobby("app.lobby.mail.MailDetailPresenter")

app.lobby.notice = app.lobby.notice or {}
app.lobby.notice.NoticePresenter            = requireLobby("app.lobby.notice.NoticePresenter")

app.lobby.rank = app.lobby.rank or {}
app.lobby.rank.RankPresenter                = requireLobby("app.lobby.rank.RankPresenter")

app.lobby.safe = app.lobby.safe or {}
app.lobby.safe.SafePresenter                = requireLobby("app.lobby.safe.SafePresenter")

app.lobby.debug = app.lobby.debug or {}
app.lobby.debug.DebugPresenter              = requireLobby("app.lobby.debug.DebugPresenter")
------------------------------------ 游戏文件  -------------------------------------
app.game = app.game or {}
app.game.GameConfig                         = requireLobby("app.game.GameConfig")
app.game.GameEngine                         = requireLobby("app.game.GameEngine")
app.game.GameLoader                         = requireLobby("app.game.GameLoader")
app.game.Player                             = requireLobby("app.game.Player")
app.game.PlayerData                         = requireLobby("app.game.PlayerData")