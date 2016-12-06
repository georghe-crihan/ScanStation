DEBUG EQU 0

      .386                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

      include windows.inc
      include user32.inc
      include kernel32.inc
      include macros.asm


      includelib user32.lib
      includelib kernel32.lib

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

.data

szInteractionProgram db "Interaction Program Test 0", 0
szDeviceHandleFailed db "Device handle failed with error : %d", 0
szDeviceHandleCreated db "Device handle created successfully!, %d", 0
szIOCTLCheckIntfFailed db "IOCTLCheckIntf failed (%d)", 0
szIOCTLCheckIntfReturned db "IOCTLCheckIntf returned %d:%d:%d", 0
szIOCTLGetDeviceIdsFailed db "IOCTLGetDeviceIds failed (%d)", 0
szIOCTLGetDeviceIdsReturned db "IOCTLGetDeviceIds returned %04X:%04X:%04X", 0
szIOCTLVendorRqInFailed db "IOCTLVendorRqIn failed (%d)", 0
szIOCTLVendorRqOutFailed db "IOCTLVendorRqOut failed (%d)", 0
szIOCTLVendorRqOutReturned db "IOCTLVendorRqOut returned (%08X)", 0

szDevicePath   db "\\.\usbscan%d", 0

value          dd 0
outSize        dd 0

.data?
assume cs:nothing

szMsgBuf       db 1024 dup(?)

devNum         dd ?
hDevice        dd ?
ids            deviceIds<>
rqB            rqBuf<>

buf:
buf0           db ?
buf1           db ?

.code

start:    
    invoke MessageBox, NULL, addr szInteractionProgram, NULL, MB_OK

    mov devNum, 0
    invoke wsprintf, addr szMsgBuf, addr szDevicePath, devNum
    invoke CreateFile, addr szMsgBuf, GENERIC_READ+GENERIC_WRITE,
                    0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov hDevice, eax

    .if hDevice == INVALID_HANDLE_VALUE
        invoke wsprintf, addr szMsgBuf, addr szDeviceHandleFailed, rv(GetLastError)
        jmp @@ReturnMinusOne
    .else       
        invoke wsprintf, addr szMsgBuf, addr szDeviceHandleCreated,  size rqBuf
        invoke MessageBox, NULL, addr szMsgBuf, NULL, MB_OK
    .endif

    invoke DeviceIoControl, hDevice, IOCTLCheckIntf, NULL, 0,
                         addr rqB, size rqBuf, addr outSize, NULL
    .if eax == 0
        invoke wsprintf, addr szMsgBuf, addr szIOCTLCheckIntfFailed, rv(GetLastError)
        jmp @@ReturnMinusOne
    .endif

    invoke wsprintf, addr szMsgBuf, addr szIOCTLCheckIntfReturned, rqB.bufSize, rqB.buf, rqB.value
    invoke MessageBox, NULL, addr szMsgBuf, NULL, MB_OK

    mov edx, offset ids
    xchg edx, edi
    xor eax, eax
    mov ecx, size deviceIds
    rep stosb
    xchg edi, edx          

    invoke DeviceIoControl, hDevice, IOCTLGetDeviceIds, NULL, 0,
                         addr ids, size deviceIds, addr outSize, NULL
    .if eax == 0
        invoke wsprintf, addr szMsgBuf, addr szIOCTLGetDeviceIdsFailed, rv(GetLastError)
        jmp @@ReturnMinusOne
    .endif

    invoke wsprintf, addr szMsgBuf, addr szIOCTLGetDeviceIdsReturned, ids.idVendor, ids.idProduct, ids.bcdDevice
    invoke MessageBox, NULL, addr szMsgBuf, NULL, MB_OK

    
    mov edx, offset rqB
    xchg edx, edi
    xor eax, eax
    mov ecx, size rqBuf
    rep stosb
    xchg edi, edx

    mov buf0, 06dh
    mov buf1, 0
    mov rqB.value, 08ah
    mov rqB.index, 0
    mov rqB.buf, offset buf
    mov rqB.bufSize, 1

IFDEF dummy
    mov rqB.value, 083h
    invoke DeviceIoControl, hDevice, IOCTLVendorRqIn, NULL, 0,
                         addr rqB, size rqBuf, addr outSize, NULL

    .if eax == 0 
        invoke wsprintf, addr szMsgBuf, addr szIOCTLVendorRqInFailed, rv(GetLastError)
        jmp @@ReturnMinusOne
    .endif

    mov rqB.value, 084h
ENDIF

IFDEF DEBUG
    invoke DeviceIoControl, hDevice, IOCTLVendorRqOut, addr rqB, size rqBuf,
                         addr value, 1, addr outSize, NULL
 
    .if eax == 0
        invoke wsprintf, addr szMsgBuf, addr szIOCTLVendorRqOutFailed, rv(GetLastError)
        jmp @@ReturnMinusOne
    .endif
ENDIF     
    invoke CloseHandle, hDevice

    invoke wsprintf, addr szMsgBuf, addr szIOCTLVendorRqOutReturned, value
    invoke MessageBox, NULL, addr szMsgBuf, NULL, MB_OK
    xor eax, eax
    invoke ExitProcess, eax

@@ReturnMinusOne:
    invoke MessageBox, NULL, addr szMsgBuf, NULL, MB_OK
    invoke ExitProcess, -1
    
end start
