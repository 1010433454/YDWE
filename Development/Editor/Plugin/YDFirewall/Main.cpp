#include <crtdbg.h>
#include <malloc.h>
#include <iostream>
#include <locale>
#include <boost/exception/all.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/program_options.hpp>
#include <boost/locale.hpp>
#include <winsock2.h>
#include <shellapi.h>
#include <base/util/unicode.h>

#include "FireWall.h"

namespace po = boost::program_options;

static int RunCommand(const char *command)
{
	int result = -1;

	std::wstring wCommand = base::a2w(command);
	boost::replace_all(wCommand, L"'", L"\"");

	int argc;
	LPWSTR *argv = CommandLineToArgvW(wCommand.c_str(), &argc);

	if (argv)
	{
		if (wcscmp(argv[0], L"add") == 0)
		{
			std::wstring application(argv[1]), registeredName(argv[2]);
			boost::trim_if(application, boost::is_any_of(L"\"\t '"));
			boost::trim_if(registeredName, boost::is_any_of(L"\"\t '"));

			result = FireWallAddApplication(application.c_str(), registeredName.c_str()) ? 0 : -1;
		}

		LocalFree(argv);
	}

	return result;
}

int main(int argc, char *argv[])
{
#ifdef _DEBUG
	// ����ģʽ�¼���ڴ�й©
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	// ����CRT��localeΪϵͳlocale
	std::locale::global(std::locale("", LC_CTYPE));

	// ����ķ���ֵ
	int result = 0;

	// ���������в�������ʼ����
	try
	{
		// �����в�������
		po::options_description desc("Accepted command line argments");
		desc.add_options()
			("help,h", "Display this message")
			("command,c", po::value<std::string>(), "Specify sub command. Currently support \"add\"")
			;

		// ���������в���
		po::variables_map vm;
		po::store(po::parse_command_line(argc, argv, desc), vm);
		po::notify(vm);

		// help����
		if (vm.count("help"))
		{
			std::cout << "YDWE Firewall Helper" << std::endl;
			std::cout << desc << std::endl;
		}
		// �Է���ʽ����
		else if (vm.count("command"))
		{
			result = RunCommand(vm["command"].as<std::string>().c_str());
		}
		else
		{
			std::cout << "YDWE Firewall Helper" << std::endl;
			std::cout << desc << std::endl;
		}
	}
	catch (po::error &e)
	{
		std::cout << boost::diagnostic_information(e) << std::endl;
		result = -1;
	}
	catch (boost::exception &e)
	{
		std::cout << boost::diagnostic_information(e) << std::endl;
		result = -1;
	}
	catch (std::exception &e)
	{
		std::cout << e.what() << std::endl;
		std::cout << typeid(e).name() << std::endl;
		result = -1;
	}
	catch (int e)
	{
		result = e;
	}
	catch (...)
	{
		result = -1;
	}

	return result;
}
