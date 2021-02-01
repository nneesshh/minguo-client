
-- global before config and cocos.init
print = release_print

--
require "socket" -- must before require "cocos.init", otherwise will raise error: USE " cc.exports.socket = value " INSTEAD OF SET GLOBAL VARIABLE

--
package.cpath = package.cpath .. ';C:/Users/admin/AppData/Roaming/JetBrains/IdeaIC2020.3/plugins/intellij-emmylua/classes/debugger/emmy/windows/x86/?.dll'
local dbg = require('emmy_core')
dbg.tcpConnect('localhost', 9966)
dbg.breakHere()

--
require("ccmain")