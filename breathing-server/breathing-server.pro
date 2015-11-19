#-------------------------------------------------
#
# Project created by QtCreator 2015-11-17T15:54:31
#
#-------------------------------------------------

QT       += core gui websockets

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = breathing-server
TEMPLATE = app

INCLUDEPATH += /usr/local/include/csound

SOURCES += main.cpp\
        breathwindow.cpp \
    wsserver.cpp \
    csengine.cpp

HEADERS  += breathwindow.h \
    wsserver.h \
    csengine.h

FORMS    += breathwindow.ui

unix|win32: LIBS += -lcsnd6 -lcsound64
