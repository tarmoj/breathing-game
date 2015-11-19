#ifndef BREATHWINDOW_H
#define BREATHWINDOW_H
#include "wsserver.h"
#include "csengine.h"

#include <QMainWindow>

namespace Ui {
class BreathWindow;
}

class BreathWindow : public QMainWindow
{
	Q_OBJECT

public:
	explicit BreathWindow(QWidget *parent = 0);	
	~BreathWindow();

public slots:
	void setClientsCount(int clientsCount);
	void on_volumeSlider_valueChanged(int value);
	void testChannelValue(QString channel, double value);

signals:
	void newChannelValue(QString channel, double value);
	void newScoreEvent(QString event);


private slots:
	void on_bellsButton_clicked();

private:
	Ui::BreathWindow *ui;
	WsServer * wsServer;
	CsEngine * cs;


};

#endif // BREATHWINDOW_H
