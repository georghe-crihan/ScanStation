USE_SCANNER_BUTTONS equ 0
USE_PRESETS equ 0
;DEBUG equ 0

; Most of the ideas stolen. Original sources list:
; - BehindTheAsterisks application - below 4096 bytes in size, apparently written in assembly
;   borrowed the resource framework and part of the code. The idea that everything is essentially a window.
; - HideIt - ideas only - sending messages to windows. http://www.expocenter.com/hideit/
; - http://www.codeproject.com/Articles/4768/Basic-use-of-Shell-NotifyIcon-in-Win - Systray icon.
; - ScanButtonD (sourceforge) - Plustek backend not working, some HP gl847 chip based scanner
;   button scanning algorithm. In particular, the two USB Control Message calls.
; - Sane - Plustek backends dead. gl847 backend also dead. Helped steal the scanner calls though
;   (libusb).
; - win32 libusb (examples/bulk.c) - most of the USB handling code.
; - Reverse-engineering plustek usbscan.sys.
; - A good USB standard reference - USB in a NutShell.
;
; TODO:
; - More own controls safety checks
; - NOTIFYICONINFO V1, V2, V3, V4??? size and structures
; 
      .486                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

      include windows.inc
      include user32.inc
      include kernel32.inc
      include shell32.inc
      include macros.asm        ; Switch
IFDEF USE_SCANNER_BUTTONS
      include scanintf.inc
ENDIF
      include getdllversion.inc
      include TimedMsgBox.inc
IFDEF USE_PRESETS
      include presets.inc
ENDIF

      include idc.inc           ; Resources

      includelib user32.lib
      includelib kernel32.lib
      includelib shell32.lib

IFDEF USE_SCANNER_BUTTONS
      GetScannerButtonStatus PROTO hWnd :DWORD
ENDIF
      DialogFunc PROTO :DWORD,:DWORD,:DWORD,:DWORD
      ToggleWindow PROTO hWnd:DWORD, WndState:DWORD
      InitSysTrayIcon PROTO hInstance :DWORD, hWnd :DWORD


MY_TRAY_ICON_ID equ 1

SWM_TRAYMSG equ WM_APP ; the message ID sent to our window

;SWM_SHOW equ WM_APP + 1 ; show the window
;SWM_HIDE equ WM_APP + 2 ; hide the window
;SWM_EXIT equ WM_APP + 3 ; close the window

.data
      assume cs:nothing

IFDEF USE_SCANNER_BUTTONS
dev             dd -1

szDeviceError   db "Error opening device", 0
szDeviceOK      db "success: device %04X:%04X opened", 0

szError         db "Error", 0
szSuccess       db "Success", 0
ENDIF

public WndLatch
WndLatch        dd 0
public TargetWndHandle
TargetWndHandle	dd 0
TargetWndState	dd 0

public szFullWndTitle
szFullWndTitle   db 'Hide: '
public szWndTitle
szWndTitle       db 1024 dup(0)

public BtnBLatch
BtnBLatch        dd 0
public TargetBtnBHandle
TargetBtnBHandle dd 0

public szFullBtnBTitle
szFullBtnBTitle  db 'Press &B: '
public szBtnBTitle
szBtnBTitle      db 1024 dup(0)

public BtnCLatch
BtnCLatch        dd 0
public TargetBtnCHandle
TargetBtnCHandle dd 0

public szFullBtnCTitle
szFullBtnCTitle  db 'Press &C: '
public szBtnCTitle
szBtnCTitle      db 1024 dup(0)

public BtnDLatch
BtnDLatch        dd 0
public TargetBtnDHandle
TargetBtnDHandle dd 0

public szFullBtnDTitle
szFullBtnDTitle  db 'Press &D: '
public szBtnDTitle
szBtnDTitle      db 1024 dup(0)

public BtnGLatch
BtnGLatch        dd 0
public TargetBtnGHandle
TargetBtnGHandle dd 0

public szFullBtnGTitle
szFullBtnGTitle  db 'Press &G: '
public szBtnGTitle
szBtnGTitle      db 1024 dup(0)

szShell32Dll     db "Shell32.dll", 0

szToolTip        db 'Click to show the ScanStation dialog', 0

bOwnDialogState  dd 0

IFDEF DEBUG
szDllVersionFormat db "Major: %08X Minor :%08X", 0
ENDIF

.data?
      assume cs:nothing

; char szString[3052]
;szString	db 3052	dup(?)

szWindowTitle    db ?

; char szDest[1024]
szDest db 1024 dup(?)


