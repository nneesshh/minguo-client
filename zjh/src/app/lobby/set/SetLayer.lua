--[[
@brief  SetLayer 设置界面
@by     鲁诗瀚
]]

local SetLayer = class("SetLayer", app.base.BaseLayer)

SetLayer.csbPath = "lobby/csb/set.csb"

SetLayer.clicks = {
    "background",
    "btn_music_on",
    "btn_music_off",
    "btn_effect_on",
    "btn_effect_off",
}

SetLayer.touchs = {
    "btn_close",
    "btn_switch_account"
}

function SetLayer:onClick(sender)
    SetLayer.super.onClick(self, sender)
    local name = sender:getName()
    if name == "background" then
    	-- self:exit()
    elseif name == "btn_music_on" then
        self:onClickMusicOn()
    elseif name == "btn_music_off" then
        self:onClickMusicOff()
    elseif name == "btn_effect_on" then
        self:onClickEffectOn()
    elseif name == "btn_effect_off" then
        self:onClickEffectOff()
    end    
end

function SetLayer:onTouch(sender, eventType)
    SetLayer.super.onTouch(self, sender, eventType)
    local name = sender:getName()
    if eventType == ccui.TouchEventType.ended then
        if name == "btn_close" then
            self:exit()
        elseif name == "btn_switch_account" then
            self._presenter:dealChangeAccount()
        end
    end
end

function SetLayer:initUI(bflag, gameid)
    local btn =  self:seekChildByName("btn_switch_account")    	
    btn:setVisible(bflag)
end

function SetLayer:onClickMusicOn()
    self:setMusic(false)
end

function SetLayer:onClickMusicOff()
    self:setMusic(true)
end

function SetLayer:onClickEffectOn()
    self:setEffect(false)
end

function SetLayer:onClickEffectOff()
    self:setEffect(true)
end

-- 音乐
function SetLayer:setMusic(flag)
    self._presenter:setMusic(flag)
    self:seekChildByName("btn_music_off"):setVisible(not flag)
    self:seekChildByName("btn_music_on"):setVisible(flag)
end

-- 音效
function SetLayer:setEffect(flag)    
    self._presenter:setEffect(flag)
    self:seekChildByName("btn_effect_off"):setVisible(not flag)
    self:seekChildByName("btn_effect_on"):setVisible(flag)
end

-- 大厅版本号
function SetLayer:setLobbyVersion(ver, visible)
	local txtlobby = self:seekChildByName("txt_version_lobby")
    if txtlobby then
        if ver then
            txtlobby:setString("版本信息：v" .. ver)            
        else
            txtlobby:setString("暂无版本信息")            
        end
        
        txtlobby:setVisible(visible)
	end
end

-- 游戏版本号
function SetLayer:setGameVersion(ver, visible)
    local txtgame = self:seekChildByName("txt_version_game")
    if txtgame then
        if ver then
            txtgame:setString("版本信息：v" .. ver)           
        else
            txtgame:setString("暂无版本信息")            
        end
        
        txtgame:setVisible(visible)
    end
end

return SetLayer