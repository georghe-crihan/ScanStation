  ; =========-===============================
  ; scanintf.inc copyright MASM32 1998 - 2005
  ; =========================================

IFNDEF SCANINTF_INC
SCANINTF_INC equ <1>

MY_VID equ 07b3h
MY_PID equ 1300h

; See the spec for Genesys GL84x chipsets
; Register 6Dh is GPIO[8:1]
GPIO_8_1                equ 6Dh

; From sane-backends/backend/genesys_low.h
IFDEF USE_LIBUSB
REQUEST_TYPE_IN         equ (LIBUSB_REQUEST_TYPE_VENDOR+LIBUSB_ENDPOINT_IN)
REQUEST_TYPE_OUT        equ (LIBUSB_REQUEST_TYPE_VENDOR+LIBUSB_ENDPOINT_OUT)
ENDIF
REQUEST_REGISTER        equ 0Ch
VALUE_SET_REGISTER	equ 83h
VALUE_READ_REGISTER	equ 84h
GPIO_READ		equ 8Ah
INDEX                   equ 0

BW_BUTTON_MASK     equ 04h
GRAY_BUTTON_MASK   equ 08h
COLOR_BUTTON_MASK  equ 20h
DELETE_BUTTON_MASK equ 40h


scanintf_open PROTO
scanintf_read_buttons PROTO dev :DWORD, hWnd :DWORD
scanintf_close PROTO dev :DWORD
scanintf_strerror PROTO

ELSE
echo -------------------------------------------
echo WARNING Duplicate include file scanintf.inc
echo -------------------------------------------
ENDIF

