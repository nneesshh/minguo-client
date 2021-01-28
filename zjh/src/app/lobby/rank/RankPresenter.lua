--[[
@brief  排行榜管理类
]]
local app = cc.exports.gEnv.app
local requireLobby = cc.exports.gEnv.HotpatchRequire.requireLobby

local RankPresenter = class("RankPresenter",app.base.BasePresenter)
RankPresenter._ui = requireLobby("app.lobby.rank.RankLayer")

function RankPresenter:init()   
    local richlist, winlist = self:getRankList()
    self._ui:getInstance():showRankList(richlist, winlist)
end

function RankPresenter:getRankList()    
    local richList, winlist = {}, {}
    for i=1, 100 do        
        local rich  = {}
        rich.id     = i
        rich.gender = i % 2
        rich.avator = math.random(0, 4)
        rich.userid = math.random(111111, 999999)
        rich.gold   = math.ceil(45818 / i)         
        table.insert(richList, rich)
        
        local win  = {}
        win.id     = i
        win.gender = i % 2
        win.avator = math.random(0, 4)
        win.userid = math.random(111111, 999999)
        win.gold   = math.ceil(87845 / i)         
        table.insert(winlist, win)        
    end
    
    return richList, winlist  
end

return RankPresenter