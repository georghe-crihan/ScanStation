;DEBUG EQU 0

      .386                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

      include windows.inc
      include user32.inc
      include kernel32.inc
      include macros.asm
      include TimedMsgBox.inc

      include idc.inc           ; Resources

      includelib user32.lib
      includelib kernel32.lib

.data?

hMsgBoxHook      dd ?
hWndBox          dd ?
hWndOkButton     dd ?
hTimer           dd ?


.code

TimerCallback proc hWnd:DWORD, uMsg:DWORD, idEvent:DWORD, dwTime:DWORD
    invoke SendMessageA, hWndOkButton, BM_CLICK, 0, 0
    ret
TimerCallback endp

; LRESULT CALLBACK CBTProc(int nCode, WPARAM wParam, LPARAM lParam)
CBTProc proc nCode:DWORD, wParam:DWORD, lParam:DWORD
     LOCAL lpRect :RECT
 
    .if nCode < 0
        jmp @@return
    .endif

    switch nCode
    case HCBT_ACTIVATE
        ; Do customization:
        ; Get handle to the message box!
        mov eax, wParam
        mov hWndBox, eax
        ; Hide the OK button
        invoke GetDlgItem, hWndBox, 1
        mov hWndOkButton, eax
        invoke GetWindowRect, hWndOkButton, addr lpRect
        invoke ShowWindow, hWndOkButton, SW_HIDE
        ; Resize the window: trim vertically
        mov eax, lpRect.bottom
        sub eax, lpRect.top
        push eax
        invoke GetWindowRect, hWndBox, addr lpRect
        mov eax, lpRect.left
        sub lpRect.right, eax
        mov eax, lpRect.top
        sub lpRect.bottom, eax
        ; Use height of the button
        pop eax
        add eax, 10 ; extra space
        sub lpRect.bottom, eax
;        invoke SetWindowPos, hWndBox, 0, 
;              lpRect.left, lpRect.top, lpRect.right, lpRect.bottom,
;              SWP_NOMOVE + SWP_NOOWNERZORDER + SWP_NOZORDER
        invoke MoveWindow, hWndBox, 
              lpRect.left, lpRect.top, lpRect.right, lpRect.bottom,
              1
        mov hTimer, rv(SetTimer, 0, 0, 2000, addr TimerCallback)
        xor eax, eax
        ret
    case HCBT_DESTROYWND
        mov eax, hWndBox
        .if wParam != eax
            jmp @@return
        .endif
        invoke KillTimer, hWndBox, hTimer 
        xor eax, eax
        ret
    endsw

@@return:    
    ; Call the next hook, if there is one
    mov eax, rv(CallNextHookEx, hMsgBoxHook, nCode, wParam, lParam)
    ret
CBTProc endp

; int TimedMessageBox(HWND hWnd, TCHAR *szMsgText, TCHAR *szCaption, UINT uType)
TimedMessageBox proc hWnd:DWORD, szMsgText:DWORD, szCaption:DWORD, uType:DWORD
    LOCAL rc :DWORD

    pusha

    ; Install a window hook, so we can intercept the message-box
    ; creation, and customize it
    invoke SetWindowsHookEx,
        WH_CBT,                ; Type of hook 
        addr CBTProc,          ; Hook procedure (see below)
        0,                     ; Module handle. Must be NULL (see docs)
        rv(GetCurrentThreadId) ; Only install for THIS thread!!!
    mov hMsgBoxHook, eax

    ; Display a standard message box
    mov rc, rv(MessageBox, hWnd, szMsgText, szCaption, uType)

    ; remove the window hook
    invoke UnhookWindowsHookEx, hMsgBoxHook

    popa

    mov eax, rc
    ret
TimedMessageBox endp 

end
       