IFDEF USE_SCANNER_BUTTONS
extern scanintf_bytes0:byte
ENDIF

targetHWnd DD ?

MyhInstance DD ?

niData NOTIFYICONDATA<>

.code

start:
                mov     szWindowTitle, '@'
		xor	ebx, ebx

IFDEF USE_SCANNER_BUTTONS
                invoke scanintf_open
                mov dev, eax

                .if dev == 0
                   invoke scanintf_strerror
                   invoke MessageBox, ebx, eax, addr szDeviceError, MB_OK
                   jmp @@return0
                .else
                   invoke wsprintf, addr szDest, addr szDeviceOK, MY_VID, MY_PID
                   invoke TimedMessageBox, ebx, addr szDest, addr szSuccess, MB_OK
                .endif
ENDIF

		             		; lpModuleName
		invoke	GetModuleHandleA, ebx
                mov MyhInstance, eax
                                       ; hInstance, "IDD_DIALOG", hWndParent, lpDialogFunc, dwInitParam
		invoke  DialogBoxParamA, eax, offset IDD_SCAN_STATION_DIALOG, ebx, offset DialogFunc, ebx

IFDEF USE_SCANNER_BUTTONS
                invoke scanintf_close, dev
ENDIF
@@return0:
		                  ; uExitCode
		invoke ExitProcess, ebx

IFDEF USE_SCANNER_BUTTONS
; NOTE: a feature - the below simple procedure handles SINGLE buttons pressed ONLY. 
; I.e. NO SUPPORT for multiple key presses BY DEFINITION.
;
GetScannerButtonStatus proc hWnd :DWORD
      invoke scanintf_read_buttons, dev, hWnd
      .if eax == 0
         jmp @@return
      .endif

      mov al, scanintf_bytes0
      clc
      
      test al, GRAY_BUTTON_MASK
      jnz @@next1
      mov eax, IDC_PRESS_G
      stc
      jmp @@return

@@next1:
      test al, COLOR_BUTTON_MASK
      jnz @@next2
      mov eax, IDC_PRESS_C
      stc
      jmp @@return

@@next2:
      test al, BW_BUTTON_MASK
      jnz @@next3
      mov eax, IDC_PRESS_B
      stc
      jmp @@return

@@next3:
      test al, DELETE_BUTTON_MASK
      jnz @@return
      mov eax, IDC_PRESS_D
      stc

@@return:
      ret
GetScannerButtonStatus endp
ENDIF

InitSysTrayIcon proc hInstance :DWORD, hWnd :DWORD
  LOCAL XM :DWORD
  LOCAL YM :DWORD
  LOCAL VerHi :DWORD
  LOCAL VerLo :DWORD

    pusha
     
; zero the structure - note: Some Windows funtions
; require this but I can't be bothered to remember
; which ones do and which ones don't.

    mov ecx, sizeof NOTIFYICONDATA
    mov edi, offset niData
    xor eax, eax
    rep stosb

; get Shell32 version number and set the size of the
; structure note: the MSDN documentation about this is
; a little dubious(see bolow) and I'm not at all sure
; if the code bellow is correct

; FIXME:

      invoke GetDllVersion, addr szShell32Dll, 1
      mov VerHi, edx
      mov VerLo, eax

IFDEF DEBUG
      invoke GetDllVersion, addr szShell32Dll, 0
      invoke wsprintf, addr szDest, addr szDllVersionFormat, edx, eax
      invoke MessageBox, hWnd, addr szDest, 0, MB_OK
ENDIF

      invoke MAKEDLLVERULL, 6,0,0,0
;    if(ullVersion >= )
        mov niData.cbSize, sizeof NOTIFYICONDATA

      invoke MAKEDLLVERULL, 5,0,0,0
;    else if(ullVersion >= )
;        mov niData.cbSize, NOTIFYICONDATA_V2_SIZE

;    else
;        mov niData.cbSize, NOTIFYICONDATA_V1_SIZE


; the ID number can be any UINT you choose and will
; be used to identify your icon in later calls to
; Shell_NotifyIcon


    mov niData.uID, MY_TRAY_ICON_ID


; state which structure members are valid
; here you can also choose the style of tooltip
; window if any - specifying a balloon window:
; NIF_INFO is a little more complicated 


    mov niData.uFlags, NIF_ICON + NIF_MESSAGE + NIF_TIP


