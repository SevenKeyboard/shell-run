//==============================================================
// ShellRun — Explorer-based execution through IShellDispatch2.
// GitHub: https://github.com/SevenKeyboard/shell-run
// Author: SevenKeyboard Ltd. (2026)
// License: The Unlicense (Original AHK implementation by Lexikos, CC0 1.0)
//
// References:
// https://learn.microsoft.com/en-us/windows/win32/shell/samples-execinexplorer
// https://www.autohotkey.com/board/topic/72812-run-as-standard-limited-user/page-2#entry522235
// Original attribution: Credit for explaining this method goes to BrandonLive:
// https://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/
//==============================================================
#include <windows.h>
#include <exdisp.h>
#include <shlobj.h>
#include <shldisp.h>
#include <shlguid.h>
#include <atlbase.h>
#include <atlcomcli.h>
#include <new>

// C ABI: UTF-16 inputs borrowed for this call; HRESULT returned.
// Caller must use STA. S_OK means request accepted, not child initialization.
class ComApartment
{
public:
    HRESULT result = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    ~ComApartment() { if (SUCCEEDED(result)) CoUninitialize(); }
};

static HRESULT ExecuteInExplorer(
    const wchar_t* file, const wchar_t* arguments,
    const wchar_t* directory, const wchar_t* operation, int show)
{
    ComApartment apartment;
    if (FAILED(apartment.result)) return apartment.result;

    CComPtr<IShellWindows> windows;
    HRESULT hr = windows.CoCreateInstance(CLSID_ShellWindows, nullptr, CLSCTX_LOCAL_SERVER);
    if (FAILED(hr)) return hr;

    CComVariant empty;
    long hwnd = 0;
    CComPtr<IDispatch> desktop;
    hr = windows->FindWindowSW(&empty, &empty, SWC_DESKTOP, &hwnd, SWFO_NEEDDISPATCH, &desktop);
    if (FAILED(hr)) return hr;
    if (!desktop) return HRESULT_FROM_WIN32(ERROR_NOT_FOUND);

    CComPtr<IServiceProvider> provider;
    hr = desktop.QueryInterface(&provider);
    if (FAILED(hr)) return hr;
    CComPtr<IShellBrowser> browser;
    hr = provider->QueryService(SID_STopLevelBrowser, IID_PPV_ARGS(&browser));
    if (FAILED(hr)) return hr;
    CComPtr<IShellView> view;
    hr = browser->QueryActiveShellView(&view);
    if (FAILED(hr)) return hr;
    CComPtr<IDispatch> background;
    hr = view->GetItemObject(SVGIO_BACKGROUND, IID_PPV_ARGS(&background));
    if (FAILED(hr)) return hr;
    CComPtr<IShellFolderViewDual> folder;
    hr = background.QueryInterface(&folder);
    if (FAILED(hr)) return hr;
    CComPtr<IDispatch> application;
    hr = folder->get_Application(&application);
    if (FAILED(hr)) return hr;
    CComPtr<IShellDispatch2> shell;
    hr = application.QueryInterface(&shell);
    if (FAILED(hr)) return hr;

    CComBSTR path(file);
    if (!path) return E_OUTOFMEMORY;
    CComVariant args, workingDirectory, verb;
    if (arguments) args = arguments;
    if (directory) workingDirectory = directory;
    if (operation) verb = operation;
    if (args.vt == VT_ERROR) return args.scode;
    if (workingDirectory.vt == VT_ERROR) return workingDirectory.scode;
    if (verb.vt == VT_ERROR) return verb.scode;
    return shell->ShellExecute(path, args, workingDirectory, verb, CComVariant(show));
}

extern "C" __declspec(dllexport) HRESULT __stdcall ShellRun(
    const wchar_t* file, const wchar_t* arguments,
    const wchar_t* directory, const wchar_t* operation, int show) noexcept
{
    if (!file || !*file) return E_INVALIDARG;
    try { return ExecuteInExplorer(file, arguments, directory, operation, show); }
    catch (const ATL::CAtlException& e) { return e.m_hr; }
    catch (const std::bad_alloc&) { return E_OUTOFMEMORY; }
    catch (...) { return E_FAIL; }
}
