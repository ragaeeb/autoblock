#include "precompiled.h"

#include "AutoBlock.hpp"

using namespace bb::cascades;
using namespace autoblock;

Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);

    AutoBlock::create(&app);
    return Application::exec();
}
