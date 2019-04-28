require "model.CommonUI.MessageBoxLayer"
require "model.UIHelp"

_OLD_VERSION = ""
_NEW_VERSION = ""

Update_Information = {}

CheckUpdate_Information = {}

CHECK_STATE_TYPE = 
{
  CHECKING = 0,
  ERROR = 1,
  FIND_NEW = 2,
  FIND_UNFINISH_UPDATE = 3,
  NO_NEW = 4,
  UNZ_FINISH = 5,
  FIND_NEW_CUSTOMER = 6,
}

UpdateState = 
{
  UNCHECKED = 0,
  PREDOWNLOAD_VERSION = 1,
  DOWNLOADING_VERSION = 2,
  VERSION_LOADED = 3,
  PREDOWNLOAD_MANIFEST = 4,
  DOWNLOADING_MANIFEST = 5,
  MANIFEST_LOADED = 6,
  CHECK_ASSETS = 7,
  NEED_UPDATE = 8,
  NEED_RESUME_UPDATE = 9,
  UPDATING = 10,
  UNZIPPING = 11,
  UP_TO_DATE = 12,
  FAIL_TO_UPDATE = 13,
  NEW_CUSTOMER = 14,
}

function onCheckEvent(event)
  local state =  AM:getState()   
  local eventCode = event:getEventCode()
  local errorCode = event:getCURLECode()
  local errorCode_1 = event:getCURLMCode()
  local scene = display.getRunningScene()
  if not scene then
     return
  end
  local scene_name = scene.class.__cname
  
  print("wakawak  ----",errorCode,errorCode_1)
  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
    if scene_name == "UpdateScene" then
      scene:showWindows(state,eventCode) 
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.ERROR
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
    end       
    return
  end
  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
    if scene_name == "UpdateScene" then
      scene:showWindows(state,eventCode) 
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.ERROR
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
    end         
    return     
  end
  if state == UpdateState.NEED_UPDATE and event:getEventCode() == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then       
    local p = AM:getRemoteManifest()
    local str = p:getVersion()
    local m = AM:getLocalManifest()
    local str_1 = m:getVersion()
    local size = AM:getTotalSize()
    _NEW_VERSION = str
    if scene_name == "UpdateScene" then
      scene:showWindows(state,eventCode) 
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.FIND_NEW
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
      CheckUpdate_Information.size = size 
    end
  elseif state == UpdateState.NEED_RESUME_UPDATE and event:getEventCode() == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
    local p = AM:getRemoteManifest()
    local str = p:getVersion()
    _NEW_VERSION = str
    if scene_name == "UpdateScene" then
      scene:showWindows(state,eventCode) 
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.FIND_UNFINISH_UPDATE
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
    end  
  elseif state == UpdateState.NEW_CUSTOMER then
    local p = AM:getRemoteManifest()
    local str = p:getVersion()
    local m = AM:getLocalManifest()
    local str_1 = m:getVersion()
    _NEW_VERSION = str
    if scene_name == "UpdateScene" then
      scene:showWindows(state,eventCode) 
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.FIND_NEW_CUSTOMER
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
    end 
  elseif event:getEventCode() == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then     
    local p = AM:getRemoteManifest()
    local str = p:getVersion()
    local m = AM:getLocalManifest()
    local str_1 = m:getVersion()
    _NEW_VERSION = _OLD_VERSION 
    if scene_name == "UpdateScene" then
      scene:showStep("已是最新版本，正在进入游戏") 
      scene:toLogin()
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.NO_NEW
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
    end
    --LoadResourse() 
    AsyncLoadResourse()
  elseif eventCode == cc.EventAssetsManagerEx.EventCode.CHECK_COMPRESS then
    if scene_name == "UpdateScene" then
      scene:showStep("检查资源文件中") 
    end 
  elseif state == UpdateState.UNZIPPING and eventCode == cc.EventAssetsManagerEx.EventCode.PRE_DECOMPRESS then
    Update_Information.compress_file_num_all = AM:getCompressedFilesNum()
    Update_Information.compress_file_num_remaining = Update_Information.compress_file_num_all
    if scene_name == "UpdateScene" then
       scene:showDetail()
       scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt"):setString("解压中 ".."1".."/"..Update_Information.compress_file_num_all)
       scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(0)
       scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt_0"):setString("00.00".."%")   
    end 
  elseif state == UpdateState.UNZIPPING and eventCode == cc.EventAssetsManagerEx.EventCode.DECOMPRESSING  then
    if scene_name == "UpdateScene" then
      scene:showDetail()
      local p = event:getPercent()
      p = math.ceil(p*100) / 100
      scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(p)
      scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt_0"):setString(p.."%")
    end
  elseif state == UpdateState.UNZIPPING and eventCode == cc.EventAssetsManagerEx.EventCode.DECOMPRESS_FINISHED  then
    Update_Information.compress_file_num_remaining = Update_Information.compress_file_num_remaining - 1
    if scene_name == "UpdateScene" then
      scene:showDetail()
      local num = Update_Information.compress_file_num_all - Update_Information.compress_file_num_remaining + 1
      if num > Update_Information.compress_file_num_all then
         num = Update_Information.compress_file_num_all
      end
      scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt"):setString("解压中 "..num.."/"..self.compress_file_num_all)
      scene.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(0)
    end
  elseif state == UpdateState.UP_TO_DATE and eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
    if scene_name == "UpdateScene" then
      scene:showStep("资源解析完成，进入游戏")
      scene:toLogin()
    else
      CheckUpdate_Information.state = CHECK_STATE_TYPE.UNZ_FINISH
      CheckUpdate_Information.am_state = state
      CheckUpdate_Information.code = eventCode
    end
    --LoadResourse() 
    AsyncLoadResourse()
  end 
