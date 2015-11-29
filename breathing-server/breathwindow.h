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

signals:
	void newChannelValue(QString channel, double value);
	void newScoreEvent(QString event);


private slots:
	void on_bellsButton_clicked();

	void on_blowerSlider_valueChanged(int value);

	void on_breathSlider_valueChanged(int value);

	void on_bellSlider_valueChanged(int value);

	void on_gamelanSlider_valueChanged(int value);

	void on_horizontalSlider_valueChanged(int value);

private:
	Ui::BreathWindow *ui;
	WsServer * wsServer;
	CsEngine * cs;


};

#endif // BREATHWINDOW_H
