#include "precompiled.h"

#include "AutoBlock.hpp"
#include "Logger.h"

using namespace bb::cascades;
using namespace autoblock;

Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);

    bb::system::InvokeManager i;
    registerLogging( i.startupMode() == ApplicationStartupMode::InvokeCard ? CARD_LOG : UI_LOG );

    AutoBlock ui(&i);
    return Application::exec();
}