end

local UpdateScene = class("UpdateScene",cc.Scene)


function UpdateScene:ctor(...)
  local node = cc.CSLoader:createNode("Interface/Update/Update.csb")
  self.rootnode = node:getChildByName("Panel_1")
  node:setLocalZOrder(1)
  local obj = saveAllChildren(node)
  UIHelp.autoScreenAdaptation(obj)
  self:addChild(node)
  node:getChildByName("text_version"):setString(_OLD_VERSION)
  self:showStep("检查更新中") 
  print("shenmegui -----",CheckUpdate_Information.state)
  if CheckUpdate_Information.state == CHECK_STATE_TYPE.FIND_NEW or
    CheckUpdate_Information.state == CHECK_STATE_TYPE.ERROR or
    CheckUpdate_Information.state == CHECK_STATE_TYPE.FIND_NEW_CUSTOMER or
    CheckUpdate_Information.state == CHECK_STATE_TYPE.FIND_UNFINISH_UPDATE  then 
    self:showWindows(CheckUpdate_Information.am_state,CheckUpdate_Information.code)
  elseif CheckUpdate_Information.state == CHECK_STATE_TYPE.NO_NEW then
    self:showStep("已是最新版本，正在进入游戏") 
    self:toLogin()
  elseif CheckUpdate_Information.state == CHECK_STATE_TYPE.UNZ_FINISH then
    self:showStep("资源解析完成，进入游戏")
    self:toLogin()
  end
end

local function BytesToString(value)
  local str = ""
  if  value > 1024*1024*1024 then
    value = math.ceil(value / (1024*1024*1024)*100 ) / 100
    str = value.."G"
  elseif value > 1024*1024 then
    value = math.ceil(value / (1024*1024)*100 ) / 100
    str = value.."M"
  elseif value > 1024 then
    value = math.ceil(value / (1024)*100 ) / 100
    str = value.."K"
  else
    str = value.."B"
  end    
  return str
end

