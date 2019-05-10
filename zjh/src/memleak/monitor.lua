local assert = assert
local type = type
local print = print
local string = string
local tostring = tostring
local pairs = pairs
local collectgarbage = collectgarbage
local setmetatable = setmetatable

local _M = {
    --内存泄露监控间隔（单位：秒）
    memLeaksInterval 	= 60,
    
    __memLeakTbl = {},
    __updateFunc = function(dt) end,
}

--内存泄露监控逻辑
local function __createMonitorFunc(dt)
	local monitorTime	= _M.memLeaksInterval
	local interval 		= _M.memLeaksInterval
	local str 			= nil
 
	return function(dt)
		interval = interval + dt
		if interval >= monitorTime then
			interval = interval - monitorTime
			--强制性调用gc
			collectgarbage("collect")
			collectgarbage("collect")
			--打印当前内存泄露监控表中依然存在（没有被释放）的对象信息
			str = "[memory leak monitor:]"
			for k, v in pairs(self.__memLeakTbl) do
				str = str..string.format("  \n%s = %s", tostring(k), tostring(v))
			end
            print(str)
            print("\nmem(K): ", tostring(collectgarbage("count")))
		end
	end
end
 
function _M.start()
    --内存泄露弱引用表
	setmetatable(_M.__memLeakTbl, {__mode='kv'})
    _M.__updateFunc = __createMonitorFunc()
end
 
function _M.update(dt)
	_M.__updateFunc(dt)
end
  
---------------------------------------------
--公有方法
--功能：		增加一个受监视的表
--参数tblName:	该表的名字（字符串类型），方便记忆
--参数tbl:		该表的引用
--返回：		无
---------------------------------------------
--增加一个受监视的表
function _M.addToMonitor(tblName, tbl)
	assert('string' == type(tblName), "Invalid parameters")
	--必须以名字+地址的方式作为键值
	--内存泄露经常是一句代码多次分配出内存而忘了回收，因此tblName经常是相同的
	local name = string.format("%s@%s", tblName, tostring(tbl))
	if nil == _M.__memLeakTbl[name] then
		_M.__memLeakTbl[name] = tbl
	end
end

return _M