; load the icon note: you should destroy the icon
; after the call to Shell_NotifyIcon
;

    invoke GetSystemMetrics, SM_CXSMICON
    mov XM, eax

    invoke GetSystemMetrics, SM_CXSMICON
    mov YM, eax

    invoke LoadImage, hInstance,
                      IDI_ICON,
                      IMAGE_ICON,
                      XM,
                      YM,
                      LR_DEFAULTCOLOR
    mov niData.hIcon, eax
    
; set the window you want to recieve event messages

    mov eax, hWnd
    mov niData.hwnd, eax

; set the message to send
; note: the message value should be in the
; range of WM_APP through 0xBFFF


    mov niData.uCallbackMessage, SWM_TRAYMSG

    invoke lstrcpy, addr niData.szTip, addr szToolTip

    invoke Shell_NotifyIconA, NIM_ADD, addr niData

; free icon handle

    .if niData.hIcon != 0
       invoke DestroyIcon, niData.hIcon
       .if eax != 0
           mov niData.hIcon, 0
       .endif
    .endif

    popa
    ret
InitSysTrayIcon endp

ToggleWindow proc hWnd:DWORD, WndState:DWORD
    mov eax, WndState

    switch DWORD PTR [eax]
    case 0
      invoke ShowWindow, hWnd, SW_HIDE
    case 1
      invoke ShowWindow, hWnd, SW_SHOW
    endsw

    mov eax, WndState    
    xor DWORD PTR [eax], 1
    mov eax, [eax]
    ret
ToggleWindow endp

; INT_PTR __stdcall DialogFunc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
DialogFunc      proc hDlg:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

  LOCAL Point :POINT

		pusha
		mov	ecx, hDlg
		mov	eax, uMsg
		xor	ebx, ebx

		switch eax
		case WM_INITDIALOG
                        invoke InitSysTrayIcon, MyhInstance, hDlg
IFDEF USE_PRESETS
                        invoke LoadPresets, hDlg
ENDIF
                                       ; hWnd, nIDEvent, uElapse, lpTimerFunc
		        invoke SetTimer, ecx, IDT_TIMER, 10, ebx
		        jmp	@@DEF_WND_PROC                       

                case SWM_TRAYMSG
                        switch lParam
                        case WM_LBUTTONDBLCLK
				invoke ToggleWindow, hDlg, addr bOwnDialogState
		                jmp	@@DEF_WND_PROC
                        case WM_CONTEXTMENU
			case WM_RBUTTONDBLCLK
                                invoke ToggleWindow, TargetWndHandle, addr TargetWndState
		                jmp	@@DEF_WND_PROC
                        endsw
		        jmp	@@DEF_WND_PROC                       

		case WM_COMMAND
@@ControlSwitch:
		        switch wParam
		        case IDC_WND_LATCH
                          xor   WndLatch, 1
                          jmp   @@DEF_WND_PROC
                        case IDC_BTN_B_LATCH
                          xor   BtnBLatch, 1
                          jmp   @@DEF_WND_PROC
                        case IDC_PRESS_B
                          .if TargetBtnBHandle != 0
                              invoke SendMessageA, TargetBtnBHandle, BM_CLICK, 0, 0
                          .endif
                          jmp   @@DEF_WND_PROC

                        case IDC_BTN_C_LATCH
                          xor   BtnCLatch, 1
                          jmp   @@DEF_WND_PROC
                        case IDC_PRESS_C
                          .if TargetBtnCHandle != 0
                              invoke SendMessageA, TargetBtnCHandle, BM_CLICK, 0, 0
                          .endif
                          jmp   @@DEF_WND_PROC

                        case IDC_BTN_D_LATCH
                          xor   BtnDLatch, 1
                          jmp   @@DEF_WND_PROC
                        case IDC_PRESS_D
                          .if TargetBtnDHandle != 0
                              invoke SendMessageA, TargetBtnDHandle, BM_CLICK, 0, 0
                          .endif
                          jmp   @@DEF_WND_PROC

                        case IDC_BTN_G_LATCH
                          xor   BtnGLatch, 1
                          jmp   @@DEF_WND_PROC
                        case IDC_PRESS_G
                          .if TargetBtnGHandle != 0
                              invoke SendMessageA, TargetBtnGHandle, BM_CLICK, 0, 0
                          .endif
                          jmp   @@DEF_WND_PROC

                        case IDC_HIDE
                          invoke ToggleWindow, TargetWndHandle, addr TargetWndState
                        ; Currently falling through
;		          jmp	@@DEF_WND_PROC

;                        case IDC_EXIT
                                          ;  hDlg, nResult
