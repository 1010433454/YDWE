#include <Windows.h>
#include <string>
#include <memory>
#include <base/hook/iat.h>
#include <base/hook/fp_call.h>
#include <base/util/unicode.h>
#include <base/win/font/utility.h>

class FontManager
{
public:
	FontManager(const char* name, size_t size);
	~FontManager();
	void postWindow(HWND hWnd);

private:
	HFONT font_;
};

std::unique_ptr<FontManager> g_fontptr;

namespace real
{
	uintptr_t CreateWindowExA = 0;
}

namespace fake
{
	HWND WINAPI CreateWindowExA(DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName, DWORD dwStyle, int x, int y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam)
	{
		HWND  hWnd = base::std_call<HWND>(real::CreateWindowExA, dwExStyle, lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
		if (g_fontptr) g_fontptr->postWindow(hWnd);
		return hWnd;
	}
}

FontManager::FontManager(const char* name, size_t size)
: font_(NULL)
{
	font_ = ::CreateFontA(
		base::font::size_to_height(size), //������߼��߶�
		0,                                //�߼�ƽ���ַ����
		0,                                //��ˮƽ�ߵĽǶ�
		0,                                //���߷�λ�Ƕ�
		FW_DONTCARE,                      //���Σ�����
		FALSE,                            //���Σ�б��
		FALSE,                            //���Σ��»���
		FALSE,                            //���Σ�����
		DEFAULT_CHARSET,                  //�ַ���
		OUT_DEFAULT_PRECIS,               //�������
		CLIP_DEFAULT_PRECIS,              //���ؾ���
		DEFAULT_QUALITY,                  //���Ʒ��
		DEFAULT_PITCH | FF_DONTCARE,      //��б��
		base::u2a(name).c_str()     //����
		);

	if (font_ != NULL)
	{
		real::CreateWindowExA = base::hook::iat(
			::GetModuleHandle(NULL),
			"user32.dll",
			"CreateWindowExA",
			(uintptr_t)fake::CreateWindowExA);
	}
}

FontManager::~FontManager()
{
	if (font_)
	{
		::DeleteObject(font_);
		base::hook::iat(::GetModuleHandle(NULL),
			"user32.dll",
			"CreateWindowExA",
			(uintptr_t)fake::CreateWindowExA);
	}
}

void FontManager::postWindow(HWND hWnd)
{
	if (font_) ::PostMessage(hWnd, WM_SETFONT, (WPARAM)(HFONT)(font_), (LPARAM)(BOOL)(0));
}

bool SetFontByName(const char* name, size_t size)
{
	g_fontptr.reset(new FontManager(name, size));
	return true;
}

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, LPVOID pReserved)
{
	if (reason == DLL_PROCESS_ATTACH)
	{
		::DisableThreadLibraryCalls(module);
	}
	else if (reason == DLL_PROCESS_DETACH)
	{
		g_fontptr.reset();
	}
	return TRUE;
}

const char *PluginName()
{
	return "YDFont";
}
