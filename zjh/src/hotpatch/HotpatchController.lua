local _M = {
    _VERSION = "1.0.0.1",
		_DESCRIPTION = "hotpacth controller",
}

local tbl_insert = table.insert
local setmetatable, getmetatable = setmetatable, getmetatable
local tostring, pairs, ipairs = tostring, pairs, ipairs
local str_sub = string.sub
local math_ceil = math.ceil

-- Localize
local cwd = (...):gsub("%.[^%.]+$", "") .. "."

local function __toSizeStr(value)
  local str = ""
  if value > 1024*1024*1024 then
    value = math.ceil(value / (1024*1024*1024)*100) / 100
    str = value.."G"
  elseif value > 1024*1024 then
    value = math.ceil(value / (1024*1024)*100) / 100
    str = value.."M"
  elseif value > 1024 then
    value = math.ceil(value / (1024)*100) / 100
    str = value.."K"
  else
    str = value.."B"
  end    
  return str
end

--
local mt = {__index = _M}

function _M.new(self, projectManifest, savePath)
    return setmetatable(
        {
					--
					id = id,
					updateInfo = {},
					assetsManager = nil,

					--
					projectManifest = projectManifest or "patch/project.manifest",
					savePath = savePath and cc.FileUtils:getInstance():getWritablePath() .. savePath or cc.FileUtils:getInstance():getWritablePath() .. "update"
        },
        mt
    )
end

local CHECK_ASSETS_STATE = 7

function _M:initAssetsManager()
	self.assetsManager = cc.AssetsManagerEx:create(self.projectManifest, self.savePath):retain()
	self.updateInfo.oldVersion = self.assetsManager:getLocalManifest():getVersion()
	
	local checkListener = cc.EventListenerAssetsManagerEx:create(self.assetsManager, handler(self, self.assetsCheckEvent))
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(checkListener, 1)
	self.updateInfo.checkListener = checkListener

	self.objects["Node_loading"]:hide()
	self.objects["Text_prompt"]:setString("检查更新中...")
end

function _M:destroyAssetsManager()
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	if self.updateInfo.checkListener then
		eventDispatcher:removeEventListener(self.updateInfo.checkListener)
		self.updateInfo.checkListener = nil
	end
	if self.updateInfo.updateListener then
		eventDispatcher:removeEventListener(self.updateInfo.updateListener)
		self.updateInfo.updateListener = nil
	end
	_OLD_VERSION = self.updateInfo.oldVersion
	_NEW_VERSION = self.updateInfo.newVersion
	self.assetsManager:release()
	self.assetsManager = nil
	self.updateInfo = nil
end

function _M:procUI()
	self:procAdviseUI()
end

function _M:procAdviseUI()
	local layItem = cc.CSLoader:createNode(config.path .. "AdviseNode.csb")
	local adviseNode = layItem:getChildByName("Node_advise")
	layItem:addTo(self.objects["Panel_Middle"])
	layItem:setPosition(cc.p(568, 320))

	adviseNode:setOpacity(0):runAction(cc.FadeIn:create(0.3))
	local callback = function() self.assetsManager:checkUpdate() end
	layItem:runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.FadeOut:create(0.3), cc.CallFunc:create(callback)))
end

function _M:refreshWithUpdate()
	local updateListener = cc.EventListenerAssetsManagerEx:create(self.assetsManager, handler(self, self.assetsUpdateEvent))
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:removeEventListener(self.updateInfo.checkListener)
	eventDispatcher:addEventListenerWithFixedPriority(updateListener, 1)
	self.updateInfo.updateListener = updateListener
	self.updateInfo.checkListener = nil
	self.assetsManager:update()

	self.objects["Node_loading"]:setVisible(true)
	self.objects["LoadingBar_load"]:setPercent(0)
end

function _M:refreshWithLogin()
	gg.ctrlManager["LoginLayer"]:removeFromParent(true)
	gg.schedulerHelper:unscheduleAllScriptEntry()
	display.removeAllSpriteFrames()

	package.loaded["model.enterGame"] = nil
	require("model.enterGame")
end


--------evt
--------btnEvent
function _M:assetsCheckEvent(event)
	local eventCode, errorCode = event:getEventCode(), event:getCURLECode()
	local isCheck = self.assetsManager:getState() == CHECK_ASSETS_STATE
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
		self.objects["Text_prompt"]:setString("客户端损坏, 请下载新的安装包" )
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
		self.objects["Text_prompt"]:setString("获取版本信息出错" )
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
		self.objects["Text_prompt"]:setString("解析版本信息出错" )
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEED_NEW_CLIENT then
		local title = "更新信息"
		local content = "需要重新下载客户端"
		local onSure = function() cc.Director:getInstance():endToLua() end
		self.objects["Text_prompt"]:setString("客户端已更新")
		gg.utils.showMessageTip(title, content, onSure)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND and isCheck then
		self.objects["Text_prompt"]:setString("开始解析版本信息" )
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND and not isCheck then
		self.updateInfo.newVersion = self.assetsManager:getRemoteManifest():getVersion()
		self.updateInfo.total = self.assetsManager:getTotalSize()
		local sizeStr = __toSizeStr(self.updateInfo.total)

		local title = "更新信息"
		local onSure = handler(self, self.refreshWithUpdate)
		local onCancel = function() cc.Director:getInstance():endToLua() end
		local content = "检查到新版本#k" .. self.updateInfo.newVersion .. "#k\n需要下载#k" .. sizeStr .. "#k大小的文件"
		
		self.objects["Text_prompt"]:setString("发现新版本")
		gg.utils.showMessageTip(title, content, onSure, onCancel)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
		gg.ctrlManager["LoginLayer"]:loadRes()
		self:destroyAssetsManager()
		self:requireCfg()
		self:onClose()
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
		local percent = math.floor(event:getPercent()) .. "%"
		self.objects["Text_prompt"]:setString("获取版本信息:" .. percent)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.CHECK_COMPRESS then
		self.objects["Text_prompt"]:setString("检查更新中...")
	end
end

--
function _M:assetsUpdateEvent(event)
	local eventCode, errorCode = event:getEventCode(), event:getCURLECode()
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
		self.objects["Text_prompt"]:setString("客户端损坏, 请下载新的安装包" )
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
		local percent = event:getPercent()
		self.objects["LoadingBar_load"]:setPercent(percent)
		local totalStr = __toSizeStr(self.updateInfo.total)
		local curStr = __toSizeStr(self.updateInfo.total * percent / 100)
		self.objects["Text_prompt"]:setString("载入中: " .. curStr .. "/" .. totalStr)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
		local title = "更新失败"
		local content = "#k游戏维护中#k\n请留意官网开服公告"
		local onSure = function() cc.Director:getInstance():endToLua() end
		gg.utils.showMessageTip(title, content, onSure)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
		_Loaded_New_Module = {}
	    sp.SkeletonAnimation:removeAllSkeletonData()
	    cc.Director:getInstance():getTextureCache():removeAllTextures()
		self:destroyAssetsManager()
		self:refreshWithLogin()
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
		local title = "更新失败"
		local content = "更新失败, 是否重试"
		local onSure = handler(self, self.refreshWithUpdate)
		local onCancel = function() cc.Director:getInstance():endToLua() end
		gg.utils.showMessageTip(title, content, onSure, onCancel)	end
end

return _M