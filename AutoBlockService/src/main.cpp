#include "precompiled.h"

#include "service.hpp"
#include "Logger.h"

using namespace bb;

Q_DECL_EXPORT int main(int argc, char **argv)
{
	Application app(argc, argv);
	autoblock::Service s(&app);

	registerLogging(SERVICE_LOG);

	return Application::exec();
}
