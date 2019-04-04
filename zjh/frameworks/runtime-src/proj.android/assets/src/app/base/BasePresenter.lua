--[[
@brief  �������
]]
local app           = app

local BasePresenter = class("BasePresenter")

---------------- ������������Ŀ ---------------
-- UI����
BasePresenter._ui   = nil
----------------------------------------------

-- ����
BasePresenter._instance      = nil

-- ������̬���� 
-- @param self
-- @return _instance
function BasePresenter:getInstance()
    if self._instance == nil then
        self._instance = self:create()
    end

    return self._instance
end

-- ��ʼ�� 
function BasePresenter:ctor()
end

-- ����UI
function BasePresenter:start( ... )
    self:startUI( ... )
    self:init( ... )
end

-- �򿪽���
function BasePresenter:startUI( ... )
    self._ui:getInstance():start( self, ... )
end

-- ��ʼ��(�����൥��ʵ��)
function BasePresenter:init( ... )
end

-- �˳�����
function BasePresenter:exit()
    self._ui:getInstance():exit()
end

-- �ж��Ƿ�ǰ����
function BasePresenter:isCurrentUI()
    return self._ui:getInstance():isCurrentUI()
end

return BasePresenter
