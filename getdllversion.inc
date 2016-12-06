  ; ==============================================
  ; getdllversion.inc copyright MASM32 1998 - 2005
  ; ==============================================

IFNDEF GETDLLVERSION_INC
GETDLLVERSION_INC equ <1>

MAKEDLLVERULL PROTO major :DWORD, minor :DWORD, build :DWORD, qfe :DWORD
GetDllVersion PROTO lpszDllName :DWORD, bIgnoreBuildAndPlatform :DWORD
DllGetVersion typedef PROTO STDCALL DLLVERSIONINFO :DWORD

; FIXME: This doesn't belong here!
NOTIFYICONDATAW_V1_SIZE = 152
NOTIFYICONDATAW_V2_SIZE = 152
NOTIFYICONDATAW_V3_SIZE = 152

ELSE
echo ------------------------------------------------
echo WARNING Duplicate include file getdllversion.inc
echo ------------------------------------------------
ENDIF

