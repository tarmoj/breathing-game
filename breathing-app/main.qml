import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Window 2.2
import Qt.WebSockets 1.0
import QtSensors 5.0

//import QtQuick.Dialogs 1.2

ApplicationWindow {
    title: qsTr("Breathing app")
    width: 640
    height: 480
    visible: true
    property real accY: 0 // longer axis on phone, portrait layout
    property real accX:0 // shorter side
    property real breathSpeed: 0; // for finding breathColumn length; increases when phone moving up; decreases, when down
    property real speedThreshold: 0.05

//    menuBar: MenuBar {
//        Menu {
//            title: qsTr("&File")
//            MenuItem {
//                text: qsTr("&Open")
//                onTriggered: messageDialog.show(qsTr("Open action triggered"));
//            }
//            MenuItem {
//                text: qsTr("E&xit")
//                onTriggered: Qt.quit();
//            }
//        }
//    }


    WebSocket {
        id: socket
        url: "ws://localhost:33033/ws"
        onTextMessageReceived: {
           console.log("Received message: ",message);
        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                             console.log("Error: " + socket.errorString)
                             socket.active = false;
                         } else if (socket.status == WebSocket.Open) {
                             console.log("Socket open")
                             //socket.sendTextMessage("Hello World")
                         } else if (socket.status == WebSocket.Closed) {
                             console.log("Socket closed")
                             socket.active = false;
                             //messageBox.text += "\nSocket closed"
                         }
        active: false
    }

//    onAccXChanged: {
//        if (socket.status==WebSocket.Open && Math.abs(breathSpeed)>speedThreshold)
//            socket.sendTextMessage("accX," + accX)
//    }

//    onAccYChanged: {
//        if (socket.status==WebSocket.Open && Math.abs(breathSpeed)>speedThreshold)
//            socket.sendTextMessage("accY," + accX)
//    }

    Component.onCompleted: {
        //socket.active = true;
    }

    Timer {
        id: accelerationTimer
        repeat: true
        running: true
        interval: 1/5 * 1000 // 5 times per second
        property real oldY: 0
        property real oldSpeed: 0


        onTriggered:  {
            breathSpeed = (accel.reading.y-oldY) * (interval/1000)
            oldY = accel.reading.y;

            if (socket.status==WebSocket.Open) {
                if (oldSpeed<speedThreshold && Math.abs(breathSpeed)>=speedThreshold ) {
                    var inOut = (breathSpeed>0) ? "0" : "1" // 1 - in, -1 - out
                    socket.sendTextMessage("breathStart," + inOut) }
                if (oldSpeed>=speedThreshold && Math.abs(breathSpeed)<speedThreshold )
                    socket.sendTextMessage("breathEnd")
                if (Math.abs(breathSpeed) > speedThreshold) { // send phone position info while moving
                    socket.sendTextMessage("accX," + accX/10.0 +  ",accY," + accY/10.0 + ",speed,"+breathSpeed) // send everythin as one message

                }



            }
            oldSpeed = Math.abs(breathSpeed);


        }

    }

    Accelerometer {
        id: accel
        dataRate:20 // maybe has no influence, trust the timer
        active: true
        property real oldY: 0
        property double oldTimestamp:0

        onReadingChanged: {
            accY = Math.abs(reading.y) // influences breathing in or out
            accX = Math.abs(reading.x) // influences how much is a pitch mixed in
        }
    }


    Row {
        x:5; y:5
        id: serverRow
        spacing: 5

        Label {
            text: qsTr("Server: ")
        }

        TextField {
            id: serverAddress
            width: 200
            text: "ws://192.168.1.220:33033/ws"
        }

        Button {
            id: connectButton
            enabled: !socket.active
            text: socket.active ? qsTr("Connected") : qsTr("Connect..")
            onClicked: {
                //if (!socket.active) {
                    socket.url = serverAddress.text
                    console.log("Connecting to ",socket.url)
                    socket.active = true;
                //}
            }
        }


    }


    Row {
        anchors.centerIn: parent
        spacing: 10

        Label {id: tiltLabel; text: "X accel: " + accX.toFixed(0)  }
        Label {id: accLabel; text: "Y accel: " + accY.toFixed(0)  }
        Label {id: speedLabel; text: "Y speed: " + breathSpeed.toFixed(2)  }
    }



}
