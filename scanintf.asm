;DEBUG equ 0
;USE_LIBUSB equ 0

;   Can use native driver interface (usbscan.sy_) instead of libusb. Currently
;   the libusb backend works through the filter driver on the scanner device and
;   the libusb0.dll.
;   FIXME: For now, due to interferrence from the ScanStation button polling, the native
;   TWAIN dialog controls (the "Scan" and "Preview" buttons) produce broken images, so 
;   either use the scanner buttons under ScanStation or the ScanStation ones. 
;   Hopefully, a switch to native (usbscan.sys) interface would fix this. It would definitely 
;   make libusb0.dll and the filter driver redundant.
;   UPDATE: above problem seems to have been fixed through reading the GPIO instead of direct
;   register reads. Switching to the native interface still makes sense in order to get rid of
;   libusb dll and filter driver.

      .486                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

      include windows.inc
      include user32.inc
      include kernel32.inc
      include shell32.inc
      include macros.asm        ; Switch

      include TimedMsgBox.inc

      include scanintf.inc

IFDEF USE_LIBUSB
      include libusb.inc
ENDIF

      includelib user32.lib
      includelib kernel32.lib
      includelib shell32.lib

IFDEF USE_LIBUSB
      includelib libusb.lib
ENDIF

IFDEF USE_LIBUSB
      open_dev PROTO
ELSE
;#define IOCTLVendorRqOut CTL_CODE(0x8000,0x803,METHOD_BUFFERED,FILE_ANY_ACCESS)
IOCTLVendorRqOut equ 08000200Ch

;#define IOCTLVendorRqIn CTL_CODE(0x8000,0x804,METHOD_BUFFERED,FILE_ANY_ACCESS)
IOCTLVendorRqIn equ 080002010h

rqBuf struct
   value       dw ?
   languageId  dw ?
;   value       dd ?
   bufSize     dd ?
   buf         dd ?
   index       dw ?
               dw ? ; pad to make it 16 bytes long, otherwise the IOCTL would return an error
rqBuf ends

;#define IOCTLGetDeviceIds CTL_CODE(0x8000,0x806,METHOD_BUFFERED,FILE_ANY_ACCESS)
IOCTLGetDeviceIds equ 080002018h

deviceIds struct
   idVendor    dw ?
   idProduct   dw ?
   bcdDevice   dw ?
               dw ? ; pad to make it 8 bytes long, otherwise the IOCTL would return an error
deviceIds ends

;#define IOCTLCheckIntf CTL_CODE(0x8000,0x800,METHOD_BUFFERED,FILE_ANY_ACCESS)
IOCTLCheckIntf equ 080002000h
ENDIF

.data

szError         db "Error", 0
szSuccess       db "Success", 0

IFDEF USE_LIBUSB
szExpected1_1   db "1: Expected 1", 0
szExpected1_2   db "2: Expected 1", 0

TIMEOUT         dd 0
ELSE
szIOCTLVendorRqInFailed db "IOCTLVendorRqIn failed (%d)", 0
szIOCTLVendorRqOutFailed db "IOCTLVendorRqOut failed (%d)", 0

szDevicePath   db "\\.\usbscan%d", 0

value          dd 0
outSize        dd 0
ENDIF

.data?
assume cs:nothing

IFNDEF USE_LIBUSB
szMsgBuf       db 1024 dup(?)

devNum         dd ?
;hDevice        dd ?
ids            deviceIds<>
rqB            rqBuf<>
ENDIF

bytes:
public scanintf_bytes0
scanintf_bytes0 db ?
scanintf_bytes1 db ?

.code

IFDEF USE_LIBUSB

;usb_dev_handle *open_dev(void)
open_dev proc

     invoke usb_get_busses
     mov edx, eax

     .while edx!=0
         mov ecx, [edx+usb_bus.devices]
         .while ecx!=0
            lea eax, [ecx+usb_device.descriptor]
            mov ax, [eax+usb_device_descriptor.idVendor]
            .if  ax == MY_VID
               lea eax, [ecx+usb_device.descriptor]
               mov ax, [eax+usb_device_descriptor.idProduct]
               .if ax == MY_PID
                  invoke usb_open, ecx
                  jmp @@return
               .endif
            .endif
         mov ecx, [ecx+usb_device.next]
         .endw
     mov edx, [edx+usb_bus.next]
     .endw

    xor eax, eax

@@return:
    ret
open_dev endp

scanintf_open proc
      invoke usb_init ; initialize the library
      invoke usb_find_busses ; find all busses
      invoke usb_find_devices ; find all connected devices 
      invoke open_dev
      ret
scanintf_open endp

scanintf_close proc dev :DWORD
      invoke usb_close, dev
      ret
scanintf_close endp

scanintf_strerror proc
      invoke usb_strerror
      ret
scanintf_strerror endp

scanintf_read_buttons proc dev :DWORD, hWnd :DWORD
;int usb_control_msg(libusb_device_handle *devh, uint8_t
;   bmRequestType, uint8_t bRequest, uint16_t wValue, uint16_t wIndex, unsigned
;   char *data, uint16_t wLength, unsigned int timeout) Perform a USB control
;   transfer.  Returns the actual number of bytes transferred on success, in
;   the range from and including zero up to and including wLength.  On error a
;   LIBUSB_ERROR code is returned, for example LIBUSB_ERROR_TIMEOUT if the
;   transfer timed out, LIBUSB_ERROR_PIPE if the control request was not
;   supported, LIBUSB_ERROR_NO_DEVICE if the device has been disconnected and
;   another LIBUSB_ERROR code on other failures.  The LIBUSB_ERROR codes are
;   all negative.

      mov scanintf_bytes0, GPIO_8_1
      mov scanintf_bytes1, 00h

