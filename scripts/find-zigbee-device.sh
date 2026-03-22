#!/bin/bash
# Script to find Zigbee USB device on macOS

echo "Searching for Zigbee devices..."

echo ""
echo "=== USB Devices (looking for Zigbee/Newgreentech/C3003/Silicon Labs) ==="
system_profiler SPUSBDataType 2>/dev/null | grep -A3 -i "zigbee\|newgreentech\|c3003\|silicon labs" || echo "No Zigbee device found in USB list"

echo ""
echo "=== TTY Devices (serial ports) ==="
ls -la /dev/tty.* 2>/dev/null || echo "No tty devices found"

echo ""
echo "=== How to find your device ==="
echo "1. Plug in your Zigbee USB dongle"
echo "2. Wait 5 seconds"
echo "3. Run: system_profiler SPUSBDataType"
echo "4. Look for 'Newgreentech', 'C3003', 'Silicon Labs', or 'Zigbee'"
echo "5. Note the Vendor ID (VID) and Product ID (PID)"
echo ""
echo "=== Common device paths on macOS ==="
echo "- /dev/tty.usbmodemXXX (most common)"
echo "- /dev/tty.usbserialXXX"
echo "- /dev/ttyACM0 (if using Docker on Linux VM)"
echo ""
echo "After finding your device, update zigbee2mqtt/data/configuration.yaml"
