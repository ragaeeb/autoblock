#include "precompiled.h"

#include "service.hpp"

using namespace bb;
using namespace autoblock;

#if !defined(QT_NO_DEBUG)
namespace {

FILE* f = NULL;

void redirectedMessageOutput(QtMsgType type, const char *msg)
{
	Q_UNUSED(type);
	fprintf(f, "%s\n", msg);
}

}
#endif

Q_DECL_EXPORT int main(int argc, char **argv)
{
	Application app(argc, argv);

#if !defined(QT_NO_DEBUG)
    f = fopen( QString( QDir::currentPath()+"/logs/service.log").toUtf8().constData(), "w");
    qInstallMsgHandler(redirectedMessageOutput);
#endif

	new Service(&app);
	return Application::exec();
}
