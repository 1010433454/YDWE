@call "%VS100COMNTOOLS%\vsvars32.bat"

@echo "�������¹���YDUI��YDWE|Win32"
devenv ../../UI/sln/YDUI.sln /Rebuild "YDWE|Win32"

@echo "�������¹���YDUI��YDTrigger|Win32"
devenv ../../UI/sln/YDUI.sln /Rebuild "YDTrigger|Win32"

@echo "����UI��binĿ¼"
xcopy ..\..\UI\bin ..\..\Build\bin\Release\share\mpq\ /d /y /e

