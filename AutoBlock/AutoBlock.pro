APP_NAME = AutoBlock

CONFIG += qt warn_on cascades10

INCLUDEPATH += ../../../quazip/src/
INCLUDEPATH += ../../autoblocklib/src/
INCLUDEPATH += ../../canadainc/src/
INCLUDEPATH += ../src

LIBS += -lz
LIBS += -lbb -lbbutilityi18n -lbbdata -lbbdevice -lbbsystem -lbbpim -lbbcascadespickers

QT += network

CONFIG(release, debug|release) {
    DESTDIR = o.le-v7
    LIBS += -L../../../canadainc/arm/o.le-v7 -lcanadainc -Bdynamic
    LIBS += -L../../autoblocklib/arm/o.le-v7 -lautoblocklib -Bdynamic
    LIBS += -Bstatic -L../../../quazip/arm/o.le-v7 -lquazip -Bdynamic
}

CONFIG(debug, debug|release) {
    DESTDIR = o.le-v7-g
    LIBS += -L../../../canadainc/arm/o.le-v7-g -lcanadainc -Bdynamic
    LIBS += -L../../autoblocklib/arm/o.le-v7-g -lautoblocklib -Bdynamic
    LIBS += -Bstatic -L../../../quazip/arm/o.le-v7-g -lquazip -Bdynamic
}

simulator {

CONFIG(debug, debug|release) {
    DESTDIR = o-g
    LIBS += -Bstatic -L../../../canadainc/x86/o-g/ -lcanadainc -Bdynamic
    LIBS += -Bstatic -L../../autoblocklib/x86/o-g/ -lautoblocklib -Bdynamic
    LIBS += -Bstatic -L../../../quazip/x86/o-g -lquazip -Bdynamic
}

}

include(config.pri)