--[[
@brief  双向队列
]]
local app = cc.exports.gEnv.app
local Queue = class("Queue")

Queue._first = 0
Queue._last = -1
Queue._list = {}

-- 初始化
function Queue:ctor()
    self._first = 0
    self._last = -1
    self._list = {}
end

-- 插入数据至头部
function Queue:addFirst(value)
    if(value == nil) then
        print("Queue addFirst args is nil.")
        return
    end
    self._first = self._first - 1
    self._list[self._first] = value
end

-- 插入数据至尾部
function Queue:addLast(value)
    if(value == nil) then
        print("Queue addLast args is nil.")
        return
    end
    self._last = self._last + 1
    self._list[self._last] = value
end

-- 获取并移除头部元素
function Queue:popFirst()
    if(self._first > self._last) then
        return nil 
    end
    local value = self._list[self._first]
    self._list[self._first] = nil
    self._first = self._first + 1
    return value
end

-- 获取并移除尾部元素
function Queue:popLast()
    if(self._first > self._last) then
        return nil 
    end
    local value = self._list[self._last]
    self._list[self._last] = nil
    self._last = self._last - 1
    return value
end

-- 获取不移除头部元素
function Queue:getFirst()
    if(self._first > self._last) then
        return nil 
    end
    return self._list[self._first]
end

-- 获取不移除尾部元素
function Queue:getLast()
    if(self._first > self._last) then
        return nil 
    end
    return self._list[self._last]
end

-- 获取队列长度
function Queue:getCount()
    return self._last - self._first + 1
end

-- 移除头部元素
function Queue:deleteFirst()
    if(self._first > self._last) then
        return  
    end
    self._list[self._first] = nil
    self._first = self._first + 1
end

-- 清空
function Queue:clear()
    self:ctor()
end

return Queue