function UpdateScene:showWindowsUpdate(state,eventCode)
  if self.isShow then
    return
  end
  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
    self.isShow = true
    local node 
    node = MessageBoxLayer:create("Error","更新失败，错误代码"..eventCode,function()
      node:removeFromParent(true)
      self:clear()
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)        
    return             
  end
  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
    local node 
    self.isShow = true
    node = MessageBoxLayer:create("Error","资源解压失败，错误代码"..eventCode,function()
      node:removeFromParent(true)
      self:clear()
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)         
    return
  end
  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
    local node
    self.isShow = true
    node = MessageBoxLayer:create("Error","更新失败，错误代码"..eventCode,function()
      node:removeFromParent(true)
      self:clear()
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)         
    return
  end
  if eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
    local node 
    self.isShow = true
    node = MessageBoxLayer:create("Error","更新失败，错误代码"..eventCode,function()
      node:removeFromParent(true)
      self:clear()
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)         
   return
  end
end

function UpdateScene:showUpdateInformation()
  local str = cc.FileUtils:getInstance():getStringFromFile("update_explain.txt")
  local node = cc.CSLoader:createNode("Interface/Common/Common_Ts_1.csb")
  local action = cc.CSLoader:createTimeline("Interface/Common/Common_Ts_1.csb")
  node:runAction(action)
  action:play("in",false)
  local objects = saveAllChildren(node)
  local txt = cc.Label:createWithTTF(str,"UI/Fonts/FZCQJW.TTF",20,cc.size(388,0),0,0)
  objects.text_box:addChild(txt)
  local size = txt:getContentSize()
  objects.text_box:setScrollBarEnabled(false)
  objects.text_box:setInnerContainerSize(cc.size(size.width,size.height + 20))
  local height = size.height > 200 and size.height or 200
  txt:setPosition(0,height)
  self:addChild(node)  
end

function UpdateScene:showWindows(state,eventCode)
  if self.isShow then
    return
  end

  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
    local node 
    self.isShow = true
    node = MessageBoxLayer:create("Error","检查更新失败，错误代码"..eventCode,function()
      node:removeFromParent(true)
      self:clear()
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)       
    return
  end
  if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
    local node 
    self.isShow = true
    node = MessageBoxLayer:create("Error","资源解压失败，错误代码"..eventCode,function()
      node:removeFromParent(true)
      self:clear()
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)        
    return     
  end
  if state == UpdateState.NEED_UPDATE and eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then       
    local node 
    local str = BytesToString(CheckUpdate_Information.size)
    self.isShow = true
    node = MessageBoxLayer:create("更新信息","检查到新版本".._NEW_VERSION..",需要下载"..str.."大小的文件。\n点击确定，进行更新。",function()
      node:removeFromParent(true)
      self.isShow = false
      self:toUpdate()
    end)
    node:setLocalZOrder(100)
    self:addChild(node)
  end
  if state == UpdateState.NEED_RESUME_UPDATE and eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then       
    local node 
    self.isShow = true
    node = MessageBoxLayer:create("更新信息","检查未完成的更新。\n点击确定，进行更新。",function()
      node:removeFromParent(true)
      self.isShow = false
      self:toUpdate()
    end)
    node:setLocalZOrder(100)
    self:addChild(node)
  end
  if state == UpdateState.NEW_CUSTOMER then       
    self.isShow = true
    local node 
    node = MessageBoxLayer:create("更新信息","当前版本已不支持热更新，请获取最新版本客户端",function()
      node:removeFromParent(true)
      self.isShow = false
    end)
    node:setLocalZOrder(100)
    self:addChild(node)
  end 
end

function UpdateScene:showStep(str)
  self.rootnode:getChildByName("Panel_Down"):getChildByName("txt0"):setVisible(true)
  self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):setVisible(false)
  self.rootnode:getChildByName("Panel_Down"):getChildByName("download"):setVisible(false)
  self.rootnode:getChildByName("Panel_Down"):getChildByName("txt0"):setString(str) 
end

function UpdateScene:showDetail()
    self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):setVisible(true)
    self.rootnode:getChildByName("Panel_Down"):getChildByName("download"):setVisible(true)
    self.rootnode:getChildByName("Panel_Down"):getChildByName("txt0"):setVisible(false)
end

