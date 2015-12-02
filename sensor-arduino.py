#!/usr/bin/python
# -*- coding: utf-8 -*-

# read pressure sensors connected to arduino; senossor used - smartec SPD102DAhyb

# kui /dev/ttyACM0 ei kao lsof | grep /dev/ttyACM ja kill vastavaed protsessid
# vt. ka ls /var/lock


from PyQt5.Qt import *
import PyQt5.QtCore
import sys
from pyfirmata import ArduinoMega, util
import threading, time, socket
from websocket import create_connection # you need websocket-client module installed


class FirmataThread(threading.Thread):
     def __init__(self,widget):
         super(FirmataThread, self).__init__()
         self.board = ArduinoMega('/dev/ttyACM0')
         self.it = util.Iterator(self.board)
         self.it.start()
         self.board.analog[0].enable_reporting()
         self.board.analog[1].enable_reporting()
         self.board.analog[2].enable_reporting()
         self.board.analog[3].enable_reporting()
         self.board.analog[4].enable_reporting()
         self.board.analog[5].enable_reporting()
         self.stopNow = False
         self.ws = 0
         self.widget = widget
         print "ArduinoMEGA ready to operate"
         #self.connectWS()
         #self.max1 = 0.2
         #self.min1 = 0.1
         #self.max2 = 0.2
         #self.min2 = 0.1
     
     def connectWS(self):
		try:
			self.ws = create_connection("ws://192.168.1.220:33033/ws")
			print "Websocket created"
		except:
			print "Could not create connection"
			self.ws = 0
			
     
     def run(self):
         oldValue = [-10,-10,-10,-10,-10,-10]
         while ( not self.stopNow) :
			
			for sensor in range(6):
				value = self.board.analog[sensor].read()
				if (value==None):
					print "Coulde not read value form sensor ",sensor
					return
				value = (float(value) - 0.5) * 2  # - 0.5)*2 # to -1..1; for sensor 0.5 is neutral neutral now inhaling positive, exhaling negative
				value = int(value *100) / 100.0 # leave just 2 decimals
				#TODO: ümarda nii, et suurus oleks 1 komakoht (-10..10)? , saada ws ainult, kui on muutunud
				#print value, float(value), v1
				
				if (value!=oldValue[sensor] ):
					oldValue[sensor] = value
					valueLabel[sensor].setText(str(value))
					if (self.ws!=0):
						self.ws.send("blower,"+str(sensor+1)+ "," + str(value) )
				
			time.sleep(0.25)   
     
     def stop(self):
		 self.stopNow = True
		 self.board.exit()
		 if (self.ws!=0):
			self.ws.close


#main




app = QApplication(sys.argv)


window = QWidget() # window as main widget
layout = QGridLayout(window) # use gridLayout - the most flexible one - to place the widgets in a table-like structure
window.setLayout(layout) 
window.setWindowTitle("Firmata from arduino")

arduino = FirmataThread(window)
arduino.connectWS()


layout.addWidget(QLabel("Sensor 1: "),0,0) # first row, first column
layout.addWidget(QLabel("Sensor 2: "),1,0) # second row, first column
layout.addWidget(QLabel("Sensor 3: "),2,0) # first row, first column
layout.addWidget(QLabel("Sensor 4: "),3,0) # second row, first column
layout.addWidget(QLabel("Sensor 5: "),4,0) # first row, first column
layout.addWidget(QLabel("Sensor 6: "),5,0) # second row, first column


valueLabel = [None] * 6
for i in range(6):
	valueLabel[i] = QLabel("?")
	layout.addWidget(valueLabel[i],i,1)

stopButton = QPushButton("Stop")
stopButton.clicked.connect(arduino.stop)
layout.addWidget(stopButton,6,1)

connectButton = QPushButton("Connect")
connectButton.clicked.connect(arduino.connectWS)
layout.addWidget(connectButton,6,0)



window.show()
arduino.start()
#arduino.join()

sys.exit(app.exec_())