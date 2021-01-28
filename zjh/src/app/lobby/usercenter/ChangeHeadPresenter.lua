--[[
@brief  修改头像
]]
local app = cc.exports.gEnv.app
local zjh_defs = cc.exports.gEnv.misc_defs.zjh_defs
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local ChangeHeadPresenter = class("ChangeHeadPresenter", app.base.BasePresenter)

-- UI
ChangeHeadPresenter._ui         = requireLobby("app.lobby.usercenter.ChangeHeadLayer")

local _gender, _avatar = nil, nil 

function ChangeHeadPresenter:init()
    self:initSelectedHead()
    _gender, _avatar = nil, nil
end

function ChangeHeadPresenter:initSelectedHead()
    local avatar = app.data.UserData.getAvatar()
    local gender = app.data.UserData.getGender()
    self._ui:getInstance():selected(gender, avatar)
end

function ChangeHeadPresenter:reqChangeHead(gender, avatar)
    local gameStream = app.connMgr.getGameStream()

    local po = gameStream:get_packet_obj()
    local sessionid = app.data.UserData.getSession() or 222
    if po ~= nil then
        self:dealLoadingHintStart("头像修改中")     
        _gender, _avatar = gender, avatar
        po:writer_reset()
        po:write_byte(gender)                   
        po:write_string(tostring(avatar))                   
        gameStream:send_packet(sessionid, zjh_defs.MsgId.MSGID_CHANGE_USER_INFO_REQ)            
    end
end

function ChangeHeadPresenter:onReqChangeUserinfo(flag)
    self:dealLoadingHintExit()
	if flag then
        app.data.UserData.setGender(_gender)
        app.data.UserData.setAvatar(_avatar)
        self._ui:getInstance():exit()
        self:dealTxtHintStart("头像修改成功！")        
    else
        self:dealTxtHintStart("头像修改失败")
	end
end

return ChangeHeadPresenter