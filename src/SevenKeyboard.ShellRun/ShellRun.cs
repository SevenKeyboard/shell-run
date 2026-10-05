using System;
using System.Runtime.InteropServices;

namespace SevenKeyboard;

//==============================================================
// ShellRun — Launches a process via the Explorer shell.
// GitHub: https://github.com/SevenKeyboard/shell-run
// Author: SevenKeyboard Ltd. (2026)
// License: The Unlicense (Original AHK implementation by Lexikos, CC0 1.0)
//==============================================================
public static partial class ShellRun
{
    /// <summary>Asks the desktop Explorer to execute a file in its user context.</summary>
    /// <remarks>
    /// Call on an STA thread. Success means the request was accepted, not that
    /// the child finished initializing. Explorer must be available; its context
    /// is not guaranteed to be unelevated on every system configuration.
    /// Arguments are a command-line string and must be quoted by the caller.
    /// </remarks>
    public static void Run(string file, string? arguments = null, string? directory = null, string? operation = null, int show = 1)
    {
        ArgumentException.ThrowIfNullOrEmpty(file);
        RejectNullCharacter(file, nameof(file));
        RejectNullCharacter(arguments, nameof(arguments));
        RejectNullCharacter(directory, nameof(directory));
        RejectNullCharacter(operation, nameof(operation));

        int result = Execute(file, arguments, directory, operation, show);
        Marshal.ThrowExceptionForHR(result, new IntPtr(-1));
    }

    private static void RejectNullCharacter(string? value, string name)
    {
        if (value?.Contains('\0') == true)
            throw new ArgumentException("Embedded null characters are not supported.", name);
    }

    [LibraryImport("ShellRun.Native.dll", EntryPoint = "ShellRun", StringMarshalling = StringMarshalling.Utf16)]
    [DefaultDllImportSearchPaths(DllImportSearchPath.AssemblyDirectory | DllImportSearchPath.System32)]
    private static partial int Execute(string file, string? arguments, string? directory, string? operation, int show);
}
