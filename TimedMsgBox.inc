  ; ============================================
  ; TimedMsgBox.inc copyright MASM32 1998 - 2005
  ; ============================================

IFNDEF TIMEDMSGBOX_INC
TIMEDMSGBOX_INC equ <1>

; int TimedMessageBox(HWND hWnd, TCHAR *szMsgText, TCHAR *szCaption, UINT uType)
TimedMessageBox PROTO hWnd:DWORD, szMsgText:DWORD, szCaption:DWORD, uType:DWORD

ELSE
echo ----------------------------------------------
echo WARNING Duplicate include file TimedMsgBox.inc
echo ----------------------------------------------
ENDIF

