#include "breathwindow.h"
#include "ui_breathwindow.h"
#include <QThread>

BreathWindow::BreathWindow(QWidget *parent) :
	QMainWindow(parent),
	ui(new Ui::BreathWindow)
{
	ui->setupUi(this);
	wsServer = new WsServer(33033);
	//	cs = new CsEngine("../Breath-game.csd");
	//	cs->start();
	//wsServer->setVolume((double)ui->volumeSlider->value()/100.0); // send initial value
	connect(wsServer, SIGNAL(newConnection(int)), this, SLOT(setClientsCount(int)));
	//	connect(wsServer, SIGNAL(newEvent(QString)),cs,SLOT(csEvent(QString))  );

	// move csound into another thread
	QThread *thread = new QThread(this);
	cs = new CsEngine();
	cs->moveToThread(thread);


	connect(thread, &QThread::finished, cs, &CsEngine::deleteLater);
	connect(thread, &QThread::finished, thread, &QThread::deleteLater);
	//connect(this, &QWidget::destroyed, cs, &CsEngine::stop);
	connect(this, &QWidget::destroyed, thread, &QThread::quit);
	connect(thread, &QThread::started, cs, &CsEngine::play);

	connect(this, &BreathWindow::newChannelValue, cs, &CsEngine::setChannel );
	connect(this, &BreathWindow::newScoreEvent, cs, &CsEngine::scoreEvent );

	connect(wsServer, &WsServer::newChannelValue, cs, &CsEngine::setChannel );
	connect(wsServer, &WsServer::newScoreEvent, cs, &CsEngine::scoreEvent );


	thread->start();

}

BreathWindow::~BreathWindow()
{
	delete ui;
}



void BreathWindow::setClientsCount(int clientsCount)
{
	ui->clientsCountLabel->setText(QString::number(clientsCount));
}


void BreathWindow::on_volumeSlider_valueChanged(int value)
{
	qDebug()<<"Slidervalue: "<<value;
	emit newChannelValue("volume", (double) value/100.0);
}

void BreathWindow::testChannelValue(QString channel, double value)
{
	qDebug()<<"TEST"<<channel<<value;
}


void BreathWindow::on_bellsButton_clicked()
{
	emit newScoreEvent("i \"bell\" 0 1 800 0.5");
}