function UpdateScene:clear()
  self:showStep("")
  if AM_Checklistener then 
    cc.Director:getInstance():getEventDispatcher():removeEventListener(AM_Checklistener)
    AM_Checklistener = nil
  end
  if AM_Updatelistener then
    cc.Director:getInstance():getEventDispatcher():removeEventListener(AM_Updatelistener)
    AM_Updatelistener = nil
  end
  AM:release()
end

local resources_scene_back = {
  "Images/update/update1.png",
  "Images/update/update2.png",
  "Images/update/update3.png",
  "Images/update/update4.png",
  "Images/update/update5.png",
  "Images/update/update6.png",
  "Images/update/update7.png",
  "Images/update/update8.png",
  "Images/update/update9.png",
  "Images/update/update10.png",
}

function UpdateScene:toUpdate()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(AM_Checklistener)
    AM_Checklistener = nil

    self:showStep("准备更新")
    self.rootnode:getChildByName("Panel_Middle"):getChildByName("back_image"):setTexture(resources_scene_back[1])
    self.scene_index = 1
    self.cd = 5
    self.passTimes = 0
    self:scheduleUpdateWithPriorityLua(function(dt)
       self.passTimes = self.passTimes + dt
       if self.passTimes >= self.cd then
          self.passTimes = 0
          self.scene_index = self.scene_index + 1 
          if self.scene_index > #resources_scene_back then
             self.scene_index = 1
          end
          self.rootnode:getChildByName("Panel_Middle"):getChildByName("back_image"):setTexture(resources_scene_back[self.scene_index])
       end
    end,0)
    
    local function onUpdateEvent(event)
      local eventCode = event:getEventCode()
      local state = AM:getState()

      if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
        self:showWindowsUpdate(state,eventCode)        
        return             
      end
      if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
        self:showWindowsUpdate(state,eventCode)        
        return
      end
      if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
        self:showWindowsUpdate(state,eventCode)          
        return
      end
      if eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
        self:showWindowsUpdate(state,eventCode)          
        return
      end
      if state == UpdateState.UPDATING and eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
        self:showDetail()
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt"):setString("更新中")
        self.rootnode:getChildByName("Panel_Down"):getChildByName("download"):getChildByName("txt"):setString("数据总大小：")
        local num = AM:getTotalSize()
        if not self.filesSize or self.filesSize == 0 then
           self.filesSize = num
           local str = BytesToString(self.filesSize)
           self.rootnode:getChildByName("Panel_Down"):getChildByName("download"):getChildByName("txt1"):setString(str)
        elseif num > self.filesSize then
           self.filesSize = num
           local str = BytesToString(self.filesSize)
           self.rootnode:getChildByName("Panel_Down"):getChildByName("download"):getChildByName("txt1"):setString(str)
        end
        local percent = event:getPercent()
        local value = math.ceil(self.filesSize*percent/100)
        value = self.filesSize >  value  and value or self.filesSize
        local str_1 = BytesToString(value)
        self.rootnode:getChildByName("Panel_Down"):getChildByName("download"):getChildByName("txt2"):setString("已下载："..str_1)
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(percent)
        percent = math.ceil(percent*100) / 100
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt_0"):setString(percent.."%")
      elseif state == UpdateState.UNZIPPING and eventCode == cc.EventAssetsManagerEx.EventCode.PRE_DECOMPRESS then
        self:showDetail()
        self.compress_file_num_all = AM:getCompressedFilesNum()
        self.compress_file_num_remaining = self.compress_file_num_all
        if self.compress_file_num_all == 0 then
           return
        end
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt"):setString("解压中 ".."0".."/"..self.compress_file_num_all)
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(0)
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt_0"):setString("00.00".."%") 
      elseif state == UpdateState.UNZIPPING and eventCode == cc.EventAssetsManagerEx.EventCode.DECOMPRESSING  then
        self:showDetail()
        local p = event:getPercent()
        p = math.ceil(p*100) / 100
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(p)
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt_0"):setString(p.."%")      
      elseif state == UpdateState.UNZIPPING and eventCode == cc.EventAssetsManagerEx.EventCode.DECOMPRESS_FINISHED  then
        self.compress_file_num_remaining = self.compress_file_num_remaining - 1
        local num = self.compress_file_num_all - self.compress_file_num_remaining
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("txt"):setString("解压中 "..num.."/"..self.compress_file_num_all)
        self.rootnode:getChildByName("Panel_Down"):getChildByName("back_bar"):getChildByName("bar"):setPercent(0)
      elseif state == UpdateState.UP_TO_DATE and eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
        self:showStep("更新完成，进入游戏")
        self:toLogin()
      end
    end
    AM_Updatelistener = cc.EventListenerAssetsManagerEx:create(AM,onUpdateEvent)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(AM_Updatelistener, 1)
    AM:update()

