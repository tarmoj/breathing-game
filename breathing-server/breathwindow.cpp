#include "breathwindow.h"
#include "ui_breathwindow.h"
#include <QThread>

BreathWindow::BreathWindow(QWidget *parent) :
	QMainWindow(parent),
	ui(new Ui::BreathWindow)
{
	ui->setupUi(this);
	wsServer = new WsServer(33033);

	connect(wsServer, SIGNAL(newConnection(int)), this, SLOT(setClientsCount(int)));

	// move csound into another thread
	csoundThread = new QThread(this);
	cs = new CsEngine();
	cs->moveToThread(csoundThread);


	connect(csoundThread, &QThread::finished, cs, &CsEngine::deleteLater);
	connect(csoundThread, &QThread::finished, csoundThread, &QThread::deleteLater); // somehow exiting from Csound is not clear yet, the thread gets destoyed when Csoun is still running.

	// kuskile funtsioonid startCsound, stopCsoundm thread private
	// stopCsound -> connecct widget destoyed ja kuskil cs->stop(), csoundThread.quit(), csoundThread.wait()
	connect(this, &QWidget::destroyed, cs, &CsEngine::stop);
	connect(csoundThread, &QThread::started, cs, &CsEngine::play);

	connect(this, &BreathWindow::newChannelValue, cs, &CsEngine::setChannel );
	connect(this, &BreathWindow::newScoreEvent, cs, &CsEngine::scoreEvent );

	connect(wsServer, &WsServer::newChannelValue, cs, &CsEngine::setChannel );
	connect(wsServer, &WsServer::newScoreEvent, cs, &CsEngine::scoreEvent );


	csoundThread->start();

	emit newChannelValue("volume", (double) ui->volumeSlider->value()/100.0);
	emit newChannelValue("blowvolume", (double) ui->blowerSlider->value()/100.0);
	emit newChannelValue("breathvolume", (double) ui->breathSlider->value()/100.0 );
	emit newChannelValue("bellvolume", (double) ui->bellSlider->value()/100.0);
	emit newChannelValue("gamelanvolume", (double) ui->gamelanSlider->value()/100.0);


}

BreathWindow::~BreathWindow()
{
	cs->stop();
	csoundThread->quit();
	csoundThread->wait();
	delete ui;
}



void BreathWindow::setClientsCount(int clientsCount)
{
	ui->clientsCountLabel->setText(QString::number(clientsCount));
}






void BreathWindow::on_bellsButton_clicked()
{
	emit newScoreEvent("i \"bell\" 0 1 800 0.5");
}

void BreathWindow::on_volumeSlider_valueChanged(int value)
{
	emit newChannelValue("volume", (double) value/100.0);
}

void BreathWindow::on_blowerSlider_valueChanged(int value)
{
	emit newChannelValue("blowvolume", (double) value/100.0);
}

void BreathWindow::on_breathSlider_valueChanged(int value)
{
	emit newChannelValue("breathvolume", (double) value/100.0);
}

void BreathWindow::on_bellSlider_valueChanged(int value)
{
	emit newChannelValue("bellvolume", (double) value/100.0);
}

void BreathWindow::on_gamelanSlider_valueChanged(int value)
{
	emit newChannelValue("gamelanvolume", (double) value/100.0);
}

void BreathWindow::on_horizontalSlider_valueChanged(int value)
{
	emit newChannelValue("rotationspeed", (double) value/100.0);
}
