#!/bin/bash

PREFIX="/sys/devices/platform/soc/soc:rpi_rtc/rtc/rtc0"

echo "current voltage:      $(cat ${PREFIX}/battery_voltage)"
echo "charging voltage:     $(cat ${PREFIX}/charging_voltage)"
echo "charging voltage max: $(cat ${PREFIX}/charging_voltage_max)"
echo "charging voltage min: $(cat ${PREFIX}/charging_voltage_min)"
