# ScanStation

This WIN32 utility is used to automate book scanning on a PlusTek OpticBook 3800.

It allows you to hide its TWAIN window and bind the scanner's buttons to the hidden window's buttons.

Has presets ini file.

Just point at the target button with the mouse and lock the button id (via keyboard) to assign it to a scanner button.

Then hide the window.

This is particularly useful when scanning books (i.e., batch scanning) in IrfanView, for instance.

One just binds the buttons, selects the scan area, and then hides the TWAIN window.

From now on, one can just repeatedly press the scanner button to acquire the images.

Can use native scanner driver (I reverse engineered the driver API) as well as portable libusb.


Written in plain MASM32.

