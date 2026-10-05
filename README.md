# shell-run
Launches a process via the desktop Explorer using IShellDispatch2.ShellExecute.

Windows x64 / .NET 10; NativeAOT compatible. Build the csproj with Visual Studio
2026 C++ tools, ATL and Windows SDK. Native compilation is incremental.

Call SevenKeyboard.ShellRun.Run(file, arguments) on an STA thread.
Quote arguments as a Windows command line. Failure throws; success only means
the request was accepted. The child uses Explorer's context, which is not always
unelevated. Do not use the runas verb when requesting ordinary privileges.

Distribute ShellRun.Native.dll beside the application. Build first, then sign
the final binaries if required; builds do not sign automatically.
