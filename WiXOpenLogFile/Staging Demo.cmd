=========================================================

Batch file 1, this installs remotely, for sccm you may ignore the start path that uses psexec.exe but it may help when you want to run things immediatley w/o using SCCM or when you don't have sccm installed

Install.bat
======================Cut here====================

@echo off

REM Below line is to install the PowerShell in silent mode
psexec.exe -accepteula @serverlist.txt cmd /c \\fileserver1\C$\myapp.x86.v5.5.4.743\Microsoft.Powershell.1.0.Package\windowsserver2003-kb926139-v2-x86-enu.exe /quiet 

REM Below line is to set the PowerShell ExecutionPolicy to RemoteSigned
psexec.exe -accepteula @serverlist.txt -u DOMAIN\user -p P@ssw0rd cmd /c "echo . | powershell Set-ExecutionPolicy RemoteSigned | powershell Get-ExecutionPolicy"

REM Below line is to install the myapp in silent mode with the default options
psexec.exe -accepteula @serverlist.txt -u DOMAIN\user -p P@ssw0rd cmd /c msiexec.exe /i \\fileserver1\myapp.x86.v5.5.4.743\myappSetup_x86.msi /quiet 

psexec.exe -accepteula @serverlist.txt -u DOMAIN\user -p P@ssw0rd cmd /c msiexec.exe /i \\fileserver1\myapp.x64.v5.5.4.743\myappSetup_x64.msi /quiet 

REM Below line copies the config file to the bin directory. Please change the source and destination paths accordingly
psexec.exe -accepteula @serverlist.txt -u DOMAIN\user -p P@ssw0rd cmd /c copy \\fileserver1\configfiles\myapp.exe.config "C:\Program Files\myapp\bin"

REM Below line starts the myapp services
psexec -accepteula @serverlist.txt -u DOMAIN\user -p P@ssw0rd cmd /c net start myservice

===================Cut here=================================

Batch file 2
This uses multiple files (stage.cmd and postinst.cmd,) but uses parameters to be passed on to the .msi and is quite flexible.\
  here registry is applied in postinst( to point people to Boston or NJ servers) but you may merge it all in one



STAGE.CMD

=============================================CUT HERE======================================================
@echo off
rem ---------------------------------------------------------
rem STAGE.CMD - standard entry point for launching software
rem
rem If PreInst.CMD or PostInst.CMD are present, STAGING.CMD
rem will call them before and after MSIEXEC.EXE respectively
rem
rem If PreInst.CMD or PostInst.CMD detect fatal errors they
rem must set the ERRORLEVEL > 0.
rem
rem Note that the %LOGFILE% environment variable is
rem visible to child processes of STAGING.CMD, so PreInst.CMD
rem and PostInst.CMD can log their progress here too
rem ---------------------------------------------------------

rem ---------------------------------------------------------
rem Define key global variables
rem MSIFILE - MSI file name
rem LOGFILE - Log file for STAGING.CMD
rem MSILOG  - Log file for MSIEXEC.EXE
rem ---------------------------------------------------------
set BaseAppName=Bloomberg_BTSG3_UI_9.14
set BaseAppLoggingName=%BaseAppName%_b01
set here=%~dp0
cd %here%

set LOGDIR=%SystemRoot%
if exist %TMP% set LOGDIR=%TMP%
if exist C:\Winnt\SGLogs set LOGDIR=C:\Winnt\SGLogs
if exist %SystemRoot%\Debug\Apps set LOGDIR=%SystemRoot%\Debug\Apps

set MSIFILE=%BaseAppName%.MSI
set LOGFILE=%LOGDIR%\%BaseAppLoggingName%.LOG
set MSILOG=%LOGDIR%\%BaseAppLoggingName%_MSIEXEC.LOG

rem ---------------------------------------------------------
rem Log startup
rem ---------------------------------------------------------
.\writelog -s%BaseAppName% -tI "Beginning installation of %BaseAppLoggingName%"
echo Beginning installation of %BaseAppLoggingName% > %LOGFILE%

rem ---------------------------------------------------------
rem Run pre-installation script if present
rem ---------------------------------------------------------
set ERRORMESSAGE=PreInst.CMD returned an error
if exist PreInst.CMD call PreInst.CMD %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto ERROR

rem ---------------------------------------------------------
rem Invoke MSI
rem ---------------------------------------------------------
set ERRORMESSAGE=MSIexec.exe returned an error

MSIEXEC /I %MSIFILE% REBOOT=ReallySuppress ROOTDRIVE="C:\" SOURCELIST="\\Winpkgsrc1\xpapps\%BaseAppLoggingName%;\\Winpkgsrc2\xpapps\%BaseAppLoggingName%;\\Winpkgsrc3\xpapps\%BaseAppLoggingName%;\\Winpkgsrc4\xpapps\%BaseAppLoggingName%" ALLUSERS=1 /L*V %MSILOG% /qb-! ADDLOCAL=ALL %3 %4 %5 %6 %7 %8 %9
if %errorlevel% == 3010 goto REBOOT
if errorlevel 1 goto ERROR
goto POSTINST

:REBOOT
echo MSIEXEC returned exit code 3010 which means that a reboot is required to complete installation >> %LOGFILE%

rem ---------------------------------------------------------
rem Run post-installation script if present
rem ---------------------------------------------------------
:POSTINST
set ERRORMESSAGE=Postinst.cmd returned an error
if exist PostInst.CMD call PostInst.CMD %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto ERROR

rem ---------------------------------------------------------
rem Clean-up and exit
rem ---------------------------------------------------------
set ERRORMESSAGE=
.\writelog -s%BaseAppName% -tS "Installation of %BaseAppLoggingName% complete"
echo Installation of %BaseAppLoggingName% complete >> %LOGFILE%
set STATUS=Complete
goto END

:ERROR
.\writelog -s%BaseAppName% -tE "An error occured during the installation of %BaseAppLoggingName%"
echo An error occured during the installation of %BaseAppLoggingName% >> %LOGFILE%
set STATUS=Error

:END
echo [EndOfInstallation] >> %LOGFILE%
echo Status=%STATUS% >> %LOGFILE%
if not "%ERRORMESSAGE%" == "" echo ErrorMessage=%ERRORMESSAGE% >> %LOGFILE%
EXIT

=======================================Cut here===========
POSTINST.CMD
=======================================Cut here===========

@echo off

.\tools\RegDACL.exe "HKLM\SOFTWARE\Bloomberg L.P." /GGU:F(CI)
.\tools\RegDACL.exe "HKLM\SOFTWARE\Bloomberg L.P." /GGT:F(CI)

.\tools\xcacls.exe "C:\program files\Blp\btsg3" /Y /T /G users:c administrators:f system:f everyone:c

reg import BO2.reg
reg import NJ2.reg


=======================================Cut here===========