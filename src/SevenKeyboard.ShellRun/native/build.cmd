@echo off
setlocal
set "SHELLRUN_VSROOT="
set "SHELLRUN_BUILD_TARGET=Build"
if /i not "%~1"=="Debug" if /i not "%~1"=="Release" (
    echo Usage: build.cmd Debug^|Release [Rebuild]
    exit /b 1
)
if not "%~2"=="" (
    if /i not "%~2"=="Rebuild" (
        echo Usage: build.cmd Debug^|Release [Rebuild]
        exit /b 1
    )
    set "SHELLRUN_BUILD_TARGET=Rebuild"
)
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.VC.ATL -property installationPath`) do set "SHELLRUN_VSROOT=%%i"
if not defined SHELLRUN_VSROOT (
    echo Visual Studio C++ build tools with ATL are required.
    exit /b 1
)
"%SHELLRUN_VSROOT%\MSBuild\Current\Bin\MSBuild.exe" "%~dp0ShellRun.Native.vcxproj" /nologo /v:minimal /t:%SHELLRUN_BUILD_TARGET% /p:Configuration=%1 /p:Platform=x64
exit /b %ERRORLEVEL%
