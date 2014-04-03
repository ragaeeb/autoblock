#include "precompiled.h"

#include "AutoBlock.hpp"
#include "Logger.h"

using namespace bb::cascades;
using namespace autoblock;

Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);

    registerLogging("ui.log");

    AutoBlock::create(&app);
    return Application::exec();
}
