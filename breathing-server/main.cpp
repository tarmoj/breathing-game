#include "breathwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
	QApplication a(argc, argv);
	BreathWindow w;
	w.show();

	return a.exec();
}