end

function UpdateScene:toLogin()
  if AM_Checklistener then 
    cc.Director:getInstance():getEventDispatcher():removeEventListener(AM_Checklistener)
    AM_Checklistener = nil
  end
  if AM_Updatelistener then 
    cc.Director:getInstance():getEventDispatcher():removeEventListener(AM_Updatelistener)
    AM_Updatelistener = nil
  end
  if AM then 
    AM:release() 
    AM = nil 
  end
  if _NEW_VERSION == "" then
     _NEW_VERSION = _OLD_VERSION
  end
  local delay = cc.DelayTime:create(0.5)
  --重新加载
  if _OLD_VERSION ~= _NEW_VERSION then   
    display.removeAllSpriteFrames()
    --LoadResourse() 
    AsyncLoadResourse()
  end
  local func = cc.CallFunc:create(function()
          package.loaded["model.enterGame"] = nil
      require("model.enterGame") 
  end)
  self:runAction(cc.Sequence:create(delay,func)) 
end

local cache = cc.SpriteFrameCache:getInstance()
local loadResPath = "UI/Interface/LoadRes/"
local allResTab = {
                  "UI/Images/battle/battle",
                  loadResPath .. "item_big_item",
                  loadResPath .. "Battle_Bad_Head_Plist",
                  loadResPath .. "Battle_Head_Plist",
                  loadResPath .. "enemy_bad_Head_Plist",
                  loadResPath .. "enemy_Head_Plist",
                  loadResPath .. "equip_itemImage",
                  loadResPath .. "Equip_Plist",
                  loadResPath .. "item_small_item",
                  loadResPath .. "Role_bad_Head_Plist_1",
                  loadResPath .. "Role_bad_Head_Plist_2",
                  loadResPath .. "Role_Head_Plist_1",
                  loadResPath .. "Role_Head_Plist_2",
                  loadResPath .. "Role_Head_Plist_3",
                  loadResPath .. "skill",
                  "UI/Images/base/base",
                  "UI/Images/main/map/main_map"}
function LoadResourse()
  print(os.clock(),"start111---")
  for _,v in ipairs(allResTab) do
    cache:addSpriteFrames(v .. ".plist",
           v .. ".png")
  end
  print(os.clock(),"start222---")
end
local addResNum = 1
function AsyncLoadResourse()
  -- body
  isLoadAllRes = false
  if addResNum > #allResTab then
    --display.removeUnusedSpriteFrames()
    --display.removeAllSpriteFrames()
    if ReleaseResMark == true then
      isLoadAllRes = true
      cc.SpriteFrameCache:getInstance():retainAllSpriteFrames()
      cc.TextureCache.dumpCachedTextureInfo(cc.TextureCache:getInstance())
    end
    print("fengbu----------end3",os.clock())
    return
  end
  --[[display.loadSpriteFrames(allResTab[addResNum] .. ".plist",
           allResTab[addResNum] .. ".png",AsyncLoadResourse)]]
  print(allResTab[addResNum],"----")
  display.loadImage(allResTab[addResNum] .. ".png", function ( texture )
    texture:retain()
    cache:addSpriteFrames(allResTab[addResNum] .. ".plist",texture)
    addResNum = addResNum + 1
    AsyncLoadResourse()
  end)
  print("fengbu----------",os.clock())
end

return UpdateScene