local SoundUtils = {}

local isOpenMusic = nil
local isOpenEffect = nil

local function resetMusic()
    local tmpIsOpen = app.data.SetData.isOpenMusic()
    if isOpenMusic == tmpIsOpen then
        return
    end
    isOpenMusic = tmpIsOpen
    if isOpenMusic then
        cc.SimpleAudioEngine:getInstance():setMusicVolume(1)
    else
        cc.SimpleAudioEngine:getInstance():setMusicVolume(0)
    end
end

local function resetEffect()
    local tmpIsOpen = app.data.SetData.isOpenEffect()
    if isOpenEffect == tmpIsOpen then
        return
    end
    isOpenEffect = tmpIsOpen
    if isOpenEffect then
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
    else
        cc.SimpleAudioEngine:getInstance():setEffectsVolume(0)
    end
end

function SoundUtils.playMusic(path,bLoop)
    if path == nil or path == "" then
        return
    end
    resetMusic()
    bLoop = bLoop or true
    cc.SimpleAudioEngine:getInstance():preloadMusic(path)
    cc.SimpleAudioEngine:getInstance():playMusic(path,bLoop);
end

function SoundUtils.stopMusic()
    cc.SimpleAudioEngine:getInstance():stopMusic()
end

function SoundUtils.pauseMusic()
    cc.SimpleAudioEngine:getInstance():pauseMusic()
end

function SoundUtils.resumeMusic()
    cc.SimpleAudioEngine:getInstance():resumeMusic()
end

function SoundUtils.playEffect(path)
    if path == nil or path == "" then
        return
    end
    resetEffect()
    cc.SimpleAudioEngine:getInstance():playEffect(path)
end
    
function SoundUtils.pauseEffect()
    cc.SimpleAudioEngine:getInstance():pauseAllEffects()
end

function SoundUtils.resumeEffect()
    cc.SimpleAudioEngine:getInstance():resumeAllEffects()
end

function SoundUtils.setMusciVolumeOn()
    cc.SimpleAudioEngine:getInstance():setMusicVolume(1)
end

function SoundUtils.setMusciVolumeOff()
    cc.SimpleAudioEngine:getInstance():setMusicVolume(0)
end

function SoundUtils.setEffectsVolumeOn()
    cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
end

function SoundUtils.setEffectsVolumeOff()
    cc.SimpleAudioEngine:getInstance():setEffectsVolume(0)
end

function SoundUtils.resetMusicVolume()
    cc.SimpleAudioEngine:getInstance():setMusicVolume(cc.SimpleAudioEngine:getInstance():getMusicVolume())
end

function SoundUtils.resetEffectVolume()
    cc.SimpleAudioEngine:getInstance():setEffectsVolume(cc.SimpleAudioEngine:getInstance():getEffectsVolume())
end

function SoundUtils.musicOn()
    cc.SimpleAudioEngine:getInstance():setMusicVolume(1)
end

function SoundUtils.musicOff()
    cc.SimpleAudioEngine:getInstance():setMusicVolume(0)
end

function SoundUtils.effectOn()
    cc.SimpleAudioEngine:getInstance():setEffectsVolume(1)
end

function SoundUtils.effectOff()
    cc.SimpleAudioEngine:getInstance():setEffectsVolume(0)
end

return SoundUtils