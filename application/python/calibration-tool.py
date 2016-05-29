#! /usr/bin/env python

"""
open-dobot Calibration Tool.

This tool continuously reports accelerometers and angles from those.

Use this tool to find offsets for your accelerometers:
1. Turn off power on the arm and disconnect USB cable
2. Remove accelerometers from the arm and put them on a flat surface that has no inclination
3. Connect USB cable
4. Enable accelerometers reporting mode:
4.1. Press and hold the "Sensor Calibration" button on FPGA version or ground pin D23 on AUX-4 on RAMPS version
4.2. Press and release the "Reset" button
4.3. Start this tool (still holding "Sensor Calibration" button on FPGA version or keeping pin D23 grounded on RAMPS)
4.4. Wait for the accelerometer data to start flowing on your console/whatever_you_use_to_start_this_tool
4.5. Release the "Sensor Calibration" button
5. Gently push down the accelerometers so that they are evenly on the surface. Don't touch any contacts/leads.
	You can push them one by one, not necessary to push both at the same time
6. Note the "Raw" data from accelerometers reported on the console. Those are your accelerometers' offsets
7. Turn off power on the arm, disconnect USB cable, mount accelerometers back onto the arm 

Author: maxosprojects (March 18 2016)
Additional Authors: <put your name here>

Version: 0.4.0

License: MIT
"""
import math

from DobotDriver import DobotDriver

# driver = DobotDriver('COM4')
driver = DobotDriver('/dev/tty.usbmodem1421')
driver.Open()
# driver = DobotDriver('/dev/tty.BT4-SPP-SerialPort')
# driver.Open(timeout=0.3)

# Offsets must be found using this tool for your Dobot once
# (rear arm, forearm)
offsets = (1024, 1024)

def toEndEffectorHeight(rear, fore):
	return 88.0 - 160.0 * math.sin(fore) + 135.0 * math.sin(rear)

while True:
	ret = driver.GetAccelerometers()
	if ret[0]:
		if driver.isFpga():
			print("Rear arm: {0:10f} | Forearm: {1:10f} | End effector height: {2:10f} | Raw rear arm: {3:4d} | Raw forearm: {4:4d}".format(\
				driver.accelToAngle(ret[1], offsets[0]), driver.accelToAngle(ret[4], offsets[1]),\
				toEndEffectorHeight(driver.accelToRadians(ret[1], offsets[0]), driver.accelToRadians(ret[4], offsets[1])),\
				ret[1], ret[4]))
		else:
			print("Rear arm: {0:6.2f} | Forearm: {1:6.2f} | End effector height: {2:7.2f} | Raw rear arm: {3:6d} {4:6d} {5:6d} | Raw forearm: {6:6d} {7:6d} {8:6d}".format(\
				driver.accel3DXToAngle(ret[1], ret[2], ret[3]), -driver.accel3DXToAngle(ret[4], ret[5], ret[6]),\
				toEndEffectorHeight(driver.accel3DXToRadians(ret[1], ret[2], ret[3]), -driver.accel3DXToRadians(ret[4], ret[5], ret[6])),\
				ret[1], ret[2], ret[3], ret[4], ret[5], ret[6]))
	else:
		print('Error occurred reading data')