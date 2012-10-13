TEMPLATE = app
TARGET = tetris 
DEPENDPATH += .
INCLUDEPATH += .
DESTDIR = .
CONFIG += qt

# Input
HEADERS += ./canvas/canvas.h
SOURCES += ./canvas/canvas.cc
INCLUDEPATH += ./include
LIBS += -L./lib -llua52
