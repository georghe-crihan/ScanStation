      .386                      ; create 32 bit code
      .model flat, stdcall      ; 32 bit memory model
      option casemap :none      ; case sensitive

      include windows.inc
      include kernel32.inc
      include getdllversion.inc

      includelib kernel32.lib

.data

szDllGetVersion db "DllGetVersion", 0

.code

MAKEDLLVERULL proc major :DWORD, minor :DWORD, build :DWORD, qfe :DWORD

  movzx edx, WORD PTR major
  shl edx, 16

  movzx eax, WORD PTR minor
  or edx, eax

  movzx eax, WORD PTR build
  shl eax, 16

  movzx ecx, WORD PTR qfe
  or eax, ecx
  ret  

MAKEDLLVERULL endp

; Get dll version number
;ULONGLONG GetDllVersion(LPCTSTR lpszDllName, BOOL bIgnoreBuildAndPlatform)
GetDllVersion proc lpszDllName:DWORD, bIgnoreBuildAndPlatform:DWORD

LOCAL hinstDll :DWORD
LOCAL dvi :DLLVERSIONINFO

    push esi
    push edi

    invoke LoadLibrary, lpszDllName
    mov hinstDll, eax
    .if eax != 0
        invoke GetProcAddress, hinstDll, addr szDllGetVersion
        mov esi, eax
        .if esi != 0
            lea edi, dvi
            mov ecx, sizeof DLLVERSIONINFO
            xor eax, eax
            rep stosb

            mov dvi.cbSize, sizeof DLLVERSIONINFO

            invoke (TYPE DllGetVersion) ptr esi, addr dvi
            xor edi, edi
            xor esi, esi
            .if eax >= 0
                .if bIgnoreBuildAndPlatform != 0
                    invoke MAKEDLLVERULL, dvi.dwMajorVersion, dvi.dwMinorVersion, 0, 0
                .else
                    invoke MAKEDLLVERULL, dvi.dwMajorVersion, dvi.dwMinorVersion, 
                                               dvi.dwBuildNumber, dvi.dwPlatformID
                .endif
		mov edi, eax
                mov esi, edx 
            .endif
        .endif
        invoke FreeLibrary, hinstDll
    .endif

    mov eax, edi
    mov edx, esi

    pop edi
    pop esi
    ret
GetDllVersion endp

end

