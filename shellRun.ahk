#Requires AutoHotkey v2.0.0+
;==============================================================
; shellRun — Launches a process via the Explorer shell using IShellDispatch2.ShellExecute
;
; GitHub: https://github.com/SevenKeyboard/shell-run
; Author: SevenKeyboard Ltd. (2026)
; License: The Unlicense (Originally by Lexikos, released under CC0 1.0)
;
; Upstream note (verbatim from Lexikos):
;   Credit for explaining this method goes to BrandonLive:
;     https://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/
;
; Documentation / References:
;   ShellRun by Lexikos
;     https://www.autohotkey.com/board/topic/72812-run-as-standard-limited-user/page-2#entry522235
;   Shell.ShellExecute method
;     https://learn.microsoft.com/en-us/windows/win32/shell/shell-shellexecute?redirectedfrom=MSDN
;   Re: Help Updating Lexikos ShellRun for Latest AutoHotkey 2 Release
;     https://www.autohotkey.com/boards/viewtopic.php?t=78190#p404418
;==============================================================
class VersionManager_shellRun
{
    static _ := this._init()
    static _init()    {
        global
        SHELLRUN_VERSION := "1.0.0"
    }
}
shellRun(file, arguments?, directory?, operation?, show?)    {
    static SWC_DESKTOP      := 0x8
        ,SWFO_NEEDDISPATCH  := 0x1
        ,VT_DISPATCH        := 9
        ,VT_EMPTY           := 0
        ,VT_I4              := 3
        ,VT_BYREF           := 16384
        ,VT_UNKNOWN         := 13
        ,S_OK               := 0x00000000
        ,IID_IDispatch
        ,SVGIO_BACKGROUND   := 0
    clsidFromString(str, &clsid)    {
        static NOERROR := 0, CO_E_CLASSSTRING := 0x800401F3
        clsid := buffer(16,0)
        hr := dllCall("Ole32.dll\CLSIDFromString", "WStr",str, "Ptr",clsid.Ptr, "HRESULT")
        return (hr == NOERROR)
    }
    if (!isSet(IID_IDispatch))
        clsidFromString("{00020400-0000-0000-C000-000000000046}", &IID_IDispatch) ;  Define IID_IDispatch.
    shellWindows := comObject("Shell.Application").Windows
    hwndBuf := buffer(4,0)
    desktop := shellWindows.findWindowSW(comValue(VT_EMPTY,0)
        ,comValue(VT_EMPTY,0)
        ,SWC_DESKTOP
        ,comValue(VT_BYREF|VT_I4,hwndBuf.Ptr)
        ,SWFO_NEEDDISPATCH)
    ;  Retrieve top-level browser object.
    try    {
        tlb := comObjQuery(desktop
            ,"{4C96BE40-915C-11CF-99D3-00AA004AE837}"   ;  SID_STopLevelBrowser
            ,"{000214E2-0000-0000-C000-000000000046}")  ;  IID_IShellBrowser
        ;  IShellBrowser.QueryActiveShellView -> IShellView
        if (comCall(15,tlb, "Ptr*",sv:=comValue(VT_UNKNOWN,0), "HRESULT") == S_OK)    {
            ;  IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
            hr := comCall(15,sv, "UInt",SVGIO_BACKGROUND, "Ptr",IID_IDispatch.Ptr, "Ptr*",&pdisp:=0, "HRESULT")
            if (hr == S_OK && pdisp)    {
                ;  Get Shell object.
                shell := comValue(VT_DISPATCH,pdisp).Application
                ;  IShellDispatch2.ShellExecute
                vEmpty := comValue(VT_EMPTY,0)
                shell.shellExecute(file, arguments??vEmpty, directory??vEmpty, operation??vEmpty, show??vEmpty)
            }
        }
    }  finally  {
        tlb:= sv:= ""
    }
}