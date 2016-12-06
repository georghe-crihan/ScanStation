;DEBUG EQU 0

      .386                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

      include windows.inc
      include user32.inc
      include kernel32.inc
      include presets.inc
      include idc.inc ; Resources


      includelib user32.lib
      includelib kernel32.lib

.data

szUnassigned     db 'Unassigned', 0
szFullPathFormat db '%s\ScanSttn.ini', 0
szTargetWindowSection db 'TargetWindow', 0
szWindowClassKey  db 'WindowClass', 0
szWindowTitleKey db 'WindowTitle', 0
szKeyResourceId db 'ResourceId', 0
szButtonB      db 'Button_B', 0
szButtonC      db 'Button_C', 0
szButtonD      db 'Button_D', 0
szButtonG      db 'Button_G', 0
szDefaultWindowTitle db 'DocTWAIN (Plustek OpticBook 3800)', 0
szDefaultWindowClass db '#32770', 0

IFDEF DEBUG
szHandleFormat db '%X', 0
szTrueClassName    db 'True class name', 0
szTrueHandle   db 'True handle', 0
szReturnedHandle db 'Returned handle', 0
ENDIF

extern WndLatch:dword
extern TargetWndHandle:dword
extern szFullWndTitle:byte
extern szWndTitle:byte

extern szBtnBTitle:byte
extern szFullBtnBTitle:byte
extern BtnBLatch:dword
extern TargetBtnBHandle:dword

extern szBtnCTitle:byte
extern szFullBtnCTitle:byte
extern BtnCLatch:dword
extern TargetBtnCHandle:dword

extern szBtnDTitle:byte
extern szFullBtnDTitle:byte
extern BtnDLatch:dword
extern TargetBtnDHandle:dword

extern szBtnGTitle:byte
extern szFullBtnGTitle:byte
extern BtnGLatch:dword
extern TargetBtnGHandle:dword


.data?

IFDEF DEBUG
szBuf          db 1024 DUP(?)
ENDIF
szFullFileName db 1024 DUP(?)
szWindowClass  db 1024 DUP(?)
szWindowTitle  db 1024 DUP(?)

.code

SetButton proc hWndOwn:DWORD, hWnd:DWORD, 
    resId:DWORD, resIdOwn:DWORD, checkResId:DWORD,
    lpLatch:DWORD, lpTargetHandle:DWORD,
    szTitle:DWORD, szFullTitle:DWORD,
    szSection:DWORD, szKeyName:DWORD

    LOCAL dwResId:DWORD

    invoke GetPrivateProfileInt, szSection, szKeyName, resId, addr szFullFileName
    mov dwResId, eax

; Get the target button
    .if dwResId != 0
        invoke GetDlgItem, hWnd, dwResId    

        mov ecx, lpTargetHandle
        mov [ecx], eax
    .else
        mov ecx, lpTargetHandle
        mov DWORD PTR [ecx], 0
    .endif

; Get target text
    .if dwResId != 0
        invoke GetDlgItemText, hWnd, dwResId, szTitle, 1024
    .endif

; Latch the resource
    mov eax, lpLatch
    mov DWORD PTR [eax], 1
; Set own button text 
    .if dwResId != 0
        invoke SetDlgItemText, hWndOwn, resIdOwn, szFullTitle
    .else
        invoke SetDlgItemText, hWndOwn, resIdOwn, addr szUnassigned
    .endif
; Toggle onwn checkbox
    invoke GetDlgItem, hWndOwn, checkResId
    invoke SendMessage, eax, BM_SETCHECK, BST_CHECKED, 0

    ret
SetButton endp

; Search window by class name and window title, load the presets from .ini file
;HANDLE GetDllVersion(HANDLE hWndOwn)
LoadPresets proc hWndOwn:DWORD
  LOCAL hWnd:DWORD

    pusha

; Get full path to the profile file name
    invoke GetCurrentDirectory, 1024, addr szWindowTitle
    invoke wsprintf, addr szFullFileName, addr szFullPathFormat, addr szWindowTitle

; Get the class name and window title
    invoke GetPrivateProfileString, addr szTargetWindowSection, 
           addr szWindowClassKey, addr szDefaultWindowClass, 
           addr szWindowClass, 1024, addr szFullFileName

    invoke GetPrivateProfileString, addr szTargetWindowSection, 
           addr szWindowTitleKey, addr szDefaultWindowTitle, 
           addr szWindowTitle, 1024, addr szFullFileName

    invoke FindWindow, addr szWindowClass, addr szWindowTitle
    mov hWnd, eax

    .if eax != 0
        mov WndLatch, 1
        mov TargetWndHandle, eax
        invoke lstrcpy, addr szWndTitle, addr szWindowTitle
        invoke SetDlgItemText, hWndOwn, IDC_HIDE, addr szFullWndTitle
        invoke GetDlgItem, hWndOwn, IDC_WND_LATCH
        invoke SendMessage, eax, BM_SETCHECK, BST_CHECKED, 0
    .else
        jmp @@return
    .endif

IFDEF DEBUG
    invoke GetClassName, hWnd, addr szBuf, 1024
    invoke MessageBox, hWndOwn, addr szBuf, addr szDefaultClassName, MB_OK

    invoke wsprintf, addr szBuf, addr szHandleFormat, hWnd
    invoke MessageBox, hWndOwn, addr szBuf, addr szTrueHandle, MB_OK

    invoke GetDlgCtrlID, hWnd
    invoke wsprintf, addr szBuf, addr szHandleFormat, eax
    invoke MessageBox, hWndOwn, addr szBuf, 0, MB_OK
ENDIF

; Set the buttons
    ; Preview
    invoke SetButton, hWndOwn, hWnd, 1020, IDC_PRESS_B, IDC_BTN_B_LATCH,
           addr BtnBLatch, addr TargetBtnBHandle, 
           addr szBtnBTitle, addr szFullBtnBTitle,
           addr szButtonB, addr szKeyResourceId

    ; Scan
    invoke SetButton, hWndOwn, hWnd, 1, IDC_PRESS_C, IDC_BTN_C_LATCH,
           addr BtnCLatch, addr TargetBtnCHandle, 
           addr szBtnCTitle, addr szFullBtnCTitle,
           addr szButtonC, addr szKeyResourceId


    ; Exit
    invoke SetButton, hWndOwn, hWnd, 2, IDC_PRESS_D, IDC_BTN_D_LATCH,
           addr BtnDLatch, addr TargetBtnDHandle, 
           addr szBtnDTitle, addr szFullBtnDTitle,
           addr szButtonD, addr szKeyResourceId

    ; Leave unassigned
    invoke SetButton, hWndOwn, hWnd, 0, IDC_PRESS_G, IDC_BTN_G_LATCH,
           addr BtnGLatch, addr TargetBtnGHandle, 
           addr szBtnGTitle, addr szFullBtnGTitle,
           addr szButtonG, addr szKeyResourceId
@@return:
    popa
    ret
LoadPresets endp

end
