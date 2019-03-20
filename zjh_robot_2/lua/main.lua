require "lua.init_package_path"
local b = require "bootstrap"

print("start ZjhTest...")
--local d = require("zjh.robot.ZjhTestRegister")
--[[]]
local d = require("zjh.robot.ZjhTest")

d.start()
d.check()
d.simUpdate()
