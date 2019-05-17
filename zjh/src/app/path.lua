
--[[
@brief 热更搜索路径
]]

local path = {}

if CC_HOTPATCH then
    print("add zjh search path") 
    -- zjh
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_zjh/src/", true)
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_zjh/res/", true)
    print("add jdnn search path") 
    -- jdnn
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_jdnn/src/", true)
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_jdnn/res/", true)

    -- qznn
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_qznn/src/", true)
    cc.FileUtils:getInstance():addSearchPath(cc.FileUtils:getInstance():getWritablePath() .. "patch_qznn/res/", true)
end

return path