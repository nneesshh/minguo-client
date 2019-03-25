--[[
@brief  ˫�����
]]

local Queue = class("Queue")

Queue._first = 0
Queue._last = -1
Queue._list = {}

-- ��ʼ��
function Queue:ctor()
    self._first = 0
    self._last = -1
    self._list = {}
end

-- ����������ͷ��
function Queue:addFirst(value)
    if(value == nil) then
        print("Queue addFirst args is nil.")
        return
    end
    self._first = self._first - 1
    self._list[self._first] = value
end

-- ����������β��
function Queue:addLast(value)
    if(value == nil) then
        print("Queue addLast args is nil.")
        return
    end
    self._last = self._last + 1
    self._list[self._last] = value
end

-- ��ȡ���Ƴ�ͷ��Ԫ��
function Queue:popFirst()
    if(self._first > self._last) then
        return nil 
    end
    local value = self._list[self._first]
    self._list[self._first] = nil
    self._first = self._first + 1
    return value
end

-- ��ȡ���Ƴ�β��Ԫ��
function Queue:popLast()
    if(self._first > self._last) then
        return nil 
    end
    local value = self._list[self._last]
    self._list[self._last] = nil
    self._last = self._last - 1
    return value
end

-- ��ȡ���Ƴ�ͷ��Ԫ��
function Queue:getFirst()
    if(self._first > self._last) then
        return nil 
    end
    return self._list[self._first]
end

-- ��ȡ���Ƴ�β��Ԫ��
function Queue:getLast()
    if(self._first > self._last) then
        return nil 
    end
    return self._list[self._last]
end

-- ��ȡ���г���
function Queue:getCount()
    return self._last - self._first + 1
end

-- �Ƴ�ͷ��Ԫ��
function Queue:deleteFirst()
    if(self._first > self._last) then
        return  
    end
    self._list[self._first] = nil
    self._first = self._first + 1
end

-- ���
function Queue:clear()
    self:ctor()
end

return Queue