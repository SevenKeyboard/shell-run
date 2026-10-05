@echo off
setlocal
set "VSROOT="
if "%~1"=="" (
    echo Usage: build.cmd Debug or Release
    exit /b 1
)
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.VC.ATL -property installationPath`) do set "VSROOT=%%i"
if not defined VSROOT (
    echo Visual Studio C++ build tools with ATL are required.
    exit /b 1
)
"%VSROOT%\MSBuild\Current\Bin\MSBuild.exe" "%~dp0ShellRun.Native.vcxproj" /nologo /v:minimal /p:Configuration=%1 /p:Platform=x64
exit /b %ERRORLEVEL%
