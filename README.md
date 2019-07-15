 # BLE-iOS-demo

BLE communication with ESP32 device. You can enable blinking LED via app or via button on the device.

## UUIDs

* service `6d8f85c9-d8f8-412f-95ff-a5134788caeb`
  * enable output (1 byte, bool) `df7812b2-372c-4a18-bf23-b3c7bf8d2d1c`
  * frequency cycle (1 byte, uint8) `0d70343-6a3f-450b-8dd1-a927f9f3e4fa`
  * duty cycle (1 byte, uint8) `f60c9a2b-d01a-4137-be49-1faa2ac098a6`

## Device

* ESP32 on DOIT ESP32 DEVKIT board
* button wired to GPIO0
* builtin LED
* Using [ESP32 core for Arduino](https://github.com/espressif/arduino-esp32)
* Using [TaskScheduler library](https://github.com/arkhipenko/TaskScheduler)
