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
    property real speedThreshold: 0.015


    WebSocket {
        id: socket
        url: "ws://192.168.1.199:33033/ws"
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

    Component.onCompleted: {
        socket.active = true;
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
            breathSpeed = (breathSpeed+oldSpeed)/2 // to level a bit sudden wobblings
            oldY = accel.reading.y;

            if (socket.status==WebSocket.Open && mainArea.containsPress) {
                if (Math.abs(oldSpeed)<speedThreshold && Math.abs(breathSpeed)>=speedThreshold ) {
                    socket.sendTextMessage("breathStart," + panSlider.value) }
                if (Math.abs(oldSpeed)>=speedThreshold && Math.abs(breathSpeed)<speedThreshold )
                    socket.sendTextMessage("breathEnd")
                if (Math.abs(breathSpeed) > speedThreshold) { // send phone position info while moving
                    socket.sendTextMessage("accX," + accX/10.0 +  ",accY," + accY/10.0 + ",speed,"+breathSpeed) // send everythin as one message

                }



            }
            oldSpeed = breathSpeed;


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

    Rectangle {
        id: mainRect
        color: mainArea.containsPress ? "darkblue" : "blue"
//        gradient: Gradient {
//            GradientStop {
//                position: 0.00;
//                color: "#ffffff";
//            }
//            GradientStop {
//                position: 1.00;
//                color: "#000000";
//            }
//        }
        anchors.fill: parent

        MouseArea {
            id: mainArea
            anchors.bottom: mainRect.bottom
            anchors.top: serverRow.bottom
            width: parent.width

            onReleased: {
                console.log("RELEASED")
                if (Math.abs(breathSpeed)>speedThreshold  && socket.status==WebSocket.Open)
                    socket.sendTextMessage("breathEnd")
            }

            onPressed: accelerationTimer.oldSpeed = 0; // to trigger breathStart

        }

        Row {
            x:5; y:5
            id: serverRow
            spacing: 5
            z:3

            Label {
                visible: !socket.active;
                color:"white";
                id:serverLabel; text: qsTr("Server: ")
            }

            TextField {
                id: serverAddress
                visible: !socket.active
                width: mainRect.width - serverLabel.width - connectButton.width - 20;
                text: "ws://192.168.1.199:33033/ws"
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
            id: sliderRow
            anchors.top: serverRow.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Label {id: leftLAbel; text:qsTr("Left"); color: "white"}

            Slider {
                id: panSlider
                value: 0.5
                width: mainRect.width * 0.8 - leftLAbel.width - rightLAbel.width
            }
            Label {id: rightLAbel; text:qsTr("Right"); color: "white"}
        }


        Rectangle {
            id: accelRect
            visible: mainArea.containsPress
            radius: 5
            anchors.bottom: mainRect.bottom
            anchors.bottomMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            width: mainRect.width*0.75
            property int maxHeight: mainArea.height
            height:accY/10.0 * maxHeight // floor teeb vist liiga astmeliseks...
            color: "green" // qRgb või midagi

            Behavior on height { NumberAnimation {duration: accelerationTimer.interval } } // ei toimi millegi pärast
        }






        Row {
            anchors.centerIn: parent
            spacing: 10


            Label {id: tiltLabel;  color: "white"; text: "X accel: " + accX.toFixed(0)  }
            Label {id: accLabel; color: "white"; text: "Y accel: " + accY.toFixed(0)  }
            Label {id: speedLabel; color: "white"; text: "Y speed: " + breathSpeed.toFixed(2)  }
        }

    }

}