;                          invoke EndDialog, ecx, ebx
                        ; Fall through
                        endsw                          

		        jmp	@@DEF_WND_PROC

		case WM_TIMER
                        .if wParam != IDT_TIMER
		            jmp	@@DEF_WND_PROC
                        .endif
IFDEF USE_SCANNER_BUTTONS
                        invoke GetScannerButtonStatus, hDlg
                        jnc @@SkipScannerButtons

                        mov wParam, eax
                        jmp @@ControlSwitch
ENDIF
@@SkipScannerButtons:
                                           ; lpPoint
                        invoke GetCursorPos, addr Point
                                              ; Point
                        invoke WindowFromPoint, Point.x, Point.y
                        mov targetHWnd, eax

                        ; Ignore myself:
                        ;
                        ; Filter own dialog items
                        .if eax == hDlg
                            jmp @@DEF_WND_PROC
                        .endif

                        ; Filter most of the own dialog elements
                        ; FIXME: Add more items 
                        invoke GetDlgItem, hDlg, IDC_PRESS_B
                        .if eax == targetHWnd
                            jmp @@DEF_WND_PROC
                        .endif

                        invoke GetDlgItem, hDlg, IDC_PRESS_C
                        .if eax == targetHWnd
                            jmp @@DEF_WND_PROC
                        .endif

                        invoke GetDlgItem, hDlg, IDC_WND_LATCH
                        .if eax == targetHWnd
                            jmp @@DEF_WND_PROC
                                          	
                        .endif

                        invoke GetDlgItem, hDlg, IDC_HIDE
                        .if eax == targetHWnd
                            jmp @@DEF_WND_PROC
                        .endif


                        mov eax, targetHWnd
                        .if WndLatch != 1
                            mov TargetWndHandle, eax
                            invoke lstrcpy, offset szWndTitle, offset szDest
                            invoke SetDlgItemTextA, hDlg, IDC_HIDE, offset szFullWndTitle
                        .endif


                        mov eax, targetHWnd
                        .if BtnBLatch != 1
                            mov TargetBtnBHandle, eax
                            invoke lstrcpy, offset szBtnBTitle, offset szDest
                            invoke SetDlgItemTextA, hDlg, IDC_PRESS_B, offset szFullBtnBTitle
                        .endif

                        mov eax, targetHWnd
                        .if BtnCLatch != 1
                            mov TargetBtnCHandle, eax
                            invoke lstrcpy, offset szBtnCTitle, offset szDest
                            invoke SetDlgItemTextA, hDlg, IDC_PRESS_C, offset szFullBtnCTitle
                        .endif

                        mov eax, targetHWnd
                        .if BtnDLatch != 1
                            mov TargetBtnDHandle, eax
                            invoke lstrcpy, offset szBtnDTitle, offset szDest
                            invoke SetDlgItemTextA, hDlg, IDC_PRESS_D, offset szFullBtnDTitle
                        .endif

                        mov eax, targetHWnd
                        .if BtnGLatch != 1
                            mov TargetBtnGHandle, eax
                            invoke lstrcpy, offset szBtnGTitle, offset szDest
                            invoke SetDlgItemTextA, hDlg, IDC_PRESS_G, offset szFullBtnGTitle
                        .endif

                        mov eax, targetHWnd
                                           ; hWnd, Msg, wParam, lParam
                        invoke SendMessageA, eax, WM_GETTEXT, 1024, offset szDest
                                              ; hDlg, nIDDlgItem, lpString, cchMax
;                        invoke GetDlgItemTextA, hDlg, IDC_WINDOW, offset String, 1024
;                                      ; String, szDest
;                        invoke lstrcmp, offset szString, offset szDest
;		         jz	short @@DEF_WND_PROC


		        ; Set text in own dialog.
                                              ; hDlg, nIDDlgItem, lpString
;                        invoke SetDlgItemTextA, hDlg, IDC_WINDOW, offset szDest
                        invoke SetWindowText, hDlg, offset szWindowTitle
		        jmp	short @@DEF_WND_PROC

		case WM_CLOSE
		                        ; hWnd, uIDEvent
                        invoke KillTimer, hDlg, IDT_TIMER
                        invoke Shell_NotifyIconA, NIM_DELETE, addr niData
                                        ; hDlg, nResult
                        invoke EndDialog, hDlg, ebx
;		        jmp	short $+2
		endsw

;		jmp	@@DEF_WND_PROC

@@DEF_WND_PROC:
		popa
		xor	eax, eax
		ret
DialogFunc	endp

; ---------------------------------------------------------------------------

		end start
