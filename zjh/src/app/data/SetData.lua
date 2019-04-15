--[[
@brief  设置信息
]]

local SetData = {}
SetData._isOpenMusic = nil
SetData._isOpenEffect = nil

function SetData.setOpenMusic(flag)
    SetData._isOpenMusic = flag
    cc.UserDefault:getInstance():setBoolForKey("BOOL_SET_MUSIC", flag)
end

function SetData.isOpenMusic()
    SetData._isOpenMusic = SetData._isOpenMusic or cc.UserDefault:getInstance():getBoolForKey("BOOL_SET_MUSIC", true)
    return SetData._isOpenMusic
end

function SetData.setOpenEffect(flag)
    SetData._isOpenEffect = flag
    cc.UserDefault:getInstance():setBoolForKey("BOOL_SET_EFFECT", flag)
end

function SetData.isOpenEffect()
    SetData._isOpenEffect = SetData._isOpenEffect or cc.UserDefault:getInstance():getBoolForKey("KW_BOOL_SET_EFFECT", true)
    return SetData._isOpenEffect
end

return SetData