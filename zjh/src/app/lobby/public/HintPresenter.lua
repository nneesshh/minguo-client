--[[
@brief  提示框管理
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local HintPresenter = class("HintPresenter", app.base.BasePresenter)

HintPresenter._ui   = requireLobby("app.lobby.public.HintLayer")

-- 提示语队列
HintPresenter._hintQueue = app.util.Queue.new()

--[[
--提示文字、回调函数、提示框类型
例.app.lobby.public.HintPresenter:getInstance():start("操作异常哦！")
]]--

-- 重写start函数
-- 当传入文本文空时，不给予用户提示
-- 当传入的文本与队头文本内容相同时不予用户提示
-- flag 是否需要主动换行
function HintPresenter:start(text, callback, type, flag)
    print("brnn", text, callback, type, flag)
    if text == nil or text == "" then
        return
    end

    local cache = self._hintQueue:getFirst()
    if cache ~= nil and cache.text ~= nil then
        if tostring(text) == tostring(cache.text) then
            return
        end
    end

    self:addHint(text, callback, type, flag)
end

function HintPresenter:addHint(text, callback, type, flag)
	text = text or ""
    callback = callback or function(bFlag) end
    type = type or 0

    local data = { text = text, callback = callback, type = type }
    self._hintQueue:addLast(data)
    self:showHint(flag)
end

function HintPresenter:showHint(flag)
	local cache = self._hintQueue:getFirst()
    if cache == nil then
        self._ui:getInstance():exit()
        return
    end
    print("brnnshowhint",flag)
    
    self._ui:getInstance():start(self, cache.text, cache.type, flag)
end

function HintPresenter:notifyCallBack(bFlag)
    local cache = self._hintQueue:getFirst()
    cache.callback(bFlag)
    self._hintQueue:deleteFirst()
    self:showHint()
end

return HintPresenter