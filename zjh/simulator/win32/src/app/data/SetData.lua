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

function SetData.setDubType(nDub)
	SetData._dubType = nDub
    cc.UserDefault:getInstance():setIntegerForKey(app.UserDefault.KW_INT_SET_DUB, nDub)
end

function SetData.getDubType()
	SetData._dubType = SetData._dubType or cc.UserDefault:getInstance():getIntegerForKey(app.UserDefault.KW_INT_SET_DUB, 0)
    return SetData._dubType
end

function SetData.setOpenDub(flag)
    SetData._isOpenDub = flag
    cc.UserDefault:getInstance():setBoolForKey(app.UserDefault.KW_BOOL_SET_OPEN_DUB, flag)
end

function SetData.isOpenDub()
    SetData._isOpenDub = SetData._isOpenDub or cc.UserDefault:getInstance():getBoolForKey(app.UserDefault.KW_BOOL_SET_OPEN_DUB, true)
    return SetData._isOpenDub
end

return SetData