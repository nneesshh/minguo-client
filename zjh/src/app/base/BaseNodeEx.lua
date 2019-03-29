--[[
@brief  节点基类(界面中已经存在的节点)
@by     斯雪峰
]]
local BaseNodeEx = class("BaseNodeEx", app.base.BaseNode)

---------------- 子类需配置项目 ---------------
-- 需注册按钮touch事件的列表
BaseNodeEx.touchs     = nil
BaseNodeEx.clicks     = nil
BaseNodeEx.events     = nil
-----------------------------------------------

-- 根节点
BaseNodeEx._rootNode = nil

-- 子节点数据
BaseNodeEx._children = {}

-- 控制文件的实例
BaseNodeEx._presenter = nil

-- 构造函数
function BaseNodeEx:ctor(presenter, node, ... )
    self._rootNode = node
    self._children = {}
    self._presenter = nil

    -- 注册按钮等事件
    self:registerEvent()

    -- 加载控制类
    self._presenter = presenter

    self:init( ... )
end

return BaseNodeEx