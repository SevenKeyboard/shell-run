#Requires AutoHotkey v1.1.0+
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
;==============================================================
class VersionManager_shellRun
{
    static _ := VersionManager_shellRun._init()
    _init()    {
        global
        SHELLRUN_VERSION := "1.0.0"
    }
}
shellRun(file, shellParams*)    { ;  shellRun(file[, arguments, directory, operation, show])
    local
    static SWC_DESKTOP      := 0x8
        ,SWFO_NEEDDISPATCH  := 0x1
        ,VT_DISPATCH        := 9
        ,VT_EMPTY           := 0
        ,VT_I4              := 3
        ,VT_BYREF           := 16384
        ,S_OK               := 0x00000000
        ,IID_IDispatch
        ,SVGIO_BACKGROUND   := 0
    if (!isSet(IID_IDispatch))    {
        varSetCapacity(IID_IDispatch,16,0)
        dllCall("Ole32.dll\CLSIDFromString"
            ,"WStr","{00020400-0000-0000-C000-000000000046}"
            ,"Ptr",&IID_IDispatch
            ,"Int") ;  Define IID_IDispatch.
    }
    if (shellParams.MaxParams > 4)
        return
    shellWindows := comObjCreate("Shell.Application").Windows
    varSetCapacity(hwnd,4,0)
    desktop := shellWindows.findWindowSW(comObject(VT_EMPTY,0)
        ,comObject(VT_EMPTY,0)
        ,SWC_DESKTOP
        ,comObject(VT_I4|VT_BYREF,&hwnd)
        ,SWFO_NEEDDISPATCH)
    ;  Retrieve top-level browser object.
    ptlb := comObjQuery(desktop
        ,"{4C96BE40-915C-11CF-99D3-00AA004AE837}"   ;  SID_STopLevelBrowser
        ,"{000214E2-0000-0000-C000-000000000046}")  ;  IID_IShellBrowser
    if (ptlb)    {
        ;  IShellBrowser.QueryActiveShellView -> IShellView
        if (dllCall(numGet(numGet(ptlb+0)+15*A_PtrSize), "Ptr",ptlb, "Ptr*",psv:=0, "Int") == S_OK)    {
            ;  IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
            hr := dllCall(numGet(numGet(psv+0)+15*A_PtrSize), "Ptr",psv
                ,"UInt",SVGIO_BACKGROUND, "Ptr",&IID_IDispatch, "Ptr*",pdisp:=0, "Int")
            if (hr == S_OK && pdisp)    {
                ;  Get Shell object.
                shell := comObject(VT_DISPATCH,pdisp,1).Application
                ;  IShellDispatch2.ShellExecute
                shell.shellExecute(file, shellParams*)
            }
            objRelease(psv)
        }
        objRelease(ptlb)
    }
}