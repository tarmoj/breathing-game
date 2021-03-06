#ifndef WSSERVER_H
#define WSSERVER_H

#include <QObject>
#include <QtCore/QList>
#include <QHostAddress>


QT_FORWARD_DECLARE_CLASS(QWebSocketServer)
QT_FORWARD_DECLARE_CLASS(QWebSocket)


class WsServer : public QObject
{
    Q_OBJECT
public:
    explicit WsServer(quint16 port, QObject *parent = NULL);
    ~WsServer();

	void sendMessage(QWebSocket *socket, QString message);
	void setVolume(double volume);

Q_SIGNALS:
    void closed();
    void newConnection(int connectionsCount);
	void newChannelValue(QString channel, double value);
	void newScoreEvent(QString event);


private Q_SLOTS:
    void onNewConnection();
    void processTextMessage(QString message);
	//void processBinaryMessage(QByteArray message);
    void socketDisconnected();

private:
    QWebSocketServer *m_pWebSocketServer;
    QList<QWebSocket *> m_clients;
	QList <QHostAddress> peerAdresses;



};



#endif // WSSERVER_H
