#include "main.h"
#include "SimulatorWin.h"
#include <shellapi.h>

#if _MSC_VER > 1800
#pragma comment(lib,"libcocos2d.lib")
#pragma comment(lib,"libluacocos2d.lib")
#pragma comment(lib,"libsimulator.lib")
#pragma comment(lib,"libSpine.lib")
#pragma comment(lib,"libbox2d.lib")
#pragma comment(lib,"librecast.lib")
#pragma comment(lib,"libbullet.lib")
#else
#pragma comment(lib,"libcocos2d_2013.lib")
#pragma comment(lib,"libluacocos2d_2013")
#pragma comment(lib,"libsimulator_2013")
#pragma comment(lib,"libSpine_2013.lib")
#pragma comment(lib,"libbox2d_2013.lib")
#pragma comment(lib,"librecast_2013.lib")
#pragma comment(lib,"libbullet_2013.lib")
#endif

int APIENTRY _tWinMain(HINSTANCE hInstance,
	HINSTANCE hPrevInstance,
	LPTSTR    lpCmdLine,
	int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
    return SimulatorWin::getInstance()->run();
}
