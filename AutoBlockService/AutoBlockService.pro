APP_NAME = AutoBlockService

CONFIG += qt warn_on
INCLUDEPATH += ../src ../../../canadainc/src/ ../../autoblocklib/src/
QT += declarative
LIBS += -lbb -lbbdata -lbbsystem -lbbplatform -lbbmultimedia -lbbpim -lbbdevice -lQtSql -lQtXml -lQtNetwork -lQtCore

CONFIG(release, debug|release) {
    DESTDIR = o.le-v7
    LIBS += -L../../../canadainc/arm/o.le-v7 -lcanadainc -Bdynamic
    LIBS += -L../../autoblocklib/arm/o.le-v7 -lautoblocklib -Bdynamic
}

CONFIG(debug, debug|release) {
    DESTDIR = o.le-v7-g
    LIBS += -L../../../canadainc/arm/o.le-v7-g -lcanadainc -Bdynamic
    LIBS += -L../../autoblocklib/arm/o.le-v7-g -lautoblocklib -Bdynamic
}

simulator {
CONFIG(release, debug|release) {
    DESTDIR = o
    LIBS += -Bstatic -L../../../canadainc/x86/o-g/ -lcanadainc -Bdynamic
    LIBS += -Bstatic -L../../autoblocklib/x86/o-g/ -lautoblocklib -Bdynamic     
}
CONFIG(debug, debug|release) {
    DESTDIR = o-g
    LIBS += -Bstatic -L../../../canadainc/x86/o-g/ -lcanadainc -Bdynamic
    LIBS += -Bstatic -L../../autoblocklib/x86/o-g/ -lautoblocklib -Bdynamic
}
}

include(config.pri)