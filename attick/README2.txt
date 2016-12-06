Genesys backend for scanbuttond:
https://sourceforge.net/p/scanbd/code/HEAD/tree/trunk/src/scanbuttond/backends/genesys.c
04A9:221C CanoScan LiDE 60 includes 15 combined buttons, only 4 real buttons
04A9:2213 CanoScan LiDE 35 includes 15 combined buttons, only 4 real buttons
04A9:1905 CanoScan LiDE 200 includes 15 combined buttons, only 4 real buttons

bmRequestType:
LIBUSB_REQUEST_TYPE_VENDOR + LIBUSB_RECIPIENT_DEVICE + LIBUSB_ENDPOINT_OUT
LIBUSB_REQUEST_TYPE_VENDOR + LIBUSB_RECIPIENT_DEVICE + LIBUSB_ENDPOINT_IN

IOCTL:
 0x8000200C = VendorRequest, OutputBufferLength=1
#define VendorRqOut CTL_CODE(0x8000,0x803,METHOD_BUFFERED,FILE_ANY_ACCESS)
 0x80002010 = VendorRequest, OutputBufferLength=0
#define VendorRqIn CTL_CODE(0x8000,0x804,METHOD_BUFFERED,FILE_ANY_ACCESS)
 struct rqBuf {
   uint16_t value;
   uint16_t languageId;
   uint32_t size;
   uint32_t buf;
   uint16_t index;
 }
 0x8000201C = ResetPipe, ResetStalled = 0
 0x80002004 = ResetPipe, ResetStalled = 1
 0x80002000 = Check interface, returns 1 in system buffer
 0x80002018 = Get device ids: idVendor, idProduct, bcdDevice
 0x80002020 = Get descriptor from device: idVendor, idProduct, bcdDevice
 
 SetupDiOpenDevRegKey
 IoOpenDeviceRegistryKey(DevExt->pOrigDeviceClass, 2u, 0x20006u, &KeyHandle);
 RtlInitUnicodeString(&DeviceName, L"CreateFileName");
#define IOCTL_HELLO_WORLD CTL_CODE(0x8000,0x803,METHOD_BUFFERED,FILE_ANY_ACCESS)

https://msdn.microsoft.com/en-us/library/windows/hardware/ff543023(v=vs.85).aspx
