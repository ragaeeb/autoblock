#include "precompiled.h"

#include "service.hpp"
#include "Logger.h"

using namespace bb;
using namespace autoblock;

Q_DECL_EXPORT int main(int argc, char **argv)
{
	Application app(argc, argv);

	new Service(&app);
	return Application::exec();
}
