# shell-run

Launches a process via the desktop Explorer using IShellDispatch2.ShellExecute.

Windows x64 / .NET 10 / NativeAOT compatible · 1.0.0

## Build and Reference

The repository includes an **unsigned, prebuilt Release DLL** at
`src/SevenKeyboard.ShellRun/native/win-x64/ShellRun.Native.dll`.
Normal C# builds use this DLL and require only the .NET 10 SDK:

```powershell
dotnet build src/SevenKeyboard.ShellRun -c Release
```

Reference the project from your application, adjusting the relative path:

```xml
<ItemGroup>
  <ProjectReference Include="../shell-run/src/SevenKeyboard.ShellRun/SevenKeyboard.ShellRun.csproj" />
</ItemGroup>
```

Build and publish copy `ShellRun.Native.dll` to the application's output
directory. Deploy it beside the EXE. NativeAOT publishing still requires the
native build tools required by .NET; the prebuilt DLL removes the need to
compile this library's C++ source during ordinary builds.

## Usage

Call `SevenKeyboard.ShellRun.Run` on an STA thread:

```csharp
using System;
using SevenKeyboard;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ShellRun.Run("notepad.exe");
    }
}
```

`Run(file, arguments, directory, operation, show)` accepts optional arguments,
working directory, shell verb and window display mode. Arguments are a Windows
command-line string; the caller is responsible for quoting them.

Failures throw exceptions. Success means Explorer accepted the request,
not that the child finished initializing. Explorer must be available.
The child uses Explorer's context, which is not always unelevated.
Do not use the `runas` verb when requesting ordinary privileges.

## Rebuilding the Native DLL

To build from C++ source instead of using the included DLL, install Visual
Studio 2026 C++ tools (MSVC v145, ATL and Windows SDK), then run:

```powershell
dotnet build src/SevenKeyboard.ShellRun -c Release -p:ShellRunBuildNative=true
```

This builds incrementally into `native/bin/Release` and uses that output for
this build. It does not replace the DLL tracked by Git.

After changing C++ source, refresh the included binary explicitly from the
repository root:

```powershell
$native = 'src/SevenKeyboard.ShellRun/native'
& "$native/build.cmd" Release Rebuild
if ($LASTEXITCODE -ne 0) { throw 'Native build failed.' }
Copy-Item "$native/bin/Release/ShellRun.Native.dll" "$native/win-x64/ShellRun.Native.dll"
```

Commit the matching C++ source and prebuilt DLL together. Builds do not sign
binaries automatically. Keep the repository's included DLL unsigned; sign the
EXE and DLL in your application's release output if required by your deployment.

[The Unlicense](LICENSE)
