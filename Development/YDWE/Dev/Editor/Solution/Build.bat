@echo off

@set /a beg = %date:~8,2% * 8640000 + %time:~0,2% * 360000 + %time:~3,2% * 6000 + %time:~6,2% * 100 + %time:~9,2%

echo "�������� %date%"
echo "�������� %date%">%2

@echo "����binĿ¼"
@echo "����binĿ¼" >> %2
rd /s /q ..\..\Build\bin\%1 >> %2
md ..\..\Build\bin\%1 >> %2

@echo "����objĿ¼"
@echo "����objĿ¼" >> %2
rd /s /q ..\..\Build\obj\%1 >> %2
md ..\..\Build\obj\%1 >> %2

@echo "����libĿ¼"
@echo "����libĿ¼" >> %2
rd /s /q ..\..\Build\lib\%1 >> %2
md ..\..\Build\lib\%1 >> %2

@echo "����publishĿ¼"
@echo "����publishĿ¼" >> %2
rd /s /q ..\..\Build\publish\%1 >> %2
md ..\..\Build\publish\%1 >> %2

@echo "����uiĿ¼"
@echo "����uiĿ¼" >> %2
rd /s /q ..\..\UI\bin\ >> %2
rd /s /q ..\..\UI\out\ >> %2
rd /s /q ..\..\UI\txt\ >> %2

call Compile.bat %1 %2

@echo "������publishĿ¼"
@echo "������publishĿ¼" >> %2
xcopy ..\..\Build\bin\%1 ..\..\Build\publish\%1 /d /y /e /exclude:..\Script\PublishXCopyExceptionDescription.txt >> %2

@set /a end = %date:~8,2% * 8640000 + %time:~0,2% * 360000 + %time:~3,2% * 6000 + %time:~6,2% * 100 + %time:~9,2%
@set /a t = (%end% - %beg%)/100.
@echo "������ʱ %t% s." >> %2
