#pragma once

#include <winsock2.h>

BOOL FireWallAddApplication(LPCWSTR lpszProcessImageFileName, LPCWSTR lpszRegisterName);

// TODO: �����ü̳�����װһ�£����£�

/*
struct CWindowsFirewall
{
	virtual BOOL addApplication(LPCWSTR imageFireName, LPCWSTR registerName) = 0;
	// ...
};

class CXXXFirewall : public CWindowsFirewall
{
	// ʵ�ֺ���
};

*/