;      invoke usb_control_msg, dev,  
;            LIBUSB_RECIPIENT_DEVICE+REQUEST_TYPE_OUT,            
;            REQUEST_REGISTER, VALUE_SET_REGISTER, INDEX, addr bytes, 0001h, TIMEOUT
;      .if eax != 1
;         invoke TimedMessageBox, hWnd, addr szExpected1_1, addr szError, MB_OK
;      .endif
;
;      invoke usb_control_msg, dev,
;            LIBUSB_RECIPIENT_DEVICE+REQUEST_TYPE_IN,
;            REQUEST_REGISTER, VALUE_READ_REGISTER, INDEX, addr bytes, 0001h, TIMEOUT
;      .if eax != 1
;         invoke TimedMessageBox, hWnd, addr szExpected1_2, addr szError, MB_OK
;      .endif

      invoke usb_control_msg, dev,
            LIBUSB_RECIPIENT_DEVICE+REQUEST_TYPE_IN,
            REQUEST_REGISTER, GPIO_READ, INDEX, addr bytes, 0001h, TIMEOUT

      .if eax != 1
         invoke TimedMessageBox, hWnd, addr szExpected1_2, addr szError, MB_OK
      .endif

      ret
scanintf_read_buttons endp
ELSE

scanintf_open proc
    LOCAL hDevice :DWORD

    pusha

    mov devNum, 0

    .while devNum < 256
        invoke wsprintf, addr szMsgBuf, addr szDevicePath, devNum

        invoke CreateFile, addr szMsgBuf, GENERIC_READ+GENERIC_WRITE,
                        0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov hDevice, eax
        .if eax == INVALID_HANDLE_VALUE                
            .if rv(GetLastError) == 6 ; File not found
                inc devNum
                .continue
;            .else
;                .break
            .endif
        .endif
        .break
    .endw

    .if eax == INVALID_HANDLE_VALUE
        mov hDevice, 0
        jmp @@Return
    .endif


    invoke DeviceIoControl, hDevice, IOCTLCheckIntf, NULL, 0,
                         addr rqB, size rqBuf, addr outSize, NULL
    .if eax == 0
        mov hDevice, 0
        jmp @@Return
    .endif

    mov edx, offset ids
    xchg edx, edi
    xor eax, eax
    mov ecx, size deviceIds
    rep stosb
    xchg edi, edx          

    invoke DeviceIoControl, hDevice, IOCTLGetDeviceIds, NULL, 0,
                         addr ids, size deviceIds, addr outSize, NULL
    .if eax == 0
        mov hDevice, 0
    .endif

@@Return:
    popa    
    mov eax, hDevice
    ret
scanintf_open endp

scanintf_close proc hDevice :DWORD
    invoke CloseHandle, hDevice
    ret
scanintf_close endp

scanintf_strerror proc
    invoke FormatMessageA, FORMAT_MESSAGE_FROM_SYSTEM+FORMAT_MESSAGE_IGNORE_INSERTS,
                           NULL, rv(GetLastError), 0, addr szMsgBuf, 1024, NULL

    mov eax, offset szMsgBuf
    ret
scanintf_strerror endp

scanintf_read_buttons proc hDevice :DWORD, hWnd :DWORD
    pusha

    mov edx, offset rqB
    xchg edx, edi
    xor eax, eax
    mov ecx, size rqBuf
    rep stosb
    xchg edi, edx

    mov scanintf_bytes0, GPIO_8_1
    mov scanintf_bytes1, 0
    mov rqB.value, GPIO_READ
    mov rqB.index, INDEX
    mov rqB.buf, offset bytes
    mov rqB.bufSize, 1

IFDEF DEBUG
    mov rqB.value, VALUE_SET_REGISTER
    invoke DeviceIoControl, hDevice, IOCTLVendorRqIn, addr rqB, size rqBuf,
                         NULL, 0, addr outSize, NULL

    .if eax == 0 || outSize != 1
        push eax 
        invoke wsprintf, addr szMsgBuf, addr szIOCTLVendorRqInFailed, rv(GetLastError)
        invoke TimedMessageBox, hWnd, addr szMsgBuf, addr szError, MB_OK
        pop eax
        jmp @@Return
    .endif

    mov rqB.value, VALUE_READ_REGISTER
ENDIF

    invoke DeviceIoControl, hDevice, IOCTLVendorRqOut, addr rqB, size rqBuf,
                         addr bytes, 1, addr outSize, NULL
 
    .if eax == 0 || outSize != 1
        push eax
        invoke wsprintf, addr szMsgBuf, addr szIOCTLVendorRqOutFailed, rv(GetLastError)
        invoke TimedMessageBox, hWnd, addr szMsgBuf, addr szError, MB_OK
        pop eax
        jmp @@Return
    .endif

    mov eax, 1

@@Return:
    popa     
    ret
scanintf_read_buttons endp

ENDIF

end
