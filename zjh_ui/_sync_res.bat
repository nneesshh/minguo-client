rmdir /s /q "./lua"
xcopy /sy ..\zjh_robot\lua\*.lua* .\lua\
xcopy /sy robot\config_mgzjh_robot.lua lua\zjh\config\config_mgzjh_robot.lua