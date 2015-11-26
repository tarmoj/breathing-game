#include "wsserver.h"
#include "QtWebSockets/qwebsocketserver.h"
#include "QtWebSockets/qwebsocket.h"
#include <QtCore/QDebug>
#include <QDir>



QT_USE_NAMESPACE



WsServer::WsServer(quint16 port, QObject *parent) :
    QObject(parent),
	m_pWebSocketServer(new QWebSocketServer(QStringLiteral("BreathServer"),
                                            QWebSocketServer::NonSecureMode, this)),
    m_clients()
{
    if (m_pWebSocketServer->listen(QHostAddress::Any, port)) {
        qDebug() << "WsServer listening on port" << port;
        connect(m_pWebSocketServer, &QWebSocketServer::newConnection,
                this, &WsServer::onNewConnection);
        connect(m_pWebSocketServer, &QWebSocketServer::closed, this, &WsServer::closed);
	}

}



WsServer::~WsServer()
{
    m_pWebSocketServer->close();
    qDeleteAll(m_clients.begin(), m_clients.end());
}




void WsServer::onNewConnection()
{
    QWebSocket *pSocket = m_pWebSocketServer->nextPendingConnection();

    connect(pSocket, &QWebSocket::textMessageReceived, this, &WsServer::processTextMessage);
	//connect(pSocket, &QWebSocket::binaryMessageReceived, this, &WsServer::processBinaryMessage);
    connect(pSocket, &QWebSocket::disconnected, this, &WsServer::socketDisconnected);

    m_clients << pSocket;

    emit newConnection(m_clients.count());
}



void WsServer::processTextMessage(QString message) // message must be an array of numbers (8bit), separated with colons
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (!pClient) {
        return;
    }

	QHostAddress senderAddress = pClient->peerAddress();
	if (!peerAdresses.contains(senderAddress)) {
		qDebug()<<"New peer:"<< senderAddress.toString();
		peerAdresses.append(senderAddress);
	}
	int player = peerAdresses.indexOf(senderAddress) + 1;

	qDebug()<<"Message received: "<<message;
	QStringList messageParts = message.split(",");
	if (messageParts[0].startsWith("breathStart")) { // comes in as breath, <pan>

		QString scoreLine;
		scoreLine.sprintf("i 30.%d 0 -1 %d ", player, player ); // p4 - playerm p5- panning parameter pan
		scoreLine += messageParts[1]; // panning
		qDebug()<<"Starting breath for player " << player << scoreLine;
		emit newScoreEvent(scoreLine);
		// TODO: messageParts[1] -  "IN" või "OUT" <- parem arvud..., saada CSoundile kui p4 -  mängija, p5 in/out (in -0, out - 1)
	}
	if (messageParts[0].startsWith("breathEnd")) {
		QString scoreLine;
		scoreLine.sprintf("i -30.%d 0 0 0 0", player);
		emit newScoreEvent(scoreLine);
		qDebug()<<"Stopping breath for player " << player << scoreLine;
	}
	if (messageParts[0].startsWith("accX")) { // comes in as accX,<value>,accY,<value>,speed, <value>; accX/Y 0.1, speed positive or negative, probably not over 1
		double accX = messageParts[1].toDouble();
		double accY = messageParts[3].toDouble();
		double speed = messageParts[5].toDouble();

		emit newChannelValue("accX"+QString::number(player), accX ); // send values to Csound channels
		emit newChannelValue("accY"+QString::number(player), accY );
		emit newChannelValue("speed"+QString::number(player), speed );
	}

	if (messageParts[0].startsWith("gamelan")) { // comes in as gamelan,<noteIndex>,<pan>
		QString scoreLine;
		scoreLine = "i \"gamelan\" 0 1 " +  messageParts[1] + " " + messageParts[2];
		qDebug()<<scoreLine;
		emit newScoreEvent(scoreLine);

	}

	if (messageParts[0].startsWith("bells")) { // comes in as gamelan,<noteIndex>,<pan>
		QString scoreLine;
		scoreLine = "i \"bellCascade\" 0 0 " +  QString::number(5+qrand()%10) + " " + messageParts[1];
		qDebug()<<scoreLine;
		emit newScoreEvent(scoreLine);

	}


}


// Sea Cs Class Ws alt, window: wsSwever->setVolume



void WsServer::socketDisconnected()
{
    QWebSocket *pClient = qobject_cast<QWebSocket *>(sender());
    if (pClient) {
        m_clients.removeAll(pClient);
        emit newConnection(m_clients.count());
        pClient->deleteLater();
	}
}


void WsServer::sendMessage(QWebSocket *socket, QString message )
{
    if (socket == 0)
    {
        return;
    }
    socket->sendTextMessage(message);

}

//void WsServer::setVolume(double volume)
//{
//	cs->setChannel("volume",(MYFLT)volume);
//}

