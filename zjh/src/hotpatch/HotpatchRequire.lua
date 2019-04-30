--[[
@brief 热更文件require
]]

local HotpatchRequire = {}

HotpatchRequire._lobbyList = {} 
HotpatchRequire._jdnnList  = {} 
HotpatchRequire._zjhList   = {} 

-- 大厅相关
function HotpatchRequire.requireLobby(modname)
    table.insert(HotpatchRequire._lobbyList, modname)	
	return require(modname)
end

function HotpatchRequire.reloadLobby()
    for k, modname in ipairs(HotpatchRequire._lobbyList) do
        if package.loaded[modname] then
            package.loaded[modname] = nil
            require(modname)
        end        
	end
end

function HotpatchRequire.unloadLobby()
    HotpatchRequire._lobbyList = {}
end

-- 拼三张
function HotpatchRequire.requireZJH(modname)
    table.insert(HotpatchRequire._zjhList, modname)   
    return require(modname)
end

function HotpatchRequire.reloadZJH()
    for k, modname in ipairs(HotpatchRequire._zjhList) do
        if package.loaded[modname] then
            package.loaded[modname] = nil
            require(modname)
        end        
    end
end

function HotpatchRequire.unloadLobby()
    HotpatchRequire._zjhList = {}
end

-- 经典牛牛
function HotpatchRequire.requireJDNN(modname)
    table.insert(HotpatchRequire._jdnnList, modname)   
    return require(modname)
end

function HotpatchRequire.reloadJDNN()
    for k, modname in ipairs(HotpatchRequire._jdnnList) do
        if package.loaded[modname] then
            package.loaded[modname] = nil
            require(modname)
        end        
    end
end

function HotpatchRequire.unloadJDNN()
    HotpatchRequire._jdnnList = {}
end

return HotpatchRequire