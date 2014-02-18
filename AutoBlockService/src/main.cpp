#include "precompiled.h"

#include "service.hpp"
#include "Logger.h"

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
#if !defined(QT_NO_DEBUG)
	f = fopen("/var/tmp/autoblock.txt", "w");
	qInstallMsgHandler(redirectedMessageOutput);
#endif

	LOGGER("Started");

	Application app(argc, argv);
	new Service(&app);

	LOGGER("Executing event loop");

	return Application::exec();
}
