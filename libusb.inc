  ; ===========================================
  ; libusb.inc copyright MASM32 1998 - 2005
  ; ===========================================

IFNDEF LIBUSB_INC
LIBUSB_INC equ <1>

usb_init PROTO C ; initialize the library
usb_find_busses PROTO C ; find all busses
usb_find_devices PROTO C ; find all connected devices 
usb_get_busses PROTO C ;
usb_open PROTO C :DWORD
usb_close PROTO C :DWORD
usb_strerror PROTO C

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
                      ; dev,    bmRequestType, bRequest, wValue, wIndex, data,   length, timeout
usb_control_msg PROTO C :DWORD, :DWORD,        :DWORD,   :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

LIBUSB_PATH_MAX equ 512

;enum libusb_endpoint_direction {
LIBUSB_ENDPOINT_IN  equ 80h
LIBUSB_ENDPOINT_OUT equ 00h
;};

;enum libusb_request_type {
LIBUSB_REQUEST_TYPE_STANDARD equ 00h
LIBUSB_REQUEST_TYPE_CLASS    equ 20h ; 0x01 << 5
LIBUSB_REQUEST_TYPE_VENDOR   equ 40h ; 0x02 << 5
LIBUSB_REQUEST_TYPE_RESERVED equ 80h ; 0x03 << 5
;}

;enum libusb_request_recipient {
LIBUSB_RECIPIENT_DEVICE    equ 00h
LIBUSB_RECIPIENT_INTERFACE equ 01h
LIBUSB_RECIPIENT_ENDPOINT  equ 02h
LIBUSB_RECIPIENT_OTHER     equ 03h
;};

; Device descriptor */
usb_device_descriptor struct
;{
;    unsigned char  bLength;
bLength DB ?
;    unsigned char  bDescriptorType
bDescriptorType db ?;
;    unsigned short bcdUSB;
bcdUSB dw ?
;    unsigned char  bDeviceClass;
bDeviceClass db ?
;    unsigned char  bDeviceSubClass;
bDeviceSubClass db ?
;    unsigned char  bDeviceProtocol;
bDeviceProtocol db ?
;    unsigned char  bMaxPacketSize0;
bMaxPacketSize0 db ?
;    unsigned short idVendor;
idVendor dw ?
;    unsigned short idProduct;
idProduct dw ?
;    unsigned short bcdDevice;
bcdDevice dw ?
;    unsigned char  iManufacturer;
iManufacturer db ?
;    unsigned char  iProduct;
iProduct db ?
;    unsigned char  iSerialNumber;
iSerialNumber db ?
;    unsigned char  bNumConfigurations;
bNumConfigurations db ?
;};
usb_device_descriptor ends

usb_device struct
;{
;    struct usb_device *next, *prev;
next DD ?
prev DD ?
;    char filename[LIBUSB_PATH_MAX];
filename DB LIBUSB_PATH_MAX DUP(?)
;    struct usb_bus *bus;
bus DD ?
;    struct usb_device_descriptor descriptor;
descriptor usb_device_descriptor <?>
;    struct usb_config_descriptor *config;
config DD ?
;    void *dev;		/* Darwin support */
dev DD ?
;    unsigned char devnum;
devnum DB ?
;    unsigned char num_children;
num_children DB ?
;    struct usb_device **children;
children DD ?
;};
usb_device ends

usb_bus struct
;{
;    struct usb_bus *next, *prev;
next DD ?
prev DD ?
;    char dirname[LIBUSB_PATH_MAX];
dirname DB LIBUSB_PATH_MAX DUP(?)
;    struct usb_device *devices;
devices DD ?
;    unsigned long location;
location DD ?
;    struct usb_device *root_dev;
root_dev DD ?
;};
usb_bus ends


ELSE
echo -----------------------------------------
echo WARNING Duplicate include file libusb.inc
echo -----------------------------------------
ENDIF
