#ifndef BREATHWINDOW_H
#define BREATHWINDOW_H

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

private:
	Ui::BreathWindow *ui;
};

#endif // BREATHWINDOW_H
