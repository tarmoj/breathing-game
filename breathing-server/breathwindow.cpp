#include "breathwindow.h"
#include "ui_breathwindow.h"

BreathWindow::BreathWindow(QWidget *parent) :
	QMainWindow(parent),
	ui(new Ui::BreathWindow)
{
	ui->setupUi(this);
}

BreathWindow::~BreathWindow()
{
	delete ui;
}
